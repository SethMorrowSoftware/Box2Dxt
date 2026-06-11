# Expansion Prep — the asset dump & the content phase

The Game Kit is **done and verified** (plan.md Phases 0–5, Win32). This
document is the intake plan for what comes next: a large Kenney spritesheet
pack, new **enemy types**, and new **player actions** — and the working rules
that keep the expansion as reliable as the engine underneath it.

| | |
|---|---|
| Baseline | Kit + games user-verified; self-test harness **v8, ~96 assertions, all pass** |
| Assets | **LANDED (2026-06-11)** — Kenney's iconic platformer family, ~900 frames; Wave 0 catalogue below |
| Next | **Wave 1 OXT pass** — built 2026-06-11, statically verified (see §7); then Wave 2 |
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

## 2. Wave 0 — the catalogue (intake COMPLETE, 2026-06-11)

The upload is Kenney's **iconic platformer family** — three compatible art
sets, ~900 usable frames. Inventory by sheet (names dumped from the XMLs;
all load with `b2kSheetLoadAtlas`):

### Family C — the 70px "classic" set (PRIMARY: richest gameplay art)

| Sheet | Frames | Contents |
|---|---|---|
| `tiles_sheet` | 172 | **Six terrain biomes** — grass, dirt, sand, snow, stone, castle — each a full autotile kit: `Mid/Left/Right/Center`, cliffs, **`Half*` thin platforms (one-ways!)**, **`Hill*` slopes**, ledges. Plus: ?-boxes (coin/item/explosive + used/disabled), brick walls, two bridges, **doors** (open/closed, 2 tiles), fences, **ladders** (`ladder_mid/top`), **liquids** (lava + water, surface + body tiles), **locks ×4 colours**, **ropes** (attached/horizontal/vertical), signs (incl. exit), hills (decor), torches, windows |
| `items_sheet` | 59 | **Buttons ×4 colours with `_pressed` art** (our polled plates, finally with faces), **lever switches** (`switchLeft/Mid/Right`), **springboards** (up/down), keys ×4, gems ×4, coins ×3 metals, star, **bomb + flash**, **fireball**, flags ×4 colours (incl. hanging), weight (+`weightChained` — thwomp art!), **brick particles** (debris for breakables), clouds/plants/decor |
| `enemies` | 100 | **25 species, most with `_dead`/`_hit` states**: barnacle (bite), **bat (fly + hang!)**, bee, fish ×2, fly, frog (leap), **ghost** (the Boo!), **grassBlock (disguised mimic!)**, ladybug, mouse, **piranha (`_down` — the pipe plant!)**, slime/slimeBlock/slimeBlue/slimeGreen (squashed states), snail (+shell), **snake / snakeLava / snakeSlime** (pit dwellers), spider (2-frame walk), **spinner + spinnerHalf** (spinning blades), worm |
| `enemies_sheet` | 18 | Simple set: **blocker (body/mad/sad) and poker (mad/sad) — crusher blocks with moods**, fish, fly, slime, snail (+upside-down shell) |
| `player_sheet` | 48 | **p1/p2/p3** characters, 66×92: `stand, duck, hurt, jump, front`, **11-frame walks** (the smoothest art in the repo) |
| `hud_sheet` | 33 | Digits 0–9, `x`, coin/gem/key icons (+disabled), **hearts (full/half/empty — a health system)**, player portraits |

### Family B — the 128px "deluxe" set (alternate biomes + the aliens)

| Sheet | Frames | Contents |
|---|---|---|
| `spritesheet_ground` | 108 | Six biomes again — incl. **planet** (alien world!) — same autotile grammar at 128px (`Hill_left/right`, `Half_*`, corners, cliffs) |
| `spritesheet_tiles` | 72 | 128px interactables: boxes, bricks, bridges, doors, ladders, **liquids**, levers, locks, mushrooms, signs, spikes, **spring/sprung**, switches ×4 (+pressed), torches, water/lava tops, weights |
| `spritesheet_enemies` | 57 | Redux species incl. **saw + sawHalf**, slime ×4 colours, worms ×2, fish ×3 (`fishBlue_fall`!), barnacle/bee/fly/frog/ladybug/mouse/snail |
| `spritesheet_players` / `aliens` / `alien<Colour>` ×5 | 55/55/11 | **Five alien colourways**, 66×92, with `stand, walk1/2, jump, duck, hurt, front` **and `climb1/2` + `swim1/2`** — ladder and water gameplay art |
| `spritesheet_items` | 24 | Coins/gems/keys/star + flag poles with `_down` states |
| `spritesheet_hud` / `spritesheet` | 36/98 | 128px HUD + a mixed sampler |
| `spritesheet_complete` | 355 | ⚠ **orphan** — references `sprites.png`, which is not in the upload. No loss (it's the union of the others); ignore or upload its PNG later |

### Decisions out of Wave 0

- **World grid = 70px (Family C primary).** It has the most gameplay art
  (buttons, springboards, levers, ladders, liquids, locks, ropes, doors,
  bridges, the 25-species enemy sheet, p1–p3). Family B serves as alternate
  biomes (planet!) and the **alien player skins** — their 66×92 frames match
  p1–p3, so aliens drop onto the 70px grid directly; B's 128px tiles join via
  `b2kSheetScale` when a level wants those biomes.
- **Sprite-only graphics from now on (policy).** No new plain LC graphics
  ("native GRCs") for visible game art — every new visual is a sheet frame
  (buttons replace coloured rects, weightChained replaces the grey thwomp,
  spikes/springs/doors all have art). Plain graphics remain only as
  *invisible physics hosts* (slabs, body proxies) and inside the existing
  no-asset fallbacks, which are frozen — not extended.
- **Measure before placing** stands: every Hill/slope tile gets its surface
  profile read from the pixels before a chain is fitted under it.

## 3. Player actions roadmap (expanded by the art)

Everything from the original roadmap, plus what the new frames unlock.
Each action: Kit change + tuning keys + **self-test assertions + harness
bump** + a place in a game.

| Action | Art | Design sketch | Keys |
|---|---|---|---|
| **Drop-through** | `*Half*` one-way tiles | brief collision-mask window; chains already one-sided | `dropMs` |
| **Wall-slide + wall-jump** | reuse jump/hurt poses | side probes (the ground-probe pattern, horizontal); capped slide fall; away-launch with input lockout | `slideFall, wallJumpX/Y, wallLockMs` |
| **Dash** | walk frames at high fps | fixed-speed burst, gravity off during, cooldown | `dashSpeed, dashMs, dashCooldownMs` |
| **Double jump** | jump frame | `airJumps` counter refilled on ground | `airJumps` |
| **Platform carry** | — | probe hit on kinematic ⇒ add its velocity to target vx | (automatic) |
| **CLIMB (new)** | `ladder_mid/top` + alien `climb1/2` | ladder zones = polled regions (`b2kOverlapMoving` doctrine); in-zone + up/down ⇒ gravity scale 0, velocity-driven y, climb anim; jump exits | `climbSpeed` |
| **SWIM (new)** | `liquidWater*` + alien `swim1/2` | water zones: gravity scale ~0.3, damping up, capped fall, jump = stroke (`b2kPlayerJump` repeatable in water), swim anim | `swimSpeed, swimJump` |
| **DUCK (new)** | `*_duck` frames | down ⇒ duck state + anim; optional hitbox shrink later (capsule reshape is a Kit call away) | — |
| **HURT knockback (new)** | `*_hurt` | standardise the hurt arc: control-off + `b2kPlayerJump`-style pop + invulnerability window | `hurtMs` |
| **Springboards (new)** | `springboardUp/Down`, `spring/sprung` | sensor/contact ⇒ `b2kPlayerJump kSpringSpeed` + art swap — the canonical use of the API jump | per-spring speed |

## 4. Enemy archetype roadmap (the full bestiary)

All on existing Kit mechanisms (patrol tables, movers, thwomp lifecycle,
rays, sensors, polls). Names = actual frame sets. Each lands with art,
anims, a maker/table entry, contact rules, **and a banner/self-test check**.

| Archetype | Species (art) | Behaviour |
|---|---|---|
| **Walker** (stompable) | slime ×4, worm ×2, mouse, ladybug | patrol; stomp = squash (`_squashed`/`_dead` art), side = hurt |
| **Spiked walker** | spinner, spinnerHalf, poker | patrol; **never stompable** (the spike-slime rule) |
| **Shelled** | snail (+`snail_shell`, upside-down) | stomp ⇒ shell (safe, static-ish); second hit ⇒ **kicked shell**: fast slider that kills other enemies and the player alike |
| **Flier (sine)** | bee, fly, ladybug_fly | the mover table (bodiless proximity) |
| **Ceiling ambusher** | **bat** (`bat_hang` → `bat_fly`) | hangs static; player passes under ⇒ drop + swoop (mover with a trigger) |
| **Ghost (the Boo)** | ghost (`ghost_normal/dead`) | chases ONLY while the player faces away (`b2kPlayerFacing()` vs relative x); freezes + fades when watched |
| **Mimic** | **grassBlock** | disguised as terrain; wakes when approached (the thwomp arming pattern, sideways) |
| **Pipe plant** | **piranha (`piranha_down`)** | emerges/retreats on a timer from pits/pipes; suppressed while the player stands close (the classic) |
| **Pit dweller** | snakeLava, snakeSlime, fish ×3 | periodic leaps out of liquid (mover, vertical, liquid-synced); `fishBlue_fall` for the arc-top flip |
| **Lunger** | frog (`frog_leap`), barnacle (`barnacle_bite`) | frog: timed hops toward the player; barnacle: static bite window (lurker pattern) |
| **Chaser** | mouse/spider | patrol until `b2kRayHit` line-of-sight, then accelerate |
| **Crusher** | blocker/poker (mad/sad!), weight + `weightChained` | the thwomp lifecycle with REAL art — face swaps mad/sad with state |
| **Saw** | saw, sawHalf (B) | static sensor + the sweeping mover (both shipped patterns) |
| **Spider** | spider walk1/2 | ceiling walker: patrol upside-down, drop on proximity, climb back (rope art available) |

Promotion rule stands: when the second game needs a pattern, it graduates
to Kit API (`b2kFoe…`).

## 5. Terrain, traps & interactables roadmap

- **Biomes:** grass / dirt / sand / snow / stone / castle (70px) + planet
  (128px). Levels declare a biome; the tile verbs take it as a parameter —
  one interpreter, seven skins. **Snow = low-friction ground** (ice physics
  via `b2kSetFriction` on its slabs) — terrain that plays differently.
- **Slopes:** `*Hill*` tiles per biome — measured, then chain-fitted (the
  mound recipe, now with proper art per biome).
- **One-ways:** `*Half*` thin platforms over ghost-padded one-sided chains.
- **Liquids:** water = swim zones; **lava = instant hurt** (polled region) with
  `liquidLavaTop` surface animation (two frames). Bubbling pits for snakes.
- **Ladders:** climb zones + `ladder_mid/top` columns.
- **Bridges & ropes:** plank bridges (`bridgeA/B`, `bridgeLogs`) — including a
  **collapsing bridge** trap (planks drop on a timer after touch; kill floor
  cleans up); rope tiles for spider/climb decor.
- **?-Boxes:** `boxCoin/boxItem/boxExplosive` + disabled/used states — **hit
  from below** (the underside-contact pattern inverted) pops a coin/powerup;
  explosive boxes chain into `bomb + bombFlash + particles`.
- **Breakable bricks:** brick tiles + `particleBrick*` debris (spawned balls
  with kill-floor cleanup) — stomp-from-below demolition.
- **Switch family:** polled **buttons** ×4 colours (pressed art), **levers**
  (left/mid/right = a 2-state toggle with a real handle), **key + lock ×4
  colours** (carry key, unlock matching lock tile), **doors** (open/closed art;
  the micro-game's exit gets a face), springboards, signs, torches (lit
  states), weights on chains.
- **Checkpoints/goals:** flag families in 4 colours, hanging variants, pole
  `_down` states for raise animations.
- **HUD:** sprite digits (`hud_0-9`, `hud_x`), hearts (full/half/empty),
  key/gem/coin icons — the text-field HUD becomes sprite-based (and cheaper
  than field relayouts).

## 6. Rules of engagement (updated)

1. Kit edits only in the source Kit → sync → static gates — every time.
2. **Every Kit change adds/extends a self-test assertion and bumps
   `kStHarnessV`.** The user runs the harness before playing.
3. Doctrine: events for one-shots; **`b2kOverlapMoving` polls for
   presence**; windows for verdicts; sim-time for feel; ghost-pad chains;
   thick slabs for driven edges; both targets set in every game;
   **measure art before placing it; sprite-only visuals** (plain graphics
   only as invisible physics hosts).
4. Perf budget: ~25 *live* sprites near the ceiling; tiles are free
   (inert); HUDs throttled; build once, write on change.
5. Docs ride along; plan.md decision log records every call.
6. Statically verified → user OXT pass → next wave.

## 7. The waves (expanded)

1. **Wave 1 — the iconic-feel base:** springboards, ?-boxes (coin pop),
   breakable bricks + debris, buttons/levers with art, key+lock+door; the
   platformer re-skinned sprite-only (real thwomp art, spike tiles, biome
   ground). *The "it looks like the classics now" wave.*
   **BUILT 2026-06-11** in the platformer (statically verified; first
   OXT feedback folded in): springboard + sky coin, the bonk row
   (?-boxes pay coins, bricks shatter into kill-floor-swept debris),
   the plate wears pressed/idle button art, a stand-to-flip saw power
   lever, key + lock + door gating a stone-biome finale (opens on
   approach via `b2kDisable`, flush against the step, crown coin inside
   the open doorway), thwomps as chained weights — static at rest,
   **not player-movable** — and the crate wearing the empty-box face.
   All POLLED geometry + windows (no static-contact events); **zero Kit
   changes, so no harness bump**. Art note: Wave 1 ships in the
   platformer's native 64px family (it has the full switch/spring/
   key/door set, style-matched); Family C debuts with content built FOR
   its 70px grid (Waves 2-3).
2. **Wave 2 — player actions I:** drop-through, climb (ladders), duck,
   hurt-knockback standard; alien skins selectable in the micro-game.
3. **Wave 3 — bestiary I:** shelled (kickable!), ghost, bat, mimic,
   pipe plant, crusher-with-faces — into a platformer "haunted" section.
4. **Wave 4 — liquids:** swim zones + lava + pit dwellers + collapsing
   bridge; a water level in the micro-game (level 3).
5. **Wave 5 — player actions II:** wall-slide/jump, dash, double-jump
   powerup (boxItem delivers it), platform carry.
6. **Wave 6 — bestiary II + promotion:** chaser, lunger, spider, saws;
   `b2kFoe…` promotion decision with two consumers in hand.
7. **Wave 7 — the showcase level:** one long level using every biome
   mechanic — the "iconic platformer" demonstration piece, plus sprite HUD.
8. **Wave 8 — builder cross-pollination** (closes Phase 5): sprite parts +
   the player as placeable kinds in the contraption builder.

## 8. Open questions / risks

- **macOS/Linux (R1):** unverified; the self-test is the acceptance suite.
- **`b2kScene*` promotion:** likely lands with Wave 4 (a third level wants
  the format) — decide then.
- **`spritesheet_complete.xml`** is an orphan (its `sprites.png` wasn't
  uploaded) — no content loss; upload the PNG later or delete the XML.
- **Mixed grids:** 70px (C) vs 128px (B) — normalised per level via
  `b2kSheetScale`; never mix raw grids inside one level.
- **Sheet memory:** prefer `-default`/70px sources + scale; the `-double`
  and 128px sets are alternates, not defaults.
