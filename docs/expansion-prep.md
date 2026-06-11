# Expansion Prep — the asset dump & the content phase

The Game Kit is **done and verified** (plan.md Phases 0–5, Win32). This
document is the intake plan for what comes next: a large Kenney spritesheet
pack, new **enemy types**, and new **player actions** — and the working rules
that keep the expansion as reliable as the engine underneath it.

| | |
|---|---|
| Baseline | Kit + games user-verified; self-test harness **v7, ~93 assertions, all pass** |
| Blocked on | The asset upload (the user holds the pack) |
| Companions | [plan.md](../plan.md) (history/decision log) · [game-engine-spec.md](game-engine-spec.md) (module design) |

---

## 1. The asset dump: how to deliver it

- **Where:** new sheets go in `Spritesheets/` next to the existing four
  (characters / enemies / tiles / backgrounds, `-default` 1x and `-double` 2x).
- **Format:** PNG + Kenney **TextureAtlas XML** pairs load directly
  (`b2kSheetLoadAtlas`). Plain grids load with `b2kSheetLoad … fw, fh
  [,count, margin, spacing]`. Anything else (packed, no XML) loads with frame
  size 0 + `b2kSheetAddFrame` per region — **every layout is loadable**, so
  don't filter the pack; send everything that might be useful.
- **Licensing:** keep it CC0/Kenney-style; note the source pack names in the
  commit message.
- **Size note:** the repo carries the PNGs; the games load only the sheets
  they name, and frames slice lazily — a big pack costs disk, not runtime.

## 2. Intake checklist (first session after the upload)

1. **Inventory:** decode each XML, dump frame names and region sizes
   (`b2kSheetFrameNames` is the in-OXT equivalent); produce a short
   inventory table in this doc — what characters, enemies, tiles, effects,
   and UI art we actually have.
2. **Measure before placing** (the ramp lesson): any directional/sloped art
   gets its surface profile measured from the pixels — never guessed from
   the name. The pure-python PNG reader from the ramp fix is the tool.
3. **Pick the cast:** map available art onto the enemy/action roadmap below;
   adjust the roadmap to the art (not the other way round).
4. **Animation table:** for each chosen actor, list its frames →
   `b2kAnimDef` lines (idle/walk/attack/flat/etc.), with fps choices.

## 3. Player actions roadmap

Each action is a Kit change to the player controller, **lands with its own
self-test assertions** (harness version bump), is wired into the platformer,
and gets a tuning-keys row in kit-reference. Suggested order (feel value vs
risk):

| Action | Design sketch | New tuning keys | Self-test sketch |
|---|---|---|---|
| **Drop-through** (down+jump through one-way ledges) | A brief collision-mask window on the player (the spec's deferred mask-window technique); chains are already one-sided | `dropMs` (~250) | Stand on a one-way chain, inject down+jump, assert y passes below it; assert solid ground does NOT drop |
| **Wall-slide + wall-jump** | Side probes (2 horizontal rays, same pattern as the ground probe); sliding caps fall speed; jump while sliding launches up-and-away; brief input lockout so the away-push isn't instantly steered back | `slideFall` (~160), `wallJumpX/Y` (~320/430), `wallLockMs` (~120) | Hold into a wall airborne → vy capped; inject jump → vx sign flips away + vy up |
| **Dash** | Fixed-speed burst along facing for `dashMs`, gravity scale 0 during, cooldown; cancels into jump | `dashSpeed` (~620), `dashMs` (~140), `dashCooldownMs` (~600) | Inject dash key, assert x covered ≈ speed×time, vy ≈ 0 during, cooldown blocks a second dash |
| **Double jump** | A counter refilled on grounded; `b2kPlayerJump` already does the launch; gate on `airJumps` knob | `airJumps` (0 default) | With airJumps 1: jump, then mid-air jump fires once and only once |
| **Moving-platform carry** | The deferred one: when the ground probe hits a kinematic body, add its velocity to the player's target vx (platform-relative movement) | none (automatic) | Player idles on a moving kinematic slab → x tracks the slab |

Standing rules: external boosts via `b2kPlayerJump`; all new timers on the
**sim clock**; every new state interacts with hysteresis/ground-snap
explicitly (write the test first).

## 4. Enemy roadmap

The platformer already ships three behaviour patterns as indexed example
tables — **patrol** (`pfMakeSlime`), **sine mover** (`pfAddMover`), and the
**thwomp lifecycle** (`pfMakeThwomp`). Per the promote-once-repeated rule,
when the micro-game (or a new example) needs the same patterns, they graduate
into Kit API (working name: `b2kFoe…`); until then they stay example-side.

New archetypes to build from the known enemy-sheet frames (bee, fly, saw,
slime ×3 kinds, snail, mouse, frog, fish, worm, ladybug, barnacle, block):

| Archetype | Behaviour | Mechanism (all existing Kit pieces) |
|---|---|---|
| **Shelled patroller** (snail) | Stomp once = retreat into shell (safe, kickable block); kicked shell skids and hurts other enemies | Patrol table + contact verdicts + a kicked-state velocity |
| **Hopper** (frog) | Periodic arcs toward the player's side | Timer + `b2kPush`; land detection via its own body events |
| **Chaser** (mouse) | Patrols until line-of-sight, then accelerates | `b2kRayHit` from foe to player (the spec's chase-on-sight) |
| **Ceiling lurker** (barnacle) | Static; bites when the player passes under | Pure proximity window (the fly/sweeper pattern) |
| **Swimmer** (fish) | Sine "leaps" out of pits | Mover table with vertical amplitude |
| **Projectile** (worm/spit?) | Art permitting: a spawned ball with kill-floor cleanup + hurt-on-contact | `b2kSpawnBall` + contact + `b2kKillFloor` |

Each enemy: art + anims + one `pfMake…`/table entry + contact/hurt rules +
**one self-test or platformer-banner check** + a coin/puzzle reason to exist.

## 5. Rules of engagement (unchanged, now codified)

1. Kit edits only in the source Kit → sync → static gates — every time.
2. **Every Kit change adds/extends a self-test assertion and bumps
   `kStHarnessV`.** The user runs the harness before playing anything.
3. Doctrine: events for one-shots; **polls/windows for presence and
   verdicts**; sim-time for feel windows; ghost-pad every open chain;
   thick slabs for driven edges; set **both** `b2kFrameTarget` and
   `b2kContactTarget` in every game.
4. Perf budget: ~25 *live* sprites near the ceiling on modest hardware;
   tiles are free (inert); HUDs at 4 Hz; build once, write on change.
5. Docs ride along (kit-reference table rows, kit-guide where teaching
   value exists, CHANGELOG, decision log).
6. Statically verified → user OXT pass → only then the next wave.

## 6. Proposed wave order

1. **Wave 0 — intake:** assets land; inventory + animation tables written
   into this doc; no code.
2. **Wave 1 — player actions:** drop-through + wall-jump (+ tests), into the
   platformer.
3. **Wave 2 — enemies I:** shelled patroller + chaser (+ a platformer
   section that uses them).
4. **Wave 3 — player actions II:** dash + double-jump powerup (the
   micro-game gets a powerup door).
5. **Wave 4 — enemies II + promotion decision:** hopper/lurker/swimmer;
   decide `b2kFoe…` promotion with two consumers in hand.
6. **Wave 5 — builder cross-pollination** (the last open Phase-5 chunk):
   sprite parts + the player as a placeable kind in the contraption builder.

## 7. Open questions / risks

- **macOS/Linux (R1):** still unverified; the self-test is the acceptance
  suite when hardware appears — run it before anything else.
- **`b2kScene*` promotion:** the micro-game's level-text pattern works;
  promotion waits until a second game wants the same format (likely Wave 2+).
- **Multi-player:** controller state is a singleton by design; the refactor
  is mechanical when a real need arrives (see decision log 2026-06-11).
- **Sheet memory:** the `-double` (2x) variants are redundant for the Kit
  (`b2kSheetScale` resamples); prefer `-default` + scale unless crispness at
  large sizes demands 2x.
