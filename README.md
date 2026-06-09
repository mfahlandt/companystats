# CompanyStats

Quick hack to search CNCF DevStats for companies and see who's actually contributing. Has a Europe leaderboard because that's what I needed.

Live: **[mfahlandt.github.io/companystats](https://mfahlandt.github.io/companystats)**

## What it does

- Fuzzy search ~1,800 companies across CNCF projects
- Shows country flags (best-guess, see below)
- Europe leaderboard — flat list sorted by contributions, or grouped by country
- EU-only toggle, project selector, time range picker

## How country mapping works

Company → country is a **static mapping** (~1,480 entries). It's based on:
- Known HQ locations for major companies
- Suffix heuristics (GmbH → DE, AB → SE, Ltd → UK, etc.)

This means:
- Companies get **one country**, even if they have offices worldwide. It's the HQ / registration country.
- A company might change country if they re-incorporate (e.g. after a merger or relocation). The mapping gets updated manually — no automation for this.
- If a company isn't in the mapping, no flag shows up. PRs welcome.
- It's **not** based on where contributions come from — just where the company is legally based.

## Disclaimer

This is an unofficial side project. Not affiliated with CNCF. Data comes from [devstats.cncf.io](https://devstats.cncf.io) — if the numbers look wrong, that's where they live. Country assignments are approximate and may be wrong. Don't use this for anything that matters.

## Tech

No build step, no backend, no framework. Just HTML + JS + CSS calling the DevStats API directly (it has open CORS). 

## License

Apache 2.0 — see [LICENSE](LICENSE).