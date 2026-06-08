# Prebuilt `box2dxt` libraries

Drop-in native libraries so you can run Box2Dxt without a C toolchain. Place the
file for your platform next to your stack/standalone (or anywhere the OpenXTalk /
LiveCode foreign-binding loader can find it), then load `box2dxt.lcb`.

| Platform | File | Where |
|----------|------|-------|
| Linux x86-64 | `linux-x86_64/libbox2dxt.so` | committed here |
| macOS (universal: Intel + Apple Silicon) | `libbox2dxt-macos-universal.dylib` | committed here + GitHub **Releases** |
| Windows x64 | `box2dxt-windows-x64.dll` | committed here + GitHub **Releases** |

When you deploy, rename the file to the bare name the loader resolves `box2dxt`
to for your platform — **no `lib` prefix**:

| Platform | Deploy as |
|----------|-----------|
| Linux    | `box2dxt.so` |
| macOS    | `box2dxt.dylib` |
| Windows  | `box2dxt.dll` |

That bare name is what the `c:box2dxt>…` foreign-binding strings in `box2dxt.lcb`
resolve to at run time. Note the committed Linux file is `libbox2dxt.so`, but the
loader asks `dlopen` for `box2dxt.so` — rename it (dropping `lib`), or you'll get
"unable to load foreign library".

On **Linux** the dynamic loader does not search the stack's folder: put the file
in a search path with `sudo cp box2dxt.so /usr/lib/ && sudo ldconfig`, place it
next to the OXT engine binary, or set `LD_LIBRARY_PATH`. (If a specific engine
asks for `libbox2dxt.*` instead, provide that name too — a copy or symlink.)

## Portability of the committed binaries

The committed `linux-x86_64` binary is built with **SIMD disabled** (no AVX2/SSE
requirement), so it runs on any 64-bit x86 Linux machine. It is built from the
source in this repo and stripped. The macOS universal dylib covers both Intel
and Apple Silicon.

The canonical, per-tag binaries are produced by the
[`build` GitHub Actions workflow](../.github/workflows/build.yml) on native
runners and attached to each tagged **[Release](../../releases)** — that's the
only way to get binaries compiled and tested on each operating system.

> These committed files are convenience artifacts and can lag behind
> `src/box2d_lc.c`. When in doubt, build from source (two `cmake` commands — see
> [docs/building.md](../docs/building.md)) or grab the matching Release for a
> given tag.

> **Heads-up — the committed binaries are currently outdated.** They predate most
> of the C shim: they report **ABI 3** and export only ~92 of the ~370 handlers the
> LCB now binds, missing whole families the Kit relies on (sensors, chains, spatial
> queries, body move-events, and more). The current Kit and examples will not run
> against them. The contraption builder now probes `b2Version()` against the ABI it
> needs (**4**) and shows a "rebuild from source" dialog instead of crashing mid-run
> on the first unresolved handler. Regenerate these files — build from source, or
> attach fresh per-tag binaries from the Release workflow (on a portable toolchain;
> e.g. an `manylinux`/older-glibc runner for Linux) — before relying on them.
