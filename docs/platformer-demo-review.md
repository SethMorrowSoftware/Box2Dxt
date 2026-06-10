# Platformer Demo Review Notes

Review date: 2026-06-10

## Focus of this pass

- Prioritized the `examples/box2dxt-platformer.livecodescript` demo because it is the current showcase for the in-progress game-engine kit.
- Kept changes inside the demo's own script above the embedded Kit sentinel. The embedded Kit remains synced and untouched by hand.
- Treated OXT runtime behavior as needing an in-editor pass; this repository only allows static LiveCodeScript checks in a headless environment.

## Improvements made in this pass

- Replaced the diagnostic intro pan with a gameplay camera that starts settled on the bounded opening view.
- Added side-scroller camera lead: the view looks ahead in the hero's facing direction instead of hard-locking the hero to the exact center.
- Added a slight upward vertical bias so upcoming jumps, bridge planks, platforms, and the route ahead are easier to read.
- Added faster camera recovery after respawn/teleport-like moves while preserving slower smoothing during normal movement.
- Kept the existing Kit camera services in use: bounds, shake, grouped scrolling, and camera-corrected mouse grabbing still flow through the Kit.
- Expanded the HUD camera diagnostics to include the Kit's camera center, making it easier to compare scroll range with internal camera position during the next OXT playtest.

## Problems and risks to verify in OXT

1. **Camera feel still needs a real playtest.** The new values are intentionally conservative (`150px` look-ahead, `70px` upward bias, `0.09` normal smoothing). Tune these after playing the pit, saw, gate, and final climb in OXT.
2. **Camera target is demo-level manual logic, not a generalized Kit primitive.** This is good for making the platformer feel better now, but a future engine API should probably expose configurable follow styles such as look-ahead, bias, snap-on-teleport, and per-axis smoothing.
3. **The camera tick order is limited by the Kit loop.** The Kit applies its camera once before the demo's `b2kFrame`, then the demo calls `b2kCamGoto`. That should still produce a current frame scroll write, but OXT should be checked for any one-frame lag or shimmer.
4. **The camera-dead fallback remains crude.** If group scrolling is unavailable, the demo clamps play to the first screen and spawns a near flag. That keeps the demo completable, but it does not preserve the intended route or puzzle pacing.
5. **Plate sensor counting can over-count if a visitor enters/exits more than once unexpectedly.** It clamps negative values on exit, but it does not track unique visitors. This is acceptable for the current small demo, but a set keyed by visitor control would be safer.
6. **Coin removal mixes `b2kSpriteRemove` with a direct delete attempt.** It is guarded, but this should be watched for stale sensor/body refs in OXT after collecting every coin and resetting repeatedly.
7. **Slime defeat removes the physics body before deleting the art.** The short linger is intentional, but it should be checked for contacts or stale refs if the hero overlaps the slime while the flat sprite is still visible.
8. **Asset fallback is functional but not visually equivalent.** Placeholder art only defines character animations; missing tiles/enemies/backgrounds still fall back to simple graphics, so the polished route readability depends on loading the Kenney atlas folder.
9. **No headless runtime exists for `.livecodescript`.** The static checker passed, but only OXT can validate actual camera scroll, grouped layer behavior, input focus, mouse dragging mid-level, and sensor/contact timing.

## Recommended next pass

- Play the full route in OXT and record rough timestamps/positions where the camera feels late, too high/low, or reveals too little hazard space.
- Promote the demo's camera tuning into a Kit-level helper only after the feel is proven in this demo.
- Add unique-visitor tracking for pressure-plate sensors if OXT shows any flicker when the hero and crate overlap the plate together.
- Consider a small in-demo debug toggle for camera target, hero position, and view bounds rather than always showing diagnostics in the HUD.
