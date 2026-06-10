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

**Status: two Win32 passes done (2026-06-10); spike v3 awaiting re-run.**
All v1/v2 results are in the decision log below. v2's S11 **confirmed** that
OXT cannot call commands with function syntax — which exposed and fixed two
latent Kit bugs (`b2kSmoothGround`, named layers via `b2kLayerBits`), the
builder's servo joint, and ~30 doc snippets teaching the broken pattern (see
CHANGELOG). v3 re-arms the remaining unknowns: **S8** (the chain one-way
verdict, previously blocked by the Kit bug), **S9** (run ~20 s for steady
state), **S10** (re-click cycles orbit/anim/bodies-only modes to attribute
the sprite cost; logs first-frame stall and the engine-copy build path),
**S11** (now with valid colour names). **To re-run:** paste the new file over
the stack script, reopen, run **S8, S9, S10 (cycling its 3 modes), S11** —
and report one line of eyes-on verdict for **S3/S4** (single clean cell? no
trails while orbiting?).

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

**Exit:** user reports the checklist; failures flip the spec's documented
fallbacks (input backend, sprite backend, one-way deferral) *before* Phase 1
code exists. Record outcomes in the decision log below. The spike file is
deleted (or kept under `examples/` clearly marked) once phases land.

The spike also logs engine intel the phases will reuse: baseline `send in 16`
timer cadence (spec §2.6 pacing), rawKeyDown auto-repeat behaviour on the
user's platform, which script-side group-creation method OXT accepts (Phase 4
needs one), and scroll-corrected `b2kGrab` mapping (the `b2kCamMouse…` math).

## Phase 1 — Input module (M)

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

Sketch now, design when Phase 4 is real:

- **Scenes/levels:** load/save level layouts (seed: the builder's
  `serializeText` record format); `b2kSceneLoad/Save/Reset`; win/lose hooks
  (the ROADMAP §4.1 goal-zone work and this converge here).
- **Audio:** `b2kSoundLoad/Play` over `play`/player objects with documented
  platform caveats; hooks from player land/jump/coin events.
- **Enemy/behaviour patterns:** patrol, chase-on-sight (`b2kRayHit` line of
  sight), hazard respawn — shipped as documented example patterns first,
  promoted to API only once two examples repeat them.
- **Builder cross-pollination:** animated sprite parts and the player as a
  placeable "kind" inside the contraption builder (its §3/§4 roadmap), making
  the builder the level editor — the long-game payoff.
- **Exit:** a complete micro-game (start screen → 2 levels → win screen) as
  `examples/`, and the "build a game" chapter of the kit guide.

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
| *(Phase 0 v3)* | *One-way platforms in v1 (chains) or deferred (mask window)* | *pending S8 re-run (unblocked by the b2kSmoothGround fix)* |
| *(Phase 0 v3)* | *Sprite cost attribution + instancing path* | *pending S10 mode cycling + copy-to-group log* |
| *(Phase 0 v3)* | *S3/S4 clip+scroll visual verdict, S9 steady-state fps + grab* | *pending re-run* |
