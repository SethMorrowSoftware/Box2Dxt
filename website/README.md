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

**The landing page IS a HyperCard stack.** Instead of one long scroll, the
home page is a stack of cards you flip through, one at a time:

- **Navigate** with the menu, the Home-card launcher, the ◄ / ► card-nav bar,
  the title-bar Home box, or the keyboard (`←` `→` flip, `H` home, `M` message).
- **Card-flip transitions** (dissolve + directional slide; an iris for Home),
  honouring `prefers-reduced-motion`.
- **Deep links + history**: each card has a hash (`#examples`) and Back/Forward
  work. The doc pages' menu links jump straight to the right card.
- **The Message Box** — a HyperTalk-ish console (press `M`). Try `go to
  examples`, `next` / `prev` / `home`, `spawn a crate`, `reset`, `gravity`,
  `help`.
- **Graceful fallback**: an inline `<html class="js">` flag gates single-card
  mode, so with JavaScript off the cards simply stack into a normal scroll page.

```
website/
├── index.html   # the landing page (menu bar + window-framed "cards")
├── styles.css   # the paper/ink/orange design system + Mac window chrome + .prose
├── app.js       # crate-physics toy + the card-stack navigation + Message Box
└── docs/        # the user-facing guides, rendered from docs/*.md (generated)
    ├── index.html          # the manual overview
    └── <doc>.html          # getting-started, kit-guide, kit-reference
```

## The docs are rendered from Markdown

The pages under `website/docs/` are **generated** from the repository's
`docs/*.md` by [`tools/build-docs.py`](../tools/build-docs.py) — a small,
dependency-free Markdown→HTML converter (no `pip`/network needed).

**Only the user-facing guides are hosted on the site** — Getting started, the
Kit guide, and the Kit reference (the `DOCS` list in the generator). The deeper
material (the raw `b2…` API, architecture, build-from-source, the design/roadmap
docs — the `EXTERNAL` list) is intentionally left on GitHub and linked from the
manual overview; doc-to-doc links pointing at those are rewritten to GitHub
automatically. To host or unhost a doc, move it between `DOCS` and `EXTERNAL`.

Re-run it whenever a doc changes:

```sh
python3 tools/build-docs.py      # rewrites website/docs/*.html
```

> Don't hand-edit `website/docs/*.html` — they're overwritten on the next
> build. Edit the source `docs/*.md` and regenerate. The GitHub Pages workflow
> runs the generator before every deploy, so the live site never goes stale.

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
