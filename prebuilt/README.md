# Prebuilt `box2dxt` libraries

Drop-in native libraries so you can run Box2Dxt without a C toolchain. Place the
file for your platform next to your stack/standalone (or anywhere the OpenXTalk /
LiveCode foreign-binding loader can find it), then load `box2dxt.lcb`.

| Platform | File |
|----------|------|
| Windows x64 | `box2dxt-windows-x64.dll` |
| Windows x86 (32-bit) | `box2dxt-windows-x86.dll` |
| macOS (universal: Intel + Apple Silicon) | `libbox2dxt-macos-universal.dylib` |
| Linux x86-64 | `libbox2dxt-linux-x86_64.so` |
| Linux i686 (32-bit) | `libbox2dxt-linux-i686.so` |

These are built from the source in this repo and report **ABI 4** — what the
current Kit and examples need. Confirm after loading with `put b2Version()`
(it should return `4`).

## Deploy: rename to the bare name (no `lib` prefix)

The `c:box2dxt>…` foreign-binding strings in `box2dxt.lcb` resolve the name
`box2dxt` to a **bare platform filename** at run time. Rename the file you ship:

| Platform | Deploy as |
|----------|-----------|
| Windows | `box2dxt.dll` |
| macOS | `box2dxt.dylib` |
| Linux | `box2dxt.so` |

The committed Linux file is `libbox2dxt-linux-x86_64.so`, but the loader asks
`dlopen` for `box2dxt.so` — drop the `lib` prefix and the `-linux-x86_64`
suffix, or you'll get "unable to load foreign library". (If a particular engine
asks for the `lib`-prefixed name instead, provide that too — a copy or symlink
alongside is harmless.)

On **Linux** the dynamic loader does not search the stack's folder: put the file
in a search path with `sudo cp box2dxt.so /usr/lib/ && sudo ldconfig`, place it
next to the OXT engine binary, or set `LD_LIBRARY_PATH` before launching OXT.

> **Tip — let a script do the rename + bundling.** `tools/make-release.py`
> assembles a ready-to-ship zip (the extension + per-platform libraries already
> renamed to the bare name + your saved stack + an install guide). See
> [docs/building.md](../docs/building.md#packaging-a-distribution-zip).

## Portability & freshness

- The macOS file is a **universal** binary (Intel + Apple Silicon). For
  older-CPU (no-AVX2) or SSE2 builds, see the SIMD notes in
  [docs/building.md](../docs/building.md#platform--cpu-notes).
- These committed files are convenience artifacts and can lag behind
  `src/box2d_lc.c`. When in doubt, confirm `put b2Version()` matches the ABI
  your `box2dxt.lcb` expects, build from source (two `cmake` commands — see
  [docs/building.md](../docs/building.md)), or grab the matching tagged
  **[Release](../../releases)**, whose per-platform binaries are built and
  tested on native runners by the
  [`build` workflow](../.github/workflows/build.yml).
