# Contributing to Box2Dxt

Thanks for your interest in improving Box2Dxt — the Box2D v3 physics extension
for **OpenXTalk (OXT)** and the wider **xTalk** family! This guide covers dev
setup, conventions, and how to extend the binding.

## Ways to contribute

- **Report bugs** and request features via [Issues](../../issues).
- **Improve docs** — guides live in [`docs/`](docs/); fixes and clarifications
  are very welcome.
- **Expose more of Box2D** — add handlers (see [recipe](#adding-a-handler)).
- **Test on more platforms/CPUs** and report results.

## Development setup

1. **Build the native library** and run the tests:

   ```sh
   cmake -S . -B build -DCMAKE_BUILD_TYPE=Release -DBOX2DXT_BUILD_TESTS=ON
   cmake --build build --config Release
   ctest --test-dir build --output-on-failure
   ```

   CMake fetches Box2D v3.1.0 automatically. Full details and platform notes:
   [docs/building.md](docs/building.md).

2. **Try your change in the IDE.** Load `src/box2dxt.lcb` in OpenXTalk (or
   LiveCode 9.6.3+), place the freshly built library where the loader can find
   it, and run the demo (`examples/box2dxt-demo.livecodescript`) or the Kit
   snippets in [docs/getting-started.md](docs/getting-started.md).

## Repository layout

See [the README](README.md#repository-layout). In short: C shim and extension in
`src/`, the demo in `examples/`, guides in `docs/`, the runtime test in `tests/`,
drop-in binaries in `prebuilt/`, and helper scripts in `tools/`.

## Editing the Kit

`src/box2dxt-kit.livecodescript` is the **single source of truth** for the Kit.
The example stacks in `examples/` are self-contained, so each one embeds a
generated copy of the Kit between `>>> BEGIN EMBEDDED KIT` / `<<< END EMBEDDED
KIT` sentinels. After changing the Kit, re-sync those copies:

```sh
python3 tools/sync-embedded-kit.py
```

Never hand-edit the region between the sentinels — your change would be
overwritten on the next sync. CI runs `tools/sync-embedded-kit.py --check` and
fails if an embedded copy has drifted, so commit the re-synced examples
alongside the Kit change.

## Conventions

- **Units & types.** Across the FFI boundary: reals are `double`, booleans are
  `int` (0/1), handles are 1-based `int` (0 = invalid). The `b2…` API speaks
  metres/radians; the `b2k…` Kit speaks pixels/degrees.
- **Safety first.** Every handler must tolerate stale/`0` handles: validate ids
  with `b2*_IsValid` in C; getters return `0`, actions no-op. Never let a bad
  handle reach Box2D.
- **C ABI symbols** keep the `b2lc_` prefix (see
  [architecture.md](docs/architecture.md#the-abi-version)). Don't rename them —
  it would break already-compiled binaries.
- **Naming.** Public extension handlers are `b2PascalCase`; Kit handlers are
  `b2kPascalCase`; C shim functions are `b2lc_snake_case`.
- **Keep the shim warning-clean** (`-Wall -Wextra`, or `/W3` on MSVC).
- **Match the surrounding style** — comment density, naming, and idiom.

## Adding a handler

The full step-by-step recipe is in
[docs/architecture.md → Extending the binding](docs/architecture.md#extending-the-binding).
In brief:

1. Add a `b2lc_*` function to `src/box2d_lc.c` (validate inputs).
2. Add a `foreign handler` + public `b2…` wrapper in `src/box2dxt.lcb`.
3. Bump `LC_ABI_VERSION` in the shim if the ABI changed.
4. Add a `tests/smoke_test.c` assertion for anything non-trivial.
5. Rebuild and verify in the IDE.

## Pull requests

- Branch from `main`, keep PRs focused, and describe the change clearly.
- Make sure `ctest` passes locally; CI will build and test on Linux, macOS, and
  Windows.
- Update the relevant docs and add a [`CHANGELOG.md`](CHANGELOG.md) entry under
  *Unreleased*.
- If you bumped the ABI, say so in the PR description.

## Code of Conduct

By participating you agree to abide by our
[Code of Conduct](CODE_OF_CONDUCT.md).

## License

By contributing, you agree your contributions are licensed under the project's
[MIT License](LICENSE).
