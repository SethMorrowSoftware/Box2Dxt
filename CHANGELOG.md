# Changelog

All notable changes to Box2Dxt are documented here. The format is based on
[Keep a Changelog](https://keepachangelog.com/en/1.1.0/), and this project
adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

The native shim's ABI is tracked separately by `b2Version()` (currently `4`).

## [Unreleased]

### Added

- **Platformer: LEVEL 6 "CAVERN DEPTHS" - the DIRT biome (asset-expansion
  Phase B, slice 1).** A sixth level built on the previously-unused
  `terrain_dirt_*` tile set (block tops, `block_center` mass under the mound,
  carved `block_top_left/right` cliff corners on the goal steps AND the spike-pit
  lips, `ramp_long_a/b` dirt ramps, a one-way `cloud_left/middle/right` dirt
  platform): a WALL-JUMP SHAFT of floating dirt columns (slot coin, the L3
  ice-shaft recipe in dirt), a spike GAP to leap (checkpoint past it), a
  DIRT-RAMP mound, a high one-way-cloud bonus route, two slimes + a snail, a
  bonus GEM above the shaft, and carved dirt steps to the flag. The win moves to
  L6 (`gLevel >= 6`); L5's flag now ADVANCES. **OXT round 1 polish (atmosphere):**
  a built **dark cave backdrop** (`pfBuildCaveBackdrop` - two card graphics, not
  the flat/blank `background_solid_dirt` frame), flickering **wall torches**
  (`torch_on_a/b`, new `pfMakeTorch`), hanging **chains + stalactites**
  (`terrain_dirt_vertical_bottom`), and ground decor (a rock, cave mushrooms, a
  bush) - placed clear of every beat. Example-side only (no Kit change, no
  harness bump); `tools/audit-platformer.py` auto-discovers and clears L6 (9
  coins, 3 walkers, 0 findings). Statically verified; needs an OXT pass (see
  header verify item 20). Phase B's headline mechanics - the block slime and the
  conveyor belt - land in slices 2-3.
- **Platformer: FISH in the swim pool.** The L1 hilltop pond now has two fish
  (blue + yellow, native `foes` art that was unused) swimming at different depths
  and periods — bodiless proximity hazards (recoverable knockback) you time your
  dive between while grabbing the underwater coins.
- **Platformer: GEM bonus pickups.** A distinct collectible (`gem_*` tiles art,
  previously unused) that does **not** gate the flag — a skill-reward tally shown
  in the HUD and the win screen. One gem per level in a hard-to-reach spot (above
  the mound, atop the ladder ledge, the wall-jump-shaft top, high over the piranha
  row, above the dune crest). New synthesized "gem" chime.
- **Platformer: a PARALLAX biome backdrop.** Each level gets its own scene that
  drifts behind the foreground at 0.3× for depth — green hills (L1/L2), a pale
  wintry hills (L3), purple mushrooms (L4), and desert dunes (L5) — tiled and
  wrapped across three card panels (gated so a still camera costs one compare).
  The Kenney bg scenes are fully opaque, so this is a single drifting layer (a
  fade layer behind would be hidden); true multi-layer parallax would need
  transparent layer art (noted in the expansion plan).

### Fixed

- **Platformer: spike pits now align FLUSH with the pit edges (all levels).**
  Found over two OXT rounds:
  - *Horizontal (the real misalignment).* `pfTile` treats its `(x,y)` as the
    tile's TOP-LEFT (it centres at `x+32`, exactly like all the ground tiling),
    but the spike row was tiled over the range `pL+32 .. pR-32`, shifting every
    spike 32px RIGHT - a bare 32px gap at the left pit edge and the last spike
    OVERHANGING onto the ground on the right. The row now tiles `pL .. pR-64`
    (top-lefts), landing flush from `pL` to `pR` in every pit.
  - *Vertical.* The spike pixels are the bottom 34px of the 64px cell, so the old
    y576 sank the tips to y606 (30px below the edge); the tile now sits at y546 so
    the tips meet the ground line.
  Affects every spike pit (L1/L3/L5/L6); the hurt sensor and pit geometry are
  unchanged. The no-art fallback strip matches.
- **Platformer (OXT round 6): five polish fixes for a solid state.**
  - *Parallax seam.* Adjacent 640px backdrop panels met exactly edge-to-edge, so
    sub-pixel rounding leaked a 1px white hairline. Panels are now widened 4px and
    recentred (a ~2px overlap each side, opaque-over-opaque), and the drift is
    rounded to whole pixels; the 640 wrap modulus is unchanged so the wrap stays
    seamless.
  - *L5 spike pit.* `pfMakeSpikes` tiled the row from `pL` (burying the first
    spike's left half under the slab and leaving a bare strip at the right edge —
    it read as "the spikes don't fit"). It now centres the row at `pL+32..pR-32`,
    flush to both ground edges — fixes every pit at once.
  - *Slime stuck to the crusher (L3).* The red-key crusher's slime patrolled to
    `2148`; its right edge (`2172`) all but touched the block body (`2178`, a 6px
    gap) and the velocity-asserting slime pinned against it. Right limit pulled in
    to `2118` (36px clearance).
  - *Coin obscured by the chain (L2).* The "ride the thwomp up" coin sat at
    `1840,64` — dead in the chain's column (chain art spans y44..172 at x1840), so
    it drew behind the chain. Moved to `1912,96`, clear of the chain, still
    reachable from the rising weight.
  - *Sign overlapping the checkpoint (L2).* A decor sign at `2400` (centre 2432)
    overlapped the checkpoint flag at `2450`. Moved to `2300` (~86px clear).
  - *Bonus, caught by the extended audit:* L2's slime#1 was patrolling **inside**
    the green crusher alley (`4324..4460`), its sweep overlapping crushers 6 & 7
    (0px) — the same stick risk. Crusher alleys are walker-free by convention, so
    it was relocated to the open stretch past the 2nd-bay crusher (a real 100px
    patrol, 86px clear), and a decor bush nudged out of its new sweep.
  - The geometry audit (`tools/audit-platformer.py`) gained four checks that flag
    this whole class statically: spike-pit fill (64px-multiple width), walker
    sweep vs thwomp body proximity, coin-in-a-chain-column, and decor vs the
    checkpoint/goal flag.
- **Platformer: the L5 thorn pit fits its spikes and the final coin is off the
  flag.** The pit was widened 192px → 256px (3 → 4 spikes, `ground2` starts at
  2256, over-pit coin re-centred to 2128) for a proper spiked chasm, and the
  summit coin moved off the goal flag (`4180` → `4100,420`; it overlapped the
  flag at `4200`). The audit gained a coin/gem-vs-goal-flag overlap check.
- **Platformer (OXT round 4): the collapsing-bridge planks now actually DROP.**
  They recoloured (the "shaking" tint) but never fell — a fresh `b2kAddBox` body
  needs gravity *asserted* to drop (the working thwomp does `b2kSetGravityScale
  1.8`, commented "slam, not float"); the plank skipped that step, so it floated
  in place. It now asserts gravity on the drop, like the thwomp.
- **Platformer: the L1 swim basin has a KILL FLOOR under the water.** The solid
  pond floor is replaced by a kill sensor just below the water line
  (`uPfKillFlag` → `pfHurt`), so sinking out the bottom respawns instead of
  resting on the floor forever — the swim now has stakes. The deepest underwater
  coin is raised (`588` → `576`) for a safe dive margin above the kill line, and
  the layout audit learned about water zones so underwater coins don't false-flag.

- **Platformer (OXT round 3): the ROOT cause of the drifting coins and flags —
  cast sprites were born scroll-shifted.** The camera `b2kCamGoto` ran *before*
  the hero and the cast, so every create-once cast sprite (coins, flags,
  checkpoints, the barnacle) was created while the view was already scrolled and
  landed offset on the user's engine — pond coins pushed off-centre, flag and
  checkpoint POLES drifting to step edges or hovering "unattached". Bound bodies
  (hero, slimes) re-sync every frame, so they were always fine; static pickups
  never re-sync. Fix: build the WHOLE world (scenery, hero AND cast) at scroll 0,
  then `b2kCamGoto` exactly **once, after the cast** — matching how the
  correctly-placed terrain was always built. The flag plant drops back to 8px
  (it had been bumped to 16 to fight the now-removed offset), and the L1 pond's
  underwater coins are grouped more centrally (`7880/7960/8040`).

- **Platformer (OXT round 2): the L3 wall-jump shaft reads as a real beat now.**
  The two pillars were a stretched thin slab; rebuilt as crisp 64px ICE-BLOCK
  columns framing a clear slot, and the slot coin is now built in the SCENE
  *with* the columns (it was in the cast, created after the camera scroll, so it
  could drift off-centre relative to the scene-built columns) — it sits
  dead-centre between them to show off the wall-jump.
- **Platformer: removed the L5 spider + its floating sand overhang.** A
  ceiling-crawler needs a ceiling; a sand bar hovering in the open desert sky
  read as a glitch. The spider stays showcased in L4's cave biome (the overhang
  is a real ceiling fragment there); the 3552 coin remains as a run-home pickup.
  L5's bestiary is now frog + barnacle (+ slime/snail).
- **Platformer: the flag/checkpoint plant was raised 8px → 16px** after an OXT
  pass showed flags still hovering at 8px. `kFlagPlantPx` remains the single
  tunable knob.

- **Platformer: the L4 COLLAPSING BRIDGE was crammed into a 128px lava slot
  between two crushers — rebuilt with room to read.** The mechanic's logic was
  sound all along (the stand-to-crumble detection window, the static→dynamic
  plank flip, and the render-sync — `b2kSetType` clears `sStatic`, wakes the
  body and forces a full sync — all check out); the *space* was the problem:
  three ~42px planks pinched between faced crushers at `3040` and `3360`. The
  lava pit is now **192px** (grid-aligned `3136..3328`), the bridge is **four
  ~48px planks**, and the **far-bank crusher is retired** so the planks get
  clear air (the single entrance crusher still gates the approach). The ~190px
  strip stays double-jumpable (the L2 lift bay's ~200px reach — no dead-end) and
  the mid-lava coin re-centres to `3232`. Downstream beats (fire slime, powder
  keg, bowling lane) are untouched — no cascade.

- **Platformer: flags/checkpoints that read as "floating" on the user's engine
  are now PLANTED.** Every flag/checkpoint frame seats its pole base on the floor
  line in geometry (re-verified: the 64px frames have *zero* footroom and are
  centre-anchored at `surface − 32`), but they hovered a few px on the user's
  engine — a scrolled-group vertical quirk at sprite-create time, the same class
  of engine difference the camera code already works around. A single tunable
  constant `kFlagPlantPx` (8px) now sinks every goal/checkpoint base slightly
  *into* its surface so it reads as rooted; bump it if a flag still floats in an
  OXT pass. (Statically verified — needs an OXT confirmation.)

- **Platformer: scenery no longer spawns on top of enemies or coins.** A new
  geometric layout audit (`tools/audit-platformer.py`, advisory) found decor
  sitting on beats: L1 mushrooms/bush on the meadow-slime / 2nd-act-slime /
  mouse / frog spawns (nudged into the clear inter-enemy gaps), an L2 bush on the
  barnacle's telegraph (`3400`→`3488`), and an L4 grass tuft that both hid the
  `4000` coin and sat on the bowling-lane snail (removed). Also fixed an L2 slime
  spawned 64px in the air (`topY 512`→`576`, it dropped on build). The audit now
  passes clean across all five levels (grounding, bounds, walk-offs, overlaps).

- **Platformer: three coins sat *on* a wall — lifted clear (a measured-alpha
  audit of every coin/flag in all four levels).** The visible coin disc is a
  38×40 sprite-alpha box centred in its 64px cell (not the whole cell), so most
  coins float clear at head/jump height; the audit found only three that bit a
  solid: the L2 lift-pedestal coin (`3300`→`3350`, off the pedestal corner) and
  the L2/L3 door-passage coins (`5392`→`5440`, `5808`→`5856`, which z-ordered
  on top of the *closed* door tile). Flags verified seated on their surfaces.

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
- **Platformer: levels now hug their CONTENT, so the hero can no longer walk
  off into dead ground at either end.** `pfBounds` built its thick slabs, edge
  wall segments and camera clamp at the raw WORLD width, leaving walkable
  emptiness before each spawn (hero at x 120 vs a wall at x 0) and after each
  flag (up to ~390px past L3's). It now takes the content edges (just past the
  spawn, just past the flag); the per-frame edge failsafe follows, and the side
  slabs grew taller so no Wave-5 double-/wall-jump rounds their corners.
  Example-only.

### Removed

- **The micro-game example (`box2dxt-microgame.livecodescript`) was
  retired.** The repo concentrates its game work on the platformer showcase;
  the "build a whole game" pattern it demonstrated is preserved in
  kit-guide §20. Dropped from the embedded-Kit sync list and the example
  lists in the README and CLAUDE.md.

### Added

- **Platformer Wave 7 (biomes): a new desert Level 5, "Scorched Dunes."** The
  platformer's first *fifth* level, in the fully-tiled **sand biome** — a sand
  **dune** (ramp slope), a **thorn pit** to leap, a **two-cloud hop**, and the
  Wave 6 bestiary (frog, barnacle, spider) given **room** (one of each, well
  apart), then sand steps to the flag. Laid out **layout-first**: every
  placement was geometrically audited (coin/flag/enemy overlaps + 250px-plus
  spacing per beat) *before* coding. The win now spans five levels.
- **Platformer Wave 6 (bestiary II): frog, barnacle, and spider — woven into
  L1/L2/L4, all example-side (no Kit change, no harness bump).** Three new
  enemy archetypes, each built on an existing Kit pattern:
  - **Frog** (L1 far meadow) — a grounded *hopper* that crouches then leaps
    toward you when you're in range. Joins the slime family as a new `"frog"`
    kind, so it's **stompable for free** (the classic-slime contact path); its
    side touch knocks back. Bounded to its band so it never springs into a pit.
  - **Barnacle** (L2 machine-works) — a stationary clam (the piranha's timed
    cycle held still): it lurks shut, **opens as a telegraph**, snaps a brief
    hurt-window, then cools down. Unkillable (the saw rule) — time it or jump it.
  - **Spider** (L4 haunted hollow) — a bodiless ceiling-crawler under a small
    overhang that **drops as you pass under** and climbs back. Family-C art, so
    **optional**: a missing spooks sheet omits it *and* its overhang, and the
    level still completes (the optional-art rule). Plus a `bite` sound cue.
- **Kit: a persistent spritesheet cache (`b2kSheetPersist`) — load atlases
  once, not per level (statically verified + harness v14).** Opt-in (default
  off, so every other example and the harness are byte-for-byte unchanged).
  When on, loaded sheets are assets that **survive `b2kTeardown`** (like
  synthesized sounds): a level rebuild reuses them instead of re-decoding
  each PNG, re-parsing each XML, and re-slicing every frame — the costliest
  work the Kit does, previously repeated on every level transition. An
  identical `b2kSheetLoad`/`LoadAtlas`/`FromImage` becomes a no-op, sliced
  frames survive, and because source/frame images are named deterministically
  (`b2ksheet_<name>` / `b2kfr_<sheet>_<n>`, tagged with the file path) a
  **saved stack** carries the cache — on reopen the load adopts the in-stack
  images, skipping the disk import entirely. `b2kSheetsWipe` stays the
  explicit purge. The **platformer** turns it on at `openCard` (Shift+Reset
  purges) to cut its between-levels load time.
- **Wave 5 (player actions II) — five new player-controller moves
  (statically verified + harness v13).** All **opt-in** through
  `b2kPlayerSet` knobs whose defaults leave the pre-Wave-5 controller
  byte-for-byte unchanged, and each idle path costs one compare per frame:
  - **Double-jump** (`airJumps` — extra mid-air jumps, refilled on landing).
  - **Wall-slide + wall-jump** (`wallSlideMax` caps the fall while pressing
    into a wall; `wallJumpX`/`wallJumpY` launch up and away with a brief
    steer-lock; a side ray runs only while airborne). New `wallslide` state.
  - **Dash** (`dashSpeed`/`dashMs`/`dashCooldownMs` on the new `dash` action,
    bound to SHIFT/X — a flat horizontal burst with gravity parked; yields to
    climb/swim). New `dash` state.
  - **Duck capsule-reshape** (`duckScale < 1` turns the Wave 2 brake-duck into
    a feet-anchored **crawl** via `b2kReshape`, with a headroom check before
    standing — so the hero slips under low gaps).
  - **Moving-platform carry** (`platformCarry 1` — a grounded player inherits
    the velocity of the moving kinematic body it rides; a vertical lift's
    carry is exempt from the ground-snap).
  - New helpers: `b2kPlayerHalfH()`/`b2kPlayerHalfW()` (live capsule extents,
    serving gotcha 28), `b2kPlayerInLadder()`/`b2kPlayerInWater()` (this
    frame's zone membership), and `b2kPlayerRespawn x,y` (teleport + zero
    velocity + clean state). `b2kPlayerAnims` gains `wall`/`dash` slots.
  - The **platformer showcase** turns them all on and leans each beat on one
    (double-jump throughout, a wall-jump shaft, a dash gap, the L2 lift bay;
    DOWN stays the Wave 2 brake-duck, not the crawl-reshape). Self-test **v13**
    adds six hand-stepped tests.
- **Wave 4 (liquids) — SWIM, the Kit's first new player-action since
  Wave 2 (statically verified + harness v12; user play-tested in the
  platformer).** A new `b2kPlayerAddWater x1,y1,x2,y2` registers a polled
  water zone (world state, wiped by `b2kClear`, exactly like the ladder
  zones). While the player's centre is submerged the controller SWIMS:
  gravity drops to `swimGravity` so you sink slowly, the sink caps at
  `swimMaxFall` (far below the air terminal), UP/DOWN swim at `swimSpeed`,
  and a JUMP press is a REPEATABLE upward STROKE (`swimJump`) with no ground
  gate. A new `swim` state plus a `b2kPlayerAnims` swim slot (a 9th arg,
  falling back to the fall pose, so three-arg calls still work) drive the
  art. Swim is mutually exclusive with the climb (the tick starts only
  one); leaving the zone, a hurt, or teardown restores the saved gravity
  scale exactly once. The swim path costs ONE compare per frame when no
  water zones exist. Two Opus correctness reviews found no blockers.
  - **The platformer's L1 GREEN HILLS gains a HILLTOP POOL** — the swim
    showcase, in the level the game is actually play-tested in. A RAISED
    swim basin between two earth banks past the crusher alley: the 640-tall
    world clamps the camera at its bottom, so a swim pool is a basin held
    at the surface, never a sub-ground pit. Hop in, dive for three
    underwater coins (the gate needs them), then stroke up + hold-forward
    to HOP out the far bank to the flag. New `pfMakeWater` helper; per the
    playtest the water was made heavier (`swimGravity` 0.6, `swimMaxFall`
    200, a trimmed `swimJump` 300 — `swimJump` alone sets the escape, so it
    is the lever for "harder to climb out").
  - **Fixed a pre-existing brick head-bump gap** the pool work surfaced:
    the hero's 88px capsule was taller than its ~76px visible character
    (128px frame headroom at a 0.75 down-scale), so heads "missed" bricks
    by the difference even though the smash fired. The hitbox now matches
    the art (feet-aligned, bind offset derived) and the bonk window reads
    the real half-height instead of a hardcoded 44 (gotcha 28).
  - **Harness v12** adds three swim tests: `stTestSwim` (dive / buoyant cap
    / repeatable stroke / swim-up / gravity-restored-on-exit, every value
    printed), `stTestSwimGrounded` (swim while resting on a submerged
    floor — the pool-floor case), and `stTestSwimClear` (the level-rebuild
    path: `b2kClear` must wipe the zone, or the next level's player is born
    swimming in mid-air where the old pool was).
  - The micro-game also gained an L3 "THE DEEP" swim level (data verbs
    `water` + a `fish` pit-dweller), but it shows a white-world build issue
    in its own example code and is set aside pending a focused pass — the
    Kit swim itself is sound (it runs clean in the platformer).
  - **The COLLAPSING BRIDGE — Wave 4's last named mechanic — is now built.**
    New `pfMakeCollapseBridge`/`pfTickCollapse`: static planks crumble a beat
    after the grounded hero stands on one (CREAK then SMASH, dropping the plank
    and its rider into the lava), re-park static before the kill floor can
    destroy them, and the whole bridge re-forms once the hero retreats to the
    near bank. It crosses L4's lava pit in place of the lava lift (the gap
    already existed; a fall is the recoverable pfOuch; a running double-jump
    still clears the strip; platform-carry stays showcased by the L2 lift bay).
    Example-only — no Kit change.
- **Platformer SHOWCASE polish round (statically verified; awaiting the
  OXT pass).** A pre-Wave-4 pass over the platformer to make it a
  polished demo of the kit *as it stands today* — longer, better-spaced
  levels, classic mechanics drawn from the kit's biggest UNUSED subsystem
  (JOINTS + dynamics), and four new enemy species for variety.
  **All example-side: zero Kit changes, so harness v10 stays the
  baseline** (rule 2 is conditional on Kit edits).
  - **Three sprite-faithful mechanisms, all polled HAZARDS the player
    times or avoids (never rides — so none needs the platform-carry a
    later wave adds):** a sagging **ROPE BRIDGE** (L1 — six dynamic planks
    hinged end-to-end and pinned to the world at both posts, the canonical
    Box2D bridge, with a new checkpoint at the brink); a **ROLLING
    BOULDER** (L3 — a sprite-faced dynamic ball that slides the icy flat
    head-on, recycled on a cycle so it never reaches the kill floor,
    judged by a poll since it passes through the hero); an **EXPLOSIVE
    BARREL** (L4 — a fuse-then-`b2kExplode` powder keg that scatters a
    woodpile of loose crates). A swinging wrecking ball was prototyped and
    **cut**: a rotating arm cannot be sprite art (gotcha 23), and the kit
    is sprite-only for game visuals — so it was removed rather than left
    as a plain graphic.
  - **Four new enemy species** on the existing slime FAMILY (native 64px
    foes art, a new `pfMakeCritter` maker + per-row speed/squash-frame
    columns): a fast **mouse**, a slow **worm**, a **ladybug** (+ a
    flying one via the mover table), and a **fire slime** by the L4 lava
    (spike-type — hurts from every side). L4's PIRANHA row is now twice as
    long (four burrows on staggered timers).
  - **Longer, re-spaced levels** (the layout law: widen before squeezing
    a beat in), grown across several passes to L1 7552, L2 5952, L3 6592,
    L4 6656. Existing verified beats are preserved in place; each level's
    walled-door / steps finale shifts as a whole. Classic acts stacked on:
    L1 a "meadow gauntlet" + a "homeward run" (chained thwomp + snail under
    a cloud); L2 second and third machine bays (chained crushers + an
    always-on saw + a snail); L3 a second snow cloud + a glacier slime,
    snail and thwomp; L4 a "bowling lane" plus a snail-heavy finale.
    **Snails are now used liberally** (L4 carries four), the **classic
    chained-weight thwomps are back** in every level alongside L4's faced
    crushers, and there are more clouds, coins, and decor throughout. A
    live `awake N/M` body count on the HUD.
  - **A marquee CRUSHER ALLEY + cloud hop closes every level** (the latest
    pass: "show off the engine with as much pizzazz as possible"). Each
    level's homeward stretch is now a row of FOUR tile-block thwomps the
    hero times a dash BENEATH, biome-matched so the mechanic reads at a
    glance — **green** blocks (L1, L2 grass), **blue** (L3 ice), **red**
    (L4 haunted) — followed by a two-cloud HOP to the flag with coins up
    top. Powered by a new `pTileFace` parameter on `pfMakeThwomp` (a plain
    tile sprite, no mood-face swaps; the same drop/rest/rise/re-arm cycle,
    so the alley never blocks the path for good). The four levels each grew
    ~1280px for the new gauntlets; the walled-door/steps finales shifted as
    whole units; coins and their totals self-count as the level builds.
  - **A per-frame optimization pass** against the kit's performance
    playbook (FFI round-trips are the second-biggest per-frame cost). The
    new crusher rows exposed that `pfTickThwomps` read each block's
    position over the FFI *every frame even while ARMED* — a static body
    resting at a fixed perch that cannot move until triggered — so it now
    caches each perch x (`gBlockX`) and gates the armed→falling trigger on
    that + the shared hero snapshot, paying `b2kPosition` only for the 0–1
    blocks actually in motion (≈8 → ≈1 FFI/frame, identical trigger). Plus
    the sliding-shell tick reads its velocity once (not twice) and the HUD
    reuses the snapshotted player state and a single camera-scroll read. An
    Opus audit confirmed every other per-frame tick was already at the
    playbook's standard (O(1) idle gates, hoisted clocks, shared snapshot,
    change-gated writes, sleep-friendly).
  - **The L3 ice boulder slides ALL THE WAY** in its direction now (per
    the user: "it is an ice block/boulder") - lower friction so it coasts
    far, and its reset line moved off-screen-left (past the run, below the
    camera edge) so a fresh one comes from the source rather than the old
    one teleporting back in place.
  - **User review fixes:** the SNAIL faced backwards relative to travel
    (gotcha 26 — its sheet art is mirrored vs the slimes'); a per-row
    `gSlimeFlip` polarity column inverts only its flip. The barrel's
    woodpile is now real CRATES (the `block_empty` sprite over invisible
    fixed-rotation boxes, the L2 gate-crate pattern — a blast slides them
    without the sprite-cannot-rotate problem) instead of brown rectangles.
- **Wave 3 — bestiary I + HAUNTED HOLLOW (statically verified; awaiting
  the OXT pass).** Six enemy archetypes and a FOURTH platformer level,
  all example-side: **zero Kit changes, so harness v10 stays the
  baseline** (rule 2). Design in `docs/expansion-prep.md` §10.
  - **Snail (kickable shell):** joins the slime family as a kind chain
    `snail -> shell -> shellslide <-> shell` — a stomp shells it, any
    touch of the parked shell kicks it sliding 520px/s away from the
    hero, the slide is a per-frame velocity assert that REVERSES off
    walls (collapsed-vx poll) and bowls over every ground foe it
    reaches; stomp the slide to park it; its sides knock back.
  - **Bat:** roosts static under an overhang (`bat_hang`), drops when
    the hero nears, then flies as a gravity-scale-0 body — patrol vx +
    a proportional swoop to head height + sine bob. One stomp.
  - **Mimic:** a `grassBlock` sitting dead still in the PURPLE biome
    (wrong on purpose — the tell); wakes within ~90px and lunges in
    short hops on a cooldown. One stomp.
  - **Piranha burrows:** bodiless sprites rising from drawn mouth
    holes on a down/rise/bite/sink cycle with the classic mercy (never
    rises while the hero stands over the mouth). Unkillable.
  - **Ghost:** bodiless, drifts through terrain toward the hero at
    ~80px/s ONLY while he faces away (`b2kPlayerFacing` poll); eye
    contact freezes it in the shy pose. The level's pressure.
  - **Faced crushers:** `pfMakeThwomp` gains a `pFaced` flag that puts
    the `block_idle/fall/rest` mood art (which was already the
    machine's fallback) on L4's thwomps on purpose.
  - **L4 "HAUNTED HOLLOW"** (3712px, 10 coins): purple biome, the
    mimic field, the snail+slime bowling lane, the bat bar, a pit, two
    burrows, the ghost over the back half, a faced-crusher pair around
    a new **lava strip** hazard (`pfMakeLava`: knockback, never
    respawn), purple steps, the flag. Win moves to `gLevel >= 4`; all
    copy says FOUR. Spook art (`enemies.png`, the Family C sheet)
    loads as sheet `spooks` at `b2kSheetScale 0.9` per the mixed-grids
    law and is OPTIONAL — without it the four spook makers skip
    silently and L4 still completes.
- **Wave 2 closed (user-verified 2026-06-13; harness v10 all-pass) +
  the level SPACING pass.** The one OXT note from the wave: the new
  beats cramped the layouts. Every level stretched so each interactive
  beat gets ~100px of clear air — now a layout law:
  - **L1** 3712→3968px: the cloud steps no longer start at the mound's
    foot (+128px gap), the spike pit and second act shift out, the
    fence/bush decor moves off the bonk row.
  - **L2** 2816→3072px: the Wave 2 ladder/ledge becomes its own beat
    past the gate (the checkpoint used to stand INSIDE the ladder
    tiles and the lever 6px off them); checkpoint → 1000, lever →
    1120, saws → 1240/1430, thwomps → 1640/1840, wall → 2464.
  - **L3** 3520→3776px: the bonk-row → saw → pit corridor was
    wall-to-wall (gaps of 0–18px); the saw now has 88/56px of air and
    everything from the checkpoint out shifts +128.
  - **Micro-game L2** 1536→1664px: the exit pillar + ladder move past
    the sweeper's reach (its far end used to graze the ladder base).
- **New example: the SLINGSHOT** (`examples/box2dxt-slingshot.livecodescript`)
  — an angry-birds-style tower-knockdown game, and the example that shows
  the PHYSICS CORE carrying a whole game by itself (the platformer and
  micro-game showcase the game modules; this one uses no player, no
  camera, no sprites, and deliberately **no contact events at all**).
  Drag the red ball out of the slingshot pocket (a tether-clamped pull
  with live rubber bands and a ballistic aim preview — the dots plot the
  same `x + v·t + a·t²/2` the world then integrates), release to fire;
  three towers of columns/planks/crates (plus stone blocks on level 3)
  topple for real, and the green pigs pop on a **speed poll** — the
  light body always inherits the impact momentum, so the poll can't be
  outrun by the solver (the doctrine's answer to post-impact zero
  reads). Shot budget per level, 50 a block + 500 a pig + 1000 per
  leftover shot, out-of-ammo retry with score rollback, win screen.
  Zero assets: all visuals are colored graphics (which is also why —
  spawned box graphics rotate with their bodies; sprites don't), all
  sounds synthesized. Hot-path discipline: ammo/bands/dots/pop-rings
  are pooled at build, block polls only run during a post-shot carnage
  window, HUD at 4 Hz. Registered in the embedded-Kit sync tool.
- **Wave 2 — player actions I (statically verified; awaiting the OXT
  pass).** Four controller abilities land in the Kit, asserted by
  harness **v10** (four new tests, ~20 assertions) and consumed by both
  games:
  - **Drop-through:** every `b2kChain`/`b2kSmoothGround` chain now
    carries a reserved one-way collision category (bit 2³¹, nameable as
    the `oneway` layer; `b2kDefineLayer` stops at 2³⁰ — 31 user layers —
    and `b2kSetMask` ORs the bit in automatically so custom-masked
    bodies still stand on terrain). DOWN+JUMP while standing on a chain
    masks the bit off the player for `dropMs` (~260 ms); the probe
    ignores one-way ground during the window (no phantom re-ground),
    and the mask restores only once the capsule has CLEARED the deck it
    dropped through (a straddling restore would snap it back on top —
    chain contacts are one-sided, judged by the centroid), with a 4×
    hard deadline. On solid ground DOWN+JUMP just ducks, and the press
    is eaten. **No ABI change was needed** — `b2lc_chain_create`
    already honors the pending shape-def filter (§9's open question,
    resolved).
  - **Ladder climb:** `b2kPlayerAddLadder x1,y1,x2,y2` registers polled
    ZONES (flat numeric arrays, zero physics objects; world state —
    `b2kClear` wipes them). In-zone UP (or DOWN while airborne) enters
    `climb`: gravity scale parks at 0 (the body's own scale is saved
    and restored), y runs at `climbSpeed` off the moveY axis (0 =
    hang), x at half speed; JUMP exits with a normal jump; climbing
    down onto ground steps off. The ground-snap is climb-exempt (rising
    off a grounded ladder base is real motion).
  - **Duck:** DOWN while grounded brakes to a stop at the normal decel
    and shows the new `duck` state/anim. No hitbox change this wave
    (capsule reshape is Wave 5).
  - **Hurt-knockback standard:** `b2kPlayerHurt [fromX]` — an away-pop
    (`hurtPopX`/`hurtPopY`, riding the jump flag so the ground-snap
    can't swallow it), the `hurt` state, input suppressed until
    `hurtMs` or the first landing after half of it (whichever is
    LATER), then an `invulnMs` mercy window during which repeat hurts
    no-op and `b2kPlayerHurtIs()` answers true. An explicit
    `b2kPlayerControl` call cancels a knockback in flight (respawn
    flows take over cleanly, no mercy granted).
  - **Kit surface:** `b2kPlayerAnims` grows optional `duck`/`climb`/
    `hurt` slots (old five-argument calls unchanged; sensible pose
    fallbacks); new tuning keys `dropMs`, `climbSpeed`, `hurtPopX/Y`,
    `hurtMs`, `invulnMs`; `b2kPlayerState()` adds `duck`/`climb`/
    `hurt`. All new tick paths idle at one compare per frame, knobs
    cached at set-time, and the probe's one-way classification rides
    the body handle `b2kRayHit` already fetched — zero added FFI in
    the steady state.
  - **Platformer:** the knockback-vs-respawn SPLIT — slime sides, saw
    brushes, spike tips, thwomp undersides and movers now knock back
    (`pfOuch`, HUD counts "hits"); only pits/kill-plane falls respawn.
    The beige hero ducks and climbs with REAL frames (the default
    characters sheet has `duck`/`climb_a/b` — the design doc guessed
    wrong). L2 gains a LADDER up to a bonus ledge above the gate (one
    new coin, 9 total); the L1 bridge/clouds drop through as designed.
    The knockback pose is a LOOPING `hurtpose` twin of `hit` — a
    non-looping pose would fire `b2kSpriteOnFinish` → the respawn
    mid-knockback (both games gate their `*HurtDone` on the respawn
    lock for the same reason).
  - **Micro-game:** the same split (sweeper/spikes knock back; falls
    respawn; HUD + win screen count hits), a zero-asset `ladder` verb
    (drawn rails + rungs) up the now-taller L2 exit pillar, and
    OPTIONAL **alien skins**: when the platformer's remembered
    Spritesheets folder is present (the game itself never prompts —
    zero-asset stays zero-asset), the menu offers keys 1–6 (classic +
    five alien colours from the one `aliens.png` atlas, scaled 0.7);
    aliens duck/climb/hurt with real frames.
  - **Hardening found en route:** `b2kChain`/`b2kAddChain` parsed
    points without setting `itemDelimiter` (gotcha 5 — latent breakage
    under a tab delimiter); both now set it. `b2kRayHit` stashes the
    hit body handle it already fetched (`sRayBodyH`).
- **Wave 1 closed (user-verified 2026-06-12); Wave 2 designed.** The
  three-level platformer is the wave's verified exit. Wave 2 — player
  actions I (drop-through, ladder climb, duck, the hurt-knockback
  standard, optional alien skins in the micro-game) — is fully
  designed in `docs/expansion-prep.md` §9, including the Kit surface,
  tuning keys, harness v10 assertions, art inventory, and the open
  chain-filter ABI question to resolve first.
- **The platformer is now a THREE-LEVEL game** (user direction: "we
  need three distinct levels for this demo to show off all features").
  Touching a level's gold flag banners "LEVEL N CLEAR!" and builds the
  next level outside the physics frame (the micro-game's deferred-
  rebuild lesson); level 3's flag is the win, with TOTAL time and
  falls banked across clears. R restarts only the current level; Play
  again is a fresh run. The world build split into per-level builder
  pairs (`pfL<N>Scene` before the hero — scenery must never cover the
  actors — and `pfL<N>Cast` after), with the shared machines factored
  into parameterized makers (`pfMakeGate`, `pfMakeKeyDoor` with a
  colour, `pfMakeSpikes`, `pfMakeGoal`, `pfMakeCheckpoint`,
  `pfBounds`). Coin totals **count themselves** as each level builds,
  so totals can never drift from the layout (and the no-asset
  fallback's smaller totals fall out for free):
  - **Level 1 — GREEN HILLS** (2880px): movement + the Wave 1 toys —
    springboard + sky coin, the bonk row, the one-way bridge over the
    spike slime, the slope mound, two one-way clouds, bee/fly movers,
    the spike pit. 9 coins.
  - **Level 2 — THE WORKS** (2208px): the machines — crate onto the
    button gate, checkpoint, the stand-to-flip saw lever, both saws,
    chained thwomps, the yellow key and the walled door gating stone
    steps and the flag. 6 coins.
  - **Level 3 — FROZEN CITADEL** (2880px): everything at once on ICE
    (quarter-strength `accel`/`airAccel` — momentum rules), snow
    biome, spring over a spiked pit, bonk row, sweeping saw, second
    pit, a thwomp guarding the RED key, the red walled door, snow
    steps. 10 coins.
  - **Boundary hardening** (user report: walking past the world's
    edges): every level's box is built by one `pfBounds` helper —
    thick side slabs PLUS two-sided wall segments at the exact edges
    PLUS the ceiling, kill floor, and the camera clamped to the same
    box. Boundary bugs now have exactly one home.
  - **Final pass**: brick debris became a six-slot POOL built at level
    build (parked static off-world; a smash only moves and flings the
    chunks, a tick re-parks them before the kill floor) — mid-game
    control creation under accelerated rendering was the remaining
    hitch, and the frozen frame was why chunks "never showed up". The
    spring returned to mid-meadow (the corner bounce hugged the window
    edge). Hot path: ONE hero position/state snapshot per frame feeds
    the kill plane, edge failsafe, sound cues and all the pf ticks
    (~8 FFI round-trips per frame replaced by one), and the bonk
    rising-test now reads the controller's jump state instead of a
    per-frame velocity fetch.
  - **Polish round** (user: "much better shape now"): every level
    lengthened with a second act — GREEN HILLS to 3712px/12 coins (two
    more slimes + a rest cloud), THE WORKS to 2816px/8 (a breather
    cloud with its own bee before the wall), FROZEN CITADEL to
    3520px/10 (the glacier run: a second always-on sweeping saw under
    a snow cloud). The left-edge escape died twice over: the L1 spring
    host now sits FLUSH against the wall (the 14px slot between them
    was a solver-squeeze ejector) and the boundary slabs grew to 256px
    thick, plus a per-frame edge failsafe rides the kill-plane check.
    Brick debris no longer hitches or "appears offscreen": the
    `brick_brown` icon is PRE-WARMED at build (lazy slicing cost
    ~250ms × 3 at first smash — physics outran the freeze, so the
    chunks seemed to pop in far away). Ice strengthened to ~15%
    accel/brake (a full-speed stop slides ~300px).
  - **The scroll-shifted-build regression, found and fixed** ("level 1
    is fundamentally broken"): the restructure briefly called
    `b2kCamGoto` before any camera bounds existed; an unbounded goto
    scrolls the empty viewport (centring x=120 means scroll −392), and
    the entire level then builds INTO a scrolled group — art lands
    ~400px from its physics (gotcha #12, again). Order law now in the
    code: build at scroll 0, set bounds (`pfBounds`), only THEN goto.
    Stale per-level machine refs (the gate, plate, door, checkpoint)
    are also reset on every rebuild so no tick ever chases a deleted
    control from the previous level.
- **Wave 1 — the iconic-feel base: the platformer learns the classics.**
  Springboards, ?-boxes, breakable bricks, a saw power lever and a
  key-and-lock door land in the platformer — entirely on existing Kit
  mechanisms and the already-shipped 64px tiles atlas. **Zero Kit
  changes** (so no harness bump: the Kit's contract is untouched) and
  zero new asset dependencies; the no-asset fallback level stays frozen
  at its original 12 coins.
  - **Springboard** (`spring`/`spring_out`): feet in its band relaunch
    every 420ms — you cannot stand on a springboard — reaching a new
    sky coin ~320px up. The boost is `b2kPlayerJump 620`, the canonical
    use of the API jump (a raw upward set-velocity on a grounded player
    is ground-snapped away as solver rebound).
  - **The bonk row** (brick, ?-box, brick, ?-box over the meadow):
    headbutts are judged by POLLED geometry plus a 160ms rising window,
    because the solver has already zeroed the upward velocity on the
    very frame the head meets the tile (the stomp lesson, applied
    upward — no contact events on statics anywhere in Wave 1). ?-boxes
    pay one coin each (pop animation, then the `block_empty` face);
    bricks shatter into three `brick_brown` chunks (32×24, measured)
    riding invisible spawned balls — the kill floor destroys them and
    `b2kFell` sweeps the bound art. Debris no-collides with the hero.
  - **Button art on the plate**: the polled pressure plate now wears
    `switch_yellow` / `switch_yellow_pressed` faces in step with its
    polled state (the coloured-rect fallback survives, frozen).
  - **The saw lever** (`lever_left/right`): STANDING at it (grounded,
    near-zero vx — running past never flips it; a leave-the-band latch
    re-arms it) powers the sweeping saw down: spin stopped, ghosted,
    hurt box off. Standing again powers it back up.
  - **Key + the WALLED door — the finale's mandatory gate.** A key
    floats in thwomp alley (one-shot sensor pickup, per doctrine),
    rides the hero's shoulder as a bound sprite and shows `[KEY]` on
    the HUD. The gate itself is a **stone wall from the ceiling to the
    ground with a locked two-tile door at its foot**: the steps, two
    step coins, a coin inside the passage, and **the flag itself** sit
    behind it, so the win provably requires the door (three of the
    fifteen coins are back there) and the flag can never end the game
    with content unseen. With the key, the door opens FOR GOOD on
    approach (~20px before face contact; the lock tile dissolves into
    the wall; the passage body is `b2kMoveTo`-parked off-world first,
    then `b2kDisable`d in its own try); keyless, it buzzes and banners
    where the key is. Respawns walk back through.
    (The OXT saga, each round a recorded lesson: a slime guarded the
    unlock threshold — relocated; a flush-against-the-step column made
    the open door a jump shaft — moved to the flat; door art created
    after the hero drew over him — scenery builds first now; the
    disable-then-park ordering let a swallowed throw kill the park —
    park runs first now, and harness v9's `stTestDoorClears` asserts
    both clearing paths; and finally the free-standing 192px column
    was simply BYPASSABLE — the thwomp-ride arc sailed over it, which
    is why "the door never works" survived every physics fix. A gate
    must be structural: wall to the ceiling, prizes behind it.)
  - **Re-skinned, sprite-only**: thwomps are now chained weights
    (`weight` + `chain` tiles; the chain stays at the perch while the
    weight falls) — and a weight on a chain is **not the player's to
    move**: it rests STATIC (unpushable; `b2kGrab` refuses statics by
    design) and `mouseDown` filters the brief dynamic fall out of the
    grab, so only the crate drags. The old drag-a-thwomp coin became
    the doorway crown coin. The crate itself wears the empty-box face
    (`block_empty`, the same box a headbutted ?-box turns into) over an
    invisible fixed-rotation host. The spike pit grew real `spikes`
    tips (placed from measured alpha: tips at y 606, base flush with
    the stage floor), and the level crosses a biome seam at the locked
    door into a STONE finale.
  - **Win-state clarity** (user report: "the flag win state is
    confusing"): every coin lands in one `pfGainCoin`; the LAST one
    turns the goal flag **GOLD** (`flag_yellow` wave) with a banner +
    chime — "ready to win" is visible from across the level — and
    touching the flag short of the total now **buzzes** and banners
    exactly how many coins remain (throttled; the HUD line repeats
    it). The red checkpoint flag can no longer be confused with the
    goal.
  - **Layout audit** (jump math, v=430/g=600 → 154px apex; spring 620
    → 320px): all 15 coins verified reachable, every beat passable.
    One fix fell out: the springboard squatted on the only path out of
    the spawn — it now hugs the left wall behind the spawn, a
    discovery toy that blocks nothing.
  - Fifteen coins now (sky coin + two box coins); six new synthesized
    cues (spring, smash, key, unlock, lever, deny) — still zero asset
    files for audio.
- **Wave 0: the asset pack catalogued; the content roadmap expanded.**
  The uploaded Kenney platformer family (~900 frames, three compatible
  sets) is fully inventoried in `docs/expansion-prep.md`: six 70px
  terrain biomes with slope and one-way tiles, buttons/levers/
  springboards/keys+locks/doors/ladders/liquids/ropes/?-boxes, a
  25-species enemy sheet (bat, ghost, piranha, mimics, crushers…),
  p1–p3 players plus five alien skins **with climb and swim frames**,
  and a hearts-and-digits HUD set. Decisions recorded: the 70px grid is
  primary; **sprite-only visuals from here on** (plain LC graphics only
  as invisible physics hosts; existing no-asset fallbacks frozen); the
  roadmap now spans ten player actions, a fourteen-archetype bestiary,
  seven biomes (snow = ice friction), the full switch family, and eight
  waves aimed squarely at mimicking the iconic platformers.
- **`b2kOverlapMoving` — the presence poll done right (the plate's last
  stand).** The polled plate read *pressed from frame one, forever*:
  its pad region sits on the floor, and `b2kOverlap` asks the
  **broadphase**, whose boxes are fattened (~0.1 m ≈ a few px at game
  scale) — so the ground slab itself permanently overlapped the region.
  New `b2kOverlapMoving` runs the same query with **static bodies
  filtered out**, which is what a plate means ("is some *thing* on
  me?"); dynamic and kinematic bodies count, sleeping ones still
  register. The platformer's plate uses it; both kit docs warn about
  the fat-AABB margin; and the self-test (v8) closes its own blind spot
  — the old presence test only asserted positives, never "empty over
  bare floor", which is exactly where the fattening bites.
- **Documentation sweep + the expansion plan (the green-board close).**
  With the self-test at v7/all-pass and both games user-verified, every
  doc now states the as-built truth: the game-engine spec is marked
  **implemented** (deltas live in plan.md's decision log), plan.md flips
  Phase 3 / audio / scenes / the micro-game exit to *shipped and
  user-verified*, the Kit reference documents the player's **feel
  guarantees** (sim-time windows, dead landings, hysteresis,
  ground-snap + the `b2kPlayerJump` rule) and `b2kSetVelocity`'s
  wake-on-write, README points new platforms at the self-test first,
  and CLAUDE.md codifies the campaign's doctrine as gotchas #14–16
  (contact-target wiring, the chain ghost rule, windows/polls over
  instantaneous reads) plus the harness workflow (assert + bump
  `kStHarnessV` with every Kit change). New: **`docs/expansion-prep.md`**
  — the intake plan for the upcoming asset dump and the content phase:
  delivery format, the measure-before-placing rule, a player-actions
  roadmap (drop-through, wall-jump, dash, double-jump, platform carry —
  each with tuning keys and a self-test sketch), an enemy archetype
  roadmap mapped to the known Kenney frames, the rules of engagement,
  and a six-wave order ending in builder cross-pollination.
- **The harness doubles its reach (engine-surprise insurance).** Six new
  suites, ~40 new assertions, aimed squarely at "the LC engine OXT
  inherited is full of surprises": **engine contracts** (fractional
  `mod`, byte packing, base64, temp-file I/O, imageData/alphaData
  strides, `word 2 to -1` chunk semantics, `wholeMatches lineOffset`,
  long-id re-resolution after a relayer, custom-property boolean
  round-trips, `playLoudness` readback — when an engine update or new
  platform breaks one, the report names it in plain text);
  **materials + joints** (a 0.8-restitution ball measurably rebounds,
  density drives mass, a motorised hinge spins, a rope holds a dangling
  ball at length); **filtering** (no-collide pairs pass through; a
  ghost-layer ball ignores a solid-layer platform — regression for the
  named-layers path that once always threw); **queries** (controlAt /
  contains, overlapCircle, multi-ray nearest-first); **sheet extras**
  (per-sheet scaling sizes sprites, margin/spacing grids count
  correctly, frame-size-0 + `b2kSheetAddFrame` manual regions slice,
  flips swap to a real mirrored frame image and back); **player slopes
  + limits** (climbs a 22° chain ramp without wall-stick — also guards
  the ground-snap's slope exemption — maxFall clamps a long dive, and
  the kill floor never takes the player). The micro-game's temporary
  `ev` HUD diagnostic is retired now that it plays clean.
- **The micro-game's actual bug: it never set `b2kContactTarget`.**
  Sensor and contact *messages* dispatch to the contact target; the
  micro-game only set the frame target, so every coin/spike/door event
  fired into the void on every build — solids, player, camera and
  visuals all worked, which made it look like "collision" breakage.
  One line fixes it. The self-test had a matching blind spot — its
  sensor test used the polling accessors, which need no target — so the
  events test now also asserts the **message path** delivers
  (`on b2kSensorEnter` / `on b2kContact` received exactly once /
  at-least-once via a registered contact target).
- **Self-test round 4: ground-snap + wake-on-SetVelocity.** The
  instrumented land test measured the truth: after a hard landing the
  contact solver's push-out launches a real ~7px hop (24 frames of
  airtime, down-leg at ~61 px/s) — too long for hysteresis to mask, and
  with restitution already zero. The controller now **ground-snaps**:
  grounded on *flat* ground (probe normal |x| < 0.1 — slopes exempt,
  uphill running is real upward motion), drifting upward, without
  having jumped ⇒ upward velocity zeroed at the source. External
  boosts must use `b2kPlayerJump` (the platformer's stomp bounce now
  does — the jump flag exempts it from the snap). Separately,
  **`b2kSetVelocity` now wakes the body**: raw SetVelocity does not
  (which is why `b2kPush` always called SetAwake), so a parked,
  *sleeping* kinematic gate given one velocity write stayed frozen —
  a gate that randomly refuses to open read as "the plate is flaky
  again". The platformer's stomp gate also gained a recent-airborne
  window (250 ms) so a slime sinking under the landing hero can't
  outrun the state reads.
- **Self-test round 3: landing hysteresis.** Zeroing restitution wasn't
  the whole story — the suite still counted two land ticks per jump:
  the contact solver's push-out can blip the 4px ground probe off for a
  tick around an impact, which the state machine read as a micro-fall
  and a second landing. The controller now has the genre-standard cure:
  a touchdown counts as `land` only after a real airborne stretch (3+
  ticks), and a single ungrounded blip doesn't even show as airborne
  (no one-frame jump-anim flicker on rough ground or ramp seams) —
  unless it's the controller's own jump, which still reads `jump` on
  its launch frame. `b2kPlayerOnGround()` stays raw and truthful; only
  the state classification gained hysteresis.
- **Self-test round 2: the player landed springy.** The harness's
  "land fired exactly once (got 2)" caught that controller-created
  capsules kept `b2kAddCapsule`'s default **0.2 restitution** — every
  landing rebounded ~13px (a second airborne arc: double land ticks,
  double land sounds, a faint trampoline feel). `b2kPlayerAttach` now
  zeroes bounce on bodies it creates; explicit bounces (the slime
  stomp) are unaffected. The camera test's final assert also stopped
  using a pre-`b2kCamOff` long id (group paths go stale on ungroup —
  the test now re-resolves by name).
- **First self-test run: two real Kit bugs found and fixed.** The
  harness's first hardware run (35 passes) exposed: (1) **the player's
  coyote/buffer timers ran on wall-clock time** — on a slow machine the
  90/110 ms windows silently shrink to fewer frames than designed; they
  now run on a **sim-time clock** (summed frame ms — identical under
  the live loop, frame-coherent everywhere, deterministic under
  hand-stepping); (2) **`b2kSpriteAnim`/`b2kSpriteFrame`/
  `b2kSpriteFlipped` threw on a removed control** instead of honouring
  the Kit's stale-ref tolerance — they now return empty/false. Three
  failures were the harness's own arithmetic (jump arcs at scale 40
  take ~138 frames; tests now run full arcs, settle between phases, and
  isolate each test so one throw cannot abort the suite).
- **The Kit self-test harness** —
  `examples/box2dxt-selftest.livecodescript`: one click in OXT, ~30
  seconds, a PASS/FAIL report. There is no headless OXT, so this stack
  is the project's runtime safety net: it drives the REAL Kit
  deterministically (worlds started paused and advanced by
  `b2kStepOnce`; the keyboard replaced by the new
  **`b2kInputInject`**/`b2kInputInjectOff` — scripted keys with exact
  frame timing, also useful for replays) and asserts the behaviours the
  games depend on. Every test encodes a lesson learned on real
  hardware: fixed-step determinism, frame-exact events (one enter, one
  exit, no duplicates at rest), the chain ghost rule, one-way chains,
  presence polling incl. **sleeping** bodies, `b2kKillFloor` +
  `b2kFell`, the player feel contract (run accel, grounded probe,
  tap-vs-held jump, the **coyote** and **buffer** windows, land firing
  exactly once), input edges, sprites, tones, camera adopt/goto/off,
  and teardown hygiene. Run it after any Kit change and on every new
  platform before trusting the games. The micro-game's level build is
  now also **error-proof**: the whole build runs guarded so a mid-build
  error can never leave the screen locked — it lands, named, in the HUD
  for verbatim reporting.
- **The pressure plate is polled, not counted.** Exact events unmasked
  what enter/exit *counting* had been hiding: Box2D's sensor begin/end
  around settling and sleeping bodies is precisely the edge a pressure
  plate lives on (the old duplicate-enter bug had been inflating the
  count, accidentally holding the gate open). The plate is now a pure
  graphic whose pressed state is **polled** with `b2kOverlap` each
  frame — stateless, so it cannot drift, and the broadphase includes
  sleeping bodies, so a crate that settles and sleeps keeps holding it —
  plus a 200 ms release debounce so micro-bounces don't flap the gate.
  Doctrine added to the sensor docs: **enter/exit for one-shots; polling
  for presence.** With this, no gameplay state in the demo depends on
  balanced event counting: everything is one-shot, guarded, geometric,
  or polled.
- **Frame-exact physics events (the "flaky collisions" root cause) +
  `b2kKillFloor`.** Box2D only exposes the **last step's** begin/end
  contact and sensor events, but a frame can run two fixed steps (under
  load) or zero (timer jitter) — so the old once-per-frame snapshot
  *lost* the first step's coin touches and stomps on heavy frames and
  *re-dispatched* the previous step's events on empty ones (a pressure
  plate could double-count). The Kit now **harvests events after every
  fixed step into per-frame buffers**; the `b2kContact`/`b2kSensorEnter`
  messages and all polling accessors read the same complete,
  duplicate-free frame view. New **`b2kKillFloor screenY`**: any moving
  Kit body whose centre falls below the line is destroyed instead of
  falling forever (crates thrown into pits, enemies knocked off the
  level), with a **`b2kFell ctrl`** message to the frame target first so
  games clean up bound art and table slots — the player's body is
  exempt. Hooked into the body-sync loop, so it costs nothing extra (a
  falling body is by definition a moving one). The platformer arms it at
  820px, cleans up fallen slimes/thwomps in `on b2kFell`, and replaces
  its thin level-edge segments with **thick boundary slabs** (a capsule
  driven into a thin segment can jitter or creep; a 48px box stops it
  flush).
- **Hot-path performance pass (engine-limitation aware).** The frame
  budget on a single interpreted thread goes to interpreter ops, FFI
  round-trips and property-set redraws, so all three got leaner:
  **sprite tick** now maintains a lazy *live list* (bound and/or playing
  sprites) and walks only that — a tile-heavy level's ~100 inert sprites
  cost zero per-frame work, with membership re-derived only when a
  bind/play/stop/remove actually changes it; **input** resolves friendly
  key names to keycode lists once at bind time (`b2kBindAction`/
  `b2kBindAxis`), so the per-frame action/axis queries are pure set
  scans; the **player tick** reads its nine tuning knobs and probe
  geometry from values baked at `b2kPlayerSet`/attach time and talks to
  the body through its raw handle (no per-frame ref lookups or "x,y"
  string round-trips — same math, gotcha-9 flip preserved). Example
  side: both games **throttle their HUD to 4 Hz** — the ms readout
  changed every frame, which forced a field relayout+redraw every frame,
  the single biggest avoidable cost — and the platformer's gate writes
  its kinematic velocity only when the target flips. The kit guide's
  performance section now documents the playbook (throttle HUDs, write
  on change, one clock read per handler, build heavy things once).
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
