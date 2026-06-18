# Prebuilt `box2dxt` libraries

Per-platform native libraries built from the source in this repo, so you can run
Box2Dxt without a C toolchain. These files are the **source the packaged
extension is built from** — `tools/package-extension.py` lays them into the
extension's `src/code/<arch>-<platform>/` tree (see below), and that tree is what
ships and installs. They are *not* meant to be dropped onto a search path by hand
(that old workaround is now just a dev/fallback note at the bottom).

| Platform | File |
|----------|------|
| Windows x64 | `box2dxt-windows-x64.dll` |
| Windows x86 (32-bit) | `box2dxt-windows-x86.dll` |
| macOS (universal: Intel + Apple Silicon) | `libbox2dxt-macos-universal.dylib` |
| Linux x86-64 | `libbox2dxt-linux-x86_64.so` |
| Linux i686 (32-bit) | `libbox2dxt-linux-i686.so` |

These report **ABI 4** — what the current Kit and examples need. Confirm after
installing with `put b2Version()` (it should return `4`).

## Install: the packaged extension (the supported method)

Box2Dxt installs as a LiveCode/OpenXTalk **extension with the native library
bundled inside it**. `tools/package-extension.py` copies each file above to its
bare name under the extension's `code/` tree:

| Platform-id (`<arch>-<platform>`) | Bundled file |
|-----------------------------------|--------------|
| `x86_64-linux`  | `src/code/x86_64-linux/box2dxt.so` |
| `x86-linux`     | `src/code/x86-linux/box2dxt.so` |
| `x86_64-win32`  | `src/code/x86_64-win32/box2dxt.dll` |
| `x86-win32`     | `src/code/x86-win32/box2dxt.dll` |
| `universal-mac` | `src/code/universal-mac/box2dxt.dylib` |

The architecture comes **first** (`x86_64-linux`, not `linux-x86_64`); Windows
uses `-win32` for both bitnesses; the file is the bare token `box2dxt.<ext>`
(no `lib` prefix — it must equal the `c:box2dxt>` binding name). Regenerate the
tree from these binaries with:

```sh
python3 tools/package-extension.py            # populate src/code/<id>/
python3 tools/package-extension.py --check    # validate inputs only
```

`src/box2dxt.lcb` + its `src/code/` tree is then the ready-to-build extension:
open `src/box2dxt.lcb` in OXT's **Extension Builder** and **Package** to produce
`box2dxt.lce` (the `code/` libraries are rolled in), then install it via the
Extension Manager — or hit **Test** to compile and load it in place. Installing
the extension makes the engine load the right library for the running platform
automatically. **No separate library download, no renaming, no sudo, no
`/usr/lib`, no `LD_LIBRARY_PATH`** — the same on Windows, macOS and Linux, on
LiveCode Community 9.6.3 and OpenXTalk (including OXT Lite). See
[docs/building.md](../docs/building.md#packaging-a-distribution-zip).

## Dev / fallback: a loose library beside your stack

For quick iteration without packaging, you can drop a single library here next to
your **saved** stack under its bare name (no `lib` prefix, no platform suffix):

| Platform | Drop in as |
|----------|------------|
| Windows | `box2dxt.dll` |
| macOS | `box2dxt.dylib` |
| Linux | `box2dxt.so` |

The committed Linux file is `libbox2dxt-linux-x86_64.so`, so for this path rename
it to `box2dxt.so`. The Kit's `b2kEnsureNativeLib` (called from `b2kSetup`) then
points the engine at that file via `the revLibraryMapping["box2dxt"]` — so no
`/usr/lib`, no `sudo`, no `LD_LIBRARY_PATH` is needed even on Linux, where the
dynamic loader otherwise wouldn't search the stack's folder. (Raw `b2*` callers
that don't use the Kit can set the same mapping themselves before their first
`b2` call.) Standalones don't need this at all — the Standalone Builder bundles
the correct `code/` library automatically.

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
