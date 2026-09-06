#!/bin/bash
# check_domains.sh — verify registration status (RDAP) + Wayback history
# Usage: ./check_domains.sh domain1.com domain2.net ...
#
# Output per domain:
#   <domain> | AVAILABLE or TAKEN (created/expires) | archive: first-last (N yrs)
#
# Notes:
# - .com/.net use Verisign RDAP directly (rdap.org can hang on unregistered names)
# - HTTP 404 from the registry = unregistered = hand-registerable right now
# - "archive: none" = no Wayback history = no backlink value, keyword value only

if [ $# -eq 0 ]; then
  echo "Usage: $0 domain1.com domain2.net ..." >&2
  exit 1
fi

for d in "$@"; do
  case "$d" in
    *.com) ep="https://rdap.verisign.com/com/v1/domain/$d" ;;
    *.net) ep="https://rdap.verisign.com/net/v1/domain/$d" ;;
    *)     ep="https://rdap.org/domain/$d" ;;
  esac
  code=$(curl -sL -o /tmp/rdap_$$.json -w "%{http_code}" --max-time 15 "$ep")
  if [ "$code" = "404" ]; then
    status="AVAILABLE (unregistered)"
  elif [ "$code" = "200" ]; then
    exp=$(python3 -c "
import json
try:
  j=json.load(open('/tmp/rdap_$$.json'))
  ev={e['eventAction']:e.get('eventDate','') for e in j.get('events',[])}
  print('registered; expires ' + ev.get('expiration','?')[:10] + '; created ' + ev.get('registration','?')[:10])
except Exception: print('registered')")
    status="TAKEN ($exp)"
  else
    status="UNKNOWN (RDAP HTTP $code — verify at a registrar)"
  fi
  wb=$(curl -s --max-time 20 "https://web.archive.org/cdx/search/cdx?url=$d&fl=timestamp&collapse=timestamp:4&limit=100" 2>/dev/null)
  if [ -n "$wb" ]; then
    first=$(echo "$wb" | head -1 | cut -c1-4)
    last=$(echo "$wb" | tail -1 | cut -c1-4)
    years=$(echo "$wb" | wc -l | tr -d ' ')
    hist="archive: $first-$last (${years} yrs w/ snapshots)"
  else
    hist="archive: none"
  fi
  printf "%-40s | %-58s | %s\n" "$d" "$status" "$hist"
  sleep 1
done
rm -f /tmp/rdap_$$.json
