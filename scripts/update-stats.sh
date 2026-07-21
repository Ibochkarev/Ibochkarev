#!/usr/bin/env bash
# Refresh open-source PR counters into stats.json and README.md
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
cd "$ROOT"

USER="${GITHUB_ACTOR:-Ibochkarev}"
# Prefer explicit login for search queries
LOGIN="${STATS_LOGIN:-Ibochkarev}"

count() {
  local q="$1"
  gh api "search/issues?q=${q}&per_page=1" --jq '.total_count'
}

plus() {
  local n="$1"
  echo "${n}+"
}

echo "Fetching PR stats for ${LOGIN}..."

MERGED=$(count "author:${LOGIN}+type:pr+is:merged")
NUXT_NUXT=$(count "author:${LOGIN}+type:pr+is:merged+repo:nuxt/nuxt")
TG_NUXT=$(count "author:${LOGIN}+type:pr+is:merged+repo:translation-gang/nuxt")
DOCS_RU=$(count "author:${LOGIN}+type:pr+is:merged+repo:vuejs-translations/docs-ru")
TG_NUXT_COM=$(count "author:${LOGIN}+type:pr+is:merged+repo:translation-gang/nuxt.com")
MODX_PRO=$(count "author:${LOGIN}+type:pr+is:merged+org:modx-pro")
MODXCMS=$(count "author:${LOGIN}+type:pr+is:merged+org:modxcms")

UPDATED_AT=$(date -u +%Y-%m-%d)

MERGED_L=$(plus "$MERGED")
NUXT_NUXT_L=$(plus "$NUXT_NUXT")
TG_NUXT_L=$(plus "$TG_NUXT")
DOCS_RU_L=$(plus "$DOCS_RU")
TG_NUXT_COM_L=$(plus "$TG_NUXT_COM")
MODX_PRO_L=$(plus "$MODX_PRO")
MODXCMS_L=$(plus "$MODXCMS")

cat > stats.json <<EOF
{
  "updated_at": "${UPDATED_AT}",
  "merged_prs": ${MERGED},
  "merged_prs_label": "${MERGED_L}",
  "nuxt_nuxt": ${NUXT_NUXT},
  "nuxt_nuxt_label": "${NUXT_NUXT_L}",
  "translation_gang_nuxt": ${TG_NUXT},
  "translation_gang_nuxt_label": "${TG_NUXT_L}",
  "docs_ru": ${DOCS_RU},
  "docs_ru_label": "${DOCS_RU_L}",
  "translation_gang_nuxt_com": ${TG_NUXT_COM},
  "translation_gang_nuxt_com_label": "${TG_NUXT_COM_L}",
  "modx_pro": ${MODX_PRO},
  "modx_pro_label": "${MODX_PRO_L}",
  "modxcms": ${MODXCMS},
  "modxcms_label": "${MODXCMS_L}"
}
EOF

# Patch labeled counters between HTML markers in README
patch_marker() {
  local key="$1"
  local value="$2"
  local file="README.md"
  if ! grep -q "<!--stats:${key}-->" "$file"; then
    echo "Warning: marker stats:${key} not found in README.md" >&2
    return 0
  fi
  perl -0pi -e "s/<!--stats:${key}-->.*?<!--\\/stats:${key}-->/<!--stats:${key}-->${value}<!--\\/stats:${key}-->/sg" "$file"
}

# Static shields badge (dynamic/json с raw.githubusercontent часто даёт RESOURCE NOT FOUND)
MERGED_BADGE=$(python3 -c "import urllib.parse; print(urllib.parse.quote('${MERGED_L}', safe=''))")
perl -0pi -e "s|badge/Merged_PRs-[^-]+-|badge/Merged_PRs-${MERGED_BADGE}-|g" README.md

patch_marker "nuxt_nuxt" "$NUXT_NUXT_L"
patch_marker "tg_nuxt" "$TG_NUXT_L"
patch_marker "docs_ru" "$DOCS_RU_L"
patch_marker "tg_nuxt_com" "$TG_NUXT_COM_L"
patch_marker "modx_pro" "$MODX_PRO_L"
patch_marker "modxcms" "$MODXCMS_L"
patch_marker "updated_at" "$UPDATED_AT"

echo "Updated stats.json and README.md markers (${UPDATED_AT})"
cat stats.json
