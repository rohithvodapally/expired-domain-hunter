# Domain Threat Intelligence & Attack Surface Management

The security half of this project. It treats expired, dropped, and **dangling**
domains as what they actually are in infosec: an attack surface. Attackers
re-register abandoned assets to inherit trust (MITRE ATT&CK
[T1583.001 — Acquire Infrastructure: Domains](https://attack.mitre.org/techniques/T1583/001/));
defenders need to find their own forgotten assets first.

Run it with:

```bash
bash scripts/security_scan.sh example.com
```

Free, keyless data sources only: registry **RDAP**, **DNS** (`dig`),
**Certificate Transparency** ([crt.sh](https://crt.sh)), and the **Spamhaus DBL**.

---

## What it checks, and why each matters

| # | Check | Detects | Real-world stakes |
|---|-------|---------|-------------------|
| 1 | **Subdomain-takeover scan** | A subdomain whose CNAME points to a deprovisioned service (GitHub Pages, S3, Heroku, Azure, Shopify…), confirmed by matching the live HTTP body against the service's "unclaimed" fingerprint | Attacker re-claims the host and serves content, steals cookies, and passes cert/DV validation under a trusted name. Ref: [can-i-take-over-xyz](https://github.com/EdOverflow/can-i-take-over-xyz) |
| 2 | **DNS footprint** | Every live A/NS/MX/TXT record still attached to the domain | Baseline attack surface; NS pointing to a deleted cloud zone = full-subdomain hijack |
| 3 | **SubdoMailing / SPF-include analysis** | Expands SPF `include:`/`redirect=` targets and RDAP-checks each apex for availability | If an included domain is buyable, an attacker adds their IPs and sends **SPF-passing, DMARC-aligned** spoofed mail. Guardio's SubdoMailing weaponized 8,000+ domains this way. Ref: [Guardio Labs](https://labs.guard.io/subdomailing-thousands-of-hijacked-major-brand-subdomains-found-bombarding-users-with-millions-a5e5fb892935) |
| 4 | **Email-auth posture** | Missing/weak DMARC (`p=none`), broad SPF, no MX | The gap that lets #3 actually deliver mail |
| 5 | **Certificate Transparency history** | Historical subdomains + TLS timeline from crt.sh | Passive attack-surface mapping; a *new* cert on your dangling host is a live-takeover alarm. Ref: [crt.sh](https://crt.sh) |
| 6 | **Domain reputation** | Spamhaus DBL listing | Separates a clean expired domain from one with a burned/abused history you'd inherit |
| — | **Residual-trust age flag** | (via the main `check_domains.sh` RDAP + crt.sh combo) recent creation date + old CT/backlink footprint | The dropcatch-abuse signature. Infoblox tracked ~65k malicious re-registrations/day; "Sable Squirrel" spent ~$7M on 10k+ domains for malware C2. Ref: [Infoblox](https://www.infoblox.com/blog/) |

## Extending it (documented, optional — needs API keys)

The scanner is deliberately keyless. These are the natural next modules, each
with its free-tier source, noted in the code comments:

- **Typosquat/homograph generation** — [dnstwist](https://github.com/elceef/dnstwist) `--registered --mxcheck`
- **Multi-source reputation** — Google Safe Browsing v4, VirusTotal v3 (4 req/min free), [urlscan.io](https://docs.urlscan.io/)
- **C2 / sinkhole residual-risk** — [abuse.ch ThreatFox / URLhaus / Feodo](https://threatfox.abuse.ch/) (free API key)
- **Passive DNS** — Spamhaus Passive DNS API, SecurityTrails free tier
- **Continuous monitoring (blue-team ASM)** — cron-snapshot crt.sh + RDAP + DNS, diff for new certs/subdomains/expiry (see `check_domains.sh` as the scheduling primitive)

---

## Portfolio framing

Present this as an **Attack Surface Management (ASM) and domain threat-intelligence
tool** that operationalizes a documented threat class — abuse of expired, dropped,
and dangling domain assets (**MITRE ATT&CK T1583.001**). It works both ways:

- **Offensive / red-team recon:** enumerate a target org's dangling CNAMEs,
  weak SPF includes, and lookalike domains.
- **Defensive / blue-team ASM:** monitor your own footprint via CT logs + RDAP to
  catch forgotten assets before attackers re-register them (~13% of lapsed
  corporate domains get re-registered by third parties).

Talking points that read as security-literate, not just scripting:

- Built on **free, authoritative sources** (crt.sh, RDAP, DNSBLs) instead of paid black boxes.
- **False-positive reduction:** confirms takeovers by HTTP-fingerprint matching, not naive CNAME inspection.
- **Respects query etiquette / rate limits** (e.g., Spamhaus prohibits automated web-form queries — this uses the DNS interface).
- Mapped to framework references: [OWASP Subdomain Takeover Cheat Sheet](https://cheatsheetseries.owasp.org/cheatsheets/Subdomain_Takeover_Prevention_Cheat_Sheet.html), MITRE ATT&CK.

Ground your write-up in named incidents to show landscape awareness: Guardio
**SubdoMailing** (8,000+ hijacked subdomains), Infoblox **Sable Squirrel**
dropcatch operation, the **Conficker** sinkhole-domain expiry (three sinkhole
domains lapsed in 2011 and were re-bought), and the Georgia Tech
[combosquatting study](https://www.securitee.org/files/combosquatting_ccs2017.pdf).

## Ethics & scope

Defensive research and authorized testing only. Scan domains you own or are
explicitly permitted to assess. The tool reads public data (DNS, CT logs, RDAP,
DNSBLs) and never attempts exploitation — it flags takeover *candidates*, it does
not claim them.
