# Box2Dxt Kit Reference (`b2k…`)

The **Kit** (`src/box2dxt-kit.livecodescript`) is a batteries-included,
pure-xTalk toolkit over the `box2dxt` extension. You work in **pixels, screen
coordinates and degrees**; the Kit hides the world, the fixed-timestep loop,
coordinate conversion, and the per-frame control updates — and it runs with the
demo's performance practices built in.

**Setup:** paste the Kit into your card/stack script (or save it as a library
stack and `start using` it). It requires the `box2dxt` extension loaded
(`put b2Version()` should return `4`).

> **New here?** Read the [**Complete Guide**](kit-guide.md) first — it teaches
> the Kit start-to-finish with runnable examples. This page is the quick-lookup
> reference.

- [60-second start](#60-second-start)
- [World & loop](#world--loop)
- [Configuration](#configuration)
- [Attach & spawn](#attach--spawn)
- [Materials](#materials)
- [Body settings](#body-settings)
- [Act on bodies](#act-on-bodies)
- [Read state](#read-state)
- [Joints](#joints)
- [Drag & events](#drag--events)
- [Tips](#tips)

---

## 60-second start

```
on openCard
   b2kQuickStart                       -- world + gravity + card-edge walls + go
   b2kSpawnBall 200, 80, 50            -- create & drop a 50px ball
   b2kSpawnBox 260, 80, 60, 40, "orange"  -- (read `the result` for the ref)
   b2kContactTarget the long id of me  -- (optional) collision messages
end openCard
on mouseDown ; get b2kGrab(the mouseH, the mouseV) ; end mouseDown
on mouseUp   ; b2kRelease ; end mouseUp
on closeCard ; b2kStop ; end closeCard
```

Or **attach controls you designed in the IDE** (graphics rotate; other control
types follow position):

```
b2kSetup                                       -- world + gravity, auto origin
b2kAddStatic the long id of graphic "Floor"
b2kAddBox    the long id of graphic "Crate"
b2kAddBall   the long id of graphic "Ball"
b2kContactTarget the long id of me             -- on b2kContact pA, pB
b2kStart
```

## World & loop

| Handler | Purpose |
|---------|---------|
| `b2kSetup [gx, gy]` | Create the world + gravity, auto-detect the origin. |
| `b2kQuickStart [gy]` | One call: world + gravity + card-edge walls + start the loop. |
| `b2kStart` / `b2kStop` | Begin / end the simulation loop. |
| `b2kPause` / `b2kResume` | Freeze / resume stepping without tearing down. |
| `b2kStepOnce` | Advance exactly one fixed step (even while paused) — drives a Step button. |
| `b2kIsRunning()` | True while the loop is stepping (not stopped or paused). |
| `b2kAddWalls` | Static walls around the current card edges. |
| `b2kAddGround [screenY]` | A static floor across the card (optionally at a given Y). |
| `b2kWall x1, y1, x2, y2` | A static collision segment between two screen points (custom walls, ramps, ledges). **Two-sided** — bodies collide from both sides whichever way you list the points; for one-sided (jump-through) surfaces use `b2kChain`/`b2kSmoothGround`. Invisible — draw your own graphic to match. |
| `b2kClear` | Remove all bodies/controls the Kit created, keep the world. |
| `b2kTeardown` | Stop and destroy the world and all Kit state. |
| `b2kVersion()` | Native shim ABI version (`4`) — a load / in-sync check from Kit-only code. |

## Configuration

| Handler | Purpose |
|---------|---------|
| `b2kSetScale px` | Pixels per metre (default 40). |
| `b2kSetOrigin x, y` | Screen point that maps to the world origin. |
| `b2kSetGravity gx, gy` | Change gravity (pixels-down is positive). |
| `b2kSetSubsteps n` | Solver sub-steps per step (≈ 4). |
| `b2kContactTarget obj` | Object that receives `on b2kContact` / `on b2kEndContact` messages. |
| `b2kFrameTarget obj` | Object that receives an `on b2kFrame` message once per simulated frame. |
| `b2kEnableSleeping flag` | Toggle island sleeping (saves CPU when bodies rest). |
| `b2kEnableContinuous flag` | Toggle continuous collision (CCD) for the world. |

## Attach & spawn

Attach physics to existing controls, or spawn new ones. Pass controls by
reference (`the long id of …` is safest). Add `,true`/`,false` to force
dynamic/static where a handler takes an optional `dyn` flag.

**Any control type works** — it falls, collides, and is draggable. How it's
*drawn* to follow its body depends on the type:

| Control | Follows position | Rotates |
|---------|:---:|:---:|
| **Graphic** (box → polygon, or ball) | ✅ | ✅ |
| **Image** (dynamic) | ✅ | ✅ via `the angle` |
| **Button / field / other** | ✅ | ❌ rotation locked so the sim matches the upright render |

| Handler | Purpose |
|---------|---------|
| `b2kAddBox ctrl [,dyn]` | Treat a control as a dynamic (default) box. |
| `b2kAddBall ctrl [,dyn]` | Treat a control as a circle. |
| `b2kAddCapsule ctrl [,dyn]` | Treat a control as a capsule (pill); long side = axis, short side = diameter. |
| `b2kAddPolygon ctrl [,dyn]` | Treat a graphic's points as a convex polygon. |
| `b2kAddStatic ctrl` | Immovable body matching the control. |
| `b2kAddGround [screenY]` | Static floor (see above). |
| `b2kSpawnBox x, y, w, h [,color]` → control | Create a control *and* its box body. |
| `b2kSpawnBall x, y, diam [,color]` → control | Create a control *and* its ball body. |
| `b2kSpawnCapsule x, y, len, thick [,color]` → control | Create a pill-shaped control *and* its capsule body. |
| `b2kReshape ctrl, "box"\|"ball"\|"capsule"\|"poly"` | Rebuild a body's collision shape from the control's current size/points, on the same body (joints survive). Resets material + filter — re-apply them after. |

## Materials

| Handler | Purpose |
|---------|---------|
| `b2kSetBounce ctrl, 0..1` | Restitution. |
| `b2kSetFriction ctrl, 0..1` | Friction. |
| `b2kSetDensity ctrl, d` | Density (affects mass). |

## Body settings

| Handler | Purpose |
|---------|---------|
| `b2kSetBullet ctrl, flag` | Continuous collision for fast bodies. |
| `b2kSetFixedRotation ctrl, flag` | Stop a body from rotating. |
| `b2kSetGravityScale ctrl, s` | Per-body gravity multiplier. |
| `b2kSetDamping ctrl, lin [,ang]` | Linear (and optional angular) damping. |
| `b2kWake ctrl` | Wake a sleeping body. |
| `b2kSleep ctrl` | Send a body to sleep until something wakes it. |
| `b2kSetSleepThreshold ctrl, pxPerSec` | Speed below which a body may fall asleep. |
| `b2kSetStatic ctrl` / `b2kSetDynamic ctrl` / `b2kSetKinematic ctrl` | Change body type at runtime (freeze/unfreeze, moving platforms). |
| `b2kSetType ctrl, "static"\|"kinematic"\|"dynamic"` | Set body type by name. |
| `b2kDisable ctrl` / `b2kEnable ctrl` | Take a body out of / put it back into the simulation. |

## Act on bodies

| Handler | Purpose |
|---------|---------|
| `b2kPush ctrl, dvx, dvy` | Add a one-shot impulse (change in velocity, px/s). |
| `b2kForce ctrl, fx, fy` | Apply a continuous force (call each frame for thrust/wind). |
| `b2kImpulse ctrl, ix, iy` | One-shot impulse, mass-aware (heavier bodies move less). |
| `b2kTorque ctrl, torque` | Continuous turning force (call each frame); +/- sets direction. |
| `b2kAngularImpulse ctrl, imp` | One-shot turning impulse, mass-aware (the angular partner of `b2kImpulse`). |
| `b2kSetVelocity ctrl, vx, vy` | Set linear velocity (px/s). |
| `b2kSpin ctrl, degPerSec` | Set angular velocity. |
| `b2kSpinBy ctrl, degPerSec` | Add to the current angular velocity. |
| `b2kMoveTo ctrl, x, y [,deg]` | Teleport a body. |
| `b2kExplode x, y [,radius] [,power]` | Radial impulse from a point. |
| `b2kRemove ctrl` | Destroy a body (and the control if the Kit spawned it). |

## Read state

| Handler | Returns |
|---------|---------|
| `b2kBodyOf(ctrl)` | The underlying `b2…` body handle. |
| `b2kPosition(ctrl)` | Body centre as `x,y` in screen pixels (the position partner of `b2kVelocity`). |
| `b2kWorldCenter(ctrl)` | Centre of mass as `x,y` in screen pixels (the true pivot for spin/torque). |
| `b2kVelocity(ctrl)` | `vx,vy` in px/s. |
| `b2kSpeed(ctrl)` | Scalar speed (px/s). |
| `b2kAngle(ctrl)` | Rotation in degrees. |
| `b2kMass(ctrl)` | Body mass (kg, sim units). |
| `b2kGravityScale(ctrl)` | Per-body gravity multiplier (getter for `b2kSetGravityScale`). |
| `b2kDamping(ctrl)` | Drag as `linear,angular` (getter for `b2kSetDamping`). |
| `b2kBodyType(ctrl)` | Body type as a word: `static` / `kinematic` / `dynamic`. |
| `b2kBodyCount()` | How many bodies the Kit is tracking. |
| `b2kAwakeCount()` | How many dynamic bodies are currently awake (active). |
| `b2kIsAwake(ctrl)` | Whether the body is awake. |
| `b2kSpinRate(ctrl)` | Rotation speed in degrees/sec (getter for `b2kSpin`). |
| `b2kIsBullet(ctrl)` | Whether continuous (CCD) collision is on. |
| `b2kIsEnabled(ctrl)` | Whether the body is in the simulation. |
| `b2kControlAt(x, y)` | The control whose body covers a screen point. |
| `b2kControlContains(ctrl, x, y)` | True if a screen point is inside this control's actual (rotated) collision shape. |
| `b2kRayHit(x1, y1, x2, y2)` | True if a ray hits; then read the result functions below. |
| `b2kRayHitX()` / `b2kRayHitY()` | Hit point in screen pixels. |
| `b2kRayHitNormalX()` / `b2kRayHitNormalY()` | Surface normal at the hit (screen-oriented unit vector). |
| `b2kRayDist()` | Distance in pixels from the ray start to the hit. |

## Joints

All joint constructors return a joint handle; pass it to the motor/limit/spring
helpers or to `b2kRemoveJoint`.

| Handler | Purpose |
|---------|---------|
| `b2kHinge ctrlA, ctrlB, x, y` → joint | Revolute pivot at a screen point (ctrlB empty = pin ctrlA to the world). |
| `b2kWeld ctrlA, ctrlB` → joint | Rigidly glue two controls. |
| `b2kRope ctrlA, ctrlB [,len]` → joint | Maximum-distance link. |
| `b2kSlider ctrlA, ctrlB, axisDeg` → joint | Prismatic: slide ctrlA along an axis (0 = horizontal, 90 = vertical) relative to ctrlB or the world. |
| `b2kWheel chassis, wheel, x, y [,axisDeg]` → joint | Wheel joint: sprung sliding axis + free spin (vehicle wheels). |
| `b2kRemoveJoint joint` | Remove a joint. |

**Motors, limits, springs & readouts:**

| Handler | Purpose |
|---------|---------|
| `b2kMotor joint, degPerSec [,maxTorque]` | Drive a **hinge** joint. |
| `b2kHingeLimit joint, lowerDeg, upperDeg` | Constrain a hinge's angle. |
| `b2kHingeAngle(joint)` → degrees | Current hinge angle. |
| `b2kSliderMotor joint, pxPerSec [,maxForce]` | Drive a **slider**. |
| `b2kSliderLimit joint, lowerPx, upperPx` | Constrain a slider's travel. |
| `b2kSliderPos(joint)` → pixels | Current slider translation. |
| `b2kWheelMotor joint, degPerSec [,maxTorque]` | Drive a **wheel**. |
| `b2kWheelSpring joint, hertz [,damping]` | Tune wheel suspension. |
| `b2kRopeRange joint, minPx, maxPx` | Set a distance joint's min/max length. |
| `b2kRopeLength(joint)` → pixels | Current distance-joint length. |
| `b2kRopeSetLength joint, px` | Set a distance joint's exact rest length. |
| `b2kSpring joint, hertz [,damping]` | Make a rope (distance) joint springy. |
| `b2kWeldSpring joint, hertz [,damping]` | Make a weld springy (0 hertz = rigid). |
| `b2kMotorOff joint` | Turn a hinge motor off (free swing). |
| `b2kHingeLimitOff joint` | Remove a hinge's angle limits. |
| `b2kSliderMotorOff joint` | Turn a slider motor off. |
| `b2kSliderLimitOff joint` | Remove a slider's travel limits. |
| `b2kWheelMotorOff joint` | Turn a wheel motor off. |

## Input (keyboard)

Poll-based held-key input for games: arm it once, then read state from
`on b2kFrame`. The Kit samples `the keysDown` once per frame and diffs against
the previous frame, so held keys are smooth (no OS auto-repeat artifacts), no
focus or message-path setup is needed, and pressed/released edges are exact.
Key names: `left right up down space return escape tab shift control alt
backspace delete`, single characters (`"a"`…`"z"`, digits — letters match both
shifted and unshifted), or raw keycodes.

| Handler | Purpose |
|---------|---------|
| `b2kInputOn` / `b2kInputOff` | Arm / disarm the per-frame keyboard sample. `b2kInputOn` installs starter bindings: axis `moveX` (left,a / right,d), axis `moveY` (up,w / down,s), action `jump` (space). |
| `b2kKeyIsDown(key)` | Key currently held. |
| `b2kKeyPressed(key)` / `b2kKeyReleased(key)` | True only on the frame the key went down / came up. |
| `b2kKeysHeld()` | Everything held now, as friendly names (debug HUDs). |
| `b2kBindAction name, keyList` | Name a key set: `b2kBindAction "jump", "space,up,w"`. |
| `b2kActionIsDown(name)` / `b2kActionPressed(name)` / `b2kActionReleased(name)` | Action-level queries — any bound key counts; edges treat the set as one logical key. |
| `b2kBindAxis name, negKeys, posKeys` | Define a -1/0/+1 axis. |
| `b2kAxis(name)` | Read an axis; both directions held = 0. |
| `b2kKeyCodes(key)` / `b2kKeyName(code)` | The name↔keycode maps the module uses (handy for debugging). |
| `b2kFrameMS()` | Real elapsed ms folded into the last frame — drive animations and timers from this, not the step count. |

```
on openCard
   b2kQuickStart
   b2kSpawnCapsule 200, 100, 64, 30, "gold"
   put the result into gHero
   b2kSetFixedRotation gHero, true
   b2kInputOn
   b2kFrameTarget the long id of me
end openCard

on b2kFrame
   b2kSetVelocity gHero, b2kAxis("moveX") * 240, item 2 of b2kVelocity(gHero)
   if b2kActionPressed("jump") then b2kPush gHero, 0, -420
end b2kFrame
```

See `examples/box2dxt-platformer.livecodescript` for the full pattern
(grounded check, jump-cut, one-way ledge).

## Sprites & animation

Spritesheet animation on the **icon-button backend** (chosen by the Phase 0
benchmarks): a sheet registers named or numbered frame *regions* of one
hidden source image; each region is sliced into its own hidden image lazily,
on first use; a **sprite is a transparent button** whose `icon` is the
current frame — all sprites of a sheet share the same frame images. Sheets
persist until `b2kTeardown`; sprites are Kit-created controls, so `b2kClear`
removes them with everything else.

| Handler | Purpose |
|---------|---------|
| `b2kSheetLoad name, path, fw, fh [,count]` → count | Register an image file as a uniform grid of `fw`×`fh` frames (no spacing), numbered 1..N row-major. |
| `b2kSheetLoadAtlas name, pngPath [,xmlPath]` → count | Register a packed atlas: PNG + `TextureAtlas` XML naming its regions (the Kenney format — see `Spritesheets/` in this repo). Frames are addressed **by name** (`"coin_gold"`). XML path defaults to the PNG path with `.xml`. |
| `b2kSheetFromImage name, imgRef, fw, fh [,count]` → count | Register an image already in the stack (e.g. base64-embedded art) as a grid sheet. |
| `b2kSheetFrames(name)` / `b2kSheetHasFrame(name, frame)` | Frame count / existence checks. |
| `b2kAnimDef sheet, anim, frames, fps [,loop]` | Name an animation: `frames` is a comma list of names and/or indices, numeric ranges (`"1-8"`) expand. `loop` defaults true. |
| `b2kSpriteNew sheet [,frame, x, y]` → control | Create a sprite showing `frame` (default: the sheet's first), sized to the frame. An ordinary Kit control: give it a body (`b2kAddCapsule …`) or bind it to one. |
| `b2kSpriteFromGIF path [,x, y]` → control | An animated-GIF sprite (the engine plays it; play/stop/frame map to `repeatCount`/`currentFrame`). |
| `b2kSpritePlay spr, anim [,restart]` | Start a named animation — a no-op if already playing it, so calling it every frame from a state machine is free. |
| `b2kSpriteStop spr` / `b2kSpriteAnim(spr)` | Freeze on the current frame / what's playing. |
| `b2kSpriteSetFrame spr, frame` / `b2kSpriteFrame(spr)` | Manual frame control (stops any animation). |
| `b2kSpriteFPS spr, fps` | Per-sprite speed override (empty = each animation's own fps). |
| `b2kSpriteFlipH spr, flag` / `b2kSpriteFlipped(spr)` | Face left/right — mirrored frames are flip-cloned lazily, shared like the originals. |
| `b2kSpriteOnFinish spr, message` | When a **non-looping** animation ends, send `message spr, anim` to the frame target (attack/death/effect chains). |
| `b2kSpriteBind spr, bodyCtrl [,dx, dy]` / `b2kSpriteUnbind spr` | Pin the sprite to another control's position each frame — the standard "art bigger than the collision shape" pattern: an invisible control owns the body, the sprite follows it. |
| `b2kSpriteRemove spr` | Remove the sprite (and its body, if it has one). |

```
b2kSheetLoadAtlas "chars", tFolder & "/spritesheet-characters-default.png"
b2kAnimDef "chars", "walk", "character_beige_walk_a,character_beige_walk_b", 6, true
b2kSpriteNew "chars", "character_beige_idle", 200, 100
put the result into tSpr
b2kSpritePlay tSpr, "walk"
b2kSpriteFlipH tSpr, true       -- face left
```

Performance notes (Phase 0 measurements, modest Win32 hardware): a frame
switch is one icon set; ~25 *moving* animated sprites ≈ 40 fps, a player plus
a handful sits at the loop ceiling. Create sprites at scene load (not
mid-play) and **before** enabling `acceleratedRendering` where possible — bulk
control creation under the compositor caused the spike's one-time stall.

## Drag & events

| Handler | Purpose |
|---------|---------|
| `b2kGrab(x, y)` → control | Grab the body under a point (mouse joint). Returns the grabbed control, or empty. |
| `b2kRelease` | Release a grabbed body. |
| `on b2kContact pCtrlA, pCtrlB` | Sent to your `b2kContactTarget` when two attached controls **begin** touching. Long ids are empty for walls/ground. |
| `on b2kEndContact pCtrlA, pCtrlB` | Sent when two attached controls **stop** touching. |
| `on b2kFrame` | Sent to your `b2kFrameTarget` once per simulated frame (after bodies sync) — use it for motors, input, and custom drawing. |

**Polling contacts** — instead of (or alongside) the messages above, read this
frame's touch pairs directly, e.g. from `on b2kFrame`. Indices are 1-based; each
accessor returns a control (empty for a wall, the ground, or any untracked body).

| Handler | Returns |
|---------|---------|
| `b2kContactCount()` | How many pairs **began** touching this frame. |
| `b2kContactA(i)` / `b2kContactB(i)` | The two controls of the *i*-th begin-touch pair. |
| `b2kEndContactCount()` | How many pairs **stopped** touching this frame. |
| `b2kEndContactA(i)` / `b2kEndContactB(i)` | The two controls of the *i*-th end-touch pair. |

## Sensors (trigger zones)

Non-solid fixtures that report overlaps but never block. The Kit enables sensor
events on every body it creates, so sensors detect them automatically.

| Handler | Purpose |
|---------|---------|
| `b2kAddSensor ctrl [,shape]` → body | Attach a static sensor (`shape` = `box`/`ball`/`capsule`). |
| `b2kSetSensor ctrl, flag` | Flip an existing body between solid and sensor (rebuilds the shape, keeping the new sensor state). |
| `on b2kSensorEnter pSensorCtrl, pVisitorCtrl` | Sent to your `b2kContactTarget` when a body enters a sensor. |
| `on b2kSensorExit pSensorCtrl, pVisitorCtrl` | Sent when it leaves. |
| `b2kSensorCount()` / `b2kSensorEnterSensor(i)` / `b2kSensorEnterVisitor(i)` | Poll this frame's enters (1-based). |
| `b2kSensorExitCount()` / `b2kSensorExitSensor(i)` / `b2kSensorExitVisitor(i)` | Poll this frame's leaves (1-based). |

## Collision filtering (named layers)

Up to 32 layers. Two shapes collide only if **each** one's category is in the
other's mask (and no shared negative group forbids it).

| Handler | Purpose |
|---------|---------|
| `b2kDefineLayer name` → bit | Define/fetch a named layer. |
| `b2kSetCategory ctrl, layers` | Set which layer(s) a control *is* (comma/space list of names or numbers). |
| `b2kSetMask ctrl, layers` | Set which layer(s) it collides *with*. |
| `b2kSetCollisionGroup ctrl, n` | Negative = never collide with same group; positive = always. |
| `b2kNoCollide ctrlA, ctrlB` → joint | Stop just these two from colliding (a filter joint). |

## Chains & terrain

| Handler | Purpose |
|---------|---------|
| `b2kChain pointList [,loop]` → chain | Smooth static terrain from a list of `x,y` screen points (≥ 4). No inner corners for fast bodies to catch on. Invisible — draw a matching graphic. |
| `b2kSmoothGround pointList` → chain | An open chain (alias for `b2kChain …, false`). |
| `b2kAddChain ctrl, pointList [,loop]` | A smooth chain that **tracks a control** (move/draw the terrain as one graphic). Points are the control's own outline. |

> **Winding:** a chain's solid side is to the *right* of the point-travel
> direction. For ground you stand on, list the top surface **right-to-left** so
> the solid side faces up. (Bodies falling through? Reverse the point order.)

## Region & ray queries

| Handler | Returns |
|---------|---------|
| `b2kOverlap x1, y1, x2, y2` | Newline list of controls whose body overlaps a screen rect. |
| `b2kOverlapCircle x, y, r` | …overlapping a screen circle. |
| `b2kRayHitAll x1, y1, x2, y2` | Every control a ray crosses, nearest-first (vs `b2kRayHit`'s single closest). |

## Motors & tuning

| Handler | Purpose |
|---------|---------|
| `b2kMotorTo mover, ref, dxPx, dyPx, deg [,maxF, maxT]` → joint | Drive `mover` toward a pose offset from `ref` (a moving anchor; empty = world). |
| `b2kExplode x, y [,radius] [,power]` | Native radial blast (shape-aware, affects all dynamic bodies). `b2kExplodeLegacy` keeps the old velocity-based feel. |
| `b2kSetRestitutionThreshold px/s` · `b2kSetContactTuning hz, damp, pushPx` · `b2kSetJointTuning hz, damp` · `b2kSetMaxSpeed px/s` · `b2kEnableWarmStarting flag` | World solver tuning. |
| `b2kProfile()` | `"totalStep,collide,solve"` ms for the last step (a perf HUD). |
| `b2kAwakeBodyCount()` | Awake dynamic bodies (native count). |

## Tips

- Keep moving objects a sensible on-screen size (default scale 40 px/m, so
  roughly **4–400 px**).
- Graphic boxes/polygons and **dynamic images rotate** with their body (images
  via `the angle`). Buttons, fields, and other controls follow position only and
  have their rotation locked, so the simulation stays consistent with the
  upright render.
- The Kit render loop uses Box2D body-move events, so it only considers bodies
  that moved in the latest step, avoids per-body awake/position polling for
  sleeping objects, and skips redraws when the rounded screen pixel/angle did
  not change.
- When you need something the Kit doesn't expose, drop to the
  [core `b2…` API](api-reference.md): `b2kWorld()` returns the world and
  `b2kBodyOf(control)` the body, and `b2kToWorldX/Y(px)` / `b2kToScreenX/Y(m)`
  convert between screen pixels and Box2D metres — so you can mix both layers.
