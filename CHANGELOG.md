# Changelog

All notable changes to Box2Dxt are documented here. The format is based on
[Keep a Changelog](https://keepachangelog.com/en/1.1.0/), and this project
adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

The native shim's ABI is tracked separately by `b2Version()` (currently `3`).

## [Unreleased]

### Added

- **World feel presets (contraption builder).** A new BUILD OPTIONS cycle button
  beside Gravity tunes how the whole world responds — **Default**, **Bouncy**,
  **Floaty** (soft, speed-limited) and **Snappy** (stiff, responsive) — via the
  Kit's restitution-threshold, contact-tuning and max-speed setters. Re-applied
  each Run and saved/loaded with the layout.
- **Servo joint (contraption builder).** A new joint (the Kit's motor joint,
  `b2kMotorTo`) that drives part A to hold its position and angle relative to
  part B, yielding under load and springing back rather than locking rigidly like
  a weld — for self-righting parts, soft platforms and return-to-home arms. Saves
  and loads like any joint.
- **Sensor trigger zones (contraption builder).** A new SPECIAL part: a
  non-solid zone that parts pass straight through, but the instant a dynamic body
  *enters* it, it fires the same signal as a pressure plate — set off bombs and
  flip every motor. Perfect for tripwires and gates; it fires once per arrival
  (occupancy-tracked) so passing traffic doesn't machine-gun the motors. Built on
  the Kit's sensor events, and resizable — the Kit's `b2kReshape` now keeps a
  reshaped shape a sensor.
- **Collision layers (contraption builder).** Every solid part now has a
  *Collision layer* setting on its Physics tab: 0 hits everything (the default),
  while parts sharing a layer 1–8 pass through each other but still collide with
  the ground and parts on other layers — handy for overlapping mechanisms or
  letting a sub-assembly move without snagging on itself. Saves and loads with
  the part.
- **Smooth, rolling hills (contraption builder + Kit).** The Hill terrain tool now
  builds a smooth chain that follows its outline instead of a single convex
  polygon, so a fast ball or wheel rides over it without catching on seams — and
  the bump count scales with width (a narrow hill is a dome, a wide one rolls).
  Backed by a new Kit helper, **`b2kAddChain pControl, pPoints [, pLoop]`**, which
  attaches a *control-tracked* smooth chain — unlike the world-only `b2kChain` it
  selects, drags, resizes, deletes and saves like any static part.
- **Full Box2D v3.1.0 live-object API.** The binding now exposes essentially the
  whole engine surface a script needs — ~240 new shim functions, each with a
  `b2…` extension wrapper and, where it helps, a friendly `b2k…` Kit helper:
  - **Sensors.** Non-solid trigger zones via a new **shape-def builder**
    (`b2ShapeDefSensor`, `b2ShapeDefFilter`, `b2ShapeDefEnable*Events`,
    `b2ShapeDefMaterialId` — one-shot options applied to the next shape). Sensor
    overlaps arrive as `b2World_GetSensorEvents` (`b2SensorsUpdate` + accessors).
    The Kit adds `b2kAddSensor` and `on b2kSensorEnter` / `on b2kSensorExit`.
  - **Collision filtering.** `b2SetShapeFilter` + category/mask/group getters
    (32 layers). The Kit adds a named-layer registry: `b2kDefineLayer`,
    `b2kSetCategory`, `b2kSetMask`, `b2kSetCollisionGroup`, `b2kNoCollide`.
  - **Chains.** Smooth multi-segment terrain (`b2CreateChain` + builder,
    materials, segment enumeration; new chain handle table). Kit: `b2kChain`,
    `b2kSmoothGround`.
  - **More joints.** The **motor** joint (`b2MotorJoint`, drive a body to an
    offset pose) and the **filter** joint (`b2FilterJoint`, disable a single
    pair's collision), the generic joint surface (type, bodies, anchors,
    constraint force/torque, collide-connected, wake), and the **complete
    per-joint get/set** surface for all six joint types (springs, limits,
    motors, readouts). Kit: `b2kMotorTo`.
  - **World queries.** Overlap (AABB / point / circle / shape), ray-cast-**all**
    (sorted), and shape-cast, surfaced through one shared result buffer
    (`b2QueryCount`/`b2QueryBody`/…). Kit: `b2kOverlap`, `b2kOverlapCircle`,
    `b2kRayHitAll`.
  - **Events.** Contact **hit** events (impact point/normal/speed), **sensor**
    events, and bulk **body-move** events (`b2BodiesUpdate` — an efficient way to
    read every moved transform in one call).
  - **World tuning / info.** Restitution & hit-event thresholds, contact/joint
    tuning, max linear speed, warm-starting/speculative toggles, gravity getter,
    `b2WorldExplode` (native blast), and profile/counters. Kit passthroughs plus
    `b2kProfile`; `b2kExplode` is now native (old behaviour kept as
    `b2kExplodeLegacy`).
  - **Body extras.** World/local point & vector transforms, velocity-at-point,
    force/impulse **at a point**, full mass-data get/set + `ApplyMassFromShapes`,
    rotational inertia, local centre, kinematic target transform, sleep-enable,
    per-body event flags, AABB, and shape/joint enumeration.
  - **Shape extras.** Runtime geometry get/set for every shape type, material &
    event-flag get/set, per-shape ray cast, AABB, closest point, mass data, and
    sensor-overlap polling.
- **Kit completeness pass.** The Kit (`b2k…`) now covers the full core `b2…`
  surface — every capability the binding exposes has a friendly
  pixel/degree/screen-coordinate helper. New handlers:
  - **Read state:** `b2kPosition(ctrl)` (body centre as `x,y` screen pixels —
    the position partner of `b2kVelocity`), `b2kWorldCenter(ctrl)` (centre of
    mass), `b2kGravityScale(ctrl)` and `b2kDamping(ctrl)` (getters for the
    existing setters), and `b2kControlContains(ctrl, x, y)` (a rotation-aware
    point-in-shape test for a single control).
  - **Act:** `b2kAngularImpulse(ctrl, imp)` — a one-shot, mass-aware angular
    kick, the rotational partner of `b2kImpulse`.
  - **Contacts (polling):** `b2kContactCount()` / `b2kContactA(i)` /
    `b2kContactB(i)` and the `b2kEndContact…` equivalents, so a `b2kFrame`
    handler can read each frame's touch pairs without registering a contact
    target.
  - **Loader:** `b2kVersion()` returns the native ABI version for a Kit-only
    "extension loaded and in sync" check.
- **Multiply tool.** Alongside Duplicate, a new **Multiply** tool asks how many
  copies you want (1–50) and drops them in a tidy grid — each an independent
  copy of the part you clicked (same size, colour, material and settings). Great
  for crates, dominoes and brick walls.
- **Drop-in vehicles.** A new **VEHICLES** palette section adds a **Car** you
  place like any other object: a chassis on two sprung, motorised wheels that
  drives off when you press Run. Its three parts share a group tag, so dragging
  any one of them moves the whole car as a unit (and the grouping survives
  save/load/reset). The "Motor Cart" recipe now builds this same improved
  vehicle.
- **Scrolling tool palette.** The left palette is now a single vertically
  scrolling group, so the full tool list (SHAPES · TERRAIN · SPECIAL · VEHICLES
  · JOINTS) fits a normal-height window — the panel scrolls instead of the
  window growing. The stack is back to its original 760 px height.
- **Ramp facing.** Ramps now have a **Facing** setting (high on the left or
  right) so you can build slopes in both horizontal directions; it mirrors the
  outline and saves/loads with the piece.

- **Terrain objects in the Contraption Builder.** A new **TERRAIN** palette
  section adds three pieces of static scenery the dynamic parts rest on, roll
  down and bump into: **Platform** (a solid ledge), **Ramp** (a wedge for
  rolling and sliding) and **Hill** (a rounded mound). Each is a static polygon
  body, so it never falls and the Kit's sync skips it. They size, rotate (the
  angle is baked into the outline so a static body tilts without a redraw it
  never gets), recolour, take an adjustable grip (friction), drag, duplicate
  and save/load like any other part — and joints can pin to them, so you can
  hinge a part to a platform or hang a bridge from a ledge.
- **"Terrain Run" example recipe** — a ball rolls down a ramp, over a hill and
  onto a platform, showing the new pieces in one click.
- **Continuous integration** (`.github/workflows/build.yml`). Every push and
  pull request builds the native library and runs the C smoke test on Linux,
  macOS and Windows; publishing a GitHub Release (any tag name) additionally
  builds and attaches the per-OS binaries to it — the canonical artifacts
  `prebuilt/README.md` points to. A manual run (Actions ▸ build ▸ Run workflow)
  can attach binaries to an existing release after the fact.
- **Single-source Kit + drift check** (`tools/sync-embedded-kit.py`). The
  example stacks stay self-contained but now embed a *generated* copy of
  `src/box2dxt-kit.livecodescript` between sentinel comments, kept in sync by
  the tool. CI (`--check`) fails if a copy drifts, so the canonical Kit is the
  one place to edit.

### Changed

- **Sturdier bridges and more natural chains (contraption builder).** Bridge
  planks now hinge through a flex limit (a new internal `deckpin` joint) so a
  loaded deck sags under weight but can never fold back on itself, and chain
  spans use finer, lighter links for a smoother, more rope-like drape. Both still
  save, load and delete like any other span.
- **Examples now embed the current Kit.** The demo and contraption builder
  previously carried hand-copied, drifted snapshots of the Kit; they now embed
  the canonical `src/box2dxt-kit.livecodescript` verbatim (regenerated by
  `tools/sync-embedded-kit.py`). Their own GUI code is unchanged. One visible
  consequence: both pick up the native, shape-aware `b2kExplode` (the old
  velocity-based feel is still available as `b2kExplodeLegacy`).
- **ABI bumped 2 → 3** (`b2Version()` now returns `3`). The change is purely
  additive — every existing `b2…` handler keeps its signature — but the prebuilt
  libraries must be rebuilt (CI regenerates them on release). **Note:** collision
  filter category/mask bits are exposed as 32-bit (32 layers), not Box2D's full
  64-bit, because xTalk numbers carry 32 unsigned bits cleanly. Pre-solve / custom
  callbacks and Box2D's standalone math/geometry helpers remain intentionally
  unwrapped (no safe mid-step FFI callback into xTalk; the math operates on raw
  structs xTalk already handles).
- **Slicker tool palette.** Section headers are brighter and sit over a hairline
  rule; tool buttons are left-aligned, light up on hover, and keep their accent
  when selected — a more polished, professional left sidebar.
- **Contraption joints skip redrawing settled markers.** While running, the
  builder's per-frame `renderJoints` now skips any joint whose tracked bodies are
  all asleep — the Kit only repositions awake bodies, so an asleep joint's marker
  is already in place. Build-mode dragging still redraws every marker. The win
  grows with the joint count on a settled machine.
- **Less redundant work in hot paths.** The Kit's material setters
  (`b2kSetBounce` / `b2kSetFriction` / `b2kSetDensity`) now resolve the control's
  long id once instead of twice, matching the collision-filter setters; and the
  demo's lidar scene reads each ray-hit accessor once per ray rather than twice
  (48 rays a frame), trimming per-frame overhead with no behaviour change.

### Fixed

- **Kit collision-layer handlers no longer trip an OpenXTalk reserved word.**
  The `pLayers` parameter of `b2kLayerBits` / `b2kSetCategory` / `b2kSetMask` is
  (case-insensitively) the reserved word `players`, which stopped the script
  from compiling in OpenXTalk once the examples embedded the full Kit. Renamed to
  `pLayerList`; callers are unaffected (the parameter name is internal).
- **Contraption motors no longer stay dead after a pressure plate + rebuild.**
  Joints persist across Build↔Run, so a pressure plate that switched motors off
  during a run left them off when you returned to Build and pressed Run again
  (and the joint inspector could still read "Motor: on"). Entering Run now
  re-applies each joint's designed motor state from its marker, so a Run always
  starts from the layout you built.
- **`b2kReshape` no longer leaves a body shapeless — and keeps it sensor-aware.**
  Reshaping destroyed the old collision shape *before* building the new one, so a
  graphic whose outline collapsed to fewer than three points (a degenerate
  polygon) lost its shape entirely, leaving a body with nothing to collide with.
  The swap is now atomic: the new shape is built first and the original is kept
  untouched if the new one is rejected. Like the attach helpers, reshaping also
  re-enables sensor events, so a reshaped body stays detectable by sensors.
- **Demo's first FPS reading is no longer bogus.** `clearState` now seeds the
  frame counter and timestamp, so the HUD's opening frames-per-second value is
  meaningful instead of a one-off near-zero spike right after a (re)compile.
- **Bridge & Chain spans ignore Bouncy mode.** Building a span while the
  **Bouncy** build option was on made every plank/link springy, so bridges and
  chains jittered and never settled. Span segments are now always built
  non-bouncy, regardless of the toggle, so they hang and sag predictably.
- **Duplicating a rotated part keeps its size.** Duplicate copied the graphic's
  *bounding box* (which inflates as a part rotates) as the new part's size, so a
  rotated box, polygon, plank or terrain piece grew each time it was copied. It
  now copies the stored design size instead.
- **Kit no longer leaks image-angle cache entries across teardowns.**
  `b2kResetTables` now also clears the `sImgAngle` table, so repeatedly tearing
  a world down and rebuilding it (e.g. switching demo scene tabs) stops
  accumulating dead per-control entries.
- **No more divide-by-zero after editing the demo script.** Recompiling a stack
  script wipes its script-locals, so `sScale` was empty until `startBox2DDemo`
  ran — a click could hit `b2kToWorldX` first. The Kit's world↔screen helpers
  now return safely before setup, and the demo starts itself on the first click.
- **Playground see-saw now tilts.** Its fulcrum was a *static body* that the
  plank jammed against; it's now a decorative graphic, so the centre-hinged
  plank pivots freely.
- **`b2kRemove` now deletes kit-spawned controls**, so removing a body never
  leaves a dead graphic behind (the demo's bombs now vanish when they explode,
  and dropped shapes are cleaned up at the cap).
- **Newton's cradle no longer explodes on launch.** The demo created each ball,
  hinged it, then teleported the end ball — which violated the fresh joint. It
  now spawns the end ball already lifted, with a tiny gap and moderate
  restitution.

### Changed

- **Vehicle is now a coin-run.** Rolling segment terrain with a matching filled
  silhouette, gold coins to grab as you drive, spinning wheel spokes, a stronger
  motor, and a live "Coins N / total · Distance m" readout.
- **Light gamification.** The HUD shows a per-scene objective; the Pyramid tracks
  a live "Scattered N / total" demolition count. The pyramid is a bit smaller
  (7 rows) for a faster load.
- **Smoother rendering.** The Kit's loop now does the whole frame (body sync +
  contact/frame events + app drawing) inside a single `lock screen`, and
  `b2kSync` skips bodies that are asleep — so busy scenes stay smooth and settled
  scenes cost almost nothing. The demo opens as a proper, centred, non-resizable
  titled window. New `b2kAwakeCount()` getter.
- **Demo polish & Lidar fix.** The Lidar only scans while the cursor is inside
  the play-field (rays no longer spill over — and through — the toolbar), with a
  glowing emitter; the demo keeps its chrome layered above every scene control so
  the UI is always clickable, adds a framed play-field panel, and shows live
  body/awake counts in the HUD.
- **Rebranded from LiveCode to OpenXTalk (OXT) / xTalk.** The project is now
  *Box2Dxt*, designed in and for OpenXTalk while remaining compatible with
  LiveCode 9.6.3+.
  - The loadable library and extension are renamed `box2dlc` → **`box2dxt`**
    (`libbox2dxt.so` / `libbox2dxt.dylib` / `box2dxt.dll`); foreign-binding
    strings are now `c:box2dxt>…`.
  - The exported C ABI symbols keep the historical `b2lc_` prefix, so existing
    compiled binaries remain binding-compatible (no ABI change; `b2Version()`
    stays `2`).
- **Reorganized the repository** for a public release: source in `src/`, the
  demo in `examples/`, guides in `docs/`, tests in `tests/`, binaries in
  `prebuilt/`.
- Renamed `box2d-helper.livecodescript` → `src/box2dxt-kit.livecodescript` and
  `box2d-demo.livecodescript` → `examples/box2dxt-demo.livecodescript`.
- Renamed the test build option `BOX2DLC_BUILD_TESTS` → `BOX2DXT_BUILD_TESTS`.

### Added

- **Contraption Builder overhaul — a polished, beginner-friendly sandbox.**
  `examples/box2dxt-contraption-builder.livecodescript` was redesigned for people
  who know nothing about 2D physics:
  - **New five-region layout** (dark theme): a top action bar, a grouped left tool
    palette (SHAPES · SPECIAL · JOINTS with section headers and glyphs), the play
    stage in the centre, a right **inspector** panel, and a bottom status bar. The
    physics arena and its walls are inset to the centre stage.
  - **Plain-language guidance everywhere:** a tooltip on every control, an
    inspector that explains the hovered/selected tool in everyday words, a
    dismissible first-run onboarding overlay, and a Recipes menu of ready-made
    examples.
  - **Deeply customizable parts.** A prominent "PART SETTINGS" panel lets you tune
    a selected part live with +/− controls: **size** (re-fits the collision shape
    in place), **colour**, bounciness, weight, **grip (friction)**, **gravity /
    float**, **spin-lock**, **fixed ↔ free movement**, plus per-object specials
    (fan direction/strength/zone size, magnet pull/push/strength/reach, bomb blast
    radius/power and fuse). Everything round-trips through the save file.
  - **Duplicate tool.** Click any part to drop an identical copy — same size,
    colour, material and special settings — then drag it into place (it auto-selects
    and switches to the Drag tool).
  - **Reset.** A one-click "Reset" returns every part to exactly where it was the
    moment you last pressed Run, so you can replay a contraption again and again.
  - **Clearer Build vs Run.** The top accent turns amber and the subtitle reads
    "RUNNING" while the simulation is live (green/neutral while building), and
    picking any build tool while running drops you straight back into Build mode.
  - **New objects, all built from existing Kit primitives:** **helium balloons**
    (rise via negative gravity scale; lift parts by a rope; pop in a blast),
    **bombs** (detonate on a hard hit, a pressure-plate signal, or an optional
    Run-fuse — using `b2kExplode` + a shock ring), **pressure plates** (sense
    resting weight via contact events and fire a signal that detonates bombs and
    toggles all motors), and bonus **fan/wind zones** and **magnets** (per-frame
    `b2kForce` fields).
  - **Recipes & stress test:** Balloon Lift, Plate → Bomb Chain, Fan Tower, Magnet
    Catch, the motor cart and pendulum samples, plus a Stress Test that spawns
    batches of bodies to probe the frame-rate limit (live fps/body-count HUD).
  - **Save format `CB2`** round-trips the new objects and their properties, and
    still loads old `CB1` files. Plus internal clean-ups (table-driven button
    highlighting, named constants in place of magic numbers, and hardened
    image-import / load error handling).
- **Rebuilt the demo on top of the Kit.** `examples/box2dxt-demo.livecodescript`
  is now a polished, self-building showcase written entirely with `b2k…` calls —
  a professional header, scene tabs, a shape palette, a status HUD, and six
  scenes (Playground, Pyramid, Cradle, Bridge, Vehicle, Lidar). It is
  **self-contained** (bundles a copy of the Kit) so it runs from a single paste
  into a stack script, and doubles as a worked example of the Kit.
- **Kit per-frame hook:** `b2kFrameTarget obj` delivers an `on b2kFrame` message
  once per simulated frame, for app logic, motors, input, and custom drawing.
- **Kit getter:** `b2kBodyCount()` returns how many bodies the Kit is tracking.
- **Kit additions:** `b2kWall x1, y1, x2, y2` builds a static collision segment
  between two screen points (custom walls, ramps, ledges, floors), so static
  geometry no longer has to drop to the world-space `b2…` API; `b2kBodyType(ctrl)`
  reads a body's type back as a word (`static` / `kinematic` / `dynamic`),
  mirroring `b2kSetType`. Both are documented in the cheat sheet and Kit reference.
- **Kit shape resizing:** `b2kReshape ctrl, "box"|"ball"|"capsule"|"poly"`
  re-fits a body's collision shape to the control's current size *in place on the
  same body*, so attached joints survive and the body's mass is recomputed. Powers
  the Contraption Builder's live Size control.
- **Much broader Kit coverage of the engine.** New `b2k…` helpers wrap nearly
  all of the remaining low-level `b2…` API, in pixels/degrees:
  - **Shapes:** `b2kAddCapsule` / `b2kSpawnCapsule` (pill shape; graphics render
    as a rounded outline and rotate, images rotate via `the angle`).
  - **Joints:** `b2kSlider` (prismatic) with `b2kSliderMotor` / `b2kSliderLimit`
    / `b2kSliderPos`; `b2kWheel` with `b2kWheelMotor` / `b2kWheelSpring`;
    `b2kHingeLimit` / `b2kHingeAngle`; `b2kRopeRange` / `b2kRopeLength` /
    `b2kSpring`; `b2kWeldSpring`.
  - **Forces & body control:** `b2kForce` (continuous force), `b2kSpinBy` (add to
    spin), `b2kSetType` / `b2kSetStatic` / `b2kSetDynamic` / `b2kSetKinematic`
    (runtime body type), `b2kEnable` / `b2kDisable`.
  - **Sensing:** `on b2kEndContact` message (collisions ending); ray-hit details
    `b2kRayHitNormalX/Y` and `b2kRayDist`; `b2kMass`.
  - **World:** `b2kEnableSleeping` / `b2kEnableContinuous`.
- **Rotating image support in the Kit.** Dynamic **image** controls attached
  with `b2kAddBox`/`b2kAddBall` now follow both the body's position *and* its
  rotation (via `the angle`); previously only graphics rotated. Buttons, fields,
  and other non-rotatable controls keep their rotation locked so the simulation
  stays consistent with the upright render.
- `LICENSE` (MIT, with the bundled Box2D MIT notice).
- `CONTRIBUTING.md` and `CODE_OF_CONDUCT.md`.
- New documentation set under `docs/`: getting-started, building, api-reference,
  kit-reference, and architecture.
- This changelog.

## [0.2.0]

- Box2D Kit (`b2k…`): a batteries-included pure-script helper toolkit.
- Demo rebuilt as a self-building, multi-scene interactive testbed (Playground,
  Pyramid, Newton, Bridge, Vehicle, Lidar) with major rendering optimizations.
- Full low-level `b2…` binding over Box2D v3.1.0: world, bodies, shapes, joints
  (revolute, distance, weld, prismatic, wheel, mouse), ray casts, point picks,
  and contact events.
- Cross-platform CMake build (fetches and pins Box2D v3.1.0), runtime smoke test,
  and CI that builds and releases native libraries for Linux, macOS, and Windows.

[Unreleased]: https://github.com/SethMorrowSoftware/Box2Dxt/compare/v0.2.0...HEAD
[0.2.0]: https://github.com/SethMorrowSoftware/Box2Dxt/releases/tag/v0.2.0
