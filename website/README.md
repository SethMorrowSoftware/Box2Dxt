# Box2Dxt — project website

A small, self-contained marketing site for Box2Dxt. No build step, no
framework, no required network dependencies — it's three static files plus a
live physics demo written in plain JavaScript.

**Personality: HyperCard heritage.** The site leans into the xTalk lineage —
warm "paper" background, classic-Mac window chrome (striped title bars, square
close boxes), hard ink borders with solid offset shadows, a pixel font for
chrome, and the card/stack metaphor as the actual layout. The one signature
colour is the Box2D crate-orange, and the hero demo is a pile of tumbling,
stacking crates. Retro motifs, modern layout discipline.

```
website/
├── index.html   # the page (menu bar + window-framed "cards")
├── styles.css   # the paper/ink/orange design system + Mac window chrome
└── app.js       # menu toggle + the interactive hero crate-physics toy
```

## View it locally

Just open `index.html` in a browser, or serve the folder:

```sh
cd website
python3 -m http.server 8000
# then visit http://localhost:8000
```

(Serving is recommended over `file://` so the Google Fonts request and relative
asset paths behave exactly as they will in production. The site degrades
gracefully to system fonts offline.)

## Deploy to GitHub Pages

A workflow at [`.github/workflows/pages.yml`](../.github/workflows/pages.yml)
publishes this folder automatically. To turn it on, in the repository:

1. **Settings → Pages → Build and deployment → Source: GitHub Actions.**
2. Push to `main` (or run the workflow manually from the Actions tab).

The site will be served at `https://sethmorrowsoftware.github.io/Box2Dxt/`.

> Prefer the classic "deploy from a branch" flow instead? Point Pages at the
> `main` branch and a `/docs` folder, then copy these three files there — but
> the Actions workflow above keeps the site isolated in `website/` and needs no
> file moves.

## What it advertises

- **Ease of use** — the sixty-second `b2kQuickStart` snippet and the
  paste-and-run examples.
- **Abilities** — the full Box2D surface (joints, sensors, ray casts, chains),
  the Game Kit (player controller, camera, sprites, sound), and the safety
  model (generation-tagged handles).
- **Reach** — prebuilt cross-platform binaries and links into every doc.

## Editing

Everything is hand-written and dependency-free:

- Copy lives directly in `index.html` (sections are styled as numbered
  "cards" inside Mac windows — the `.win` / `.win-bar` components).
- The palette and tokens are CSS custom properties at the top of `styles.css`
  (`--paper`, `--ink`, `--orange`, plus `--blue` / `--green` / `--red` / `--hl`).
  Fonts: Space Grotesk (display/body), JetBrains Mono (code), Silkscreen (the
  pixel chrome).
- The hero demo is a compact impulse-based solver in `app.js` — circle
  colliders for stability, rendered as rotating crates + a few cannonballs.
  Tune the constants near the top (`GRAV`, `REST`, `MAX_BODIES`, `CRATES`, …).

If you change any GitHub link, the repository slug `SethMorrowSoftware/Box2Dxt`
appears throughout `index.html`.
