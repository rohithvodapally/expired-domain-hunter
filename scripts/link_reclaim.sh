#!/bin/bash
# link_reclaim.sh — link-reclamation discovery.
# Crawl a page (a niche resource list, competitor "links" page, old blog post),
# extract every external domain it links to, and flag which are now AVAILABLE to
# register. Those dropped domains already have a live backlink pointing at them —
# register one and you inherit that link. Also a security signal: a dead external
# link on a trusted page is a re-registration/abuse vector.
#
# Usage: bash link_reclaim.sh https://example.com/resources
#
# Needs: curl, python3. Uses registry RDAP (free, no key).

URL="$1"
[ -z "$URL" ] && { echo "Usage: $0 <url-of-page-with-outbound-links>"; exit 1; }

echo "Fetching $URL ..."
html=$(curl -sL --max-time 30 -A "Mozilla/5.0 (compatible; link-reclaim/1.0)" "$URL")
[ -z "$html" ] && { echo "Could not fetch page."; exit 1; }

# extract unique registrable domains from href links (skip common infra hosts)
domains=$(echo "$html" \
  | grep -oiE 'href="https?://[^"/]+' \
  | sed -E 's|href="https?://||i; s|^www\.||i' \
  | tr 'A-Z' 'a-z' \
  | grep -viE '(google|facebook|twitter|x\.com|instagram|youtube|linkedin|pinterest|apple|microsoft|amazon|cloudflare|wordpress|gravatar|gstatic|googleapis|bit\.ly|t\.co|fonts|cdn|schema\.org|w3\.org|archive\.org)' \
  | awk -F. '{if (NF>=2) print $(NF-1)"."$NF}' \
  | sort -u)

n=$(echo "$domains" | grep -c .)
echo "Found $n distinct external domains. Checking availability..."
echo

# Only .com/.net give a trustworthy 404 (Verisign is authoritative and always
# supports RDAP). Other TLDs — ccTLDs, .edu, multi-part like co.uk — often lack
# RDAP and would 404 falsely, so we never claim those are available; we list them
# for manual check instead. This avoids "cornell.edu is available" nonsense.
avail=0; manual=0
for d in $domains; do
  case "$d" in
    *.com) ep="https://rdap.verisign.com/com/v1/domain/$d"; auth=1 ;;
    *.net) ep="https://rdap.verisign.com/net/v1/domain/$d"; auth=1 ;;
    *)     ep=""; auth=0 ;;
  esac
  if [ "$auth" = 1 ]; then
    code=$(curl -sL -o /dev/null -w "%{http_code}" --max-time 12 "$ep")
    if [ "$code" = "404" ]; then
      echo "  ⭐ AVAILABLE -> $d   (live backlink on the page; register to reclaim)"
      avail=$((avail+1))
    fi
  else
    manual=$((manual+1))
  fi
  sleep 0.5
done

echo
if [ "$avail" = 0 ]; then
  echo "No available (dropped) .com/.net domains among the outbound links."
else
  echo "$avail reclaimable .com/.net domain(s) found. Verify Wayback history with check_domains.sh before registering."
fi
[ "$manual" -gt 0 ] && echo "($manual non-.com/.net domains skipped — RDAP unreliable for those TLDs; check manually at a registrar.)"
