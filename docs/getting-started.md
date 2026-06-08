# Getting Started with Box2Dxt

This guide takes you from nothing to a running, draggable physics scene in
**OpenXTalk (OXT)** — or any compatible **LiveCode 9.6.3+** IDE. It assumes no
C toolchain: you'll use a prebuilt native library.

- [1. Get the native library](#1-get-the-native-library)
- [2. Load the extension](#2-load-the-extension)
- [3. Sanity check](#3-sanity-check)
- [4. Your first scene (the Kit)](#4-your-first-scene-the-kit)
- [5. Attach controls you designed in the IDE](#5-attach-controls-you-designed-in-the-ide)
- [6. Run the full demo](#6-run-the-full-demo)
- [Troubleshooting](#troubleshooting)
- [Where to go next](#where-to-go-next)

---

## 1. Get the native library

Box2Dxt is a real physics engine compiled to a native shared library. Grab the
file for your platform from [`prebuilt/`](../prebuilt/) (or from the
[Releases](../../releases) page for a specific version):

| Platform | Download | Rename it to |
|----------|----------|--------------|
| Windows x64 | `prebuilt/box2dxt-windows-x64.dll` | `box2dxt.dll` |
| macOS (Intel/Apple Silicon) | `prebuilt/libbox2dxt-macos-universal.dylib` | `box2dxt.dylib` |
| Linux x86-64 | `prebuilt/linux-x86_64/libbox2dxt.so` | `box2dxt.so` |

OXT's loader resolves the name `box2dxt` to the **bare platform filename with no
`lib` prefix** (the table above). This bites on Linux especially: the committed
file is `libbox2dxt.so`, but OXT asks `dlopen` for `box2dxt.so` — leaving the
`lib` prefix on is the single most common cause of "unable to load foreign
library".

**Put the renamed file where the loader looks at run time:**

- **Windows / macOS:** next to the stack you're editing works.
- **Linux:** the dynamic loader does **not** search the stack's folder. Copy the
  file to a search path and refresh the cache:
  ```
  sudo cp box2dxt.so /usr/lib/ && sudo ldconfig
  ```
  (or place it next to the OXT engine binary, or add its folder to
  `LD_LIBRARY_PATH` before launching OXT).

> If a particular engine asks for the `lib`-prefixed name instead, provide that
> too — a copy or symlink alongside is harmless.

> Prefer building it yourself? See [building.md](building.md). It's two `cmake`
> commands.

## 2. Load the extension

`src/box2dxt.lcb` is the extension that exposes the `b2…` handlers.

- **From the IDE:** *Tools → Extension Manager* → add `src/box2dxt.lcb`, then
  **Load** it. (During development you can also use *Tools → Extension Builder →
  Test* to compile and load it in one step.)
- **From script:**

  ```
  load extension from file (the defaultFolder & "/box2dxt.lcb")
  ```

Foreign bindings resolve on **first use**, so the native library only has to be
findable when a `b2…` handler actually runs — not when the extension loads.

## 3. Sanity check

Open the Message Box and run:

```
put b2Version()
```

You should see `4` (the shim ABI version). If you get an error instead, the
extension didn't load or the native library can't be found — jump to
[Troubleshooting](#troubleshooting).

## 4. Your first scene (the Kit)

The **Kit** (`box2dxt-kit.livecodescript`) is the friendly layer: you work in
**pixels, screen coordinates and degrees**, and it owns the world, the
fixed-timestep loop, and per-frame control updates.

1. Open your stack's script (*Object → Stack Script*) and paste in the entire
   contents of [`src/box2dxt-kit.livecodescript`](../src/box2dxt-kit.livecodescript).
   (For reuse across stacks, save it as a library stack and `start using` it.)
2. Add these handlers to the **card** script:

```
on openCard
   b2kQuickStart                          -- world + gravity + card-edge walls + go
   get b2kSpawnBall(200, 80, 50)          -- create & drop a 50px ball
   get b2kSpawnBox(260, 80, 60, 40, "orange")
end openCard

on mouseDown
   get b2kGrab(the mouseH, the mouseV)    -- grab a body under the pointer
end mouseDown

on mouseUp
   b2kRelease
end mouseUp

on closeCard
   b2kStop                                -- stop the loop, free the world
end closeCard
```

Open the card. A ball and a box fall, settle on the bottom edge of the card, and
you can **drag** them with the mouse. That's it — a live physics scene.

`b2kQuickStart` is the one-call setup: it creates the world, applies gravity,
builds static walls around the card edges, and starts the loop. From there,
`b2kSpawnBall`/`b2kSpawnBox` create controls *and* their bodies in one go.

## 5. Attach controls you designed in the IDE

Prefer to draw your objects in the IDE? Attach physics to **any** control —
graphics, images, buttons, fields. Graphics and **dynamic images rotate** with
their body; buttons/fields and other controls follow position only (upright).

```
b2kSetup                                     -- world + gravity, auto origin
b2kAddStatic the long id of graphic "Floor"  -- immovable
b2kAddBox    the long id of graphic "Crate"  -- dynamic box
b2kAddBall   the long id of graphic "Ball"   -- dynamic circle
b2kContactTarget the long id of me           -- receive `on b2kContact pA, pB`
b2kStart                                      -- begin the loop
```

Now `Crate` and `Ball` fall and collide with `Floor`, and your card gets a
`b2kContact` message whenever two attached controls begin touching.

See the [Kit Reference](kit-reference.md) for the full `b2k…` surface
(materials, joints, forces, queries, events).

## 6. Run the full demo

[`examples/box2dxt-demo.livecodescript`](../examples/box2dxt-demo.livecodescript)
is a self-building, multi-scene **testbed** — it creates its own buttons, HUD and
scenes at runtime, so there's nothing to lay out.

The demo is **self-contained**: it bundles a copy of the Kit, so it runs from a
single paste — no separate setup.

1. Make sure the extension is loaded and `put b2Version()` returns `3`.
2. Paste the whole of
   [`examples/box2dxt-demo.livecodescript`](../examples/box2dxt-demo.livecodescript)
   into a stack's script (*Object → Stack Script*). If you previously pasted a
   demo or the Kit into the **card** script, clear that first.
3. Reopen the card, or run `startBox2DDemo` in the Message Box (`stopBox2DDemo`
   stops it).

> The demo embeds a verbatim copy of the Kit purely for one-paste convenience.
> For your own projects, use the standalone Kit
> ([`src/box2dxt-kit.livecodescript`](../src/box2dxt-kit.livecodescript)) as
> shown in steps 4–5 above.

Click the tabs up top to switch scenes:

| Scene | Shows off |
|-------|-----------|
| **Playground** | boxes, a ball, a capsule, polygons, a hinged **pendulum**, a powered **windmill** (hinge motor), and a **see-saw** |
| **Pyramid** | a tall stack; pick the **Bomb** tool and click beside it for a blast |
| **Cradle** | a Newton's cradle — hinge joints + restitution |
| **Bridge** | a plank bridge of hinge joints you can load up |
| **Vehicle** | a car (wheel joints + motor + spring suspension) you **drive with ←/→** over bumps |
| **Lidar** | a live **ray-cast** scanner that follows your mouse and stops each ray at the nearest shape |

Across every scene you can **drag** any dynamic body, **click empty space** to
drop the selected shape (Box/Ball/Capsule/Poly/Bomb), and bodies **flash white**
the instant they begin touching (contact events). A HUD shows live FPS and body
count. The whole demo is written with `b2k…` calls — read it as a worked example
of the [Kit](kit-reference.md).

## Troubleshooting

| Symptom | Likely cause & fix |
|---------|--------------------|
| `b2Version()` throws / "handler not found" | The extension isn't loaded. Re-add and **Load** `box2dxt.lcb` in the Extension Manager. |
| First `b2…` call (or `b2Version()`) errors **"unable to load foreign library"** | The native library isn't found or is misnamed. Use the **no-`lib`** bare name: `box2dxt.dll` / `box2dxt.dylib` / `box2dxt.so`. On **Linux** the stack folder isn't searched — put it in `/usr/lib` then run `sudo ldconfig`, or place it next to the OXT engine. (Tip: launching OXT from a terminal prints `dlopen failed <name>` showing the exact filename it wants.) |
| `b2Version()` returns a different number | Your `box2dxt.lcb` and native library are from different versions. Rebuild/redownload both from the same tag. |
| Library won't load on an older PC (Linux/Windows) | Use the committed SIMD-disabled `prebuilt/` binary, or build with `-DBOX2D_DISABLE_SIMD=ON` (see [building.md](building.md)). |
| Bodies jitter or behave non-deterministically | You're stepping with a variable timestep. Let the Kit drive the loop, or step in fixed 1/60 s chunks (see [API Reference → Notes](api-reference.md#notes-and-gotchas)). |
| Objects fly off instantly / explode | Sizes are wrong for Box2D's MKS units. Keep moving objects roughly 4–400 px at the default 40 px/m scale. |

## Where to go next

- [**Kit Guide**](kit-guide.md) — the complete, teach-you-everything walkthrough of the `b2k…` toolkit, with runnable examples.
- [Kit Reference](kit-reference.md) — the same `b2k…` API as quick-lookup tables.
- [API Reference](api-reference.md) — the low-level `b2…` API and units/gotchas.
- [Architecture](architecture.md) — how it all works under the hood.
- [Building](building.md) — compile the native library yourself.
