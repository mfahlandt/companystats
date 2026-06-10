#!/bin/bash
# Refresh country contributor/commits data from DevStats Grafana SQL API
# This runs server-side (no CORS restrictions) and updates the embedded data in devstats-search.html
#
# Usage: ./country-data-refresh.sh
# Requires: curl, python3

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
HTML_FILE="$SCRIPT_DIR/index.html"
GRAFANA_API="https://all.devstats.cncf.io/api/ds/query"

echo "🔄 Fetching country data from DevStats..."

# Fetch yearly contributors
echo "  → Yearly contributors..."
YEARLY_CONTRIBUTORS=$(curl -sf -X POST "$GRAFANA_API" \
  -H 'Content-Type: application/json' \
  -d '{"queries":[{"refId":"A","datasourceId":1,"format":"table","rawSql":"SELECT * FROM scountries WHERE series = '\''countriesallcontributors'\'' AND period = '\''y'\'' ORDER BY time"}]}')

# Fetch cumulative contributors
echo "  → Cumulative contributors..."
CUM_CONTRIBUTORS=$(curl -sf -X POST "$GRAFANA_API" \
  -H 'Content-Type: application/json' \
  -d '{"queries":[{"refId":"A","datasourceId":1,"format":"table","rawSql":"SELECT * FROM scountriescum WHERE series = '\''countriescumallcontributors'\'' AND period = '\''m'\'' ORDER BY time DESC LIMIT 1"}]}')

# Fetch yearly commits
echo "  → Yearly commits..."
YEARLY_COMMITS=$(curl -sf -X POST "$GRAFANA_API" \
  -H 'Content-Type: application/json' \
  -d '{"queries":[{"refId":"A","datasourceId":1,"format":"table","rawSql":"SELECT * FROM scountries WHERE series = '\''countriesallcommits'\'' AND period = '\''y'\'' ORDER BY time"}]}')

# Fetch cumulative commits
echo "  → Cumulative commits..."
CUM_COMMITS=$(curl -sf -X POST "$GRAFANA_API" \
  -H 'Content-Type: application/json' \
  -d '{"queries":[{"refId":"A","datasourceId":1,"format":"table","rawSql":"SELECT * FROM scountriescum WHERE series = '\''countriescumallcommits'\'' AND period = '\''m'\'' ORDER BY time DESC LIMIT 1"}]}')

echo "📊 Processing data..."

# Process all data with Python and generate the embedded JS
EMBEDDED_DATA=$(python3 << 'PYTHON'
import json, sys, os
from datetime import datetime, timezone

def parse_yearly(raw_json):
    data = json.loads(raw_json)
    frames = data['results']['A']['frames']
    if not frames:
        return {}
    schema = frames[0]['schema']['fields']
    values = frames[0]['data']['values']
    time_vals = values[0]
    country_names = [f['name'] for f in schema[3:]]
    yearly = {}
    for row_idx in range(len(time_vals)):
        ts = time_vals[row_idx]
        year = str(datetime.fromtimestamp(ts / 1000, tz=timezone.utc).year)
        yearly[year] = {}
        for ci, country in enumerate(country_names):
            val = values[ci + 3][row_idx]
            if val is not None and val > 0:
                yearly[year][country] = int(val)
    return yearly

def parse_cumulative(raw_json):
    data = json.loads(raw_json)
    frames = data['results']['A']['frames']
    if not frames:
        return {}
    schema = frames[0]['schema']['fields']
    values = frames[0]['data']['values']
    country_names = [f['name'] for f in schema[3:]]
    cumulative = {}
    for ci, country in enumerate(country_names):
        val = values[ci + 3][0] if values[ci + 3] else None
        if val is not None and val > 0:
            cumulative[country] = int(val)
    return dict(sorted(cumulative.items(), key=lambda x: x[1], reverse=True))

yearly_contributors = parse_yearly(os.environ['YEARLY_CONTRIBUTORS'])
cum_contributors = parse_cumulative(os.environ['CUM_CONTRIBUTORS'])
yearly_commits = parse_yearly(os.environ['YEARLY_COMMITS'])
cum_commits = parse_cumulative(os.environ['CUM_COMMITS'])

combined = {
    'lastUpdated': datetime.now(timezone.utc).strftime('%Y-%m-%dT%H:%M:%SZ'),
    'contributors': {
        'yearly': yearly_contributors,
        'cumulative': cum_contributors
    },
    'commits': {
        'yearly': yearly_commits,
        'cumulative': cum_commits
    }
}

print(json.dumps(combined, separators=(',', ':')))
PYTHON
)

if [ -z "$EMBEDDED_DATA" ]; then
  echo "❌ Failed to process data"
  exit 1
fi

echo "📝 Updating HTML file..."

# Use Python to replace the embedded data in the HTML file
python3 << PYTHON
import re, sys

html_file = "$HTML_FILE"
with open(html_file, 'r') as f:
    html = f.read()

new_data = '''$EMBEDDED_DATA'''

# Replace the COUNTRIES_DATA block
pattern = r'const COUNTRIES_DATA = \{.*?\};(\s*// END COUNTRIES_DATA)'
replacement = f'const COUNTRIES_DATA = {new_data};\\1'

new_html = re.sub(pattern, replacement, html, flags=re.DOTALL)

if new_html == html:
    print("⚠️  Could not find COUNTRIES_DATA block to replace!")
    sys.exit(1)

with open(html_file, 'w') as f:
    f.write(new_html)

print(f"✅ Updated {html_file}")
data_size = len(new_data)
print(f"   Data size: {data_size:,} bytes")
PYTHON

echo "✅ Done! Country data refreshed."
