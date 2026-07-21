#!/usr/bin/env bash
# build-writing.sh — render the writing archive from source posts.
#
#   ./build-writing.sh
#
# Reads:   writing/_posts/<slug>/index.qmd  (+ any images alongside)
# Writes:  writing/<slug>/index.html        (+ the images, copied)
#
# The posts are Quarto documents with executable R chunks. We deliberately do
# NOT execute them — several read internal data that isn't public, and the code
# itself is the point. ```{r ...} fences are rewritten to plain ```r so pandoc
# renders them as highlighted, non-executed blocks.
#
# Requires: pandoc, python3.

set -euo pipefail
cd "$(dirname "$0")"

command -v pandoc >/dev/null || { echo "error: pandoc not found" >&2; exit 1; }

SRC=writing/_posts
TEMPLATE=writing/_template.html

[[ -d "$SRC" ]] || { echo "error: no $SRC directory" >&2; exit 1; }

for dir in "$SRC"/*/; do
  slug="$(basename "$dir")"
  qmd="$dir/index.qmd"
  [[ -f "$qmd" ]] || { echo "skip $slug — no index.qmd"; continue; }

  out="writing/$slug"
  mkdir -p "$out"

  # Executable chunk fences -> plain language fences, and pull a pretty date.
  tmp="$(mktemp)"
  python3 - "$qmd" "$tmp" <<'PY'
import re, sys
src, dst = sys.argv[1], sys.argv[2]
text = open(src, encoding="utf-8").read()
# ```{r label, opts} -> ```r   (also handles {python}, {bash}, etc.)
text = re.sub(r"^```\{([a-zA-Z]+)[^}]*\}", r"```\1", text, flags=re.M)
open(dst, "w", encoding="utf-8").write(text)
PY

  date="$(grep -m1 -E '^date:' "$qmd" | sed 's/date: *//; s/"//g' | tr -d "\r" || true)"
  pretty="$(python3 -c "
import sys,datetime
d=sys.argv[1].strip()
try: print(datetime.date.fromisoformat(d).strftime('%-d %B %Y'))
except Exception: print(d)
" "$date")"

  echo "→ $out/index.html   ($pretty)"

  pandoc "$tmp" \
    --from=markdown+yaml_metadata_block+fenced_code_attributes \
    --to=html5 \
    --template="$TEMPLATE" \
    --highlight-style=tango \
    --metadata date-pretty="$pretty" \
    --wrap=none \
    --output="$out/index.html"

  rm -f "$tmp"

  # Images referenced relatively by the post.
  find "$dir" -maxdepth 1 -type f \( -iname '*.png' -o -iname '*.jpg' -o -iname '*.svg' \) \
    -exec cp {} "$out/" \;
done

echo
echo "built:"
ls -d writing/*/ | grep -v _posts | grep -v _template
