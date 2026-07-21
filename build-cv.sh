#!/usr/bin/env bash
# build-cv.sh — regenerate the downloadable CV files from index.html.
#
# index.html is the single source of truth. Run this after editing content:
#
#   ./build-cv.sh
#
# Produces:
#   cv/phil-donovan-cv.pdf    rendered through the print stylesheet
#   cv/phil-donovan-cv.docx   editable Word version via pandoc
#
# Requires: chromium (or google-chrome), pandoc, python3 with beautifulsoup4.

set -euo pipefail
cd "$(dirname "$0")"

PORT=8799
OUT=cv
BASE="phil-donovan-cv"

mkdir -p "$OUT"

# --- locate a chrome ------------------------------------------------------
CHROME="$(command -v chromium || command -v chromium-browser || command -v google-chrome || true)"
if [[ -z "$CHROME" ]]; then
  echo "error: need chromium or google-chrome to render the PDF" >&2
  exit 1
fi
command -v pandoc >/dev/null || { echo "error: pandoc not found" >&2; exit 1; }

# --- serve locally so fonts and CSS resolve -------------------------------
python3 -m http.server "$PORT" >/dev/null 2>&1 &
SERVER=$!
trap 'kill "$SERVER" 2>/dev/null || true' EXIT
sleep 1.5

# --- PDF: straight through the print stylesheet ---------------------------
echo "→ $OUT/$BASE.pdf"
"$CHROME" --headless --disable-gpu --no-sandbox --no-pdf-header-footer \
  --print-to-pdf="$OUT/$BASE.pdf" "http://localhost:$PORT/" 2>/dev/null

# --- DOCX: strip the page furniture, then hand the content to pandoc ------
echo "→ $OUT/$BASE.docx"
python3 - "$OUT/$BASE.clean.html" <<'PY'
import sys
from bs4 import BeautifulSoup

soup = BeautifulSoup(open("index.html", encoding="utf-8").read(), "html.parser")

# Screen-only furniture that means nothing in a Word document.
for sel in ("aside.rail", "svg", "script", "a.skip",
            "div.hero__actions", "footer.foot", "p.eyebrow"):
    for el in soup.select(sel):
        el.decompose()


def para(text, bold=False):
    p = soup.new_tag("p")
    if bold:
        s = soup.new_tag("strong")
        s.string = text
        p.append(s)
    else:
        p.string = text
    return p


# Roles: the markup is a grid (years in one cell, body in another). Left as-is
# pandoc emits a numbered list of years with the job title as a sub-bullet.
# Rebuild each as heading + org/date line + achievement bullets.
timeline = soup.select_one("ol.timeline")
if timeline:
    box = soup.new_tag("div")
    for li in timeline.select("li.role"):
        years = li.select_one(".role__years")
        title = li.select_one(".role__title")
        org = li.select_one(".role__org")
        ticks = li.select_one("ul.ticks")

        h = soup.new_tag("h3")
        h.string = title.get_text(strip=True)
        box.append(h)

        meta = " · ".join(x.get_text(" ", strip=True)
                          for x in (years, org) if x).strip()
        box.append(para(meta, bold=True))

        if ticks:
            box.append(ticks.extract())
    timeline.replace_with(box)


# Span-grid lists concatenate without separators ("Emailphil@donovan.family").
# Join their spans explicitly.
def join_spans(selector, sep=" — "):
    for li in soup.select(selector):
        parts = [c for c in li.find_all(["span", "a"], recursive=False)]
        if not parts:
            continue
        text = sep.join(p.get_text(" ", strip=True) for p in parts if p.get_text(strip=True))
        li.clear()
        li.append(text)


join_spans("ul.edu > li", sep=" · ")
join_spans("ol.papers > li")
join_spans("ul.contact > li", sep=": ")

main = soup.select_one("main")
out = BeautifulSoup("<html><head><meta charset='utf-8'></head><body></body></html>",
                    "html.parser")
out.body.append(main)

with open(sys.argv[1], "w", encoding="utf-8") as fh:
    fh.write(str(out))
PY

pandoc "$OUT/$BASE.clean.html" \
  --from=html --to=docx \
  --metadata title="Phil Donovan — Curriculum Vitae" \
  --output="$OUT/$BASE.docx"

rm -f "$OUT/$BASE.clean.html"

echo
ls -lh "$OUT" | tail -n +2
