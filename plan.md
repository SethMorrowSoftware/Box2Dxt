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

**Status: built — awaiting OXT results.** Paste
`examples/box2dxt-spike-gamekit.livecodescript` into a new stack's **stack
script** and reopen the stack; run the numbered test buttons top to bottom and
paste the report field's contents back.

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
| S10 | Perf scene: 25 group-scroll sprites animating + 25 dynamic bodies | ≥ 55 fps on the user's machine |

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
| *(Phase 0)* | *Sprite inner-image sharing: filename vs data copy* | *pending spike* |
| *(Phase 0)* | *One-way platforms in v1 or deferred* | *pending S8* |
