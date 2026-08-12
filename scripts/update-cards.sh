#!/usr/bin/env bash
# Refresh GitHub stats SVG cards. Do not write numbers into README.md.
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
OUT="$ROOT/assets/cards"
BASE="${STATS_API:-https://github-readme-stats.shion.dev}"
STREAK_API="${STREAK_API:-https://streak-stats.demolab.com}"

mkdir -p "$OUT"

fetch() {
  local url="$1"
  local dest="$2"
  echo "Fetching $(basename "$dest")"
  curl -fsSL --max-time 45 "$url" -o "$dest"
  python3 - "$dest" <<'PY'
import sys
from pathlib import Path
p = Path(sys.argv[1])
data = p.read_bytes()
if b"<svg" not in data[:400]:
    raise SystemExit(f"{p.name} is not an SVG: {data[:80]!r}")
print(f"  {p.name}: {len(data)} bytes")
PY
}

USER="Ibochkarev"
STATS_QS="username=${USER}&show_icons=true&include_all_commits=true&show=prs_merged,reviews&theme=vue-dark&hide_border=true&hide_rank=true&locale=ru"

fetch "${BASE}/api?${STATS_QS}" "$OUT/stats-dark.svg"
fetch "${BASE}/api/pin/?username=${USER}&repo=ImageOptimizer&theme=vue-dark&hide_border=true" "$OUT/pin-imageoptimizer-dark.svg"
fetch "${BASE}/api/pin/?username=${USER}&repo=mxEditorJs&theme=vue-dark&hide_border=true" "$OUT/pin-mxeditorjs-dark.svg"
fetch "${BASE}/api/pin/?username=modx-pro&repo=vueTools&theme=vue-dark&hide_border=true" "$OUT/pin-vuetools-dark.svg"
fetch "${BASE}/api/pin/?username=modx-pro&repo=MiniShop3&theme=vue-dark&hide_border=true" "$OUT/pin-minishop3-dark.svg"
fetch "${STREAK_API}/?user=${USER}&theme=vue-dark&hide_border=true" "$OUT/streak-dark.svg"

echo "Cards updated in assets/cards/"
