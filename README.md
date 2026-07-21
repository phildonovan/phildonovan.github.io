# phildonovan.github.io

Personal site and CV for Phil Donovan — data architect and engineer, Auckland.

Live at **https://phildonovan.github.io**

## Structure

Plain static HTML/CSS. No build step, no dependencies, no framework — edit and push.

```
index.html    all content
styles.css    all styling, including the print stylesheet
favicon.svg   trig-station mark
```

## Design

Laid out as a survey sheet: topographic palette (bistre contour, topo water blue,
survey red), cartographic marginalia in the left rail, and trig-station triangles as
section and list markers. Type is Archivo (display), Source Serif 4 (body) and
IBM Plex Mono (data and labels).

The print stylesheet strips the rail, contours and controls so the page prints as a
clean CV — "Print / save as PDF" in the hero, or just Ctrl+P.

## Editing

Content lives directly in `index.html` under commented section markers. To update a
role, edit the matching `<li class="role">` block. Changes go live on push to `main`.

## Local preview

```bash
python3 -m http.server 8000
# → http://localhost:8000
```
