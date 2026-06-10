# Platformer Demo Review

Date: 2026-06-10

This review covers the current Phase 1/2 platformer demo and the in-progress
engine support it depends on. The demo is still intentionally built from the
available Kit primitives: input polling, spritesheet animation, sensors, rays,
and direct velocity control. The dedicated Player and Camera modules described
in `docs/game-engine-spec.md` are not implemented yet.

## Fixes made in this pass

- **Chrome wipe bug:** `pfWipeStage` matched every control whose name began with
  `pf_`, which included the HUD, title/help fields, Pause button, and Reset
  button. A reset/open rebuild could delete the controls that later handlers
  still write to. The stage wipe now preserves the chrome controls.
- **Playable-jump polish:** added demo-local coyote time, jump buffering,
  variable jump height, and a max-fall clamp so the platformer has more modern
  game feel before the engine-level Player module exists.
- **Clear objective:** added a fourth coin and a locked/open goal sensor so the
  slice has an explicit win condition instead of only a movement checklist.
- **Failure recovery:** falling below the visible playfield now routes through
  the same hurt/respawn flow as the saw hazard.
- **Better playtest telemetry:** the HUD now reports goal state, grounded state,
  jump-buffer time, animation, and frame time.

## Problems and risks to flag

### High priority

1. **Player controller is still demo-local, not engine API.** The coyote time,
   jump buffering, max-fall clamp, and state-to-animation glue now make this
   example feel better, but they duplicate the future `b2kPlayer...` module
   planned in the game-engine spec. When Phase 3 lands, this example should
   shrink and use the shared player controller.
2. **No headless runtime verification is available here.** The repository has a
   useful static LiveCode checker, but OXT/LiveCode behavior still needs a human
   paste-and-play pass. Sensor sizes, atlas frame names, group clipping, and
   button layering can only be fully confirmed in the GUI runtime.
3. **Camera is not available yet.** The level is still constrained to one card
   because the planned camera/viewport API is not implemented. This limits the
   demo's ability to show a real platformer course.

### Medium priority

1. **Ground probing is hand-authored.** `pfOnGround` uses two downward rays and a
   normal threshold. This is good enough for a flat demo, but it will become
   brittle around moving platforms, slopes, and wall-adjacent edge cases until
   the Player module owns this logic.
2. **Direct velocity setting is intentionally blunt.** The demo sets horizontal
   velocity every frame for responsiveness. The future controller should expose
   acceleration, deceleration, air control, and slope rules as tuning values.
3. **Goal feedback is minimal.** The goal changes color and the HUD prints a
   clear message, but there is no scene transition, audio, confetti, or restart
   countdown yet. That belongs in the later game-scaffolding/audio phase.
4. **Fallback art path is less representative.** If the Kenney spritesheets are
   not located, the placeholder hero and fallback coin/saw controls exercise
   less of the sprite/atlas path. The fallback is still useful, but the OXT pass
   should prefer the real `Spritesheets/` folder.

### Low priority / polish backlog

1. Add a visible start marker and checkpoint marker once levels get wider.
2. Add a small landing/hit effect sprite when the sprite API grows enough helper
   patterns to make one-shot effects easy.
3. Add a second hazard type, such as spikes, once there is a standard hazard
   helper or scene format.
4. Document an OXT playtest transcript format: platform, OXT version, whether
   real atlases loaded, observed frame time, and any control/sensor failures.

## Recommended next steps

1. Run the updated demo in OXT with the real `Spritesheets/` folder selected.
2. Verify reset/pause controls survive repeated resets and card reopen events.
3. Stress jump feel at ledge edges: jump just after leaving ground and press jump
   just before landing on the floor/steps/one-way ledge.
4. Start Phase 3 by moving this demo-local controller logic into the planned
   `b2kPlayer...` API, then simplify the example to prove the API is paying off.
