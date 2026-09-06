---
name: expired-domain-hunter
description: Find and vet expired/dropped domains for SEO or security research. Sweeps auction marketplaces, hunts defunct businesses via the Wayback Machine, verifies availability + drop-dates via registry RDAP, enriches with authority/spam signals, and produces a ranked buy report — plus a cybersecurity mode (subdomain-takeover, dangling-DNS, SubdoMailing/SPF, CT history, reputation) framed as Attack Surface Management. Use for expired domains, aged domains, dropped domains, domains with backlinks, link reclamation, or domain threat-intel / ASM.
---

# Expired Domain Hunter

Two jobs from one keyword or domain:
1. **SEO mode** (default) — find dropped/expired domains with real history + backlinks worth rebuilding on.
2. **Security mode** — profile a domain (or an org's footprint) for expired-asset attack surface: subdomain takeover, dangling DNS, SubdoMailing/SPF abuse, reputation. See `SECURITY.md`.

Bundled scripts (bash + curl + python3, no API keys required):
- `scripts/check_domains.sh` — RDAP availability + drop-date prediction + Wayback history (`CSV=1` for machine output)
- `scripts/security_scan.sh` — full cybersecurity profile of one domain
- `scripts/link_reclaim.sh` — find registerable domains linked from any resource page

---

## SEO MODE

### Inputs
- **keyword** (required) — must appear in the domain, e.g. "pestcontrol"
- niche/intent (local business / ecommerce / content) — shapes ranking
- TLD preference (default .com, then .net/.org)

### Phase 1 — Discovery (run these angles in PARALLEL subagents)

**A. Auction/marketplace sweep** (WebSearch + WebFetch): fetchable = expireddomains.**com**, dynadot.com/market/auction, Atom.com, Flippa. Usually walled (try once, move on) = expireddomains.**net**, GoDaddy Auctions, Sedo, Namecheap, DropCatch, Sav. Dan.com is dead (→Afternic). Capture domain, price, any metrics, listing URL.

**B. Defunct-business hunt** (highest yield): WebSearch old citations of `<keyword>` companies (Yelp/BBB/YellowPages, old blogs/forums), `site:web.archive.org <keyword>`. Dead site + multi-year archive = prime candidate. This is our signature angle — most tools don't do it.

**C. Curated aged shops**: ODYS, SpamZilla, DomCop, SerpNames are login/subscription-gated — check for indexed pages but report walls honestly.

**D. Link reclamation** (unique angle): if the user has a niche resource page / competitor links page / old article, run `link_reclaim.sh <url>` to find dropped domains already linked from it.

**Anti-hallucination rule (critical):** only report domains actually seen in a fetched page or search result, each with an evidence URL. NEVER invent domain names.

### Phase 2 — Verify (scripts/check_domains.sh)
Run on every candidate. Reports availability (RDAP 404 = hand-registerable ~$10), **drop-date prediction** from EPP status (pendingDelete ≈ 5 days, redemption ≈ 30 days, or estimate from expiry), and Wayback depth. Use `CSV=1` to produce a sortable table.

### Phase 3 — Enrich the finalists (top 3-8)
- **History quality**: year-by-year snapshots (`curl "https://web.archive.org/cdx/search/cdx?url=<d>&fl=timestamp,statuscode&collapse=timestamp:4"`), page inventory, and fetch one mid-history snapshot with curl (WebFetch is often blocked for web.archive.org; use long timeouts) to extract business name/location/services. Real business = good; spun/parked/foreign-spam = skip.
- **Authority signal** (optional): if the user has an OpenPageRank free API key (domcop.com/openpagerank), fetch a DA-like 0-10 score. Otherwise instruct them to spot-check in Ahrefs/Majestic/Moz free checkers.
- **Google index/penalty check**: WebSearch `site:<domain>` — zero results ≈ de-indexed/penalized (red flag). Cross-check for a Wayback traffic/coverage cliff.
- **Automated spam scan**: from the CDX status history + a fetched snapshot, flag casino/pharma/adult/CJK anchors or a year the site flipped to parked/spam. Downrank anything with a spam interlude.

### Phase 4 — Ranked report
Rank by: history depth (years, capture count, site type) → name quality (no-hyphen > hyphen, shorter, .com) → verified metrics → niche/geo match. Structure:
1. **Top 5 picks** with reasoning
2. **Available-to-register** (~$10) with one-line histories + drop-dates
3. **Marketplace listings** with metrics/prices — flag suspicious profiles (high RD + low DA + spam ≥6 = likely spammed)
4. **Watchlist**: registered-but-dead to backorder (DropCatch/SnapNames/GoDaddy)
5. **How to buy** + **redevelop-and-rank playbook**

### Always caveat
- Verify backlink profile in Ahrefs/Majestic/Moz before paying >$50 (anchor-text poison).
- Availability changes daily — drop-catchers are fast; re-verify at purchase.
- Google's expired-domain-abuse policy: rebuild in the SAME niche with real content (legit); unrelated flips get punished. Restore old URL paths (from Wayback) so legacy backlinks resolve. Aged domains buy faster indexing, not instant rankings.

### Optional — continuous monitoring
For watchlist domains, use the `schedule` or `loop` skill to re-run `check_domains.sh` on a cadence and alert when a domain hits pendingDelete / becomes AVAILABLE.

---

## SECURITY MODE (ASM / domain threat-intel)

Run `scripts/security_scan.sh <domain>` and interpret with `SECURITY.md`. Six keyless checks: subdomain-takeover (HTTP-fingerprint confirmed), DNS footprint, SubdoMailing/SPF-include re-registration risk, email-auth posture, Certificate Transparency history (crt.sh), Spamhaus DBL reputation. Maps to MITRE ATT&CK T1583.001 and OWASP. Extendable (documented, need keys): dnstwist typosquats, Google Safe Browsing / VirusTotal / urlscan.io, abuse.ch C2 feeds, passive DNS, scheduled blue-team monitoring.

Defensive/authorized use only — flags takeover *candidates*, never claims them.
