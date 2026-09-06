#!/bin/bash
# check_domains.sh — verify registration status (RDAP) + drop-date + Wayback history
# Usage:
#   bash check_domains.sh domain1.com domain2.net ...
#   CSV=1 bash check_domains.sh domain1.com ...     # machine-readable output
#
# Per domain:
#   - Registration status via registry RDAP (Verisign for .com/.net; rdap.org else)
#     HTTP 404 = UNREGISTERED = hand-registerable right now.
#   - EPP status parsing -> DROP-DATE PREDICTION for expiring domains
#     (pendingDelete ~5 days to release; redemptionPeriod ~30 days prior).
#   - Wayback history: first/last snapshot year + years-with-snapshots
#     ("archive: none" = no backlink value, keyword value only).

if [ $# -eq 0 ]; then
  echo "Usage: $0 [CSV=1] domain1.com domain2.net ..." >&2
  exit 1
fi

[ "$CSV" = "1" ] && echo "domain,status,created,expires,epp_status,drop_estimate,archive_years,archive_span"

for d in "$@"; do
  case "$d" in
    *.com) ep="https://rdap.verisign.com/com/v1/domain/$d" ;;
    *.net) ep="https://rdap.verisign.com/net/v1/domain/$d" ;;
    *)     ep="https://rdap.org/domain/$d" ;;
  esac
  code=$(curl -sL -o /tmp/rdap_$$.json -w "%{http_code}" --max-time 15 "$ep")

  status="TAKEN"; created=""; expires=""; epp=""; drop=""
  if [ "$code" = "404" ]; then
    status="AVAILABLE"
  elif [ "$code" = "200" ]; then
    read -r created expires epp drop < <(python3 -c "
import json,datetime
try:
    j=json.load(open('/tmp/rdap_$$.json'))
except Exception:
    print('? ? ? ?'); raise SystemExit
ev={e['eventAction']:e.get('eventDate','')[:10] for e in j.get('events',[])}
st=[s.lower() for s in j.get('status',[])]
created=ev.get('registration','?'); expires=ev.get('expiration','?')
epp='|'.join(s.replace(' ','') for s in st) or 'active'
drop='-'
# drop-date heuristics from EPP lifecycle
if any('pendingdelete' in s for s in st):
    drop='~5 days (pendingDelete -> release)'
elif any('redemption' in s for s in st):
    drop='~30 days (redemption -> pendingDelete)'
elif expires not in ('?',''):
    try:
        exp=datetime.date.fromisoformat(expires)
        today=datetime.date(2026,8,24)
        days=(exp-today).days
        if days<0: drop=f'EXPIRED {abs(days)}d ago -> ~45-75d to drop'
        elif days<45: drop=f'expires in {days}d -> watch for drop ~{days+75}d'
    except Exception: pass
print(created, expires, epp, drop.replace(' ','_'))
")
  else
    status="UNKNOWN_HTTP_$code"
  fi

  wb=$(curl -s --max-time 20 "https://web.archive.org/cdx/search/cdx?url=$d&fl=timestamp&collapse=timestamp:4&limit=100" 2>/dev/null)
  if [ -n "$wb" ]; then
    afirst=$(echo "$wb" | head -1 | cut -c1-4); alast=$(echo "$wb" | tail -1 | cut -c1-4)
    ayears=$(echo "$wb" | wc -l | tr -d ' ')
  else
    afirst=""; alast=""; ayears="0"
  fi

  if [ "$CSV" = "1" ]; then
    span=""; [ -n "$afirst" ] && span="$afirst-$alast"
    echo "$d,$status,${created:-},${expires:-},${epp:-},$(echo "$drop"|tr '_' ' '),$ayears,$span"
  else
    if [ "$status" = "AVAILABLE" ]; then
      st="AVAILABLE (unregistered)"
    elif [ "$status" = "TAKEN" ]; then
      st="TAKEN (created ${created:-?}; expires ${expires:-?})"
      [ -n "$drop" ] && [ "$drop" != "-" ] && st="$st | drop: $(echo "$drop"|tr '_' ' ')"
    else
      st="$status (verify at a registrar)"
    fi
    if [ "$ayears" = "0" ]; then hist="archive: none"; else hist="archive: $afirst-$alast (${ayears} yrs w/ snapshots)"; fi
    printf "%-38s | %-60s | %s\n" "$d" "$st" "$hist"
  fi
  sleep 1
done
rm -f /tmp/rdap_$$.json
