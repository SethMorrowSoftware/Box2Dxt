# Changelog

All notable changes to Box2Dxt are documented here. The format is based on
[Keep a Changelog](https://keepachangelog.com/en/1.1.0/), and this project
adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

The native shim's ABI is tracked separately by `b2Version()` (currently `4`).

## [Unreleased]

### Fixed

- **Kit: commands called with function syntax never worked in OXT.** OXT
  cannot invoke a *command* handler with function syntax (`get b2kChain(...)`
  throws "can't find function"), which the Game Kit Phase 0 spike caught on
  real hardware. Repaired everywhere:
  - `b2kSmoothGround` (returned `b2kChain(...)`) — the alias **always threw**;
    it now calls `b2kChain` as a statement and returns `the result`.
  - `b2kLayerBits` (used `b2kDefineLayer(...)`) — **named** collision layers
    via `b2kSetCategory`/`b2kSetMask` always threw; numeric layer lists were
    unaffected.
  - Contraption builder: the **servo** joint (`put b2kMotorTo(...) into tJ`)
    never created its motor joint; it now uses statement + `the result` like
    the neighbouring joint cases.
  - Docs taught the broken pattern: the 60-second starts (README,
    kit-reference, getting-started, Kit header comment) and ~25 snippets in
    the kit guide now use `b2kSpawnBox ...` / `put the result into tRef`.
- **Kit: an invalid colour name no longer aborts a spawn.** `b2kSpawnBox` /
  `b2kSpawnBall` / `b2kSpawnCapsule` ignored-or-threw inconsistently on bad
  colours (CSS-only names like `teal` are not LC/X11 colour names and threw
  mid-spawn, leaving an orphaned control with no body). The colour set is now
  tolerated like every other bad input: the spawn proceeds with the default
  colour.
- **Docs: `b2AddSegment` / `b2kWall` segments are two-sided.** The references
  claimed segments were one-sided; the Phase 0 spike disproved it (a body is
  blocked from below on either winding). Both docs now say so and point
  one-way platform builders at chains (chain segments are the one-sided
  primitive).

### Added

- **The micro-game (Game Kit Phase 5 exit artifact):**
  `examples/box2dxt-microgame.livecodescript` — a COMPLETE game in one
  pasteable file: start screen → two levels → win screen, with nothing
  to install beyond the extension (the hero sheet is embedded base64,
  every sound is `b2kToneMake`d). It is the "copy this to start your own
  game" example and the companion to the kit guide's new **"Building a
  whole game"** chapter (§20). What it adds over the platformer
  showcase: the **one-call player** (`b2kPlayerMake` — the green-field
  path the platformer's adopt-flow doesn't exercise), **levels as
  data** (each level is a dozen lines of `verb args` text — `slab`,
  `ledge`, `coin`, `spike`, `sweep`, `door`… — interpreted by a ~100
  line `mgBuild`; the `ledge` verb ghost-pads its chain automatically),
  and a **game-state machine** (menu/play/won) gated by
  `b2kPlayerControl`, so the world runs live behind the menus. The
  coins-unlock-the-door rule, sweeper hazards, kill-plane respawns and
  the win screen's time/falls stats are all sensor + frame-hook
  patterns, no new Kit surface. This is also the plan's scenes/levels
  design probe: the level format lives at example level first;
  promotion to `b2kScene*` API gets decided from how it holds up.
- **Kit Sound module (Game Kit Phase 5 begins).** Named sounds over
  **audioClips** — the one LC sound path with no external media-layer
  dependency — with `b2kSoundLoad` (import a WAV/AIFF/AU file) and
  **`b2kToneMake`**, a pure-script synthesizer (8-bit mono WAV at
  22050 Hz, square or sine, a comma list of note frequencies with a
  per-note decay) so self-contained examples ship SFX with **zero asset
  files**. `b2kSound`/`b2kSoundLoop`/`b2kSoundStop` play (one clip at a
  time — the classic LC model, documented not fought), `b2kSoundMute` is
  a preference that survives teardown, `b2kSoundVolume` wraps the
  engine-global `playLoudness`, and failures degrade to silence, never
  errors (first failing play trips a dead-flag; `b2kSoundStatus()` says
  why). Sounds **survive `b2kTeardown`** — clips are tiny and
  deterministic, and resets must stay snappy; `b2kSoundsWipe` purges
  them (it also sweeps `b2ksnd_` clips a dead session left behind, and
  stable names mean re-making replaces rather than accumulates). The
  platformer gains eight synthesized cues — jump, land (off the player's
  one-tick land state), coin, stomp, hurt, checkpoint, gate, win — plus
  an M-key mute and HUD audio diagnostics.
- **Sheets beyond the Kenney format: custom grids and hand-named
  regions.** `b2kSheetLoad`/`b2kSheetFromImage` take optional `margin`
  (outer border px) and `spacing` (gutter between cells px) for grid
  sheets that aren't edge-to-edge, and a frame size of **0 registers the
  source with no grid at all** — then **`b2kSheetAddFrame sheet, frame,
  x, y, w, h`** names each region yourself: the no-XML path for packed
  sheets in any layout (any sizes/positions; redefining a name re-bakes
  its slice; works on top of grids and atlases too).
  **`b2kSheetFrameNames(sheet)`** lists every frame key of a loaded
  sheet — introspect an atlas you didn't make.
- **The platformer is now a collect-them-ALL puzzle platformer** on a
  rebuilt, half-again-longer level (3072 → 4608 px) with a traditional
  left-to-right arc: meadow → one-way bridge over a **spike slime** (the
  unstompable kind — hurts from every side) → the slope mound → two
  cloud steps guarded by the fly → spike pit with a mid-air coin → the
  crate/plate/gate puzzle (a coin locked **inside the gateway**) →
  checkpoint → a saw plus a **sweeping saw** (a bodiless sine-path mover,
  like the fly) → **thwomp alley** — dodge the first, ride the second
  one's head to a sky coin, and **mouse-DRAG a resting thwomp** under
  the lone high coin to ride up from there (rest extended to 2.6 s so
  dragging is feasible; it rises from wherever you park it, then snaps
  home) → slime fields → step platforms → flag. **Twelve coins, every
  one verified reachable** (jump arc ≈ 154 px apex at the demo tuning),
  most of them a small puzzle; all 12 + flag wins. Enemies/traps/movers
  are now indexed tables (`pfMakeSlime`/`pfMakeThwomp`/`pfAddMover`), so
  the level adds foes in one line each. The **mound's ramp art is fixed**
  by measuring the actual Kenney tiles (the short ramps are a 45° pair,
  drawn descending left-to-right; the long ramps are the 26.6° pair that
  matches the chain) — ascent shows them mirrored, and the ground row
  beneath the mound switches to dirt-centre tiles so the hill reads as
  one mass. The first OXT runs then surfaced **the chain ghost rule**:
  Box2D collides an open chain's N points as only **N−3 segments** (the
  first and last are ghost anchors), which the original level had
  silently respected by always running chains one tile past the art —
  the rebuild didn't, so the bridge's outer planks, both cloud edges and
  *both mound ramps* were intangible. All four chains are now
  ghost-padded (the mound grew to six points so its ramps, the actual
  slope test, really collide), and the rule is documented in `b2kChain`,
  the kit reference and the guide. Two more OXT findings fixed: **slime
  stomps are judged by the player controller's land/fall state**, not by
  post-impact velocity (contacts dispatch after the solver has already
  absorbed the impact, so a clean stomp read as ~0 velocity and hurt the
  hero), and **thwomps re-arm wherever they rose** instead of
  teleporting back to their perch (the snap-home read as
  vanish-and-reappear, and it undid the drag-to-reposition puzzle).
  Optimization pass: the sprite tick now skips inert sprites (no bind,
  no animation — about a hundred static tiles) before doing any work,
  sounds persisting across teardown removes the ~quarter-second tone
  re-synthesis from every reset, and the mover tick reads the clock
  once per pass.
- **Kit Player module (Game Kit Phase 3 — the headline feature).** A
  complete platformer character controller for one keyboard player:
  `b2kPlayerMake` (capsule body host + bound sprite + controller + input
  in one call) or `b2kPlayerAttach` (adopt an existing control/sprite —
  a capsule body is added if missing, with fixed rotation, sleep
  disabled and low friction). The per-frame `b2kPlayerTick` (loop order:
  input → player → sprites → camera) reads axis `moveX` / action `jump`,
  accelerates vx toward `axis × moveSpeed` (`accel`/`airAccel`), probes
  the ground with three short downward rays gated by a surface-normal
  slope test (`maxSlopeDeg` — walkable slope vs wall is one cosine
  compare; the probe is suppressed while the controller's own jump is
  still rising, so one-way chains can't phantom-ground a jump-through),
  and runs the state machine (`idle`/`run`/`jump`/`fall` + a one-tick
  `land` for dust/sound hooks). Genre-standard jump feel is built in:
  **coyote time** (`coyoteMs`), **jump buffering** (`bufferMs`),
  **release jump-cut** (`jumpCut` — tap = hop, hold = full) and a
  terminal fall speed (`maxFall`). `b2kPlayerAnims` maps states to sheet
  animations (optional held land flourish; facing auto-flips);
  `b2kPlayerSet/Get` expose the nine tuning knobs (kept across
  `b2kClear` like input bindings, wiped by `b2kTeardown`);
  `b2kPlayerJump` gives springs/powerups the same launch without the
  grounded gate; `b2kPlayerControl false` turns the controller
  observe-only for cutscenes/hit-poses/knockback; plus
  `b2kPlayerOnGround/State/Facing`, `b2kPlayer`, `b2kPlayerSprite`,
  `b2kPlayerRemove`. New general body setting: **`b2kSetSleepEnabled`**
  (per-body sleep permission over raw `b2EnableSleep`; the controller
  forbids sleep on its body). The platformer example's entire hand-rolled
  movement layer — axis-to-velocity tick, jump-press/release handling and
  the two-ray ground probe (~53 lines) — is replaced by four declarative
  calls (`b2kPlayerAttach` + `b2kPlayerAnims` + two `b2kPlayerSet`s),
  and the level gains a **walkable slope mound** (26.6° Kenney ramp
  tiles over a one-sided chain, with a plain-polygon fallback), a 7th
  coin on its plateau, and a HUD readout of the controller state, land
  count and sleep anomaly for the OXT feel checklist.
- **Kit Camera module (Game Kit Phase 4, pulled forward).** Scrolling
  levels on the viewport-group mechanism the Phase 0 spike benchmarked:
  `b2kCamOn/Off`, follow with lerp + deadzone (`b2kCamFollow`,
  `b2kCamDeadzone`), level bounds, `b2kCamGoto`/`b2kCamPos`,
  `b2kCamShake`, and camera-aware mouse mapping (`b2kCamMouseX/Y` — the
  Kit's own grab-drag target now routes through it). While the camera is
  on, spawned bodies and sprites are created inside the viewport
  automatically and keep world-pixel locs, so physics math is untouched;
  `b2kCamAdopt` moves hand-made controls in; `b2kTeardown` dissolves the
  viewport and the orphan sweep ungroups (never deletes) a dead
  session's viewport so adopted controls survive. The platformer example
  is now a complete 3072px scrolling level: far-parallax backdrop,
  spike pit, a pressure-plate + crate puzzle driving a kinematic gate
  (sensor enter/exit counting), a patrolling stompable slime
  (contact-event stomp vs hurt), camera shake on every hit, and the
  goal flag — with plain-graphic fallbacks for every piece of art.
- **The platformer demo (release candidate).** The example grew into a
  complete showcase: intro splash, centre-locked scrolling camera, a
  two-cloud one-way route guarding a bonus coin, hazard fly, spike pit,
  crate-on-pressure-plate gate puzzle, mid-level checkpoint flag, saw, a
  riding Thwomp (underside kills, head is a platform, slow kinematic
  rise), two stompable patrol slimes, six coins with pickup pops, and an
  all-coins-plus-flag win dialogue with run time, fall count and a
  physics-confetti burst. R restarts and ESC pauses (raw key events, so
  they work while paused); every art piece has a plain-graphic fallback.
- **Camera hardening (from the demo's OXT runs).** `b2kCamOn` self-tests
  that the scroll property pans the group and probes the engine's
  grouped-loc coordinate model (`b2kCamStatus`, `b2kCamLocSemantics`);
  scroll-adjusted ("visual") engines get every in-viewport write
  compensated automatically (`b2kCamShiftX/Y`, `b2kSpriteMoveTo`). The
  follow carries a mathematical never-offscreen guarantee plus a
  real-scroll failsafe; the bounds stretch the viewport's invisible
  anchor so the engine can never clamp the scroll short; teardown wipes
  sprites BEFORE dissolving the viewport (their stored ids embed the
  group path), and sprite removal survives stale references.
- **Kit Sprite module (Game Kit Phase 2).** Spritesheet animation on the
  icon-button backend the Phase 0 benchmarks selected: sheets register
  frame regions of one hidden source image — a uniform grid
  (`b2kSheetLoad`), an existing stack image (`b2kSheetFromImage`), or a
  packed **TextureAtlas XML** with named regions (`b2kSheetLoadAtlas`,
  the Kenney format shipped in `Spritesheets/`). Regions are sliced into
  shared per-frame images lazily; a sprite is a transparent button whose
  icon is the current frame. Named animations (`b2kAnimDef` with ranges
  or frame names), `b2kSpritePlay/Stop/SetFrame/FPS`, lazy mirrored
  facing (`b2kSpriteFlipH`), end-of-animation messages
  (`b2kSpriteOnFinish`), body-following sprites (`b2kSpriteBind` — give
  an invisible control the body, bind the art to it), an animated-GIF
  backend (`b2kSpriteFromGIF`), and lifecycle integration (`b2kClear`
  removes sprites, `b2kTeardown` also frees sheets). The platformer
  example now plays an atlas-driven animated hero with spinning coin
  pickups, a patrolling bee, and a saw hazard that chains
  hit-pose-then-respawn through `b2kSpriteOnFinish`. **Per-sheet display
  scaling** (`b2kSheetScale` — engine-resampled at slice time, any frame
  size at any sprite size; `b2kSheetFrameSize` for layout math), and an
  **orphan sweep** on every teardown (script state resets when a stack
  reopens but controls persist — previously a ghost sprite could linger
  frozen on its last frame). The platformer example is now a polished
  scene: hills backdrop panels (256px art engine-scaled to 640), grass
  tile terrain over invisible physics slabs, bridge-plank one-way ledge,
  a 0.75-scaled hero, and a waving goal flag with a LEVEL COMPLETE
  state.
- **Kit Input module (Game Kit Phase 1).** Poll-based keyboard input for
  games: `b2kInputOn` arms a once-per-frame `keysDown` sample (taken inside
  the loop's screen lock, so `on b2kFrame` always sees the current frame's
  state), diffed against the previous frame for exact pressed/released
  edges with zero auto-repeat or focus-path artifacts. Friendly key names
  (letters match both shifted/unshifted keysyms), named **actions**
  (`b2kBindAction "jump", "space,up,w"` + `b2kActionIsDown/Pressed/
  Released`), **axes** (`b2kAxis("moveX")` → -1/0/+1, both directions held
  = 0), `b2kKeyIsDown/Pressed/Released`, `b2kKeysHeld()`, and
  `b2kFrameMS()` (the frame's real elapsed ms, for animation timing).
- **Paced simulation loop.** `b2kStep` now schedules the next tick
  `in max(1, 16 − elapsed)` ms instead of a flat 16 ms after the frame's
  work — the flat delay made the real rate "timer cadence plus frame
  cost" (~50 fps under load in the Phase 0 spike measurements).
- **`examples/box2dxt-platformer.livecodescript`** — Game Kit Phase 1's
  playable example: a fixed-rotation capsule driven by the Input module
  (axis run, edge-triggered jump with release-cut variable height, ray
  grounded-check) on flat ground, steps, and a jump-through one-way chain
  ledge. Registered in `tools/sync-embedded-kit.py`.
- **Keyboard support in the contraption builder.** **Delete**/**Backspace**
  removes the selected part or joint (Build mode, with full joint/wire
  cleanup); **Escape** walks outward — closes an open overlay, then cancels a
  half-made joint or wire, then clears the selection; **arrow keys** nudge the
  selected part 1 px (Shift: 10 px) with the same group-follow, arena clamping
  and body re-seat as a mouse drag.
- **Generation-tagged handles (C shim).** Every handle now packs an 11-bit
  generation above its 20-bit table slot, bumped each time the slot is freed.
  A stale handle therefore stays a harmless no-op even after its slot is
  recycled by a new object — previously a stale handle could silently alias
  whatever was created next in that slot. First-generation handle values are
  unchanged (1, 2, 3, …) and the ABI signatures are untouched; treat handles
  as opaque positive ints. The smoke test now proves a recycled slot rejects
  its old handle.
- **ABI fail-fast in the LCB binding.** `b2NewWorld` / `b2NewThreadedWorld`
  check `b2lc_abi_version()` and throw a clear, catchable error when the
  loaded native library doesn't match the binding (ABI `4`), instead of
  crashing on whichever later call hit the skew first.
- **A root `README.md`** — project overview, quick start, doc map, and build
  instructions on the repository landing page.

- **Showcase pass — every Kit capability is now reachable from the builder.**
  Several engine features the demo never surfaced are now exposed (raising the
  count of directly-used `b2k…` handlers from 79 to 98; the rest are alternate
  spellings of features already shown, e.g. `b2kSpawnBall` vs `b2kAddBall`):
  - **Laser (SPECIAL).** A body-less emitter that casts a ray each frame and
    draws its beam to the first thing it strikes — walls count — via `b2kRayHit`
    / `b2kRayHitX/Y` / `b2kRayDist`. The beam is live in Build and Run, follows
    its emitter when dragged, and its angle cycles in 45° steps; select it during
    Run to read the live hit distance.
  - **Thruster (SPECIAL).** A self-propelled rocket: an ignition pop (`b2kPush`)
    on Run, then steady force along its own facing (`b2kForce`) with optional
    spin (`b2kTorque`). Lock its rotation for a straight climb or let it tumble.
  - **Shift-click to kick.** Shift-clicking a body during Run gives it a sharp,
    mass-aware impulse and a tumble (`b2kImpulse` / `b2kAngularImpulse`).
  - **Live telemetry.** While running, the status bar shows solver step time and
    awake-body count (`b2kProfile`, `b2kAwakeBodyCount`) plus a live readout of
    the selected part (speed/mass/angle) or joint (`b2kHingeAngle` /
    `b2kRopeLength` / `b2kSliderPos`).
  - **Bomb blast preview.** Selecting a bomb reports how many parts sit inside
    its radius right now (`b2kOverlapCircle`), and a bomb can switch between the
    shape-aware native blast and the old velocity-based feel (`b2kExplodeLegacy`).
  - **World · Advanced panel.** Solver toggles the Feel presets don't cover —
    continuous collision (`b2kEnableContinuous`), sleeping (`b2kEnableSleeping`),
    warm-starting (`b2kEnableWarmStarting`) and a sub-step quality cycle
    (`b2kSetSubsteps`) — applied on Run and saved with the layout.

- **Per-part collision filter (contraption builder).** Beyond the quick
  *Collision layer*, every solid part now has a **Collision filter** that opens a
  popup of eight channels in two rows — which channels the part *is on*
  (category) and which it *collides with* (mask). Two parts touch only when each
  is on a channel the other collides with, so you can make whole sets of parts
  ignore each other while still landing on the ground. Built on the Kit's
  `b2kSetCategory` / `b2kSetMask`, re-applied after any reshape, and saved/loaded.
- **Per-part sensor toggle (contraption builder).** Any solid part (box, image,
  ball, capsule, polygon) can be flipped into a **trigger zone** from its Collide
  tab — it turns translucent, stops blocking, and fires the same enter/exit
  signal as the dedicated Sensor. The Kit gained `b2kSetSensor` so the flag can
  be toggled on an existing part (the shape is rebuilt, keeping the sensor state).
  Saved and loaded.
- **Categorised Examples gallery.** The Examples menu is now a tidy two-column
  gallery grouped into **Launchers / Machines / Chain Reactions / Toys & Tests**
  with section headers, instead of one long scrolling list — room to keep adding
  machines and far easier to scan. (UI version bumped so it rebuilds.)
- **Enable/disable parts.** Every dynamic part has an **In simulation: yes/no**
  toggle (Collide tab) that pulls it out of / back into the live world
  (`b2kDisable` / `b2kEnable`); saved and loaded.
- **Comprehensive part inspector.** More of box2dxt is now editable per object:
  a body can be **kinematic** (a moving platform — set a launch velocity and it
  drifts, unaffected by gravity or collisions) as well as static or dynamic;
  every dynamic part exposes a **sleep threshold**; **imported images** can pick
  their collision shape (box / ball / capsule, which survives resize and
  save/load); and previously bare inspectors gained options — *Draw* ground gets
  a colour and *Anchors* get bounce and grip.
- **Three more example machines (contraption builder).** **Trebuchet** (a
  counterweight arm that whips round and flings a ball), **Crane** (a motorised
  jib with a load hung on a rope) and **Wrecking Ball** (a roped weight shoved
  into a brick wall) — each one click from the Examples menu, showcasing the
  hinge-motor, weld and rope joints.
- **Cannon example recipe (contraption builder).** A new one-click machine in the
  Examples menu: a static carriage + barrel and a heavy ball that fires across the
  field on Run (via the launch system) into a crate stack. It doubles as a demo
  of **collision layers** — the ball and barrel share a layer so the ball slips
  clear of the barrel as it launches.
- **Draw-your-own terrain (contraption builder).** A new TERRAIN tool (**Draw**,
  the ✎ glyph): press and drag across the play field to sketch a ground contour —
  bumps, valleys, ramps, anything — and on release it becomes a smooth one-sided
  chain (`b2kAddChain`, open) that parts roll along without catching on seams. It
  saves and loads as its own point list and can be dragged to reposition.
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
  *Collision layer* setting on its Collide tab: 0 hits everything (the default),
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

### Changed

- **Input validation across the whole shim surface.** Joint creation and every
  double-taking joint/world/body setter now rejects non-finite values (and
  mirrors Box2D's own ordering/sign/range requirements: revolute limits clamp
  to ±0.95π, limit pairs must be ordered, hertz/damping/max-force non-negative,
  prismatic/wheel axes non-zero, capsules need distinct centers, distance-joint
  length clamps to Box2D's linear slop). NaN/Inf from script can no longer
  poison the solver in Release builds.
- **Collision filter bits widened and made safe.** Category/mask values are
  range-checked before conversion (negative or oversized doubles were undefined
  behaviour in C) and now pass through 53 usable bits (a double's exact-integer
  range) instead of silently truncating to 32.
- **Kit hardening: a missing body is never a script error.** Every `b2k…`
  wrapper that targets a control's body, a joint handle, or the world now
  no-ops cleanly when there is none (unregistered control, removed part, call
  before `b2kSetup`). Previously ~35 handlers passed empty into an LCB
  `Integer` parameter, which raises an execution error. Getters return the
  same defaults a stale handle produces (`0` / `"0,0"` / `false`).

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

### Fixed

- **Placed parts now show up immediately, not "only after I press Run".** Two
  independent causes, the first one the engine-room bug (Kit-level, so the
  demo and user code are healed too):
  - **The Kit never drew a freshly attached body while the loop was stopped.**
    `b2kAddBox`/`b2kAddCapsule` switch a spawned graphic's style to `polygon`
    and leave its points empty until the first body sync — but the sync fast
    path draws only bodies reported by Box2D **move events**, and a world that
    isn't stepping emits none. So a box, capsule or thruster placed in Build
    mode stayed a point-less (invisible) polygon until Run produced the first
    step. The attach handlers now draw the body the moment it's created, and
    the public `b2kSync` (the "loop is stopped, redraw by hand" entry point)
    full-scans instead of relying on move events; the running loop keeps the
    fast path. Balls, polygons and terrain were never affected — their
    graphics are complete at creation — which is why the bug hit "often"
    rather than always.
  - **Per-frame overlays now composite on their own GPU layer (contraption
    builder).** Joint markers, signal wires, the freehand sketch line,
    thruster flames and shock rings are re-pointed constantly while running,
    but lived in the compositor's cached static scene; they're now dynamic
    layers like the moving bodies they follow.
- **Popups no longer glitch over a running sim (contraption builder).**
  Opening Recipes / Filter / World / Images while running left dozens of
  GPU-layered parts repainting underneath the popup — parts and joint markers
  bled through patchy chrome. A popup now freezes the view beneath it: the
  sim pauses (only if it was running) and the stack composites the classic,
  cache-free way while the popup is up; both are restored exactly as found on
  close. This also means a contraption can't change while the user is reading
  a menu.
- **Inspector text no longer overlaps the settings rows (contraption
  builder).** The hint/preview line shares screen space with the settings
  rows by design (visibility-toggled), but two paths showed both at once —
  the "Simple mode hides some expert settings" notice and the live previews
  for bomb/laser/fan/magnet/goal drew straight over the first rows.
  `setSettingsHint` now parks itself below the last visible row (and drops
  the text when a full tab leaves no room). Also: eleven tool descriptions
  were longer than the description box and clipped mid-sentence — trimmed to
  fit — and a long part name no longer overflows the inspector title.
- **Parts can no longer be parked overlapping the chrome (contraption
  builder).** Placement, duplicate/multiply copies, build-mode drags and arrow
  nudges keep the part's whole rect inside the arena (previously only its
  centre was clamped, so a wide platform could hang halfway over the palette
  or under the ground bar). The laser keeps its emitter-based dragging.
- **Signal wires no longer churn the renderer (contraption builder).**
  `drawWires` reuses its marker graphics and re-points them instead of
  deleting and recreating every wire on every build-mode redraw.
- **Geometry getters no longer leak the previous shape's values.** The
  circle/capsule/segment read-back stash zeroes on a failed update (stale
  handle or wrong shape type), so `b2ShapeCircleRadius()` & co. report `0`
  instead of stale data.
- **An aborted `b2kAddSensor` / `b2kReshape` no longer leaks one-shot shapedef
  flags.** Bail paths now call `b2ShapeDefReset`, so a failed attach can't
  silently turn the next spawned shape into a sensor.
- **`b2kPruneDeadRefs` now clears every parallel table** (shape, render,
  verts, radius, image-angle, static, spawned, sensor) like `b2kRemove` does,
  so a control deleted behind the Kit's back leaves no stale state.
- **`b2kDefineLayer` refuses a 33rd layer** instead of overflowing xTalk's
  32-bit `bitOr` into a collide-with-nothing category.
- Stale ABI-`3` references in the demo header, getting-started, kit-reference,
  and changelog preamble now read `4`.

- **Every inspector setting is reachable again.** As the part inspector grew, the
  Physics tab had more settings than the panel can show at once, so the last few
  (Collision layer, Sleep, In-simulation, Sensor) were silently cut off. The
  settings are re-balanced across the tabs — Physics keeps the material/dynamics
  settings, a renamed **Collide** tab gathers the collision and simulation-state
  settings, and the launch settings move to **Special** — so nothing is hidden.
- **Collision settings survive a reshape.** Changing an image's collision shape,
  toggling the sensor flag, or resizing a part rebuilds its shape with a fresh
  (default) filter; the part's collision layer and channel filter are now
  re-applied afterwards instead of being quietly dropped.
- **Drawn ground now collides and is clearly visible.** A freehand *Draw* piece
  is now a filled, closed ground mass (the drawn surface down to the floor) with
  its chain wound so the solid side faces up — bodies rest on it instead of
  falling through, and it reads as solid ground rather than a thin line. The same
  chain-winding fix applies to the smooth **Hill**.
- **Drawn terrain saves where you last dragged it.** A freehand *Draw* terrain
  piece is now serialized from its current points, so repositioning it before a
  save no longer snaps it back to where it was first drawn when you load.
- **Tidied the smooth-hill outline locals.** Its working variables used bare
  names (including `env`); they're now `t`-prefixed like the rest of the file,
  removing any chance of clashing with an xTalk reserved word.
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
