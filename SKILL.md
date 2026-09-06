---
name: expired-domain-hunter
description: Find and vet expired/dropped domains containing a keyword — sweeps auction marketplaces, hunts defunct businesses via the Wayback Machine, verifies availability via registry RDAP, and produces a ranked buy report with backlink-quality guidance. Use when the user wants expired domains, aged domains, dropped domains, or domains with existing backlinks for SEO/redevelopment.
---

# Expired Domain Hunter

Find expired and dropped domains containing the user's keyword that have real
history and backlinks, verify what can actually be bought (and how), and
deliver a ranked report. The biggest wins are domains that dropped completely —
hand-registerable for ~$10 despite years of history.

## Inputs

Ask for (or infer from the request):
- **keyword** (required) — must appear in the domain name, e.g. "pestcontrol"
- niche/intent (local business, ecommerce, content site) — shapes ranking
- TLD preferences (default: .com first, then .net/.org)

## Workflow

### Phase 1 — Discovery (run these three angles in parallel subagents)

**Angle A: Auction/marketplace sweep** (WebSearch + WebFetch):
- Fetchable without login: `expireddomains.com` (note: the .COM site — the
  better-known expireddomains.NET is login-walled), `dynadot.com/market/auction`,
  Atom.com listing pages, Flippa search.
- Usually walled (403/JS-shell — try once, then move on): expireddomains.net,
  GoDaddy Auctions, Sedo, Namecheap Market, DropCatch, Sav, park.io.
  Dan.com is discontinued (301s to Afternic).
- Also WebSearch: `site:expireddomains.com <keyword>`, `"<keyword>" domain auction`,
  `site:afternic.com <keyword>`, etc.
- Capture: domain, price, any published metrics (DA/PA/TF/CF/referring domains,
  age, spam score), listing URL.

**Angle B: Defunct-business hunt** (the highest-yield angle):
- WebSearch for old citations of `<keyword>` company websites: directory pages
  (Yelp/BBB/YellowPages), old blog/forum mentions, `site:web.archive.org <keyword>`.
- The Wayback Machine's search index surfaces historical domains; per-domain CDX
  lookups then confirm capture history.
- A dead site + multi-year archive history = prime candidate.

**Angle C: Curated aged-domain shops**:
- ODYS, SpamZilla, DomCop, SerpNames are subscription/login-gated — check for
  indexed inventory pages via WebSearch but expect little; report walls honestly.

**Anti-hallucination rule (critical):** only report domains actually seen in a
fetched page or search result, each with an evidence URL. NEVER invent or
"generate plausible" domain names for the report.

### Phase 2 — Verification (scripts/check_domains.sh)

Run the bundled verifier on every candidate:

```bash
scripts/check_domains.sh domain1.com domain2.net ...
```

Per domain it reports:
- **Registration status** via registry RDAP (Verisign for .com/.net — HTTP 404
  means UNREGISTERED = hand-registerable now; rdap.org for other TLDs, where a
  timeout on unregistered names is common — treat timeouts as "unknown, check
  at a registrar").
- **Wayback history**: first/last snapshot year and number of years with captures.

### Phase 3 — History quality check (top candidates only)

For the best 3-5 candidates, inspect what the site actually was:
- Year-by-year snapshots: `curl "https://web.archive.org/cdx/search/cdx?url=<domain>&fl=timestamp,statuscode&collapse=timestamp:4"`
- Page inventory: `...cdx?url=<domain>/*&fl=original&collapse=urlkey&filter=statuscode:200&limit=25`
- Fetch one mid-history snapshot with curl (WebFetch is often blocked for
  web.archive.org; the replay endpoint can be slow — use generous timeouts and
  retries) and extract: business name, location, services, phone. A real local
  business or genuine content site = good; thin/spun/foreign-spam content = skip.

### Phase 4 — Ranked report

Rank by: (1) real-history depth (years, capture count, site type — ecommerce/
forum/association usually out-link small brochure sites), (2) name quality
(no hyphens > hyphens; shorter > longer; .com > rest), (3) verified metrics
where available, (4) niche/geo match to the user's intent.

Structure the report:
1. **Top 5 picks** with reasoning
2. **All available-to-register** (~$10 path) with one-line histories
3. **Marketplace listings** with metrics and prices — flag suspicious profiles
   (high RD + low DA + spam score ≥6 = likely spammed; say so)
4. **Watchlist**: registered-but-dead domains worth backordering (DropCatch/
   SnapNames/GoDaddy, ~$59-79)
5. **How to buy** per path + **redevelop-and-rank playbook**

### Always include these caveats

- Backlink counts are only as good as the source; tell the user to verify the
  link profile in Ahrefs/Majestic/Moz free checkers before paying >$50
  (anchor-text poison: casino/pharma/CJK spam anchors).
- Availability changes daily — drop-catchers are fast; re-verify at purchase.
- Google's expired-domain-abuse policy: rebuilding in the SAME niche with real
  content is the legitimate use; unrelated-content flips get punished. Advise
  restoring old URL paths (from Wayback) so legacy backlinks resolve.
- Aged domains buy faster indexing and crawl trust, not instant rankings.
