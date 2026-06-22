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

**A scrollable HyperCard "desktop" with a live playground.** The home page is a
freely scrollable desktop of Mac-style windows (no longer a one-card-at-a-time
carousel), with:

- **A live xTalk Playground** — write `b2k…` handlers and **Run** them against a
  real physics world right in the browser. A tiny, self-contained interpreter
  (in `app.js`) supports `b2kSpawnBox`/`b2kSpawnBall`/`b2kGravity`/`b2kImpulse`/
  `b2kClear`, `repeat` loops (`with i = a to b` and `N times`), `put`, `if`,
  variables, string concat, and `random()` — with one-click presets. Sandboxed
  (own parser, no `eval`) and budget-capped so it can't hang.
- **Two physics worlds** (a reusable `createWorld` factory) — the hero toy and
  the playground — both drag/fling, pausing when off-screen.
- **Scroll-spy navigation** (the menu highlights the section in view), smooth
  scrolling, and **scroll-reveal** windows (all honour `prefers-reduced-motion`).
- **The floating Message Box** — a HyperTalk console (press `M`): `go to
  <section>`, `run`, `clear`, or any `b2k…` command typed straight in.
- Prior polish kept: a11y (skip link, ARIA live region, focus rings),
  copy-to-clipboard on every code block, FAQ accordions, full SEO/social meta +
  generated `og-image.png`, and a styled `404.html`.

```
website/
├── index.html     # the scrollable desktop of windows + the Playground
├── styles.css     # the paper/ink/orange design system + Mac window chrome + .prose
├── app.js         # physics factory (2 worlds) + the xTalk interpreter + nav + Message Box
├── 404.html       # styled "card not found"
├── og-image.png   # generated 1200×630 social card
└── docs/          # the user-facing guides, rendered from docs/*.md (generated)
    ├── index.html          # the manual overview
    └── <doc>.html          # getting-started, kit-guide, kit-reference
```

> Regenerate the social card after a brand change by re-screenshotting
> `/tmp/og.html` (or any 1200×630 mock) into `website/og-image.png`.

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
