# Plan — Box2Dxt Game Kit

The phased implementation plan for
[docs/game-engine-spec.md](docs/game-engine-spec.md): keyboard input,
spritesheet animation, a player controller, and a camera — turning Box2Dxt +
xTalk into a working 2D game engine.

Read the spec first; this file is the *sequence*, the spec is the *what and
why*. Effort scale: **S** ≈ hours, **M** ≈ a day, **L** ≈ multi-day.

---

## Ground rules (every phase)

1. **Kit edits only in `src/box2dxt-kit.livecodescript`**, then
   `python3 tools/sync-embedded-kit.py` and commit the re-synced examples in
   the same change. New example files that embed the Kit must be added to
   `EXAMPLES` in `tools/sync-embedded-kit.py`.
2. `python3 tools/check-livecodescript.py` clean after **every** script edit
   (smart quotes, handler balance, control balance, embed drift).
3. **No native changes**: `src/box2d_lc.c` / `src/box2dxt.lcb` / ABI 4 stay
   untouched through Phase 5. Anything that seems to need C is a design smell —
   re-read the spec.
4. **No runtime claims**: every phase ends "verified statically; needs an OXT
   pass" with a concrete manual checklist for the user. A phase is *done* only
   after that pass.
5. Additive API only; the demo and contraption builder must behave identically
   after each sync.
6. Docs ride along: each phase updates `docs/kit-reference.md` (new tables),
   `docs/kit-guide.md` (one teaching section per module), and `CHANGELOG.md`.

---

## Phase 0 — OXT runtime spike (S/M) ★ gate for everything else

**Status: CLOSED (2026-06-10, four Win32 passes).** Every S-question is
answered by data; all verdicts live in the decision log below. The headline
results: `keysDown` polling is the input backend; chains are one-sided
(jump-through platforms are in); the camera viewport scrolls at the loop
ceiling; **icon-button sprites beat scroll-group sprites on every axis**
(S12 warm 40.2 fps vs 30.7, build 3.8 s vs 6.6 s, first-frame stall halved)
and are Phase 2's primary mechanism; commands must be called as statements +
`the result` (three latent shipping bugs found and fixed by that discovery);
and the idle loop ceiling is ~58–60 fps with the Phase 1 pacing fix landed.
The spike file stays in `examples/` as the hardware-acceptance harness;
re-run it on new platforms (macOS/Linux verdicts are still open, tracked as
risk R1).

One throwaway stack script that answers the spec's *(verify in OXT)* items
with on-screen instructions and an accumulating PASS/FAIL report. It **embeds
the Kit** (registered in `tools/sync-embedded-kit.py`) because S7–S10 must
exercise the *actual Kit code paths* the later phases build on — `b2kRayHit`
semantics, `b2kWall`/chain sidedness, the real `b2kStep` loop under load —
not re-implementations of them:

| # | Question | Pass looks like |
|---|---|---|
| S1 | `the keysDown` reports held arrows/WASD/space, multiple at once, on each platform | Live readout matches fingers; chords show all codes |
| S2 | Letter keysym case shift (`w` vs `W` with Shift) | Both codes observed, noted |
| S3 | Unadorned lockLoc group clips, `hScroll`/`vScroll` selects cells of an inner image, no scrollbars appear | A 4-frame strip cycles cleanly at 10 fps |
| S4 | S3 under `acceleratedRendering` true + group `layerMode "dynamic"` | No artifacts; smooth |
| S5 | Animated GIF: `frameCount` / settable `currentFrame` / `repeatCount` 0 and -1 | Manual stepping works |
| S6 | `flip image` horizontal on a copy | Mirrored copy renders |
| S7 | `b2kRayHit` cast from inside a capsule downward ignores self, returns ground + sane normal | Hit reports the floor control |
| S8 | One-way: capsule lands on a correctly-wound `b2kWall`/chain from above, passes from below | Both behaviours |
| S9 | Camera: card-sized group, 60 fps scroll while 20 bodies tumble | No smear, frame time < 16 ms |
| S10 | Perf scene: 25 group-scroll sprites animating + 25 dynamic bodies | ≥ 55 fps (the send-in-16 ceiling) on the user's machine |
| S11 | Can Kit *commands* be called with function syntax (`get b2kSpawnBall(...)`, as the Kit header/docs show), or only as statements + `the result`? | Two report lines; settles the calling convention for docs and examples |
| S12 | Icon-button sprites (shared frame images, `the icon` flip) vs S10's scroll-groups, identical scene | Warm fps + build ms + first-frame ms, directly comparable to S10 mode 1 |

**Exit:** user reports the checklist; failures flip the spec's documented
fallbacks (input backend, sprite backend, one-way deferral) *before* Phase 1
code exists. Record outcomes in the decision log below. The spike file is
deleted (or kept under `examples/` clearly marked) once phases land.

The spike also logs engine intel the phases will reuse: baseline `send in 16`
timer cadence (spec §2.6 pacing), rawKeyDown auto-repeat behaviour on the
user's platform, which script-side group-creation method OXT accepts (Phase 4
needs one), and scroll-corrected `b2kGrab` mapping (the `b2kCamMouse…` math).

## Phase 1 — Input module (M)

**Status: shipped and user-verified (2026-06-11), through the RC demo.**
Built 2026-06-10 (the full input surface below plus the pacing fix); the
platformer demo is driven entirely by this module, and its Phase 2+4
user-verified pass exercised held-axis running, chords, jump press/release
edges and pause/resume on real hardware — the module's own checklist rode
along with it.

- **Build:** `b2kInputOn/Off`, `b2kInputTick` (keysDown sample + diff),
  key-name map, `b2kKeyIsDown/Pressed/Released`, `b2kKeysHeld`,
  `b2kBindAction`, `b2kActionIsDown/Pressed/Released`, `b2kAxis`/`b2kBindAxis`,
  `b2kFrameMS`. Wire `b2kInputTick` into `b2kStep`/`b2kStepOnce` per spec §8.
- **Prove it:** start the new flagship example
  `examples/box2dxt-platformer.livecodescript` (embeds the Kit; add to sync
  tool): flat ground, a spawned capsule, arrows/WASD set velocity, space
  impulses a hop, on-card readout of `b2kKeysHeld()`. Ugly but driveable.
- **Static gates** (rule 2) + **OXT checklist:** drive with chords (left+jump),
  hold both directions, alt-tab away mid-hold (released edge fires on return —
  the polling model self-heals), pause/resume.
- **Exit:** capsule drives smoothly at 60 fps; no auto-repeat stutter.

## Phase 2 — Sprite module (M/L)

**Status: shipped and user-verified (2026-06-11), together with Phase 4.**
Built on the icon-button backend per the spike verdict, extended with a
**TextureAtlas XML loader** for the Kenney-format `Spritesheets/` pack
(named frames like `character_beige_walk_a`), per-sheet display **scaling**
(`b2kSheetScale`), lazy slicing/mirroring, `b2kSpriteBind`, and
`b2kSpriteMoveTo`. The platformer example became the **release-candidate
demo** — scrolling camera, win dialogue, checkpoint, riding Thwomp, two
slimes, hazard fly, plate-gate puzzle, confetti — see the decision log.

- **Build:** sheet registry (`b2kSheetLoad/FromImage/Frames`), `b2kAnimDef`,
  sprite factory (`b2kSpriteNew`, clipped-group mechanism), `b2kSpritesTick`,
  `b2kSpritePlay/Stop/Anim/SetFrame/Frame/FPS/FlipH/Flipped/OnFinish/Remove`,
  GIF backend (`b2kSpriteFromGIF`), lazy mirrored sheets, dynamic layerMode,
  `b2kClear`/`b2kTeardown` integration.
- **Assets:** produce the tiny CC0 placeholder sheet (idle 2f, run 6f, jump 2f,
  fall 2f at 32×48) and embed as base64 + `b2kSheetFromImage` in the example.
- **Prove it:** platformer example v2 — the Phase 1 capsule becomes an animated
  sprite bound via `b2kAddCapsule`; a free-standing looping GIF sprite and an
  `OnFinish` one-shot (e.g. an explosion that removes itself) on the card.
- **OXT checklist:** anim plays at its own fps independent of sim rate; flip
  faces travel direction; 25-sprite perf scene from S10 re-run *inside* the
  Kit; `b2kClear` leaves no orphan groups; GIF sprite parity.
- **Exit:** spec §5 table fully live; perf within S10 numbers.

## Phase 3 — Player controller (M/L) ← the headline feature

**Status: shipped and user-verified (2026-06-11).** Verified twice over:
the platformer's feel checklist on real hardware, and the self-test's
player contract (run accel, grounded probe, tap-vs-held apex, coyote and
buffer windows on the sim clock, single land tick, slope climb, maxFall,
ground-snap, kill-floor exemption) — all green. As-built additions beyond
the spec: sim-time feel windows, landing hysteresis, ground-snap with
slope exemption, zero-restitution owned bodies, `b2kPlayerJump` as the
required path for external boosts. Originally: The full surface
below landed in the Kit (loop order: input → player → sprites → camera),
and the platformer demo's hand-rolled movement layer (~53 lines: velocity
tick, jump press/release, two-ray ground probe) collapsed into four calls —
`b2kPlayerAttach` + `b2kPlayerAnims` + two `b2kPlayerSet`s — exactly the
shrink the plan predicted. The level gained a walkable slope mound (26.6°
ramp tiles over a one-sided chain, plain-polygon fallback) with a 7th coin
on its plateau, and the HUD now reads controller state, a land counter and
a sleep anomaly flag. The demo's banner carries the 8-point feel checklist
below; run it in OXT and report.

- **Build:** `b2kPlayerMake/Attach/Set/Get/Anims/OnGround/State/Facing/Jump/`
  `Control/Remove`, `b2kPlayerTick` (axes → accel-clamped vx; ray ground probe
  with slope normal test; coyote + buffer timers; jump-cut on release; maxFall
  clamp; state machine → `b2kSpritePlay`/`FlipH`), `b2kSetSleepEnabled`,
  defaults table from spec §6.
- **Prove it:** platformer example v3 — `b2kPlayerMake` + `b2kPlayerAnims`
  replaces the hand-rolled Phase 1/2 movement (the diff should *shrink* the
  example: that is the API working); level gains a slope (`b2kChain`), steps, a
  one-way ledge (if S8 passed), a moving platform, coins (sensors + counter),
  spikes (sensor → respawn).
- **OXT checklist (feel-focused):** no wall-stick while airborne against a
  wall; slope walk ≤ maxSlope without sliding; coyote jump off a ledge edge;
  buffered jump while landing; tap vs held jump heights clearly differ; land
  state fires once; player never sleeps after standing still for minutes;
  state/anim transitions clean at 60 fps.
- **Exit:** a stranger can paste the example and immediately *play* it; tuning
  knobs all respond via `b2kPlayerSet`.

## Phase 4 — Camera (M)

- **Build:** viewport group lifecycle (`b2kCamOn/Off/Adopt`), spawn-into-group
  routing, `b2kCamTick` (follow + lerp + deadzone + bounds + shake),
  `b2kCamFollow/Unfollow/Deadzone/Bounds/Goto/Pos/Shake`,
  `b2kCamMouseX/Y`, parallax recipe in the kit guide.
- **Prove it:** platformer example v4 — level widens to ~3 cards; camera
  follows with deadzone and bounds; one parallax background group; HUD (coin
  counter) outside the viewport; `b2kCamShake` on landing hard (uses hit speed
  or fall velocity); mouse-grab still works through `b2kCamMouse…`.
- **OXT checklist:** smooth scroll at 60 fps (S9 numbers inside the Kit); walls
  bound the level not the card; grab/click accuracy while scrolled; shake
  decays and re-centres; `b2kCamOff` restores a sane card.
- **Exit:** scrolling platformer, playable start to finish.

## Phase 5 — Game scaffolding (L, design-first)

Phase 4 is real, so the design work is unblocked. The chunks land
separately, each PR-sized, in rough value order:

- **Audio — SHIPPED and user-verified (2026-06-11).** `b2kSound*` over
  imported audioClips (`play audioClip`: the one LC sound path with no
  external media dependency; one clip at a time, documented) plus
  `b2kToneMake`, a pure-script WAV synthesizer (square/sine, note lists,
  per-note decay) so self-contained examples have SFX with zero asset
  files. Mute survives teardown; engine-global volume wrapped; a play
  failure trips a dead-flag (silence, never errors; `b2kSoundStatus()`).
  The platformer plays eight synthesized cues (jump, land — off the
  player's land state — coin, stomp, hurt, checkpoint, gate, win); M
  mutes. Player objects for streamed music stay future work.
- **Enemy/behaviour patterns — IN THE DEMO as documented patterns.** The
  platformer's indexed tables are the plan's "example patterns first":
  `pfMakeSlime` (patrol + stomp/spike kinds), `pfAddMover` (bodiless
  sine-path hazards: bee/fly/sweeping saw), `pfMakeThwomp` (arm/fall/
  rest/rise lifecycle, rideable, draggable). Promote to `b2k` API once a
  second example repeats them (the micro-game below is that test).
- **Scenes/levels — design probe SHIPPED and user-verified inside the micro-game.**
  Levels are data: one `verb args` line per object (`slab`, `ledge`, `coin`,
  `spike`, `sweep`, `door`, `text`, `spawn`, `bounds`), interpreted by a
  ~100-line example-side `mgBuild`; the `ledge` verb ghost-pads its chain
  automatically. Win/lose hooks ride sensors + the frame hook. Whether this
  is promoted to `b2kScene*` API (and merged with the builder's
  `serializeText` lineage) gets decided from how the pattern holds up in use.
- **Builder cross-pollination:** animated sprite parts and the player as a
  placeable "kind" inside the contraption builder (its §3/§4 roadmap), making
  the builder the level editor — the long-game payoff.
- **Exit — SHIPPED and user-verified (2026-06-11):** the micro-game
  (`examples/box2dxt-microgame.livecodescript`): start screen → 2 levels →
  win screen, on `b2kPlayerMake` (the green-field path the platformer
  doesn't exercise), hero sheet embedded as base64, all sounds synthesized
  — paste one file, click, play. Plus the kit guide's new "Building a whole
  game" chapter (§20) walking its four ideas: the mode machine gated by
  `b2kPlayerControl`, levels-as-data, the one-call player, and
  rules-as-hooks.

---

## Sequence and dependencies

```
Phase 0 (spike) ──► Phase 1 (input) ──► Phase 3 (player) ──► Phase 4 (camera) ──► Phase 5 (game)
                └─► Phase 2 (sprites) ──┘
```

Phases 1 and 2 are independent of each other (both need only Phase 0) and can
land in either order or in parallel branches; Phase 3 needs both. Each phase is
one PR: Kit edit + sync + example + docs + changelog, statically verified, then
user-confirmed in OXT before the next begins.

## Decision log

| Date | Decision | Why |
|---|---|---|
| 2026-06-10 | All modules in the **single Kit**, not a second gamekit file | Loop-internal ticks; one embed region; project philosophy (spec §3.1) |
| 2026-06-10 | Input = **poll `the keysDown` + frame diff**; events only as fallback | No auto-repeat/focus/frontscript complexity; edges fall out of the diff (spec §4) |
| 2026-06-10 | Sprites = **group-clip + scroll**; GIF secondary; icon-flip plan B | Zero-copy, alpha-correct, engine-rendered (spec §2.2/§5) |
| 2026-06-10 | Player = **capsule, fixed rotation, velocity-driven, ray-grounded** | Genre-standard; everything required already exists in the Kit (spec §6) |
| 2026-06-10 | Camera = **scrolled viewport group**; Kit draw path untouched | Card coords preserved inside scrolled groups (spec §7) |
| 2026-06-10 | **No native/ABI changes** through Phase 5 | Raw layer already covers Box2D v3.1 (spec §1.1) |
| 2026-06-10 | Spike **embeds the Kit** (added to the sync tool), instead of a Kit-free card script | S7–S10 must test the real Kit paths (rays, walls, loop) the phases depend on; a raw-`b2*` re-implementation would validate the wrong code |
| 2026-06-10 | Spec gains §2.6 single-threaded budget; Phase 1 adds the `in max(1, 16 − elapsed)` pacing fix | Honest answer to "is this usable single-threaded": yes within a stated envelope, measured by S9/S10 |
| 2026-06-10 | **Spike v1 (Win32) results.** keysDown polling LOCKED as the input backend (3-key chords work; auto-repeat = 21 rawKeyDowns vs 5 rawKeyUps while held, so events are noisy and polling is immune). `create group` from script works (plan A) — camera/sprite groups unblocked. `flip image` works (byte-verified) — mirrored sheets unblocked. Ray ground-probe semantics exact (self-skip, dist 160.000005, normalY −1) — player design locked. | Spike report lines 11–21 |
| 2026-06-10 | **Win32 `send in 16` cadence ≈ 18 ms ⇒ ~55 fps ceiling**; S9 saturated it (55.2 steady; min 25.8 was warm-up/build). Phase 1 pacing fix (`in max(1, 16 − elapsed)`) promoted from optional to **required**. | Spike S0/S9 |
| 2026-06-10 | **`b2kWall`/`b2AddSegment` segments are two-sided** (both windings "blocked from below") — one-way platforms cannot use plain segments. Chains pending S8 v2; fallback = brief upward mask window. api-reference.md + kit-reference.md corrected. | Spike S8 v1 |
| 2026-06-10 | **Suspected: function syntax on commands (`get b2kSpawnBall(...)`) throws.** v1's two silent failures (S8 chain phase, S10) were exactly its two `get <command>(...)` sites — the S8 one swallowed by the Kit loop's protective try/catch. Spike v2: statement + `the result` everywhere, error capture logged to the report, S11 probes the syntax directly. Kit header/docs fix pending S11. | Failure-pattern analysis |
| 2026-06-10 | **Spike v2 (Win32) results.** S0 re-measured clean: 16.5 ms avg / 17–18 max ⇒ idle ceiling ~58–60 fps (v1's 18/3268 was settling noise). S2 case-shift CONFIRMED (w=119 and W=87 — the Kit binds both). S5 GIF full PASS (frameCount 4; stop; manual stepping wraps in order) — GIF sprite backend viable. S6/S7 re-passed. | Spike report v2 |
| 2026-06-10 | **`get <command>(...)` CONFIRMED broken in OXT** (S11 throws at the call line; never enters the handler). Statement + `the result` is the project-wide calling convention. Found+fixed: Kit `b2kSmoothGround` (always threw), Kit `b2kLayerBits` (named collision layers always threw), builder servo joint (never created), README/kit-reference/getting-started/kit-guide/Kit-header snippets (~30). Spawn handlers also made tolerant of invalid colour names (S11's form-1 throw was CSS "teal", not the convention). | Spike v2 S11 + traces; CHANGELOG |
| 2026-06-10 | **S10 sprite-perf flag.** Build 6377 ms (~250 ms/sprite, script imageData path); long first-frame stall before sampling began; warm avg 33.6 / min 27.4 with 25 sprites + 25 bodies — well under the ceiling. v3 instruments: mode cycling (orbit/anim/bodies-only), first-frame latency log, engine `copy…to group` build path. Phase 2's instancing strategy hangs on this. | Spike v2 S10 |
| 2026-06-10 | **Spike v3: one-way platforms SOLVED — chains are one-sided** (S8 chain: "rose through, landed on top"; walls re-confirmed two-sided on both windings). The platformer gets jump-through ledges via `b2kChain`/`b2kSmoothGround`, top surface listed right-to-left. R5 resolved. | Spike v3 S8 |
| 2026-06-10 | **S9 camera PASS at the loop ceiling** (warm avg 50.6, last 57.3 and climbing toward the ~58–60 idle ceiling). S11 re-run clean: statement + `the result` works; get-command definitively broken. R9 closed. | Spike v3 |
| 2026-06-10 | **Sprite cost attributed (S10 mode cycling):** bodies-only warm 54.2 ≈ ceiling-ish; + 25 scroll-anims ≈ 39–44; + 25 orbit moves 29.8. One-time **14.6 s first-frame stall** in mode 1 (bulk dynamic-layer creation under acceleratedRendering; 36 ms once warm). Engine `copy…to group` works but builds no faster (~220–285 ms/sprite either path). v4 adds **S12** (icon-button backend, identical scene) — its warm avg picks Phase 2's primary mechanism; pooling + build-before-accel land in Phase 2 regardless. | Spike v3 S10 |
| 2026-06-10 | Spike stage geometry overlapped the chrome (S9 viewport under the button column; S10 arena top wall under the status bar) — user report; v4 shifts the geometry clear. | User report |
| 2026-06-10 | **Spike v4: icon-button sprites WIN — Phase 2's primary backend.** Identical scene: S12 warm avg 40.2 fps vs S10 mode 1's 30.7 (+31%), build 3785 ms vs 6579 ms, first-frame stall 6.6 s vs 13.5 s. Shared frame images also beat per-sprite sheet copies on memory. Scroll-groups stay documented as the secondary mechanism (sheet-direct cases); neither hits the ceiling at 25 *moving* sprites on this hardware, so Phase 2 also pools at load, builds before enabling acceleration, and documents a per-scene budget. | Spike v4 S12 vs S10 |
| 2026-06-10 | **Phase 0 CLOSED.** S3/S4 visuals: no artifact/trail reports across four runs (and the icon backend doesn't clip at all); final eyes-on confirmation rides the Phase 2 example rather than a fifth spike pass. The spike stays in `examples/` as the acceptance harness for new platforms (macOS/Linux open, risk R1). | All spike passes |
| 2026-06-10 | **Phase 1 built:** Kit Input module (18 handlers), paced loop (`in max(1, 16 − elapsed)`), `b2kFrameMS`, and `examples/box2dxt-platformer.livecodescript` (axis run, edge jump + release-cut, ray grounded check, one-way ledge). Statically verified; awaiting the OXT pass. | Phase 1 commit |
| 2026-06-10 | **User shipped the asset pack** — Kenney-format atlases (`Spritesheets/`, PNG + TextureAtlas XML, named non-grid regions at 1px pitch, 1x and 2x variants) merged to main. Consequence: Phase 2 gains a first-class **atlas loader with named frames** (`b2kSheetLoadAtlas`) alongside grid sheets; animations reference frame names. | main merge c95e401 |
| 2026-06-10 | **Phase 4 (camera) pulled forward of Phase 3, by user request,** to ship a scrolling showcase level. Built: the full `b2kCam*` surface from spec §7 (viewport group, follow/lerp/deadzone/bounds/shake, world-px mouse mapping, spawn auto-routing into the view, teardown integration, sweep-safe). | Phase 4 commit; user request |
| 2026-06-10 | **Phase 2 hardening from first OXT runs:** (a) file sheets load as image CONTENT (binfile), not filename references — referenced images size lazily when hidden, which broke the slicer stride; (b) per-sheet **display scaling** (`b2kSheetScale`); (c) **orphan sweep** on teardown kills ghost sprites after a stack reopen; (d) per-item art fallbacks + on-screen load diagnostics. | OXT runs + user reports |
| 2026-06-10 | **Phase 2 built:** Kit Sprite module (~26 handlers) on the icon-button backend — lazy region slicing, shared frame images, lazy mirroring, `b2kAnimDef` names/ranges, `b2kSpriteOnFinish`, `b2kSpriteBind` (invisible body + bound art = collision independent of art size), GIF backend, `b2kClear`/`b2kTeardown` lifecycle. Platformer example v2: atlas hero (idle/walk/jump/hit), coin sensors, bee path sprite, saw hazard with hit-then-respawn chain; placeholder fallback keeps it runnable without the asset folder. Statically verified; awaiting the OXT pass. | Phase 2 commit |
| 2026-06-11 | **The camera's hardest bug: grouped-loc semantics.** Symptom: the hero "sped up past the middle" and outran a scrolling view. Cause: OXT reports/sets grouped locs SCROLL-ADJUSTED, so per-frame world-coordinate writes cancelled the pan. Fix: `b2kCamOn` probes the model; every in-viewport write compensates (`b2kCamShiftX/Y`); `b2kSpriteMoveTo` for manual moves. Also fixed along the way: bounds-clamp write-back, no compositor scrolling cache (GPU surface limits froze the picture past ~2048px content), level-spanning anchor, never-offscreen snap + real-scroll failsafe, centre-locked follow. CLAUDE.md gotcha #12. | User runs, camera rounds 1–6 |
| 2026-06-11 | **Compile gotchas found by OXT, now gated/documented:** the dangling else (single-line `if` before a bare `else` — checker gate added; CLAUDE.md #10) and `local` declarations nested in control blocks breaking the whole script (CLAUDE.md #11 — broke the intro-pan rework, which was reverted). | OXT compiles |
| 2026-06-11 | **Teardown order fixed:** sprites must be wiped BEFORE the viewport dissolves (their stored long ids embed the group path); sprite removal made stale-ref-proof; example `b2kClear`s spawned bodies pre-teardown and guards re-entrant restarts. Fixed Reset/Play-again breakage. | User report |
| 2026-06-11 | **The demo is the release candidate.** Win dialogue (all coins + flag: time, falls, confetti, Play again), checkpoint flag, riding Thwomp (underside-kill, head rideable, slow kinematic rise), second slime, hazard fly, two-cloud bonus route, splash, R/ESC keys. The opening camera pan was CUT (the rework broke an OXT compile; reverted) — the demo opens with a splash beat. **Phase 3 (player controller) is next.** | This commit |
| 2026-06-11 | **Phase 3 built:** Kit Player module (20 handlers incl. internals) + `b2kSetSleepEnabled`; `b2kPlayerTick` wired between input and sprites in both loop paths; demo movement collapsed to 4 declarative calls; slope mound + 7th coin + state/lands/asleep HUD. Statically verified; awaiting the OXT feel pass. | Phase 3 commit |
| 2026-06-11 | **Controller state is a singleton** (flat `sPlay*` locals, one player), matching the argless public API (`b2kPlayerOnGround()` etc.). Spec principle 4's per-control keying is deferred with multi-player (the refactor is mechanical: key the locals by ref, add an optional ctrl arg). | Phase 3 design |
| 2026-06-11 | **`b2kPlayerControl false` = observe-only:** the tick keeps state/ground/facing fresh but writes neither velocity NOR animations (only the maxFall clamp stays live). Rationale: the demo's hit pose and win dance need manual `b2kSpritePlay` to survive; a controller that kept animating would stomp them on the next tick. Cutscene walks animate via manual `b2kSpritePlay "walk"`. | Phase 3 design |
| 2026-06-11 | **Ground probe is suppressed while the controller's own jump is still rising** (`sPlayJumping` and vy upward). Without it, the launch frame could re-ground at low jumpSpeed and — the real case — rising THROUGH a one-way chain (the bridge route) phantom-grounded mid-flight. Plain upward motion is NOT suppressed: running up a slope rises while genuinely grounded (upslope vy ≈ vx·tan θ, ~140 px/s on the mound — any naive vy threshold would misfire). | Phase 3 design |
| 2026-06-11 | **Player tuning survives `b2kClear`, dies with `b2kTeardown`/`b2kPlayerRemove`** — tuning is config (like input bindings, which clear also keeps), not world state. Spec §8's "clear removes sprites/player" applies to the controller *binding*, which clear does drop. | Phase 3 design |
| 2026-06-11 | **Ramp art fixed by measuring the PNG, not guessing names.** Decoded the Kenney tiles sheet offline: `ramp_short_a/b` are a 45° pair (filled + full diagonal) drawn DESCENDING left-to-right; `ramp_long_a/b` are the 26.6° halves that match the mound's chain. The mound now uses mirrored long ramps for ascent, long ramps for descent, and dirt-centre ground tiles beneath so the hill reads as one mass. Rule going forward: verify atlas art geometry before placing it. | User report ("ramps wrong/weird") |
| 2026-06-11 | **Demo rebuilt as a collect-them-ALL puzzle platformer** (user direction): 4608px traditional left-to-right level, 12 coins each verified reachable against the jump arc (154px apex), drag-physics as puzzle verbs (crate→plate; a resting thwomp is draggable for 2.6s and rises from where you park it). New foes on existing mechanisms only: spike slime (unstompable), sweeping saw (bodiless sine mover), second thwomp. Enemy/trap/mover state generalized to indexed tables so a new foe is one `pfMake…` line. | User direction; this commit |
| 2026-06-11 | **Sheet loaders generalized beyond Kenney** (user requirement): grid sheets take margin/spacing; frame size 0 = source-only registration; `b2kSheetAddFrame` names arbitrary regions (the no-XML packed-sheet path); `b2kSheetFrameNames` for atlas introspection. No new mechanism — regions were always the internal model; this exposes authoring them. | User requirement; this commit |
| 2026-06-11 | **Phase 5 opened with audio; backend = audioClips + script-synthesized WAVs.** `play audioClip` needs no external media layer and an imported clip is stack-embedded — the only sound path that keeps examples self-contained; `b2kToneMake` removes the asset problem entirely (8-bit mono 22050 Hz WAV built in script, hand-rolled little-endian packers, temp-file import, ~23k samples for the demo's 8 cues). One-clip-at-a-time is documented, not fought (suits retro SFX). Failures degrade to silence via a dead-flag; mute is a preference surviving teardown; teardown sweeps `b2ksnd_` clips like sprite orphans. Streamed music via player objects deferred. | Phase 5 audio commit |
| 2026-06-11 | **Phase 5 sequencing:** audio first (biggest feel win for the now-good demo), enemy patterns declared satisfied as in-demo documented patterns (indexed tables; promotion to API waits for the micro-game to repeat them), scenes next, then builder cross-pollination and the micro-game exit. | Phase 5 kickoff |
| 2026-06-11 | **OXT compile gotcha #13 found by the audio module:** `import audio clip from file` fails to compile ("bad image type") — the type token is the single word `audioClip` (prose in the LC dictionary spells it as two words; the parser doesn't). Fixed both import sites; CLAUDE.md gotcha added. | User OXT compile |
| 2026-06-11 | **The chain GHOST RULE, surfaced by the rebuilt level:** an open Box2D chain collides N points as N−3 segments — the first and last segments are ghost anchors. The original level obeyed it implicitly (chains always ran one tile past the art; that's also why `b2kChain` says ">= 4 points"); the rebuild placed endpoints AT the art edges, making bridge ends, cloud edges and BOTH mound ramps intangible ("falls through on the left side", "collisions occasionally do not work"). All chains re-padded (mound = 6 points so its three real segments collide); rule documented in the Kit comment, kit-reference and kit-guide (whose own example used to violate it). | User OXT runs |
| 2026-06-11 | **Stomp detection moved off velocity onto controller state.** Contacts dispatch after the physics step, when the solver has already absorbed a clean stomp's impact — `vy > 40` read ~0 and hurt the hero instead of squashing. Now: squash when this frame's or last frame's player state is land/fall (velocity kept as fallback) + the existing above-the-slime position gate. General lesson: judge gameplay intent from controller state, not post-solve velocities. | User OXT runs |
| 2026-06-11 | **Thwomps re-arm in place** (user direction): the rise ends with set-static at the CURRENT x — no teleport home (it read as vanish/reappear and undid drag-repositioning). `gBlockHomeX` removed. | User direction |
| 2026-06-11 | **Optimization round:** sprite tick skips inert sprites (no bind + no anim) before the try/catch — the ~100 static tiles now cost two array reads each per frame; sounds persist across `b2kTeardown` (resets skip ~0.25s of tone re-synthesis; clips are KBs); mover tick reads the clock once. Declined as not-worth-it: caching `b2kPlayerGet` lookups (µs), reducing ground tiles (visual cost), rendering-config changes (not statically verifiable). | This commit |
| 2026-06-11 | **Phase 5 exit built: the micro-game** (start → 2 levels → win, one pasteable file, zero external assets) + the guide's "Building a whole game" chapter. The scenes/levels design shipped as the micro-game's example-side data format (verb-per-line text + a small interpreter) rather than Kit API — per the promote-once-repeated rule, `b2kScene*` waits until a second game wants the same format. `b2kPlayerMake` gets its first real exercise (the platformer adopts; this creates). Statically verified; awaiting the OXT pass. | Phase 5 exit commit |
| 2026-06-11 | **Loop hardening found by the micro-game design: `b2kStep` now reschedules with ITS OWN generation (pGen), not the live sGen.** A world rebuild from inside a frame (the door sensor advancing a level) changes sGen mid-frame; rescheduling with the new value would clone the loop and double-step forever. With pGen the stale instance dies at the guard. The micro-game still defers its rebuild out of the frame (`send … in 80 ms`) — belt and braces, and the door chime gets its beat. | Micro-game design review |
| 2026-06-11 | **WAVE 0 COMPLETE: the asset dump catalogued; the content plan expanded.** ~900 frames across three Kenney families inventoried in `docs/expansion-prep.md`: the 70px classic set is PRIMARY (six terrain biomes with slopes/halves, buttons/levers/springboards/keys+locks/doors/ladders/liquids/ropes/?-boxes, the 25-species enemy sheet incl. bat/ghost/piranha/mimic/crushers, p1-p3 players, hearts-and-digits HUD); the 128px deluxe set supplies alternate biomes (planet) and five ALIEN player skins with climb/swim frames; `spritesheet_complete.xml` is an orphan (PNG absent, no content loss). Decisions: world grid 70px; **SPRITE-ONLY visuals policy** — no new plain LC graphics for game art, plain graphics survive only as invisible physics hosts and inside frozen fallbacks; the roadmap grows to 10 player actions (incl. climb/swim/duck), a 14-archetype bestiary, 7 biomes, and 8 waves ending in builder cross-pollination. | Asset upload; this commit |
| 2026-06-11 | **The plate's true root cause: broadphase fattening.** The polled plate read pressed from frame one — `b2kOverlap` queries fattened broadphase boxes (~0.1m), so the pad's own FLOOR overlapped the region permanently. Fix: `b2kOverlapMoving` (statics filtered — what "pressed" means); harness v8 adds the empty-over-bare-floor assert the old presence test lacked (it only ever asserted positives). Doctrine refined: presence = poll *Moving*. | User report; harness v8 |
| 2026-06-11 | **FINAL GREEN BOARD (harness v7, ~93 assertions, all pass; both games user-verified).** Phases 0–5 closed on Win32 except builder cross-pollination (deferred to the content phase, where sprite parts arrive naturally). Docs swept current; the spec marked implemented; `docs/expansion-prep.md` created — the intake plan for the Kenney asset dump and the enemy/player-action expansion. Content phase is GO. | This commit |
| 2026-06-11 | **Green board (user): self-test all-pass, platformer good, micro-game plays both levels.** Harness then doubled (user direction: more robustness vs LC/OXT surprises): +6 suites/~40 asserts — engine contracts (mod/bytes/strides/chunks/relayer-id/playLoudness…), materials+joints, filtering (incl. named-layers regression), queries, sheet extras (scale/margin/AddFrame/mirror images), player slopes+maxFall+kill-floor exemption. Content phase (Kenney pack) is GO on the next all-pass. | User report; this commit |
| 2026-06-11 | **The micro-game mystery solved: a missing `b2kContactTarget`.** Sensor/contact MESSAGES go to the contact target; the micro-game set only the frame target — every sensor event fired into the void (coins, spikes, door dead; solids fine) across every build tested. The harness missed it because its sensor test polls (no target needed): the events test now asserts the message path too. Lesson: the harness must cover every DELIVERY mechanism, not just every event source. | User reports; code audit |
| 2026-06-11 | **Self-test round 4: the double land was the SOLVER's push-out hop, measured** (instrumented test: land at vy 460 falling, then 24 frames later at vy 61 — a real ~7px rebound with restitution 0). Fix = GROUND-SNAP in the controller: grounded + flat (probe |normalX| < 0.1; slopes exempt) + rising + not jumping ⇒ vy zeroed. External boosts go through `b2kPlayerJump` (stomp bounce converted). Plus `b2kSetVelocity` now wakes (raw SetVelocity never did — a sleeping parked kinematic gate with one cached write stayed frozen = "plate flaky again"). Doctrine reinforced twice over: windows/polls over instantaneous reads; setting a velocity means move, so wake. | Fourth self-test run (user) |
| 2026-06-11 | **Self-test round 3 (50/51): landing hysteresis.** Bounce 0 wasn't sufficient — solver push-out blips the probe for a tick around impacts, reading as micro-fall + second land. State machine now requires 3+ airborne ticks for `land` and 2+ to show airborne at all (own jumps exempt: instant `jump`). Kills double land sounds and one-frame anim flicker on seams; `b2kPlayerOnGround()` stays raw. | Third self-test run (user) |
| 2026-06-11 | **Self-test round 2 (48/50): the player capsule kept the default 0.2 restitution** — every landing was a ~13px rebound (double land ticks/sounds, springy feel since Phase 3 day one). Controller-owned bodies now get bounce 0 alongside friction 0.08. The camera-test throw was a stale long id after `b2kCamOff` (group paths dissolve) — test re-resolves by name. | Second self-test run (user) |
| 2026-06-11 | **The harness's first run paid out instantly: 35 pass, 5 fail → 2 real Kit bugs.** (1) Player coyote/buffer timers were WALL-clock — windows shrink in frames on slow machines; now a SIM-TIME clock (summed sFrameMS: identical live, deterministic hand-stepped). (2) Sprite getters threw on removed controls — now stale-safe per the Kit's own tolerance principle. The other 3 were harness arithmetic (full jump arcs at scale 40 ≈ 138 frames; settle between phases; per-test isolation added so one throw can't abort the suite). | First self-test run (user) |
| 2026-06-11 | **The self-test harness is the new robustness backbone** (user direction: "rock solid, reliable, robust"). `examples/box2dxt-selftest.livecodescript`: deterministic in-OXT regression suite — paused world + `b2kStepOnce` hand-stepping + the new `b2kInputInject` scripted keyboard — encoding every hardware-learned lesson as an assertion (events, ghost rule, one-way, presence/sleep, kill floor, player feel incl. coyote/buffer windows and the single land tick, sprites, tones, camera, teardown). Run after every Kit change and on each new platform (the R1 acceptance path). Kenney content pack (new enemies, player actions) queued BEHIND a green self-test + micro-game pass. | User direction; this commit |
| 2026-06-11 | **Pressure plate converted to presence POLLING** (user report: plate flaky after exact events). Exact events unmasked what duplicate enters had been hiding — sensor begin/end around settling/sleeping bodies drifts a counter. New doctrine, documented in both kit docs: enter/exit messages for ONE-SHOT triggers; `b2kOverlap` polling for PRESENCE (stateless, sees sleeping bodies), plus a ~200ms release debounce for feel. Demo audit: with the plate converted, no gameplay state depends on balanced event counting anywhere (coins/checkpoint/goal = one-shot + guarded; stomps = state-based; thwomps/movers = geometric; plate = polled). | User OXT runs |
| 2026-06-11 | **Event loss root-caused: Box2D exposes only the LAST step's events, and frames run 0..n steps.** A 2-step frame lost the first step's coin/stomp events; a 0-step frame re-dispatched (duplicated) the previous step's — together, the "occasional" collision flakiness that survived the chain fix. The Kit now harvests events after EVERY fixed step into per-frame buffers; messages and pollers read one complete, duplicate-free frame view. Plus `b2kKillFloor`/`on b2kFell` (movers below the line are destroyed, player exempt, zero-cost hook in the move-event sync) and thick boundary slabs replacing the platformer's thin edge segments (capsule-vs-segment creep). | User OXT runs |
| 2026-06-11 | **Final hot-path pass (user direction: "optimize around the engine's limitations").** The three real costs on a single interpreted thread: interpreter ops, FFI round-trips, property-set redraws. Landed: sprite-tick LIVE LIST (lazy, dirty-flagged — per-frame cost no longer scales with inert tiles), bind-time keycode resolution for actions/axes, player-tick knob+probe caches baked at set/attach + raw-handle velocity I/O (same math), 4 Hz HUD throttle in both games (an every-frame ms readout = an every-frame field relayout+redraw), gate velocity written on change only. The guide's §17 now carries the playbook. Declined again: rendering-config changes (not statically verifiable). | User direction; this commit |
