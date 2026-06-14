# Box2Dxt Kit — The Complete Guide

A friendly, start-to-finish guide to the **Box2Dxt Kit** for xTalk
(LiveCode / OpenXTalk) users. By the end you'll know how to drop physics onto
any control, build joints and machines, react to collisions, filter what hits
what, sculpt terrain, and tune the world — using **pixels, screen coordinates
and degrees** the whole way.

> **Already know your way around?** The terse lookup tables live in
> [`kit-reference.md`](kit-reference.md). This document is the *teaching* version
> — read it top-to-bottom the first time, then keep the reference handy.

**Contents**

1. [What the Kit is (and why)](#1-what-the-kit-is-and-why)
2. [Install and your first scene](#2-install-and-your-first-scene)
3. [The mental model: coordinates & the loop](#3-the-mental-model-coordinates--the-loop)
4. [Making bodies: attach vs. spawn](#4-making-bodies-attach-vs-spawn)
5. [Shapes and reshaping](#5-shapes-and-reshaping)
6. [Materials: bounce, friction, weight](#6-materials-bounce-friction-weight)
7. [Body settings](#7-body-settings)
8. [Making things move](#8-making-things-move)
9. [Reading what's happening](#9-reading-whats-happening)
10. [Joints: building machines](#10-joints-building-machines)
11. [Dragging with the mouse](#11-dragging-with-the-mouse)
12. [Reacting to events](#12-reacting-to-events)
13. [Sensors (trigger zones)](#13-sensors-trigger-zones)
14. [Collision filtering](#14-collision-filtering)
15. [Terrain and smooth chains](#15-terrain-and-smooth-chains)
16. [Asking the world questions (queries)](#16-asking-the-world-questions-queries)
17. [Tuning and performance](#17-tuning-and-performance)
18. [Dropping to the core `b2…` API](#18-dropping-to-the-core-b2-api)
19. [A complete worked example: a little car](#19-a-complete-worked-example-a-little-car)
20. [Building a whole game (the micro-game pattern)](#20-building-a-whole-game-the-micro-game-pattern)
21. [xTalk gotchas worth knowing](#21-xtalk-gotchas-worth-knowing)
22. [Complete API index](#22-complete-api-index)

---

## 1. What the Kit is (and why)

`box2dxt` is a binding of the **Box2D 3.x** physics engine for LiveCode/OpenXTalk.
The raw engine speaks **metres, radians, and y-up** — fine for an engine, awkward
for an xTalk programmer used to **pixels, screen coordinates, and degrees**.

The **Kit** (`src/box2dxt-kit.livecodescript`) is a pure-xTalk layer on top that:

- creates and owns the physics **world**,
- runs a fixed-timestep **loop** and moves your controls each frame,
- converts coordinates and angles for you, and
- gives every handler a tidy `b2k…` name.

You give the Kit a control; it gives that control gravity, collisions, and the
ability to be dragged. Three layers exist, and you can mix them:

| Layer | Units | Names | Use it when… |
|-------|-------|-------|--------------|
| **Kit** | pixels / degrees / screen | `b2k…` | almost always — start here |
| **Extension** (`b2…`) | metres / radians / y-up | `b2…` | you need something the Kit doesn't wrap |
| **Native shim** | C ABI | `b2lc_…` | never, directly |

This guide is entirely about the **Kit** layer.

---

## 2. Install and your first scene

**Requirements:** the `box2dxt` extension loaded. Check with `put b2Version()`
— it should return `3`. The Kit runs in OpenXTalk and LiveCode 9.6.3+.

**Install:** paste the contents of `src/box2dxt-kit.livecodescript` into your
card or stack script. (Or save it as a library stack and `start using` it.)

Now the famous sixty-second scene — a ball and a box that drop, bounce, and can
be flung with the mouse:

```livecode
on openCard
   b2kQuickStart                         -- world + gravity + walls around the card + go
   b2kSpawnBall 200, 80, 50         -- create and drop a 50px ball
   b2kSpawnBox 260, 80, 60, 40, "orange"
   b2kContactTarget the long id of me    -- (optional) collision messages to this card
end openCard

on mouseDown
   b2kGrab the mouseH, the mouseV   -- grab whatever body is under the pointer
end mouseDown

on mouseUp
   b2kRelease
end mouseUp

on closeCard
   b2kStop
end closeCard
```

`b2kQuickStart` is the one-liner that does everything: makes the world, sets
gravity, builds static walls around the card edges, and starts the loop. The two
`b2kSpawn…` calls each **create a graphic and give it a body** — we wrap them in
`get` because they *return* the new control and we don't need the value here.

That's a complete, playable physics toy. Everything below is about doing more.

---

## 3. The mental model: coordinates & the loop

### Coordinates and angles

You always work in **screen pixels** and **degrees**, exactly like the rest of
xTalk:

- A position is `x,y` in card pixels (x right, **y down**).
- An angle is in **degrees**, clockwise-positive (because y is down).
- Sizes (a ball's diameter, a wall's length) are in **pixels**.

The Kit converts to Box2D's metres/radians internally using a **scale** of
**40 pixels per metre** by default. You rarely touch this, but you can:

```livecode
b2kSetScale 50          -- 50 px = 1 metre (objects behave a touch "smaller/heavier")
b2kSetOrigin 0, 0       -- which screen point maps to the world origin (auto by default)
```

> **Keep objects a sensible size.** At the default scale, dynamic objects behave
> best between roughly **4 px and 400 px**. A 4000-px boulder or a 1-px pebble
> will feel wrong, just like in real Box2D.

### The loop

Physics advances in a **fixed-timestep loop** the Kit runs for you. You start and
stop it; you can pause, resume, and single-step it:

```livecode
b2kStart                 -- begin stepping (b2kQuickStart already did this)
b2kPause                 -- freeze, but keep the world intact
b2kResume                -- carry on
b2kStepOnce              -- advance exactly one step (works even while paused) — great for a Step button
b2kStop                  -- end the loop
put b2kIsRunning()       -- true while actively stepping (not stopped, not paused)
```

Each frame, after the physics steps, the Kit moves every attached control to
match its body and (optionally) sends you an `on b2kFrame` message — your hook
for motors, input, scorekeeping, and custom drawing (see
[§12](#12-reacting-to-events)).

**Tearing down.** `b2kStop` ends the loop. `b2kClear` removes every body and
Kit-spawned control but keeps the world. `b2kTeardown` destroys the world and all
Kit state — call it before rebuilding a scene from scratch.

```livecode
b2kClear                 -- empty the scene, keep the world running
b2kTeardown              -- nuke everything (world + state); next run starts fresh
```

---

## 4. Making bodies: attach vs. spawn

There are two ways to get a physical object, and you'll use both.

### A. Attach physics to a control you already designed

Lay out a graphic, image, button, or field in the IDE, then hand its reference to
the Kit. **Pass controls by `the long id of …`** — it's the reference that stays
valid even if names or layers change.

```livecode
b2kSetup                                        -- world + gravity, auto origin
b2kAddStatic the long id of graphic "Floor"     -- never moves
b2kAddBox    the long id of graphic "Crate"     -- a dynamic box (the default)
b2kAddBall   the long id of graphic "Marble"    -- a dynamic circle
b2kStart
```

The attach handlers, and the shape each gives the control:

| Handler | Shape |
|---------|-------|
| `b2kAddBox ctrl [,dyn]` | rectangle (from the control's rect) |
| `b2kAddBall ctrl [,dyn]` | circle (from the control's width) |
| `b2kAddCapsule ctrl [,dyn]` | pill — long side is the axis, short side the diameter |
| `b2kAddPolygon ctrl [,dyn]` | convex polygon from a graphic's `points` |
| `b2kAddStatic ctrl` | immovable body matching the control |

The optional `dyn` flag forces dynamic (`true`) or static (`false`); it defaults
to dynamic for the `b2kAdd…` shape handlers.

**Any control type works** — it falls, collides, and is draggable. What differs is
how it's *drawn* to follow its body:

| Control | Follows position | Rotates |
|---------|:---:|:---:|
| **Graphic** (rectangle/oval/polygon) | yes | yes |
| **Image** (dynamic) | yes | yes — via `the angle` |
| **Button / field / other** | yes | no — rotation is locked so the sim matches the upright render |

### B. Spawn a brand-new control with its body in one call

When you just want objects fast, let the Kit create the graphic too. Each returns
the new control's long id.

```livecode
local tBall, tBox
b2kSpawnBall 200, 80, 50              -- x, y, diameter [, color]
put the result into tBall
b2kSpawnBox 260, 80, 60, 40, "orange"  -- x, y, w, h     [, color]
put the result into tBox
b2kSpawnCapsule 320, 80, 80, 30, "120,200,232"   -- x, y, len, thick [, color]
```

The optional colour is a LiveCode colour name (`"orange"`) or an `"r,g,b"` triple
(`"120,200,232"`). Keep the returned reference if you want to act on the object
later.

---

## 5. Shapes and reshaping

A body's collision shape is set when you attach/spawn it. If you resize the
control later (or want to switch shape), rebuild the shape on the **same body**
so any joints attached to it survive:

```livecode
set the width of graphic "Crate" to 120
b2kReshape the long id of graphic "Crate", "box"     -- "box" | "ball" | "capsule" | "poly"
```

`b2kReshape` reads the control's *current* size (or `points`, for `"poly"`) and
fits a fresh shape to it. It's atomic — the body is never momentarily shapeless,
and a sensor stays a sensor across the reshape.

> A reshape resets the shape's **material and collision filter** to defaults. If
> you'd set a custom bounce/friction/density or a collision layer, re-apply them
> after reshaping.

---

## 6. Materials: bounce, friction, weight

Three knobs control how a surface behaves. Set them any time after the body
exists:

```livecode
b2kSetBounce   tBall, 0.8     -- restitution 0..1 (0 = dead, 1 = perfectly elastic)
b2kSetFriction tBox, 0.3      -- 0 = ice, 1 = grippy
b2kSetDensity  tBox, 2.0      -- mass per area; heavier bodies shrug off impulses
```

Density changes a body's **mass**, which is why a denser box is harder to push and
pushes lighter things around more convincingly.

---

## 7. Body settings

Beyond materials, each body has behaviour switches:

```livecode
b2kSetBullet         tBall, true    -- continuous collision: a fast small body won't tunnel through walls
b2kSetFixedRotation  tBox,  true    -- never spin (good for characters/markers)
b2kSetGravityScale   tBalloon, -0.4 -- per-body gravity multiplier (negative floats it up)
b2kSetDamping        tBox, 0.5, 0.8 -- linear drag, and optional angular drag (air resistance)
```

### Sleeping

Resting bodies "sleep" to save CPU and wake on contact. You can nudge this:

```livecode
b2kWake  tBox                      -- force-wake a body
b2kSleep tBox                      -- send it to sleep until something disturbs it
b2kSetSleepThreshold tBox, 12      -- speed (px/s) below which it's allowed to nod off
b2kEnableSleeping true             -- world-wide on/off (on by default)
```

### Body type — static, dynamic, kinematic

- **dynamic** — moved by forces and collisions (the usual).
- **static** — never moves; the world flows around it (floors, walls).
- **kinematic** — *you* move it (via velocity); it shoves dynamic bodies but
  ignores gravity and collisions itself — perfect for **moving platforms**.

```livecode
b2kSetStatic    tBox               -- freeze in place
b2kSetDynamic   tBox               -- unfreeze
b2kSetKinematic tPlatform          -- a driven platform
b2kSetType      tBox, "dynamic"    -- ...or set it by name: static | kinematic | dynamic

b2kSetKinematic tPlatform          -- example: a platform that slides right forever
b2kSetVelocity  tPlatform, 60, 0
```

### Taking a body out of the simulation

```livecode
b2kDisable tBox     -- removed from the sim: no gravity, no collisions, stays put on screen
b2kEnable  tBox     -- put it back, exactly where it is
```

---

## 8. Making things move

There's a verb for every way you might want to push something. The rule of thumb:
**impulses are one-shot, forces are continuous** (call them every frame).

### Linear

```livecode
b2kPush         tBox, 0, -300    -- one-shot change in velocity (px/s): an instant shove. Ignores mass.
b2kImpulse      tBox, 0, -300    -- one-shot impulse, mass-aware: heavy things move less
b2kForce        tBox, 0, -50     -- continuous force — call each frame for thrust, wind, a tractor beam
b2kSetVelocity  tBox, 120, 0     -- hard-set the linear velocity (px/s)
```

### Rotational

```livecode
b2kSpin            tWheel, 360    -- set angular velocity (deg/sec): a full turn each second
b2kSpinBy          tWheel, 90     -- add to the current angular velocity
b2kTorque          tWheel, 500    -- continuous turning force — call each frame; sign sets direction
b2kAngularImpulse  tWheel, 200    -- one-shot turning impulse, mass-aware (the angular partner of b2kImpulse)
```

### Teleport and blast

```livecode
b2kMoveTo  tBox, 300, 120, 45    -- teleport to a screen point, optionally to an angle (deg)
b2kExplode 300, 200              -- radial blast at a point: kicks nearby dynamic bodies outward
b2kExplode 300, 200, 240, 1200   -- ...with explicit radius (px) and power (defaults 180, 900)
```

`b2kExplode` uses Box2D's native, shape-aware blast — a wide plank catches more
of it than a small ball, and it affects **every** dynamic body in range.
`b2kExplodeLegacy` reproduces the older, size-blind velocity kick if you want it.

### Remove

```livecode
b2kRemove tBox     -- destroy the body (and the control too, if the Kit spawned it)
```

---

## 9. Reading what's happening

Every getter takes a control and returns screen-friendly values.

```livecode
put b2kPosition(tBox)       -- "x,y" centre, in screen pixels
put b2kWorldCenter(tBox)    -- "x,y" centre of mass (the true pivot for spin/torque)
put b2kVelocity(tBox)       -- "vx,vy" in px/s
put b2kSpeed(tBox)          -- scalar speed (px/s)
put b2kAngle(tBox)          -- rotation in degrees
put b2kSpinRate(tBox)       -- rotation speed in deg/s
put b2kMass(tBox)           -- mass (sim kg)
put b2kBodyType(tBox)       -- "static" | "kinematic" | "dynamic"
put b2kIsAwake(tBox)        -- true if actively simulating
put b2kIsBullet(tBox)       -- continuous-collision flag
put b2kIsEnabled(tBox)      -- in the simulation?
put b2kGravityScale(tBox)   -- getter for b2kSetGravityScale
put b2kDamping(tBox)        -- "linear,angular" (getter for b2kSetDamping)
```

Scene-wide counts:

```livecode
put b2kBodyCount()          -- bodies the Kit is tracking
put b2kAwakeCount()         -- dynamic bodies currently awake
```

Find a body by where it is on screen:

```livecode
put b2kControlAt(the mouseH, the mouseV)              -- the control whose body covers a point (or empty)
put b2kControlContains(tBox, the mouseH, the mouseV)  -- is a point inside this body's actual (rotated) shape?
```

(Ray and region queries are in [§16](#16-asking-the-world-questions-queries).)

---

## 10. Joints: building machines

Joints connect two bodies (or one body to the **world**). Every constructor
**returns a joint handle** — keep it, because motors, limits, springs, and
read-outs all take that handle. Remove a joint with `b2kRemoveJoint joint`.

For the "to the world" variants, pass **empty** as the second control to pin the
first body to a fixed point in space.

### Hinge (revolute) — a pin things rotate around

```livecode
local tArm, tPivot
b2kHinge tArm, empty, 200, 100     -- pin tArm to the world at (200,100): it swings freely
put the result into tPivot
-- or join two parts: b2kHinge tArmA, tArmB, x, y
b2kMotor      tPivot, 180, 1500                     -- drive it: 180 deg/s, max torque 1500 (default 1000)
b2kHingeLimit tPivot, -45, 45                       -- clamp the angle to a range (degrees)
put b2kHingeAngle(tPivot)                            -- read the current angle
b2kMotorOff      tPivot                              -- let it swing free again
b2kHingeLimitOff tPivot                              -- remove the limits
```

### Weld — glue two bodies rigidly

```livecode
local tJoint
b2kWeld tA, tB
put the result into tJoint
b2kWeldSpring tJoint, 4, 0.7      -- make the weld springy (hertz, damping); 0 hertz = rock-rigid
```

### Rope (distance) — a maximum-length link

```livecode
local tRope
b2kRope tBall, tAnchor        -- length defaults to the current gap between centres
put the result into tRope
b2kRope tBall, tAnchor, 150              -- ...or set the length in pixels
b2kRopeRange     tRope, 40, 200               -- allow the length to vary between min/max (px)
b2kRopeSetLength tRope, 120                    -- set the exact rest length (px)
put b2kRopeLength(tRope)                        -- read the current length (px)
b2kSpring        tRope, 3, 0.6                 -- make it springy (hertz, damping) — a bungee
```

### Slider (prismatic) — travel along an axis

```livecode
local tSlide
b2kSlider tDoor, empty, 0     -- slide along a 0° (horizontal) axis vs. the world (90 = vertical)
put the result into tSlide
b2kSliderMotor tSlide, 80, 600                 -- drive it: 80 px/s, max force 600
b2kSliderLimit tSlide, 0, 160                  -- clamp the travel (px)
put b2kSliderPos(tSlide)                         -- read the current translation (px)
b2kSliderMotorOff tSlide
b2kSliderLimitOff tSlide
```

### Wheel — a sprung, spinning axle (for vehicles)

```livecode
local tAxle
b2kWheel tChassis, tWheel, the mouseH, the mouseV  -- pivot at a point; axis defaults to vertical
put the result into tAxle
b2kWheelMotor  tAxle, 600, 800       -- drive the wheel: 600 deg/s, max torque 800
b2kWheelSpring tAxle, 5, 0.7         -- suspension stiffness: hertz, damping
b2kWheelMotorOff tAxle
```

### Motor-to — drive toward a pose (a soft, self-righting target)

`b2kMotorTo` drives one body toward a position/angle **offset from another body**
(or from the world). Unlike a weld, it *yields* under load and springs back — for
return-to-home arms, soft platforms, and self-righting parts.

```livecode
-- hold tMover 0px across / 60px below tRef, upright, with limited force/torque:
local tServo
b2kMotorTo tMover, tRef, 0, 60, 0, 800, 800   -- ref empty = relative to the world
put the result into tServo
```

### Stop two parts colliding without a visible joint

```livecode
b2kNoCollide tA, tB     -- a filter joint: tA and tB simply pass through each other
```

> **Tip:** a motor with no `maxTorque`/`maxForce` defaults to a strong value
> (1000 for hinges). If a motor "can't lift" its load, raise the max; if it's
> twitchy, lower it.

---

## 11. Dragging with the mouse

`b2kGrab` attaches a temporary mouse joint to whatever body is under a point and
returns that control (or empty). `b2kRelease` lets go. The body then follows the
pointer until you release — springy and stable, exactly what you want for a toy.

```livecode
on mouseDown
   if b2kGrab(the mouseH, the mouseV) is not empty then
      -- optionally remember/highlight the grabbed control
   end if
end mouseDown

on mouseUp
   b2kRelease
end mouseUp
```

The Kit updates the grab target to the current mouse position automatically each
frame, so you don't need `mouseMove`.

---

## 12. Reacting to events

The Kit can **send you messages** as things happen. Point it at a receiver first:

```livecode
b2kContactTarget the long id of me    -- gets contact + sensor messages
b2kFrameTarget   the long id of me    -- gets an on b2kFrame message each frame
```

### Per-frame

`on b2kFrame` fires once per simulated frame, **after** bodies have moved — the
right place to run motors, read input, update a HUD, or draw:

```livecode
on b2kFrame
   -- e.g. keep a fan blowing while running
   if the mouse is down then b2kForce tBall, 0, -40
end b2kFrame
```

### Contacts

```livecode
on b2kContact pCtrlA, pCtrlB
   -- two attached controls just BEGAN touching.
   -- Either id is empty if that side is a wall, the ground, or an untracked body.
   beep
end b2kContact

on b2kEndContact pCtrlA, pCtrlB
   -- ...and when they STOP touching.
end b2kEndContact
```

### Polling instead of messages

Sometimes a tight `on b2kFrame` loop is cleaner than message handlers. Read this
frame's touch pairs directly (indices are 1-based; an accessor is empty for a
wall/ground/untracked body):

```livecode
on b2kFrame
   local i
   repeat with i = 1 to b2kContactCount()
      -- b2kContactA(i) and b2kContactB(i) are the two controls that began touching
   end repeat
   -- and b2kEndContactCount() with b2kEndContactA(i)/b2kEndContactB(i)
end b2kFrame
```

### Keyboard input (`b2kInputOn`)

Games need *held* keys (run while the arrow is down), *chords* (run + jump),
and clean *edges* (jump on the frame the key goes down) — none of which the
classic `arrowKey`/`keyDown` messages give you, because they arrive at the OS
auto-repeat rate and stop the moment a field steals focus. The Kit's input
module polls instead: while armed, it samples `the keysDown` once per frame
and diffs it against the previous frame, so state and edges are exact and
nothing depends on focus or the message path.

```livecode
on openCard
   b2kQuickStart
   b2kSpawnCapsule 200, 100, 64, 30, "gold"
   put the result into gHero
   b2kSetFixedRotation gHero, true     -- a character stays upright
   b2kInputOn                          -- arm the sampler (installs defaults)
   b2kBindAction "jump", "space,up,w"  -- any of these counts as "jump"
   b2kFrameTarget the long id of me
end openCard

on b2kFrame
   -- axis: -1 / 0 / +1 from left,a vs right,d (a default binding)
   b2kSetVelocity gHero, b2kAxis("moveX") * 240, item 2 of b2kVelocity(gHero)
   -- edge: true only on the frame the action went down
   if b2kActionPressed("jump") then b2kPush gHero, 0, -420
end b2kFrame
```

Key names are friendly (`"left"`, `"space"`, `"a"`; raw keycodes also work),
and letters match both their shifted and unshifted codes. Read anything per
frame: `b2kKeyIsDown`/`Pressed`/`Released` for single keys,
`b2kActionIsDown`/`Pressed`/`Released` for named sets, `b2kAxis` for paired
directions (both held = 0), `b2kKeysHeld()` for a debug HUD, and
`b2kFrameMS()` for the frame's real elapsed milliseconds (drive animations
from that, never the step count). The
`examples/box2dxt-platformer.livecodescript` stack is this section turned
into a playable scene — grounded checks, variable-height jumps, and a
jump-through ledge included.

### Sprites and spritesheets (`b2kSheetLoadAtlas`, `b2kSpriteNew`)

A *sheet* registers the frames inside one image — either a uniform grid
(`b2kSheetLoad name, path, frameW, frameH`) or a packed **atlas** whose XML
names each region (`b2kSheetLoadAtlas`; the `Spritesheets/` folder in this
repo is that format). A *sprite* is a transparent button the Kit drives:
name animations once, then play them by name — `b2kSpritePlay` is free to
call every frame, so a state machine stays one line per state.

```livecode
b2kSheetLoadAtlas "chars", tFolder & "/spritesheet-characters-default.png"
b2kAnimDef "chars", "idle", "character_beige_idle", 2, true
b2kAnimDef "chars", "walk", "character_beige_walk_a,character_beige_walk_b", 6, true

b2kSpriteNew "chars", "character_beige_idle", 200, 100
put the result into gHeroSpr

on b2kFrame
   -- the body's state picks the animation; flipping mirrors the art
   if b2kAxis("moveX") is 0 then
      b2kSpritePlay gHeroSpr, "idle"
   else
      b2kSpritePlay gHeroSpr, "walk"
      b2kSpriteFlipH gHeroSpr, (b2kAxis("moveX") < 0)
   end if
end b2kFrame
```

A sprite is an ordinary control: give it a body directly
(`b2kAddCapsule the long id of …`), or — the better pattern for characters,
whose art is bigger than their collision shape — give an **invisible**
control the body and `b2kSpriteBind` the sprite to it. Non-looping
animations can announce themselves: `b2kSpriteOnFinish gHeroSpr, "heroHitDone"`
sends your handler a message when the hit/attack/death pose finishes. The
platformer example wires all of it together: an atlas-driven hero, spinning
coin pickups, a bee on a flight path, and a saw hazard that triggers the
hit-then-respawn chain.

**Not a Kenney sheet? Every layout loads.** Grids with borders or gutters
pass them straight in (`b2kSheetLoad "run", tPath, 32, 48, 0, 2, 1` —
2px margin, 1px spacing). A packed sheet with no XML at all loads with
frame size 0 (no grid) and you name each region yourself:

```livecode
b2kSheetLoad "boss", tPath, 0, 0          -- source only, no grid
b2kSheetAddFrame "boss", "idle", 0, 0, 96, 80
b2kSheetAddFrame "boss", "roar", 96, 0, 128, 80
b2kAnimDef "boss", "wake", "idle,roar", 4, false
```

`b2kSheetFrameNames("chars")` lists every frame key of a sheet you didn't
make — the quickest way to find what an atlas calls things.

### The player controller (`b2kPlayerMake`)

Everything the input and sprite snippets above hand-roll — and the parts
everyone gets wrong the first time — exists as one module. A *player* is a
vertical capsule with fixed rotation, sleep disabled and low friction; every
frame the controller reads the axis `moveX` and the action `jump`,
accelerates vx toward `axis × moveSpeed`, probes the ground with three short
rays (a hit counts only while its surface normal is within `maxSlopeDeg` of
straight up, so slopes walk and walls don't), and picks the matching
animation. Jump *feel* is built in: **coyote time** (a jump still fires
~90 ms after running off a ledge), **jump buffering** (pressed just before
touchdown fires on landing), and **jump-cut** (tap = hop, hold = full
height).

```livecode
on openCard
   b2kQuickStart
   b2kSheetLoadAtlas "chars", tFolder & "/spritesheet-characters-default.png"
   b2kAnimDef "chars", "idle", "character_beige_idle", 2, true
   b2kAnimDef "chars", "walk", "character_beige_walk_a,character_beige_walk_b", 6, true
   b2kAnimDef "chars", "jump", "character_beige_jump", 1, true
   b2kPlayerMake 200, 100, 32, 48, "chars"   -- body + sprite + controller
   put the result into gHero
   b2kPlayerAnims "idle", "walk", "jump", "jump"
   b2kFrameTarget the long id of me
end openCard
```

That is a complete, well-tuned character — arrows/WASD run, space jumps,
DOWN ducks, one-way decks drop through, ladders climb, water swims (§21).
Feel lives in `b2kPlayerSet` knobs (`moveSpeed`, `accel`, `airAccel`,
`jumpSpeed`, `jumpCut`, `coyoteMs`, `bufferMs`, `maxFall`, `maxSlopeDeg`,
plus Wave 2's `dropMs`, `climbSpeed`, `hurtPopX/Y`, `hurtMs`, `invulnMs`,
and Wave 4's `swimSpeed`/`swimJump`/`swimGravity`/`swimMaxFall`); read the
character back with `b2kPlayerState()`
(`idle`/`run`/`jump`/`fall`/`duck`/`climb`/`hurt`/`swim`, plus `land` for
exactly one frame on touch-down — perfect for dust and sound),
`b2kPlayerOnGround()` and `b2kPlayerFacing()`. Already have a body or
sprite? `b2kPlayerAttach` adopts it instead of making one. Springs,
bounces and powerups call `b2kPlayerJump 700` — always use it for external
boosts: a raw upward `b2kSetVelocity` on a grounded player is treated as
solver rebound and snapped flat. Contact damage calls `b2kPlayerHurt`
(the knockback standard, §21); for cutscenes and scripted deaths,
`b2kPlayerControl false` makes the controller *observe only* — your code
owns velocity and animations until you hand control back. Under the hood
the controller guarantees consistent feel (sim-time reaction windows,
dead landings, hysteresis against solver blips) — all of it asserted by
the self-test harness. The platformer example's whole movement system is
the four lines above.

### Sound effects (`b2kToneMake`, `b2kSound`)

Sounds are named **audioClips** — the engine plays one at a time (a new
play cuts the previous), which is exactly right for short retro SFX. You
can import files (`b2kSoundLoad "boom", tPath`), but the fun path needs no
files at all: `b2kToneMake` synthesizes a clip from a list of note
frequencies, square (retro) or sine (soft), with a per-note decay.

```livecode
b2kToneMake "jump", "392,587", 40          -- a quick up-chirp
b2kToneMake "coin", "1319,1760", 36, 45    -- a bright blip
b2kToneMake "win", "523,659,784,1047", 110 -- a four-note fanfare

-- hooks: the player's land state, your sensors, your win handler
on b2kFrame
   if b2kPlayerState() is "land" then b2kSound "land"
end b2kFrame
```

`b2kSoundMute true` silences everything (a preference — it survives
`b2kTeardown`); `b2kSoundVolume` drives the engine-global loudness. On an
engine with no working audio the Kit degrades to silence rather than
errors — check `b2kSoundStatus()` if you hear nothing. The platformer's
eight cues are all synthesized; press M in it to mute.

---

## 13. Sensors (trigger zones)

A **sensor** is a non-solid fixture: bodies pass straight through it, but it
*reports* the overlap. Perfect for tripwires, goals, and pickup zones. The Kit
enables sensor events on every body it creates, so sensors detect them
automatically.

```livecode
b2kAddSensor the long id of graphic "Goal"          -- a static box sensor (shape: "box" | "ball" | "capsule")
b2kAddSensor the long id of graphic "Ring", "ball"
```

You can also flip an **existing solid body** into a sensor and back — the Kit
rebuilds its shape, keeping the new sensor state:

```livecode
b2kSetSensor tBox, true     -- tBox becomes a non-solid trigger
b2kSetSensor tBox, false    -- ...solid again
```

React with messages (sent to your `b2kContactTarget`):

```livecode
on b2kSensorEnter pSensorCtrl, pVisitorCtrl
   put "Goal!" into field "status"
end b2kSensorEnter

on b2kSensorExit pSensorCtrl, pVisitorCtrl
end b2kSensorExit
```

…or poll this frame's overlaps (1-based):

```livecode
put b2kSensorCount()              -- enters this frame
put b2kSensorEnterSensor(1)       -- the sensor control of the 1st enter
put b2kSensorEnterVisitor(1)      -- the body that entered it
put b2kSensorExitCount()          -- leaves this frame
put b2kSensorExitSensor(1)        -- ...and b2kSensorExitVisitor(1)
```

> **One sensor, many visitors.** Each enter/exit fires per body. If you want
> "fire once while occupied," count enters minus exits yourself and act on the
> 0→1 and 1→0 transitions.

---

> **One-shots vs. presence.** Enter/exit messages are perfect for one-shot
> triggers — a coin is removed on first fire, a checkpoint sets a flag. But for
> *presence* (a pressure plate that must stay pressed while anything sits on
> it), don't count enters minus exits: counting drifts, and Box2D's sensor
> begin/end around settling and sleeping bodies is exactly the edge a plate
> lives on. Poll instead — `if b2kOverlap(x1,y1,x2,y2) is not empty` each frame
> is stateless and still sees sleeping bodies — but use **`b2kOverlapMoving`**:
> the pad region sits on its floor, and the broadphase's fattened boxes make a
> plain `b2kOverlap` report the floor itself, forever. Add a short release
> debounce (~200 ms) so a settling crate's micro-bounces don't flap your door.

## 14. Collision filtering

By default everything collides with everything. Three independent tools change
that.

### Named layers (categories & masks)

The flexible system: a body **is** on one or more layers (its *category*), and it
**collides with** a set of layers (its *mask*). Two bodies touch only when **each**
one's category is in the other's mask. Up to 32 layers; name them or use numbers.

```livecode
b2kDefineLayer "enemies"     -- define/fetch a named layer (returns its bit) — optional; names auto-define
b2kSetCategory tGhost, "enemies"             -- tGhost IS an "enemy"
b2kSetMask     tGhost, "walls,player"        -- ...and only collides with walls and the player
```

Pass layers as a comma/space list of **names or numbers**. (`b2kLayerBits` is the
helper that turns such a list into a bitmask if you ever need the raw value.)

### Groups — a quick "these ignore each other"

A simpler override: bodies sharing a **negative** group never collide; a
**positive** group always collide. `0` (the default) means "use category/mask."

```livecode
b2kSetCollisionGroup tWheelA, -1     -- everything on group -1 passes through everything else on -1
b2kSetCollisionGroup tWheelB, -1
```

### Just these two

```livecode
b2kNoCollide tArm, tBody)    -- exempt one specific pair (a filter joint
```

---

## 15. Terrain and smooth chains

Stacked boxes make lumpy ground that fast bodies can catch on. A **chain** is a
single smooth surface built from a list of `x,y` screen points (≥ 4) — no inner
corners to snag. Chains are invisible; draw a matching graphic over them.

```livecode
local tPts
-- six points = four segments, of which the OUTER TWO are ghost anchors
-- (see below): the solid ground here runs from 520,360 back to 80,400
put "600,380" & cr & "520,360" & cr & "360,420" & cr & "200,360" & cr & "80,400" & cr & "20,400" into tPts
b2kChain tPts               -- an open smooth ground line
b2kChain tPts, true         -- pass true to close it into a loop (all solid)
b2kSmoothGround tPts        -- alias for an open chain
```

To make a chain that **tracks a control** (so you can move/draw the terrain as one
graphic), give it the control plus the points in the control's own outline:

```livecode
b2kAddChain the long id of graphic "Hill", the points of graphic "Hill", true
```

> **Winding matters.** A chain's *solid side is to the right of the direction the
> points travel.* For ground you stand on, list the top surface **right-to-left**
> so the solid side faces up. (If bodies fall through your terrain *everywhere*,
> reverse the point order.)

> **The ghost rule.** An **open** chain's first and last segments are Box2D's
> *ghost anchors* — they smooth the junctions but **don't collide** (N points ⇒
> N−3 solid segments). Always run the chain **one segment past** the surface you
> need on each side; over solid ground the tails can just continue flat. If
> bodies fall through your platform only *near its ends*, this is why — the
> chain's endpoints are sitting at the platform's edges. Closed loops
> (`pLoop` true) have no ends, so every segment is solid.

---

## 16. Asking the world questions (queries)

### Point

```livecode
put b2kControlAt(x, y)                 -- control whose body covers a point (empty if none)
put b2kControlContains(tBox, x, y)     -- is a point inside tBox's actual rotated shape?
```

### Region

```livecode
put b2kOverlap(100, 100, 300, 240)     -- newline list of controls overlapping a screen rect
put b2kOverlapCircle(200, 170, 60)     -- ...overlapping a screen circle (x, y, radius)
```

### Ray casts

A single closest hit, then read the result functions:

```livecode
if b2kRayHit(0, 200, 600, 200) then
   put b2kRayHitX() & "," & b2kRayHitY()           -- the hit point (screen px)
   put b2kRayHitNormalX() & "," & b2kRayHitNormalY()-- the surface normal at the hit
   put b2kRayDist()                                  -- distance from the ray start (px)
end if
```

Or every control a ray crosses, nearest-first:

```livecode
put b2kRayHitAll(0, 200, 600, 200)     -- newline list, closest first
```

---

## 17. Tuning and performance

Most scenes never need these, but they're here when you want a specific feel or a
performance HUD.

### Solver feel

```livecode
b2kSetSubsteps 4                 -- solver sub-steps per step (higher = more stable, more CPU)
b2kSetRestitutionThreshold 30    -- speed (px/s) below which bounces are killed (less jitter)
b2kSetContactTuning 30, 10, 5    -- contact stiffness: hertz, damping, max push-out (px)
b2kSetJointTuning   60, 2        -- default joint stiffness: hertz, damping
b2kSetMaxSpeed 1800              -- clamp how fast any body may move (px/s)
b2kEnableWarmStarting true       -- reuse last frame's solution (on by default; faster + stabler)
b2kEnableContinuous true         -- world-wide continuous collision (CCD)
b2kSetGravity 0, 600             -- change gravity any time (px-down is positive)
```

### Measuring

```livecode
put b2kProfile()           -- "totalStep,collide,solve" ms for the last step — a perf HUD
put b2kAwakeBodyCount()    -- awake dynamic bodies (native count)
```

> **Performance habits the Kit already follows:** sleeping is on, the renderer
> syncs from Box2D body-move events instead of scanning every body each frame,
> angle reads are skipped for non-rotating controls, pixel-identical redraws are
> skipped, joint markers that haven't moved aren't redrawn, the sprite tick walks
> only bound/playing sprites (a hundred static tiles cost nothing per frame),
> input bindings resolve their keycodes at bind time, and the player tick reads
> pre-baked tuning over raw body handles. Keep sleeping enabled, avoid heavy work
> every `on b2kFrame`, and big scenes stay smooth.

> **Performance habits for YOUR game code** (the engine is a single interpreted
> thread, and every property set risks a redraw):
> 1. **Throttle your HUD.** Setting a field's text re-lays-out and redraws it —
>    a readout that changes every frame costs a redraw every frame. Update HUDs
>    at ~4 Hz (`if the milliseconds < gHudNextMS then …`), and still skip the
>    set when the text is unchanged. Both game examples do this.
> 2. **Write properties and velocities only on change.** Track the last value you
>    applied (the platformer's gate writes its kinematic velocity only when the
>    target flips).
> 3. **Read the clock once per handler**, not once per entity.
> 4. **Build heavy things once.** Sounds survive `b2kTeardown`; tiles are
>    create-at-level-build; sheets slice lazily and share frames.

---

## 18. Dropping to the core `b2…` API

When you need something the Kit doesn't wrap, reach through to the extension and
mix both layers freely:

```livecode
put b2kWorld()                 -- the underlying world handle
put b2kBodyOf(tBox)            -- the underlying b2… body handle for a control
put b2kToWorldX(the mouseH)    -- screen px -> Box2D metres (and b2kToWorldY)
put b2kToScreenX(2.5)          -- Box2D metres -> screen px (and b2kToScreenY)
```

With the world and a body handle plus the converters, every raw `b2…` call (see
[`api-reference.md`](api-reference.md)) is available — set an exotic shape
property, then let the Kit keep drawing the control each frame.

---

## 19. A complete worked example: a little car

Putting it together — a two-wheeled car on smooth ground that you drive with the
arrow keys. Paste into a card script with the Kit installed.

```livecode
local sCar, sWheelL, sWheelR, sAxleL, sAxleR

on openCard
   b2kSetup                                  -- world + gravity, auto origin
   buildGround
   buildCar
   b2kFrameTarget the long id of me          -- we'll drive the wheels in on b2kFrame
   b2kStart
end openCard

on closeCard
   b2kStop
end closeCard

on buildGround
   local tPts
   -- top surface listed right-to-left so the solid side faces up
   put "620,360" & cr & "420,330" & cr & "220,370" & cr & "20,340" into tPts
   b2kChain tPts                         -- invisible smooth ground
   -- (draw a matching graphic over it if you want it visible)
end buildGround

on buildCar
   b2kSpawnBox 200, 120, 90, 30, "70,130,210"
   put the result into sCar
   b2kSetDensity sCar, 1.0
   b2kSpawnBall 168, 150, 36, "30,30,36"
   put the result into sWheelL
   b2kSpawnBall 232, 150, 36, "30,30,36"
   put the result into sWheelR
   b2kSetFriction sWheelL, 1.0
   b2kSetFriction sWheelR, 1.0
   -- sprung axles that can also be driven
   b2kWheel sCar, sWheelL, 168, 150
   put the result into sAxleL
   b2kWheel sCar, sWheelR, 232, 150
   put the result into sAxleR
   b2kWheelSpring sAxleL, 6, 0.7
   b2kWheelSpring sAxleR, 6, 0.7
end buildCar

on b2kFrame
   local tDrive
   put 0 into tDrive
   if the keysDown contains 124 then put 700 into tDrive    -- right arrow
   if the keysDown contains 123 then put -700 into tDrive   -- left arrow
   b2kWheelMotor sAxleL, tDrive, 900
   b2kWheelMotor sAxleR, tDrive, 900
end b2kFrame
```

That's a complete vehicle: a chassis, two sprung-and-driven wheels on wheel
joints, smooth chain terrain, and a per-frame motor driven by the keyboard.

---

## 20. Building a whole game (the micro-game pattern)

`examples/box2dxt-microgame.livecodescript` is a complete game — start
screen, two levels, a win screen — in a few hundred lines of card logic,
with nothing to install beyond the extension (the hero sheet is embedded
base64; every sound is `b2kToneMake`d). It is the file to copy when you
start your own game. Its skeleton is four ideas:

**1. A game-state machine, gated by `b2kPlayerControl`.** One `gMode`
local (`menu` / `play` / `won`) decides what clicks and keys mean. The
world is built and *running* behind the menu — the hero idles, sweepers
patrol — but `b2kPlayerControl false` means the keys do nothing until
`mgBegin` hands them over. Hit poses and the win screen reuse the same
switch.

**2. Levels are data; the interpreter is yours.** Each level is a few
lines of text, one verb per line:

```
bounds 1024,640
spawn 110,500
slab 0,576,1024,640
ledge 620,860,420
coin 460,448
spike 250,330,560
door 945,478
```

…and `mgBuild` is a ~100-line `switch` that tears the world down
(`b2kClear` + `b2kTeardown`), interprets the lines, then makes the player
and hands the camera its bounds. Verbs are cheap — when your game needs a
new object, add a `case` and a line format. This is the Kit's intended
scene pattern: the *format* belongs to your game, the heavy lifting
(bodies, sprites, camera, controller) is already API. Two details worth
stealing: the `ledge` verb ghost-pads its chain automatically (see §15),
and `door` is just a sensor plus a `gDoorOpen` flag the frame hook flips
when the coin count is full.

**3. One call makes the player.** `b2kPlayerMake gSpawnX, gSpawnY, 32,
56, "hero"` creates the capsule body host, the bound sprite, the
controller, and arms input. After it: map the anims, set two tuning
knobs, `b2kCamFollow`. The micro-game's whole "character system" is six
lines.

**4. Game events ride the hooks you already have.** Coins/spikes/door are
sensors (`on b2kSensorEnter`); landing and jump sounds key off
`b2kPlayerState()` in `on b2kFrame`; respawn is a non-looping `hit`
animation whose `b2kSpriteOnFinish` message teleports the hero home. No
new machinery — a game is the Kit's events plus your rules.

Play order: `openCard` builds level 1 and shows the menu → click →
`mgBegin` → door (all coins) → `mgAdvance` → level 2 → door → `mgShowWin`
→ click → back to level 1. `R` rebuilds the current level, `ESC` pauses,
`M` mutes.

---

## 21. Player actions: duck, drop-through, ladders, knockback, swim

Wave 2 builds four standard platformer verbs into the controller. They
cost nothing until used (each idles at one compare per frame) and they
compose — a drop-through can fall into a ladder grab; a knockback ends a
climb and restores gravity itself.

**Duck** needs no setup: DOWN while grounded brakes the player to a stop
and shows the `duck` anim slot (`b2kPlayerAnims`'s sixth argument; it
falls back to the idle pose). **The hitbox does not shrink this wave** —
you cannot duck *under* a saw yet; capsule reshaping is scheduled with
Wave 5. Say so in your help text if your level dangles something
head-high.

**Drop-through** works on every `b2kChain`/`b2kSmoothGround` deck
automatically — chains carry a reserved collision category, and DOWN+JUMP
while standing on one masks that category off the player for `dropMs`
(~260 ms), long enough to fall clear; the deck is solid again on the next
landing. On solid ground the same press just ducks (and is eaten — no
buffered launch when DOWN releases). Two level-design rules: the deck
needs **head-room below** (a solid platform parked less than a
player-height under a one-way deck means the drop can't clear it — the
mask is restored by a hard deadline and the player may pop back on top),
and remember the **ghost rule** (§15) so the deck's ends are solid in the
first place.

**Ladders** are *zones*, not bodies: `b2kPlayerAddLadder x1,y1,x2,y2`
registers a screen-px rect; presence is a pure per-frame poll (the
presence doctrine — no sensors, no contacts). In-zone, UP enters the
`climb` state: gravity parks at 0, y runs at `climbSpeed` off the moveY
axis (neither held = hang), x at half `moveSpeed`. JUMP exits with a
normal jump; sliding out of the zone or climbing down onto ground
restores gravity. DOWN grabs the ladder only while **airborne** — a
grounded DOWN is a duck — so to descend from a platform top, run the zone
a little above the platform and walk off its edge holding DOWN. Draw your
own rungs (a few lines, or the tiles sheet's `ladder_*` frames); zones
are world state, wiped by `b2kClear` with everything else.

**Knockback** (`b2kPlayerHurt fromX`) is the contact-damage standard the
games share. It pops the player away from `fromX` (`hurtPopX`/`hurtPopY`,
exempt from the ground-snap), holds the `hurt` state with input
suppressed until `hurtMs` *or* the first landing after half of it
(whichever is later), then opens an `invulnMs` mercy window during which
`b2kPlayerHurt` no-ops and `b2kPlayerHurtIs()` answers true — gate your
hazard checks on it. The split that makes games feel right: **contact
damage knocks back in place; lethal hits (pits, kill planes) keep your
respawn flow.** Your respawn's `b2kPlayerControl false` call also cancels
any knockback in flight, so the two paths hand over cleanly when a
knockback ends in a pit. One art note: if your game uses
`b2kSpriteOnFinish` on the player's sprite (the respawn-on-finish
pattern), map a **looping** animation to the `hurt` anim slot — a
non-looping pose would finish mid-knockback and fire your respawn.

**Swim** (Wave 4) is the buoyant parallel to the climb. `b2kPlayerAddWater
x1,y1,x2,y2` registers a water *zone* (polled presence, world state, wiped
by `b2kClear` like a ladder). While the player's centre is submerged the
`swim` state owns the controller: gravity scales to `swimGravity` (the
body's own scale is saved and restored, so a game-tuned floatiness
survives), the sink caps at `swimMaxFall`, UP/DOWN swim at `swimSpeed`, and
a JUMP press is a *repeatable* upward **stroke** of `swimJump` — no
grounded/coyote/buffer gate. Leaving the zone or a hurt restores gravity;
swim and climb are mutually exclusive (the tick starts only one). Map a
swim frame with `b2kPlayerAnims`'s ninth argument (it falls back to the
`fall`/`jump` pose, so a sheet without one still reads).

Two things the OXT rounds taught: **(1) tuning** — `swimGravity` sets only
how fast you sink *between* strokes; the single-stroke escape height is
`swimJump` ALONE (the stroke sets velocity directly, then full air-gravity
governs the apex once you break the surface), so to make climbing out of a
pool harder, lower `swimJump`, not the gravity. **(2) layout** — a swim
pool can't be a pit *below* the ground, because `b2kCamBounds` clamps the
camera at the world's bottom edge and anything lower is off-screen; build
the pool as a RAISED basin between two banks (or raise the whole ground, as
the micro-game does), then hop in, dive for the coins, and stroke up +
hold-forward to hop out the far bank.

---

## 22. xTalk gotchas worth knowing

A few things that trip up LiveCode/OpenXTalk users specifically:

- **Pass controls by `the long id of …`.** Short names break if you rename or
  re-layer; long ids stay valid. Every `ctrl` parameter wants a reference.
- **Identifiers are case-insensitive — dodge reserved words.** xTalk treats
  `players`, `Players`, and `pLayers` as the *same* name, and many words
  (`type`, `name`, `layer`, `number`, `time`, `id`, `mode`…) are reserved. The
  Kit prefixes everything (`b2k…`, internal `s…`); prefix **your** variables too
  (`tBox`, `gScore`) so you never collide with a keyword.
- **`get` vs. `put` for functions that return.** `b2kSpawn…`, `b2kGrab`, and the
  joint constructors *return* a value. Use `put … into tVar` to keep it, or
  `get …` to discard it. Calling them as a bare statement is a syntax error.
- **Custom properties stick to objects.** A handy pattern is to stash per-object
  data as `set the uColor of tBox to …` and read it back later — the Kit and the
  examples use `u…` custom properties throughout.
- **One world at a time.** The Kit owns a single world. `b2kTeardown` before you
  build a fresh scene, or `b2kClear` to empty the current one.

---

## 23. Complete API index

Every public handler, grouped. `[f]` marks a **function** (returns a value — call
it with `()` / `get` / `put`); everything else is a **command** (a statement).
Optional arguments are in `[…]`.

### World & lifecycle
`b2kSetup [gx, gy]` · `b2kQuickStart [gy]` · `b2kStart` · `b2kStop` ·
`b2kPause` · `b2kResume` · `b2kStepOnce` · `b2kIsRunning()` `[f]` ·
`b2kAddWalls` · `b2kAddGround [screenY]` · `b2kWall x1,y1,x2,y2` · `b2kClear` ·
`b2kTeardown` · `b2kVersion()` `[f]` · `b2kWorld()` `[f]`

### Configuration & coordinates
`b2kSetScale px` · `b2kSetOrigin x,y` · `b2kSetGravity gx,gy` ·
`b2kSetSubsteps n` · `b2kContactTarget obj` · `b2kFrameTarget obj` ·
`b2kEnableSleeping flag` · `b2kEnableContinuous flag` ·
`b2kToScreenX(m)` `[f]` · `b2kToScreenY(m)` `[f]` · `b2kToWorldX(px)` `[f]` ·
`b2kToWorldY(px)` `[f]`

### Attach & spawn
`b2kAddBox ctrl [,dyn]` · `b2kAddBall ctrl [,dyn]` · `b2kAddCapsule ctrl [,dyn]` ·
`b2kAddPolygon ctrl [,dyn]` · `b2kAddStatic ctrl` · `b2kReshape ctrl, shape` ·
`b2kSpawnBox x,y,w,h [,color]` `[f]` · `b2kSpawnBall x,y,diam [,color]` `[f]` ·
`b2kSpawnCapsule x,y,len,thick [,color]` `[f]`

### Materials & body settings
`b2kSetBounce ctrl,0..1` · `b2kSetFriction ctrl,0..1` · `b2kSetDensity ctrl,d` ·
`b2kSetBullet ctrl,flag` · `b2kSetFixedRotation ctrl,flag` ·
`b2kSetGravityScale ctrl,s` · `b2kSetDamping ctrl,lin [,ang]` ·
`b2kWake ctrl` · `b2kSleep ctrl` · `b2kSetSleepEnabled ctrl,flag` ·
`b2kSetSleepThreshold ctrl,pxPerSec` ·
`b2kSetStatic ctrl` · `b2kSetDynamic ctrl` · `b2kSetKinematic ctrl` ·
`b2kSetType ctrl,name` · `b2kDisable ctrl` · `b2kEnable ctrl`

### Act on bodies
`b2kPush ctrl,dvx,dvy` · `b2kImpulse ctrl,ix,iy` · `b2kForce ctrl,fx,fy` ·
`b2kSetVelocity ctrl,vx,vy` · `b2kSpin ctrl,deg/s` · `b2kSpinBy ctrl,deg/s` ·
`b2kTorque ctrl,t` · `b2kAngularImpulse ctrl,imp` · `b2kMoveTo ctrl,x,y [,deg]` ·
`b2kExplode x,y [,radius] [,power]` · `b2kExplodeLegacy x,y [,radius] [,power]` ·
`b2kRemove ctrl`

### Read state
`b2kBodyOf(ctrl)` `[f]` · `b2kPosition(ctrl)` `[f]` · `b2kWorldCenter(ctrl)` `[f]` ·
`b2kVelocity(ctrl)` `[f]` · `b2kSpeed(ctrl)` `[f]` · `b2kAngle(ctrl)` `[f]` ·
`b2kSpinRate(ctrl)` `[f]` · `b2kMass(ctrl)` `[f]` · `b2kBodyType(ctrl)` `[f]` ·
`b2kGravityScale(ctrl)` `[f]` · `b2kDamping(ctrl)` `[f]` · `b2kIsAwake(ctrl)` `[f]` ·
`b2kIsBullet(ctrl)` `[f]` · `b2kIsEnabled(ctrl)` `[f]` · `b2kBodyCount()` `[f]` ·
`b2kAwakeCount()` `[f]` · `b2kControlAt(x,y)` `[f]` · `b2kControlContains(ctrl,x,y)` `[f]`

### Joints
`b2kHinge a,b,x,y` `[f]` · `b2kWeld a,b` `[f]` · `b2kRope a,b [,len]` `[f]` ·
`b2kSlider a,b,axisDeg` `[f]` · `b2kWheel chassis,wheel,x,y [,axisDeg]` `[f]` ·
`b2kMotorTo mover,ref,dx,dy,deg [,maxF,maxT]` `[f]` · `b2kNoCollide a,b` `[f]` ·
`b2kRemoveJoint joint`
&nbsp;&nbsp;**Drive/limit/spring:** `b2kMotor j,deg/s [,maxT]` ·
`b2kHingeLimit j,lo,hi` · `b2kHingeAngle(j)` `[f]` · `b2kMotorOff j` ·
`b2kHingeLimitOff j` · `b2kSliderMotor j,px/s [,maxF]` · `b2kSliderLimit j,lo,hi` ·
`b2kSliderPos(j)` `[f]` · `b2kSliderMotorOff j` · `b2kSliderLimitOff j` ·
`b2kWheelMotor j,deg/s [,maxT]` · `b2kWheelSpring j,hz [,damp]` ·
`b2kWheelMotorOff j` · `b2kRope…` readouts: `b2kRopeRange j,min,max` ·
`b2kRopeLength(j)` `[f]` · `b2kRopeSetLength j,px` · `b2kSpring j,hz [,damp]` ·
`b2kWeldSpring j,hz [,damp]`

### Drag
`b2kGrab(x,y)` `[f]` · `b2kRelease`

### Input (keyboard)
`b2kInputOn` · `b2kInputOff` · `b2kInputIsOn()` `[f]` · `b2kKeyIsDown(key)` `[f]` ·
`b2kKeyPressed(key)` `[f]` · `b2kKeyReleased(key)` `[f]` · `b2kKeysHeld()` `[f]` ·
`b2kBindAction name,keys` · `b2kActionIsDown(name)` `[f]` ·
`b2kActionPressed(name)` `[f]` · `b2kActionReleased(name)` `[f]` ·
`b2kBindAxis name,negKeys,posKeys` · `b2kAxis(name)` `[f]` ·
`b2kInputInject keys` · `b2kInputInjectOff` ·
`b2kKeyCodes(key)` `[f]` · `b2kKeyName(code)` `[f]` · `b2kFrameMS()` `[f]`

### Sprites & sheets
`b2kSheetLoad name,path,fw,fh [,n,margin,spacing]` · `b2kSheetLoadAtlas name,png [,xml]` ·
`b2kSheetFromImage name,img,fw,fh [,n,margin,spacing]` ·
`b2kSheetAddFrame sheet,frame,x,y,w,h` · `b2kSheetFrames(name)` `[f]` ·
`b2kSheetHasFrame(name,frame)` `[f]` · `b2kSheetFrameNames(name)` `[f]` ·
`b2kSheetScale name,factor` ·
`b2kSheetFrameSize(name,frame)` `[f]` · `b2kAnimDef sheet,anim,frames,fps [,loop]` ·
`b2kSpriteNew sheet [,frame,x,y]` · `b2kSpriteFromGIF path [,x,y]` ·
`b2kSpritePlay spr,anim [,restart]` · `b2kSpriteStop spr` · `b2kSpriteAnim(spr)` `[f]` ·
`b2kSpriteSetFrame spr,f` · `b2kSpriteFrame(spr)` `[f]` · `b2kSpriteFPS spr,fps` ·
`b2kSpriteFlipH spr,flag` · `b2kSpriteFlipped(spr)` `[f]` ·
`b2kSpriteOnFinish spr,msg` · `b2kSpriteMoveTo spr,x,y` ·
`b2kSpriteBind spr,bodyCtrl [,dx,dy]` · `b2kSpriteUnbind spr` · `b2kSpriteRemove spr`

### Player (the platformer controller)
`b2kPlayerMake x,y,w,h [,sheet]` · `b2kPlayerAttach ctrl` ·
`b2kPlayerAnims idle,run,jump [,fall] [,land] [,duck] [,climb] [,hurt] [,swim]` ·
`b2kPlayerSet key,value` ·
`b2kPlayerGet(key)` `[f]` · `b2kPlayerOnGround()` `[f]` · `b2kPlayerState()` `[f]` ·
`b2kPlayerFacing()` `[f]` · `b2kPlayerJump [speed]` · `b2kPlayerControl flag` ·
`b2kPlayerAddLadder x1,y1,x2,y2` · `b2kPlayerAddWater x1,y1,x2,y2` · `b2kPlayerHurt [fromX]` ·
`b2kPlayerHurtIs()` `[f]` ·
`b2kPlayer()` `[f]` · `b2kPlayerSprite()` `[f]` · `b2kPlayerRemove`

### Camera
`b2kCamOn [rect]` · `b2kCamOff` · `b2kCamIsOn()` `[f]` · `b2kCamGroup()` `[f]` ·
`b2kCamAdopt ctrl` · `b2kCamFollow ctrl [,lerp]` · `b2kCamUnfollow` ·
`b2kCamDeadzone w,h` · `b2kCamBounds x1,y1,x2,y2` · `b2kCamGoto x,y` ·
`b2kCamPos()` `[f]` · `b2kCamShake ampPx,ms` · `b2kCamStatus()` `[f]` ·
`b2kCamLocSemantics()` `[f]` · `b2kCamMouseX()` `[f]` · `b2kCamMouseY()` `[f]`

### Sound
`b2kSoundLoad name,path` · `b2kToneMake name,freqs,msPerNote [,vol,shape]` ·
`b2kSound name` · `b2kSoundLoop name` · `b2kSoundStop` · `b2kSoundMute flag` ·
`b2kSoundMuted()` `[f]` · `b2kSoundVolume pct` · `b2kSoundIsLoaded(name)` `[f]` ·
`b2kSoundStatus()` `[f]`

### Events (handlers you write)
`on b2kFrame` · `on b2kContact pA,pB` · `on b2kEndContact pA,pB` ·
`on b2kSensorEnter pSensor,pVisitor` · `on b2kSensorExit pSensor,pVisitor`
&nbsp;&nbsp;**Polling:** `b2kContactCount()` `[f]` · `b2kContactA(i)` `[f]` ·
`b2kContactB(i)` `[f]` · `b2kEndContactCount()` `[f]` · `b2kEndContactA(i)` `[f]` ·
`b2kEndContactB(i)` `[f]`

### Sensors
`b2kAddSensor ctrl [,shape]` `[f]` · `b2kSetSensor ctrl,flag` ·
`b2kSensorCount()` `[f]` · `b2kSensorEnterSensor(i)` `[f]` ·
`b2kSensorEnterVisitor(i)` `[f]` · `b2kSensorExitCount()` `[f]` ·
`b2kSensorExitSensor(i)` `[f]` · `b2kSensorExitVisitor(i)` `[f]`

### Collision filtering
`b2kDefineLayer name` · `b2kLayerBits(list)` `[f]` · `b2kSetCategory ctrl,layers` ·
`b2kSetMask ctrl,layers` · `b2kSetCollisionGroup ctrl,n` · `b2kNoCollide a,b` `[f]`

### Terrain & chains
`b2kChain points [,loop]` · `b2kSmoothGround points` · `b2kAddChain ctrl,points [,loop]`

### Queries
`b2kOverlap x1,y1,x2,y2` `[f]` · `b2kOverlapMoving x1,y1,x2,y2` `[f]` ·
`b2kOverlapCircle x,y,r` `[f]` ·
`b2kRayHit(x1,y1,x2,y2)` `[f]` · `b2kRayHitX()` `[f]` · `b2kRayHitY()` `[f]` ·
`b2kRayHitNormalX()` `[f]` · `b2kRayHitNormalY()` `[f]` · `b2kRayDist()` `[f]` ·
`b2kRayHitAll x1,y1,x2,y2` `[f]`

### Tuning & profiling
`b2kSetRestitutionThreshold px/s` · `b2kSetContactTuning hz,damp,pushPx` ·
`b2kSetJointTuning hz,damp` · `b2kSetMaxSpeed px/s` · `b2kEnableWarmStarting flag` ·
`b2kProfile()` `[f]` · `b2kAwakeBodyCount()` `[f]`

### Internal helpers (you usually won't call these)

The Kit also defines handlers it uses on your behalf — the loop and renderer
(`b2kSync`, `b2kDrawPoly`, `b2kDrawBall`, `b2kDrawImage`, `b2kDispatchContacts`,
`b2kDispatchSensors`), construction primitives (`b2kEdge`, `b2kRegister`,
`b2kResetTables`), and math helpers (`b2kLocalAnchor`, `b2kQueryToControls`,
`b2kCorner`, `b2kCapsuleVerts`). They're listed here for completeness; reach for
the public handlers above instead.

---

*See also:* [`getting-started.md`](getting-started.md) ·
[`kit-reference.md`](kit-reference.md) (quick tables) ·
[`api-reference.md`](api-reference.md) (the core `b2…` layer) ·
[`architecture.md`](architecture.md) (how the three layers fit together).
