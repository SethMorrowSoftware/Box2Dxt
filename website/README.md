# Box2Dxt — project website

A small, self-contained marketing site for Box2Dxt. No build step, no
framework, no required network dependencies — it's three static files plus a
live physics demo written in plain JavaScript.

```
website/
├── index.html   # the page
├── styles.css   # dark, modern theme (palette echoes the project's own demos)
└── app.js       # mobile nav + the interactive hero physics toy
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

- Copy lives directly in `index.html`.
- The colour palette and layout are CSS custom properties at the top of
  `styles.css` (`--orange`, `--teal`, `--purple`, …).
- The hero demo is a compact impulse-based circle solver in `app.js`; tune the
  constants near the top (`GRAV`, `REST`, `MAX_BODIES`, …).

If you change any GitHub link, the repository slug `SethMorrowSoftware/Box2Dxt`
appears throughout `index.html`.
