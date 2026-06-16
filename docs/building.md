# Building Box2Dxt from source

You only need to build if you want a fresh native library (or are porting to a
new platform/architecture). Most users can skip this and grab a
[prebuilt library](../prebuilt/) instead.

- [Prerequisites](#prerequisites)
- [Build](#build)
- [Run the tests](#run-the-tests)
- [Output files](#output-files)
- [Packaging a distribution zip](#packaging-a-distribution-zip)
- [Platform & CPU notes](#platform--cpu-notes)
- [Continuous integration](#continuous-integration)

---

## Prerequisites

- A **C toolchain** (GCC, Clang, or MSVC).
- **CMake 3.22 or newer** (Box2D v3 requires it).
- Git (CMake uses `FetchContent` to download Box2D — you do **not** download it
  separately).
- To *use* the result: **OpenXTalk**, or **LiveCode 9.6.3+** (the FFI and
  extension tooling are present in Community 9.6.3).

Desktop targets: Windows, macOS, Linux.

## Build

From the project root (which contains `CMakeLists.txt`):

```sh
cmake -S . -B build -DCMAKE_BUILD_TYPE=Release
cmake --build build --config Release
```

CMake fetches and pins **Box2D v3.1.0**, compiles it together with the shim
(`src/box2d_lc.c`), and links everything into one shared library. Build once per
platform/architecture you ship.

> **Build note.** Box2D v3.1.0 compiles its own sources with
> `-Wall -Wextra -pedantic -Werror` *and* the CMake `COMPILE_WARNING_AS_ERROR`
> property, so on newer compilers (e.g. GCC 13+) a harmless upstream warning like
> `-Wmaybe-uninitialized` would otherwise fail the whole build. Our
> `CMakeLists.txt` neutralises both — Box2D's warnings stay visible but
> non-fatal — so the build just works on a modern toolchain.

## Run the tests

A self-contained runtime smoke test drives the engine through the same C entry
points the extension calls — gravity, collision settling, sleeping, joints, ray
casts, point picks, contact events, and the handle-validity guards:

```sh
cmake -S . -B build -DCMAKE_BUILD_TYPE=Release -DBOX2DXT_BUILD_TESTS=ON
cmake --build build --config Release
ctest --test-dir build --output-on-failure
```

A green check means the binary actually *simulates* correctly on this
platform/architecture — something a compile check alone can't show.

## Output files

The build produces a single shared library:

| Platform | File |
|----------|------|
| Linux    | `libbox2dxt.so` |
| macOS    | `libbox2dxt.dylib` |
| Windows  | `box2dxt.dll` |

You don't deploy this file by hand. Box2Dxt ships as a LiveCode/OpenXTalk
**extension with the native library bundled inside it**, under
`src/code/<arch>-<platform>/`. `tools/package-extension.py` copies the built
library (or the committed `prebuilt/` one) to its bare name in that tree:

```sh
python3 tools/package-extension.py            # populate src/code/<id>/
python3 tools/package-extension.py --check    # validate inputs only
```

| Platform-id (`<arch>-<platform>`) | Bundled file |
|-----------------------------------|--------------|
| `x86_64-linux`  | `src/code/x86_64-linux/box2dxt.so` |
| `x86-linux`     | `src/code/x86-linux/box2dxt.so` |
| `x86_64-win32`  | `src/code/x86_64-win32/box2dxt.dll` |
| `x86-win32`     | `src/code/x86-win32/box2dxt.dll` |
| `universal-mac` | `src/code/universal-mac/box2dxt.dylib` |

The architecture comes **first** (`x86_64-linux`, not `linux-x86_64`); Windows
uses `-win32` for both bitnesses; the file is the bare token `box2dxt.<ext>` (no
`lib` prefix) so it matches the `c:box2dxt>` FFI binding name in
`src/box2dxt.lcb`. `src/box2dxt.lcb` + its `src/code/` tree is then the
ready-to-build extension: open `src/box2dxt.lcb` in OXT's **Extension Builder**
and **Package** to produce `box2dxt.lce` (the `code/` libraries roll in), then
install it via the Extension Manager — or **Test** to compile and load in place.
Installing the extension makes the engine load the right library for the running
platform automatically, on Windows, macOS and Linux, on LiveCode Community 9.6.3
and OpenXTalk (incl. OXT Lite) — **no library download, no renaming, no sudo, no
`/usr/lib`, no `LD_LIBRARY_PATH`**. Confirm with `put b2Version()` → `4`.

When you build a **standalone**, the Standalone Builder bundles the matching
`code/` library automatically. For quick dev without packaging, you can instead
drop a single `box2dxt.{so,dll,dylib}` (bare name) next to your **saved** stack;
the Kit's `b2kEnsureNativeLib` (called from `b2kSetup`) points the engine at it
via `the revLibraryMapping` — see [prebuilt/README.md](../prebuilt/README.md).

## Packaging a distribution zip

The supported install is the packaged extension: run
`python3 tools/package-extension.py` to populate `src/code/<arch>-<platform>/`
(above), then **Package** `src/box2dxt.lcb` into `box2dxt.lce` in OXT's Extension
Builder. Shipping the `.lce` (or the source tree with its `code/` folder) gives
the recipient a one-step install with the right native library bundled in — no
loose libraries to place.

To instead hand someone a ready-to-run game as a single self-contained zip (no
repo, no toolchain, no internet, no extension install step), bundle the source
(extension + C shim + Kit), the per-platform native libraries under their bare
name, the demo's spritesheets, a built **and saved** stack, and the end-user
install guide. `tools/make-release.py` does it — the recipient runs straight from
the unzipped folder, with the Kit's `b2kEnsureNativeLib` mapping the
beside-the-stack library at runtime (the dev/fallback path, no install needed):

```sh
# Build & SAVE the stack in OXT first (e.g. the platformer), then:
python3 tools/make-release.py --stack /path/to/NewPlateformerDemo.oxtstack
# -> dist/NewPlateformerDemo.zip
```

It copies `src/box2dxt.lcb` / `box2d_lc.c` / `box2dxt-kit.livecodescript` into
`source/`, renames each `prebuilt/` library to the bare name the Kit maps under
`libraries/`, copies the platformer's `Spritesheets/` art into `spritesheets/`,
adds `dist/INSTALL.md`, and drops your saved stack at the root — producing:

```
NewPlateformerDemo/
├── NewPlateformerDemo.oxtstack    # your --stack
├── INSTALL.md                     # the three-step end-user install guide
├── source/      box2dxt.lcb, box2d_lc.c, box2dxt-kit.livecodescript
├── libraries/   box2dxt.{dll,dylib,so}
└── spritesheets/  the demo's PNG + XML sheets
```

Override a library with `--win` / `--mac` / `--linux` (e.g. an SSE2 or
older-glibc build), the art folder with `--sheets`, or the stack's in-zip name
with `--stack-name`; `--check` validates the inputs without writing the zip.
The recipient follows `INSTALL.md`: drop their platform's `libraries/` file
beside the stack, **Load** `source/box2dxt.lcb`, open the stack, and point its
first-run prompt at `spritesheets/`.

## Platform & CPU notes

- **AVX2 / SIMD.** Box2D assumes **AVX2** on x64 by default. If your binary must
  run on older CPUs, configure Box2D with `-DBOX2D_DISABLE_SIMD=ON` (slower) or
  an SSE2 build. The committed `prebuilt/linux-x86_64` binary is built with SIMD
  disabled so it runs anywhere.

  ```sh
  cmake -S . -B build -DCMAKE_BUILD_TYPE=Release -DBOX2D_DISABLE_SIMD=ON
  ```

- **macOS universal binary.** Build for both architectures at once:

  ```sh
  cmake -S . -B build -DCMAKE_BUILD_TYPE=Release \
        -DCMAKE_OSX_ARCHITECTURES="arm64;x86_64"
  cmake --build build --config Release
  ```

- **32-bit Windows.** cdecl exports can be decorated; if a symbol fails to bind,
  export the `b2lc_*` names via a `.def` file. 64-bit builds need no workaround.

- **Symbol naming.** The exported C ABI symbols use the historical `b2lc_*`
  prefix. This is intentional and stable — the binding strings in the `.lcb`
  reference these names, and keeping them lets older compiled binaries keep
  working across the rebrand.

## Continuous integration

[`.github/workflows/build.yml`](../.github/workflows/build.yml) builds and tests
the library on native **Linux**, **macOS** (universal arm64 + x86_64), and
**Windows** runners on every push and pull request. On a `vX.Y.Z` tag it gathers
every platform's library and attaches them to a GitHub
[**Release**](../../releases) — that's the canonical source of tested binaries
for each version.
