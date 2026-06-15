# Box2Dxt Architecture

How the pieces fit, why the shim exists, and how to extend the binding.

- [The three layers](#the-three-layers)
- [Why a C shim](#why-a-c-shim)
- [Handles and safety](#handles-and-safety)
- [Coordinate systems](#coordinate-systems)
- [The ABI version](#the-abi-version)
- [Extending the binding](#extending-the-binding)

---

## The three layers

```
  your xTalk script
        │  b2k…  (pixels, degrees, screen coords)
  ┌─────▼──────────────────────────────────┐
  │ box2dxt-kit.livecodescript  (the Kit)   │  pure xTalk; owns world + loop
  └─────┬──────────────────────────────────┘
        │  b2…   (metres, radians, handles)
  ┌─────▼──────────────────────────────────┐
  │ box2dxt.lcb  (xTalk Builder extension)  │  foreign handlers + public wrappers
  └─────┬──────────────────────────────────┘
        │  FFI: c:box2dxt> b2lc_*  (ints & doubles)
  ┌─────▼──────────────────────────────────┐
  │ box2d_lc.c  (C shim)  +  Box2D v3.1.0   │  one shared library: box2dxt
  └─────────────────────────────────────────┘
```

- **`src/box2d_lc.c` + Box2D** compile together into one shared library,
  `box2dxt` (`libbox2dxt.so` / `.dylib` / `box2dxt.dll`). The shim exports flat C
  functions prefixed `b2lc_*`.
- **`src/box2dxt.lcb`** is the xTalk Builder (LCB) extension. It declares
  `private foreign handler` bindings to the `b2lc_*` symbols
  (`binds to "c:box2dxt>b2lc_…!cdecl"`) and wraps each in a friendly public
  `b2…` handler that scripts call directly.
- **`src/box2dxt-kit.livecodescript`** is optional pure-xTalk sugar (`b2k…`) on
  top of the `b2…` API.

## Why a C shim

Box2D v3 is already C, so why not bind to it directly? Two reasons:

1. **Identifiers are structs passed by value.** Box2D v3 ids (`b2WorldId`,
   `b2BodyId`, …) are small structs. The LCB FFI is happiest with plain scalars
   and pointers, and there is no 64-bit integer foreign type. The shim stores
   every Box2D id in a handle table and hands the script a **positive 32-bit int**
   instead (`0` = null/invalid). Treat handles as opaque tokens.
2. **Scalar conventions.** Every real number crosses the boundary as `double`
   (xTalk numbers are doubles); the shim casts to/from Box2D's `float`. Every
   boolean crosses as `int` (`0`/`1`).

The shim also flattens array-ish APIs into call sequences the FFI can express —
for example, polygons are built with `b2PolyBegin()` / `b2PolyAddPoint(x, y)` /
`b2AddPolygon(...)` instead of marshalling a vertex array.

## Handles and safety

Box2D v3 ids carry a **generation counter**, so the engine can tell a live id
from a stale one. The shim validates every handle with the generation-checked
`b2*_IsValid()` before use. The result: calling any handler with a stale,
destroyed, or never-created handle is a **harmless no-op** — getters return `0`,
actions do nothing — instead of crashing the engine.

The integer handle of each body/shape is also stored in its Box2D `userData`, so
queries, ray casts, and contact events can hand a handle *back* to the script.

> Handles are **generation-tagged**: each one packs a small generation counter
> above its table slot, bumped every time the slot is freed. So even after the
> slot is recycled by a new object, your stale handle stays dead (no-op) instead
> of silently addressing the new occupant. Still drop references on destroy —
> that's what keeps the tables small.

## Coordinate systems

Box2D works in **MKS units** (metres, kilograms, seconds) with **Y pointing up**.
OpenXTalk screens use **pixels** with **Y pointing down**. Conversion happens
only at draw time:

- The core `b2…` API is pure metres/radians — *you* convert.
- The Kit does the conversion for you: it keeps a pixels-per-metre scale
  (default 40) and an origin, and flips Y so screen-space "down" maps to
  world-space "down".

Keep moving objects roughly 0.1–10 m (≈ 4–400 px at the default scale). Drive the
simulation from a **fixed timestep** — the Kit and demo accumulate real elapsed
time and step in 1/60 s chunks; variable steps make the solver jittery and
non-deterministic.

## The ABI version

The shim exports `b2lc_abi_version()`, surfaced to scripts as `b2Version()`. It
returns the integer `LC_ABI_VERSION` defined in `src/box2d_lc.c` (currently `4`).
Use it as a load/version sanity check, and **bump it whenever the exported ABI
changes** so the `.lcb` and native library can't silently drift apart.

> The exported symbols keep the historical `b2lc_` prefix even though the library
> is now named `box2dxt`. This is deliberate: it keeps already-compiled binaries
> binding-compatible across the OpenXTalk rebrand.

## Extending the binding

Exposing more of Box2D is mechanical. To add a handler:

1. **C shim (`src/box2d_lc.c`)** — add a `LC_API … b2lc_yourthing(…)` function
   that calls the Box2D API. Store/look up any ids in the existing handle tables,
   and validate inputs with the relevant `b2*_IsValid`.
2. **Extension (`src/box2dxt.lcb`)** — add a matching
   `private foreign handler … binds to "c:box2dxt>b2lc_yourthing!cdecl"`, then a
   `public handler b2YourThing(…)` wrapper that calls it (and tolerates `0`
   handles like the rest).
3. **Bump `LC_ABI_VERSION`** in the shim if the exported ABI changed.
4. **Rebuild** the native library (see [building.md](building.md)) and reload the
   extension.

Add a smoke-test assertion in `tests/smoke_test.c` for anything non-trivial so CI
exercises it on every platform.

The binding (currently ABI 4) covers the full Box2D v3.1 **live-object**
surface. The newer additions reuse a few shared shim patterns worth knowing when
you extend further:

- A **shape-def "pending overrides"** struct lets the existing shape creators gain
  sensors / filters / event-flags / materials without new variants — set options
  with `b2lc_shapedef_*`, and `fill_shape_def` applies them to the next shape then
  resets (one-shot, like the polygon vertex builder).
- A **chains handle table** (the same `DEFINE_TABLE` macro) plus a point-cloud
  builder mirrors the polygon path.
- **Queries** are callback-based upstream; the shim runs them with a small C
  callback that pushes hits into one **shared result buffer**, then exposes a
  count + indexed getters — the same idea as the ray/contact stashes.
- **Sensor / hit / body-move events** reuse the growable snapshot pattern of the
  contact events.

What stays **intentionally unwrapped**: pre-solve / custom-filter / friction /
restitution callbacks (there is no safe way to call back into xTalk mid-step over
the LCB FFI), and Box2D's standalone math / geometry / TOI / manifold helpers
(they operate on raw structs, which xTalk handles itself). Filter category/mask
bits are exposed as **32-bit** (xTalk doubles carry 32 unsigned bits cleanly), so
scripts get 32 collision layers rather than Box2D's full 64.
