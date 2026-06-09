# CompanyStats

🔍 Fuzzy search for companies contributing to CNCF projects, with country flags and a Europe Top leaderboard.

Built on data from [CNCF DevStats](https://devstats.cncf.io).

## Features

- **Company Search** — fuzzy search across 1,800+ companies contributing to CNCF projects
- **Country Flags** — every company gets a flag based on HQ country
- **Europe Top** — flat leaderboard of all European companies by contributions, with global rank
- **By Country** — grouped view showing companies per European country with totals
- **EU-only toggle** — filter to EU-27 member states
- **Project selector** — switch between All CNCF, Kubernetes, Prometheus, etc.
- **Time range** — Last year / Last decade / Last month

## Live

👉 **[mfahlandt.github.io/companystats](https://mfahlandt.github.io/companystats)**

## Tech

Pure HTML + JS + CSS, no build step, no backend. Calls the DevStats API directly (CORS-open).

Company → country mapping is a static JS file with ~1,480 known mappings.

## License

MIT