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

The FFI binding strings in `src/box2dxt.lcb` use the base name `box2dxt`, which
the loader maps to these platform names. Deploy the file next to your stack or
standalone (when you build a standalone, bundle the matching platform library
with it).

## Packaging a distribution zip

To hand someone a ready-to-run game (no repo, no toolchain, no internet),
bundle the extension, the per-platform native libraries, a built **and saved**
stack, and the end-user install guide into one zip. `tools/make-release.py`
does it:

```sh
# Build & SAVE the stack in OXT first (e.g. the platformer), then:
python3 tools/make-release.py --stack /path/to/platformer.livecode
# -> dist/box2dxt-platformer.zip
```

It copies `src/box2dxt.lcb` and `dist/INSTALL.md`, renames each `prebuilt/`
library to the bare name the loader wants under `lib/`, and adds your saved
stack — producing:

```
box2dxt-platformer/
├── INSTALL.md             # the three-step end-user install guide
├── box2dxt.lcb
├── platformer.livecode    # your --stack
└── lib/box2dxt.{dll,dylib,so}
```

Override a library with `--win` / `--mac` / `--linux` (e.g. an SSE2 or
older-glibc build); `--check` validates the inputs without writing the zip.
The recipient just follows `INSTALL.md`: drop their platform's `lib/` file
beside the stack, **Load** `box2dxt.lcb`, open the stack.

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
