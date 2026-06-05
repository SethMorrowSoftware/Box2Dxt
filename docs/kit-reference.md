# Box2Dxt Kit Reference (`b2k…`)

The **Kit** (`src/box2dxt-kit.livecodescript`) is a batteries-included,
pure-xTalk toolkit over the `box2dxt` extension. You work in **pixels, screen
coordinates and degrees**; the Kit hides the world, the fixed-timestep loop,
coordinate conversion, and the per-frame control updates — and it runs with the
demo's performance practices built in.

**Setup:** paste the Kit into your card/stack script (or save it as a library
stack and `start using` it). It requires the `box2dxt` extension loaded
(`put b2Version()` should return `3`).

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
   get b2kSpawnBall(200, 80, 50)       -- create & drop a 50px ball
   get b2kSpawnBox(260, 80, 60, 40, "orange")
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
| `b2kWall x1, y1, x2, y2` | A static collision segment between two screen points (custom walls, ramps, ledges). Invisible — draw your own graphic to match. |
| `b2kClear` | Remove all bodies/controls the Kit created, keep the world. |
| `b2kTeardown` | Stop and destroy the world and all Kit state. |
| `b2kVersion()` | Native shim ABI version (`3`) — a load / in-sync check from Kit-only code. |

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
| `on b2kSensorEnter pSensorCtrl, pVisitorCtrl` | Sent to your `b2kContactTarget` when a body enters a sensor. |
| `on b2kSensorExit pSensorCtrl, pVisitorCtrl` | Sent when it leaves. |
| `b2kSensorCount()` / `b2kSensorEnterSensor(i)` / `b2kSensorEnterVisitor(i)` | Poll this frame's enters (1-based); `…Exit…` for leaves. |

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
- When you need something the Kit doesn't expose, drop to the
  [core `b2…` API](api-reference.md): `b2kWorld()` returns the world and
  `b2kBodyOf(control)` the body, and `b2kToWorldX/Y(px)` / `b2kToScreenX/Y(m)`
  convert between screen pixels and Box2D metres — so you can mix both layers.
