# 🕵️ Expired Domain Hunter — Dropped-Domain Finder, Backlink Vetter & Domain Security Scanner

> A free **Claude Code skill** that finds expired & dropped domains with real
> backlinks for any keyword, verifies availability + drop-dates via registry
> RDAP, digs their history out of the Wayback Machine, flags spam/penalty
> signals — and doubles as a **domain security scanner** (subdomain-takeover,
> dangling-DNS, SPF/SubdoMailing, Certificate Transparency & reputation).

Find **expired and dropped domains with real backlinks** for any keyword — *and*
analyze any domain for **expired-asset security risks**. One skill, two jobs:
SEO domain prospecting and domain **Attack Surface Management (ASM)**.

Runs on free, public data only — registry **RDAP**, the **Wayback Machine**,
**Certificate Transparency** (crt.sh), and **DNS/DNSBLs**. No SpamZilla
subscription, no API keys required.

---

## Why it's different

Most expired-domain tools compete on one thing: scraping auction lists and
showing you DA/TF metrics. This one adds two angles they don't have:

**1. It hunts dead businesses, not just auctions.** The best domains never reach
the marketplaces you're watching — when a small business folds, its domain (with
years of organically-earned local backlinks) just *drops*. This skill digs them
out of the Wayback Machine, extracts the old business's name/location/services
to prove the history is real, and confirms the domain is hand-registerable for
~$10.

**2. It has a cybersecurity mode.** Expired and *dangling* domains are a
documented attack class (MITRE ATT&CK **T1583.001**). The bundled
`security_scan.sh` profiles any domain for **subdomain takeover**, **dangling
DNS**, **SubdoMailing/SPF-include hijacking**, **Certificate Transparency**
exposure, and **reputation** — usable as red-team recon *or* blue-team ASM.
See **[SECURITY.md](SECURITY.md)**. No other expired-domain skill does this.

Plus the discipline reviewers notice: **every domain in a report carries an
evidence URL** (no hallucinated names), and reports end with a **redevelop-and-
rank playbook** that keeps you inside Google's expired-domain-abuse policy.

## Real result from the first run

Keyword `pestcontrol` → among ~50 candidates, the skill found
**`rightwaypestcontrol.com`**: a real St. Louis pest-control company's domain,
11 years of Wayback history, once listed by a flipper at **$395**, sitting
**unregistered** — hand-registerable for the price of a coffee. See
[examples/pestcontrol-report.txt](examples/pestcontrol-report.txt).

## Install

```bash
git clone https://github.com/rohithvodapally/expired-domain-hunter.git \
  ~/.claude/skills/expired-domain-hunter        # personal (all projects)
# or: .claude/skills/expired-domain-hunter      # per-project
```

Requires Claude Code with web search. Scripts need `bash`, `curl`, `python3`
(and `dig` for the security scan).

## Use

```
/expired-domain-hunter pestcontrol
```
or ask naturally:
> find me expired domains containing "plumbing" with good backlinks
>
> run a security scan on example.com for dangling subdomains

## What you get

**SEO mode** — parallel discovery (auctions + Wayback defunct-business hunt +
curated shops + link reclamation) → RDAP verification with **drop-date
prediction** → history/authority/spam enrichment → a ranked report: top 5 picks,
available-to-register list (~$10), marketplace listings with red-flag warnings,
a backorder watchlist, and the rebuild playbook.

**Security mode** — a six-check domain threat profile (subdomain takeover,
dangling DNS, SPF/SubdoMailing, email-auth, CT history, reputation), mapped to
MITRE ATT&CK and OWASP. Great as a portfolio project — see SECURITY.md's
framing section.

## The scripts (usable standalone)

```bash
# availability + drop-date + wayback history (CSV=1 for a sortable table)
bash scripts/check_domains.sh candidate1.com candidate2.net
CSV=1 bash scripts/check_domains.sh candidate1.com > results.csv

# full cybersecurity profile of a domain
bash scripts/security_scan.sh example.com

# link reclamation: dropped domains linked from a resource page
bash scripts/link_reclaim.sh https://example.com/useful-links
```

## Honest limitations

- Backlink **quality** still needs an eyeball in Ahrefs/Majestic/Moz free
  checkers before you spend real money — the skill verifies history, availability,
  and (optionally) an OpenPageRank score, not anchor-text cleanliness.
- Availability is a snapshot; drop-catchers move daily.
- RDAP 404 is trustworthy only for `.com`/`.net` (Verisign); other TLDs get
  flagged for manual check rather than falsely called available.
- Subscription marketplaces (ODYS, SpamZilla, DomCop) stay closed — the skill
  reports what's walled rather than pretending.
- Security mode is for **authorized/defensive** use: it flags takeover
  *candidates* from public data, never attempts exploitation.

## License

MIT — see [LICENSE](LICENSE).
