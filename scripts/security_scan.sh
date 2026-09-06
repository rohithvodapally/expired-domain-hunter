#!/bin/bash
# security_scan.sh — cybersecurity profile of a domain (defensive research).
# Usage: bash security_scan.sh example.com
#
# Uses only free, public data sources: registry RDAP, DNS (dig), Certificate
# Transparency logs (crt.sh), and the Spamhaus DBL. No API keys required.
#
# For a DROPPED/expiring domain it surfaces the "residual trust" risks an
# attacker inherits on re-registration, and gives blue teams a pre-drop checklist.
#
# Checks:
#   1. Registration status (RDAP)                — is it droppable / already gone?
#   2. DNS footprint (A/NS/MX/TXT/CNAME)         — what still points at it
#   3. Dangling-CNAME / subdomain-takeover scan  — deprovisioned-service fingerprints
#   4. Email-trust residue (SPF/DMARC/MX)        — spoofing/phishing inheritance
#   5. Certificate Transparency history (crt.sh) — subdomains + past usage
#   6. Domain reputation (Spamhaus DBL)          — was it abused / burned?

D="$1"
[ -z "$D" ] && { echo "Usage: $0 <domain>"; exit 1; }
line(){ printf '\n=== %s ===\n' "$1"; }

# --- 1. Registration status ------------------------------------------------
line "1. REGISTRATION STATUS (RDAP)"
case "$D" in
  *.com) ep="https://rdap.verisign.com/com/v1/domain/$D" ;;
  *.net) ep="https://rdap.verisign.com/net/v1/domain/$D" ;;
  *)     ep="https://rdap.org/domain/$D" ;;
esac
code=$(curl -sL -o /tmp/sec_rdap_$$.json -w "%{http_code}" --max-time 15 "$ep")
if [ "$code" = "404" ]; then
  echo "UNREGISTERED — available to register (attacker or defender)."
elif [ "$code" = "200" ]; then
  python3 -c "
import json
j=json.load(open('/tmp/sec_rdap_$$.json'))
ev={e['eventAction']:e.get('eventDate','')[:10] for e in j.get('events',[])}
print('registered; created', ev.get('registration','?'), '| expires', ev.get('expiration','?'))
print('status:', ', '.join(j.get('status',[])) or 'n/a')"
else
  echo "RDAP HTTP $code (verify at a registrar)"
fi
rm -f /tmp/sec_rdap_$$.json

# --- 2. DNS footprint ------------------------------------------------------
line "2. DNS FOOTPRINT"
for t in A NS MX TXT; do
  out=$(dig +short "$t" "$D" 2>/dev/null)
  printf '%-4s: %s\n' "$t" "${out:-(none)}"
done

# --- 3. Dangling CNAME / subdomain-takeover scan ---------------------------
line "3. SUBDOMAIN-TAKEOVER / DANGLING-CNAME SCAN"
# A CNAME to a deprovisioned third-party service lets an attacker re-claim it.
# We confirm by matching the live HTTP body against the service's "unclaimed"
# fingerprint. Refs: github.com/EdOverflow/can-i-take-over-xyz  (MITRE T1583.001)
subs="www mail ftp blog dev staging test api cdn shop app m portal help docs support status assets static"
takeover_re='github\.io|herokudns|herokuapp|s3[.-].*amazonaws|cloudfront\.net|azurewebsites|trafficmanager\.net|ghost\.io|wpengine|pantheonsite|fastly\.net|zendesk\.com|readthedocs\.io|surge\.sh|bitbucket\.io|netlify\.app|myshopify|shopify|unbouncepages|helpscoutdocs|cargocollective|wixdns|launchrock|tumblr\.com'
# "unclaimed" response fingerprints (body substrings) per service
fp='There isn.t a GitHub Pages site here|No such app|NoSuchBucket|The specified bucket does not exist|Repository not found|Do you want to register|not found|Sorry, this shop is currently unavailable|The feed has not been found|project not found|Trying to access your account|do not exist|The requested URL was not found|herokucdn.com/error-pages/no-such-app|This UptimeRobot page|is not a registered'
found=0
for s in $subs; do
  c=$(dig +short CNAME "$s.$D" 2>/dev/null | head -1)
  [ -z "$c" ] && continue
  if echo "$c" | grep -qiE "$takeover_re"; then
    a=$(dig +short A "$s.$D" 2>/dev/null | head -1)
    # confirm with a live HTTP fetch against the unclaimed-service fingerprint
    body=$(curl -s --max-time 12 "http://$s.$D" 2>/dev/null | head -c 4000)
    if echo "$body" | grep -qiE "$fp"; then
      verdict="⚠⚠ LIKELY TAKEOVER — live page shows an unclaimed-service fingerprint"
    elif [ -z "$a" ]; then
      verdict="⚠ DANGLING — CNAME to service, no A record (takeover candidate; verify manually)"
    else
      verdict="points to 3rd-party service (in use — lower risk)"
    fi
    echo "  $s.$D -> $c"
    echo "      [$verdict]"
    found=1
  fi
done
[ "$found" = 0 ] && echo "  No CNAMEs to known-takeover-prone services on common subdomains."

# --- 4. Email-trust residue ------------------------------------------------
line "4. EMAIL-TRUST RESIDUE (spoofing/phishing inheritance)"
spf=$(dig +short TXT "$D" 2>/dev/null | grep -i 'v=spf1')
dmarc=$(dig +short TXT "_dmarc.$D" 2>/dev/null | grep -i 'v=DMARC1')
mx=$(dig +short MX "$D" 2>/dev/null)
echo "SPF   : ${spf:-(none)}"
echo "DMARC : ${dmarc:-(none — domain can be spoofed if re-registered)}"
echo "MX    : ${mx:-(none)}"
# SubdoMailing check: expand SPF include:/redirect= targets and test each for
# availability. A buyable include target = attacker sends SPF-passing spoofed
# mail. Ref: labs.guard.io SubdoMailing (8,000+ hijacked domains)
inc=$(echo "$spf" | grep -oiE '(include:|redirect=)[a-z0-9._-]+' | sed -E 's/(include:|redirect=)//i' | sort -u)
if [ -n "$inc" ]; then
  echo "  SPF include/redirect targets (SubdoMailing exposure check):"
  for t in $inc; do
    case "$t" in
      *.com) tep="https://rdap.verisign.com/com/v1/domain/$(echo "$t"|awk -F. '{print $(NF-1)"."$NF}')" ;;
      *.net) tep="https://rdap.verisign.com/net/v1/domain/$(echo "$t"|awk -F. '{print $(NF-1)"."$NF}')" ;;
      *) tep="https://rdap.org/domain/$(echo "$t"|awk -F. '{print $(NF-1)"."$NF}')" ;;
    esac
    tc=$(curl -sL -o /dev/null -w "%{http_code}" --max-time 10 "$tep")
    if [ "$tc" = "404" ]; then
      echo "    ⚠⚠ $t — apex UNREGISTERED = SPF-spoofing takeover risk!"
    else
      echo "    ok   $t"
    fi
  done
fi

# --- 5. Certificate Transparency history -----------------------------------
line "5. CERTIFICATE TRANSPARENCY (crt.sh) — subdomains + history"
curl -s --max-time 30 "https://crt.sh/?q=$D&output=json" -o /tmp/sec_crt_$$.json 2>/dev/null
if [ -s /tmp/sec_crt_$$.json ]; then
  python3 -c "
import json
try:
    d=json.load(open('/tmp/sec_crt_$$.json'))
except Exception:
    print('  (no CT data)'); raise SystemExit
names=set()
years=set()
for c in d:
    for n in c.get('name_value','').split(chr(10)):
        names.add(n.strip().lstrip('*.'))
    y=str(c.get('not_before',''))[:4]
    if y: years.add(y)
print('  certificates on record:', len(d))
if years: print('  active TLS span:', min(years), '-', max(years))
print('  distinct hostnames seen:', len(names))
for n in sorted(names)[:15]:
    print('   -', n)
" 2>/dev/null
else
  echo "  (crt.sh returned nothing)"
fi
rm -f /tmp/sec_crt_$$.json

# --- 6. Domain reputation (Spamhaus DBL) -----------------------------------
line "6. DOMAIN REPUTATION (Spamhaus DBL)"
ans=$(dig +short "$D.dbl.spamhaus.org" A 2>/dev/null | head -1)
if [ -z "$ans" ]; then
  echo "  not listed on Spamhaus DBL (clean)"
else
  case "$ans" in
    127.0.1.*) echo "  ⚠ LISTED on Spamhaus DBL ($ans) — domain has an abuse/spam history. Investigate before use." ;;
    127.255.255.*) echo "  query error/blocked ($ans) — DBL rate-limited or needs a paid resolver for bulk use." ;;
    *) echo "  DBL response: $ans" ;;
  esac
fi

echo
echo "Done. Defensive/research use only — see SECURITY.md for interpretation."
