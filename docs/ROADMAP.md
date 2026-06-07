# Contraption Builder — Alpha Feedback Triage & Roadmap

A review of the alpha team's reports against the actual code, turned into a
prioritized, actionable plan. The north star from the feedback: **this should
become a small physics *puzzle / machine creation studio*** — highly
customizable, more gamified, shareable. The work below is sequenced so that
fidelity (trust) comes first, then customization, then the creation-studio
systems, then gamification and UI.

Effort: **S** ≈ hours, **M** ≈ a day, **L** ≈ multi-day / needs design.
Priority: **P0** ship-blocker, **P1** important, **P2** later.
Code references are handlers in `examples/box2dxt-contraption-builder.livecodescript`
unless noted.

---

## 0. Fixed in this pass (already committed)

| Report | Diagnosis | Fix |
|---|---|---|
| "laser is broken" | `drawLaserBeam` did `if b2kRayHit(...) then`, but `b2kRayHit` returns the **hit control or empty**, not a boolean — illegal in an `if` in OXT, so it errored every frame. | Capture the result, test `is not empty`. |
| "DRAW TERRAIN broken if started outside play area" | `beginDrawTerrain` seeded its first vertex from the raw click; only `extendDrawTerrain` clamped. | Clamp point 1 to the arena in `beginDrawTerrain`. |
| "default bomb state should be fuse on" | `placeBomb` set `uFuseOnRun` to `false`. | Default to `true`. |

---

## 1. Fidelity & trust — confirmed bugs (do first)

**1.1 Objects leave the arena / fast objects pass through walls / "items move off
screen if dragged very fast" / "shapes should respect the boundary"  — P0, M.**
Root cause: continuous collision (CCD) is **off by default** (`setWorldOptionDefaults`
→ `gCCD = false`) and the arena walls (`b2kWall`) are thin, so a fast body (a
fling, a blast, a thruster) tunnels straight through. The run-mode grab
(`b2kGrab`) also isn't position-clamped.
Plan: default **CCD on**; mark walls/fast bodies as bullets (`b2kSetBullet`);
thicken the arena walls; clamp the grabbed body to the arena each frame. Add a
hard "kill plane" so anything that does escape is removed rather than lost.

**1.2 Draw terrain "buggy fo sho" / "should float" / breaks on degenerate input
 — P0, M.** Beyond the start-clamp (fixed), `finishDrawTerrain`/`regenTerrain`
should reject a < 2-point or zero-length stroke, and the stroke→chain conversion
should be validated (a single dot or a fully-collapsed path must not create a
broken static body). Decide the intended semantics of "float": a drawn line is
currently a thin static polyline — confirm whether it should be a fillable solid
slab. Also gate `beginDrawTerrain` so a press that starts on the palette/chrome
doesn't begin a stroke at all.

**1.3 Visual clipping to the rect / artifacts on fast-moving objects — P1, M.**
This is the LiveCode rendering paradigm, and it *is* improvable from within it:
- Set moving body graphics to `set the layerMode of <ctrl> to "dynamic"` so each
  is composited on its own layer — this removes trails and the "clip to rect"
  smearing, and is the single biggest win.
- Confirm `lock screen` wraps the whole per-frame update (it does in
  `renderBuild`; verify the run loop path too) and consider
  `set the acceleratedRendering of this stack to true`.
- Rotated graphics report an inflated bounding rect; resize math already
  compensates (`setPartDimension`), but selection/redraw should use the body
  angle, not the rect.

**1.4 Chains: "doesn't stay connected, links not equal length, fast objects pass
through" — P1, M.** `buildSpan` (chain/bridge) builds a row of segments; review
link spacing (equal-length segment math), the joint stiffness
(`b2kSetJointTuning`), and apply CCD (1.1) so a fast body can't punch through a
chain. Equal links = derive segment count from span length / desired link length,
not a fixed count.

**1.5 Recipes "lackluster or straight up broken" — P1, M.** Only two builders
exist (`buildSampleCart`, `buildSampleSwing`) yet the menu implies more. Rebuild
the recipe library as a set of **showcase puzzles** (a Newton's cradle, a
catapult, a domino run, a balloon lift, a laser-and-mirror gate, a thruster
rocket) — each both a demo and a starter level for the gamified mode (§4).

---

## 2. Customization — remove limits, add knobs (do second)

**2.1 "No artificial limits" on fans/magnets/thrusters — P1, S.** The steppers in
`adjustPartProp` clamp force/strength to modest ceilings. Raise them an order of
magnitude (and coarsen the step at the top end) so users can build wild machines;
keep a generous sanity ceiling only to avoid NaN/instability, and surface the
value as a type-in field so power users aren't stepping forever.

**2.2 Bomb fuse length configurable — P1, S.** Default-on is done; add a
`uFuseLen` property (frames or seconds), an inspector row (`partProps`/`propLabel`/
`adjustPartProp`), use it in `armFuses` instead of the constant `kBombFuseFrames`,
and round-trip it in `partSpecial`/`applyPartSpecial`.

**2.3 Thruster rework — "broken or unintuitive" — P1, M.** Current thrust is
**body-relative** (rotates as the rocket tumbles), which reads as chaotic. Make
the default **world-fixed** direction (predictable), add a clear visible flame/
arrow that shows thrust direction and magnitude, expose an on/off and a
"point-and-thrust" aim handle, and reconsider the ignition pop. Consider a
"fixed rotation" default for thruster bodies so they fly straight.

**2.4 Image collision respects shape — "rect based" — P1, M.** Imported images
render with PNG transparency (they're real `image` objects) but collide as a
**box** (`b2kAddBox`). Let the user pick the collision shape per image
(box / ball / capsule / convex hull), defaulting to ball for roundish art. True
alpha-accurate hulls aren't available from Box2D directly; a chosen-primitive or
a few-point editable hull is the pragmatic answer.

---

## 3. Creation-studio systems (the heart of the pitch)

**3.1 Naming + signal wiring — "plate 1 detonates bomb 1", name shapes/bridges —
P1, L (needs design).** Today `triggerSignal` is **global**: any plate/sensor
fires *every* bomb and toggles *all* motors. To make real puzzles, add:
- a `uName`/`uId` on every part (auto-assigned, user-renamable in the inspector);
- a lightweight **wiring model**: each emitter (plate, sensor, button, timer)
  has a target list; each receiver (bomb, motor, door, thruster, spawner) has an
  action. Store as `from→to` edges in the save format.
- a wiring UI: pick a source, then click a target (a "link" tool), with on-canvas
  connector lines. This is the feature that turns the sandbox into a *machine you
  design*.

**3.2 Destructible parts — "items should be destroyed by a bomb, laser, etc." —
P1, M/L.** `b2kRemove` exists, so the primitive is there. Add a `uDestructible`
(and optional `uHitPoints`) flag; have the bomb blast (within radius), the laser
(on sustained hit, via the hit control `drawLaserBeam` now captures), and high-
impact contacts remove parts — with a debris/particle puff for juice. This is
both a toy and a puzzle mechanic (clear the blocks, cut the rope).

**3.3 User image library — import images as any kind — P2, L (needs design).**
Generalize image import so a user PNG can *back* any kind: object, terrain,
magnet, plate, bomb, even a named prop. Needs an asset manager (import once,
reuse many; remember paths/relative storage in the save) and a "use image for…"
picker. Pairs naturally with 2.4 (collision shape per asset).

---

## 4. Gamification & UI (turn it into a game)

**4.1 Goals, win-conditions, and a Play vs Edit mode — P2, L (needs design).**
The studio pitch needs a *point*: place a goal zone, a "get the ball to the
exit", a "destroy all crates", a "keep it balanced for 10s" objective; a **Play**
mode that hides the editor and runs the challenge with a win/lose/timer/score; a
**level** wrapper around the existing save format. This reframes every existing
part as a puzzle piece.

**4.2 UI overhaul — "UI NEEDS HELP", inspector/sidebar as palettes/modals —
P1, L (needs design).** The chrome is dense and fixed. Options to evaluate:
floating/dockable palettes, a collapsible inspector, a cleaner tool grid, an
onboarding/tutorial overlay, and a Play-mode chrome that gets out of the way.
Worth a small design spike (a couple of mockups) before committing, since it
touches `buildUI`/`makeInspector`/`makePalette` and `kUIVersion`.

---

## Recommended sequence

1. **Phase 1 — Fidelity (P0/P1, ~week):** §1.1 boundary/CCD, §1.2 draw terrain,
   §1.3 rendering, §1.4 chains, §1.5 recipes. Restores trust in the toy.
2. **Phase 2 — Customization (~week):** §2.1 limits, §2.2 fuse, §2.3 thruster,
   §2.4 image shapes. Cheap wins that make it feel powerful.
3. **Phase 3 — Creation systems:** §3.1 naming + wiring, §3.2 destruction. The
   differentiators.
4. **Phase 4 — Game + UI:** §4.1 goals/Play mode, §4.2 UI overhaul, §3.3 image
   library. The studio.

## Open design decisions (need a call before building these)

- **Gamification model:** pure sandbox with optional goals, authored puzzle
  levels, or both? (Drives §4.1 and the save format.)
- **Wiring UX:** explicit "link tool" with connector lines, or a dropdown
  "target" picker in the inspector? (Drives §3.1.)
- **UI direction:** keep docked-but-cleaner, or move to floating/modal palettes?
  (Drives §4.2 — worth a mockup first.)
- **Image library scope:** simple per-part import (today, generalized), or a full
  reusable asset manager with relative-path storage? (Drives §3.3.)
