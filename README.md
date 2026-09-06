# 🕵️ Expired Domain Hunter — a Claude Code skill

Find **expired and dropped domains with real backlinks** for any keyword —
without paying $37/month for SpamZilla or clicking through auction sites for
hours. This skill turns Claude Code into a domain research analyst that sweeps
marketplaces, digs through the Wayback Machine for dead businesses, verifies
availability at the registry level, and hands you a ranked buy report.

## Why this exists

The best expired domains never reach the auction platforms you're watching.
When a small business shuts down, its domain — with years of history and
organically earned backlinks — often just **drops** and becomes hand-registerable
for ~$10. The tools that find these are subscription-gated. The data they use
is not:

- **Registry RDAP** (free) tells you the exact registration status of any domain
- **Wayback Machine CDX** (free) tells you what lived on it and for how long
- **Web search** (free) finds the marketplaces' indexed listings and the ghosts
  of dead businesses

This skill orchestrates all three.

## Real result from the first run

Searching keyword `pestcontrol`, the skill found — among ~50 candidates —
**`rightwaypestcontrol.com`**: a genuine St. Louis pest-control company's domain
with 11 years of Wayback history, previously listed by a domain flipper at
**$395**, sitting **unregistered** — hand-registerable for the price of a pizza.
Plus 20 more available domains with history, 3 buy-now listings with verified
Moz metrics, and a backorder watchlist topped by a domain with 7,573 archive
captures since 2002.

## Install

```bash
# personal (all projects)
git clone https://github.com/YOUR_USERNAME/expired-domain-hunter.git \
  ~/.claude/skills/expired-domain-hunter

# or per-project
git clone https://github.com/YOUR_USERNAME/expired-domain-hunter.git \
  .claude/skills/expired-domain-hunter
```

Requires Claude Code with web search enabled. The verifier script needs only
`bash`, `curl`, and `python3`.

## Use

```
/expired-domain-hunter pestcontrol
```

or just ask naturally:

> find me expired domains containing "plumbing" that have good backlinks

Claude will sweep the sources in parallel, verify every candidate, inspect the
Wayback history of the finalists, and produce a report with:

1. **Top 5 picks** with reasoning
2. **Available-to-register list** (~$10 each) with site histories
3. **Marketplace listings** with metrics — spam-profile red flags called out
4. **Backorder watchlist** of registered-but-dead domains
5. **Redevelop & rank playbook** (same-niche rebuild, restoring old URLs so
   legacy backlinks resolve, staying inside Google's expired-domain policies)

## The standalone verifier

The bundled script works on its own too:

```bash
./scripts/check_domains.sh candidate1.com candidate2.net
# candidate1.com | AVAILABLE (unregistered)          | archive: 2013-2025 (11 yrs w/ snapshots)
# candidate2.net | TAKEN (expires 2027-05-12)        | archive: none
```

## Honest limitations

- Backlink **quality** still needs a look in Ahrefs/Majestic/Moz free checkers
  before you spend real money — this skill verifies history and availability,
  not anchor-text cleanliness.
- Availability is a snapshot; drop-catchers move daily.
- Subscription marketplaces (ODYS, SpamZilla, DomCop) stay closed — the skill
  reports what's walled rather than pretending.

## License

MIT — see [LICENSE](LICENSE).
