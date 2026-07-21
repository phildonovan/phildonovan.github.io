# phildonovan.github.io

Personal site and CV for Phil Donovan — data architect and engineer, Auckland.

Live at **https://phildonovan.github.io**

## Structure

Plain static HTML/CSS. No build step, no dependencies, no framework — edit and push.

```
index.html    all content
styles.css    all styling, including the print stylesheet
favicon.svg   trig-station mark
build-cv.sh   regenerates the downloadable CV files
cv/           generated PDF and DOCX (committed, so Pages can serve them)
```

## Downloads

The hero offers the CV as **PDF** and **Word**, both generated from `index.html`
so there is one source of truth. After changing any content, regenerate them:

```bash
./build-cv.sh
```

The PDF renders the page through the print stylesheet. The DOCX strips the page
furniture (rail, contours, buttons), rebuilds the experience entries as proper
headings, and hands the result to pandoc — recruiters get an editable file.

Needs `chromium`, `pandoc`, and `python3` with `beautifulsoup4`.

You don't have to remember any of that, though: **`.github/workflows/build-cv.yml`
rebuilds and commits both files automatically** whenever `index.html`, `styles.css`
or `build-cv.sh` changes on `main`. Edit content, push, and the downloads catch up
on their own. Running `build-cv.sh` locally is only for previewing the output
before you push.

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
