# Box2Dxt

[![build](../../actions/workflows/build.yml/badge.svg)](../../actions/workflows/build.yml)

**Real 2D physics for OpenXTalk and the xTalk family.** Box2Dxt packages the
[Box2D v3.1.0](https://box2d.org) engine — the one behind countless games — as a
drop-in module for **OpenXTalk (OXT)**, compatible with **LiveCode 9.6.3+**.
You write plain xTalk; your controls fall, roll, bounce, hinge, and collide.

```livecodescript
on openCard
   b2kQuickStart                          -- world + gravity + walls + go
   b2kSpawnBall 200, 80, 50               -- create + drop a ball
   b2kSpawnBox 260, 80, 60, 40, "orange"  -- (read `the result` for the ref)
end openCard
on mouseDown ; get b2kGrab(the mouseH, the mouseV) ; end mouseDown
on mouseUp   ; b2kRelease ; end mouseUp
```

## How it's put together

```
Box2D v3.1.0 (fetched by CMake)
   └─ C shim          src/box2d_lc.c              → libbox2dxt.{so,dylib,dll}
        └─ LCB binding  src/box2dxt.lcb            → raw  b2*  API (metres, radians)
             └─ the Kit  src/box2dxt-kit.livecodescript → friendly b2k* API
                          (pixels, degrees, control-backed bodies, render loop)
                  └─ examples/*.livecodescript     → self-contained demo stacks
```

- **The Kit (`b2k…`)** is what most users call: screen pixels, degrees, bodies
  bound to LiveCode controls, an animation loop that moves them for you.
- **The extension (`b2…`)** is the full Box2D v3.1 surface — 370+ handlers
  covering bodies, shapes, joints, chains, sensors, queries, ray casts, contact
  events, and world tuning — in metres and radians.
- **Safety by design:** every handle is validated and generation-tagged in the
  C shim. Stale or invalid handles are harmless no-ops, never crashes.

## Quick start

1. **Get the native library** for your platform from [`prebuilt/`](prebuilt/)
   (or [Releases](../../releases)) and rename it to the bare name the loader
   expects — `box2dxt.dll` / `box2dxt.dylib` / `box2dxt.so` (no `lib` prefix).
2. **Load the extension** `box2dxt.lcb` in the Extension Manager.
3. **Sanity check:** `put b2Version()` in the Message Box should print `4`.
4. **Run a demo:** paste all of
   [`examples/box2dxt-demo.livecodescript`](examples/box2dxt-demo.livecodescript)
   into a stack script and reopen the card — six interactive scenes, from a
   Newton's cradle to a drivable car. Or try the flagship
   [contraption builder](examples/box2dxt-contraption-builder.livecodescript):
   a full build-and-run physics sandbox with fans, magnets, lasers, bombs,
   motors, and save/load. Game-minded? The
   [micro-game](examples/box2dxt-microgame.livecodescript) is a complete
   two-level platformer (menu → levels → win screen, embedded art,
   synthesized sound) and the
   [platformer showcase](examples/box2dxt-platformer.livecodescript) is the
   Game Kit pushed hard — player controller, scrolling camera, spritesheets,
   coin puzzles.

The step-by-step version (with troubleshooting) is in
[**docs/getting-started.md**](docs/getting-started.md).

## Documentation

| Doc | What's in it |
|-----|--------------|
| [Getting started](docs/getting-started.md) | Zero to a draggable scene, plus troubleshooting. |
| [Kit guide](docs/kit-guide.md) | The friendly `b2k…` layer, taught start to finish. |
| [Kit reference](docs/kit-reference.md) | Every `b2k…` handler, one line each. |
| [API reference](docs/api-reference.md) | The raw `b2…` extension surface. |
| [Architecture](docs/architecture.md) | The three layers, handles, units, the ABI. |
| [Building](docs/building.md) | Compile the native library yourself with CMake. |

## Building from source

```sh
cmake -S . -B build -DCMAKE_BUILD_TYPE=Release -DBOX2DXT_BUILD_TESTS=ON
cmake --build build --config Release
ctest --test-dir build --output-on-failure
```

CMake fetches Box2D v3.1.0 automatically. CI builds and smoke-tests Linux
(x86-64 and i686, glibc 2.17 floor), macOS (universal), and Windows (x64 and
x86) on every push; see [docs/building.md](docs/building.md).

## Contributing

See [CONTRIBUTING.md](CONTRIBUTING.md) for the layer conventions, the
embedded-Kit sync rule, and the static checks
(`python3 tools/check-livecodescript.py`) that gate every change.

## License

[MIT](LICENSE) — Box2D itself is also MIT, © Erin Catto.
