# Box2Dxt Full Project Audit

**Date:** 2026-06-07  
**Scope requested:** full repository audit, including LiveCode/xTalk source.  
**Change policy:** no production code changed; this document is the only intended output.

## Executive summary

Box2Dxt is already a serious, coherent project: it has a clearly layered design, a pinned native dependency, a C smoke test, GitHub Actions, a generated embedded-Kit workflow, detailed docs, and two substantial LiveCode/xTalk examples. The main path to "professional quality" is not a rewrite; it is hardening lifecycle correctness, build reproducibility, release provenance, and test coverage.

The highest-risk issues are in the native handle lifecycle. The C shim uses reusable integer handle tables, but destroy functions add handles to free lists unconditionally and do not clear slots or track whether a slot is already freed. Destroying a world/body also invalidates child objects without recycling their native handle-table entries. Over long sessions, especially with the Contraption Builder and repeated resets, this can create stale-handle growth and, in double-destroy cases, duplicated free-list entries. The next priority is build/release reproducibility: Box2D is fetched from GitHub during configure, prebuilt binaries are committed without an in-repo manifest, and CI uses a SIMD option name that disagrees with the documented option.

## Audit methodology and commands run

I reviewed every tracked text file and intentionally treated the prebuilt shared libraries as binary artifacts that cannot be meaningfully audited line-by-line without source/provenance metadata. The livecode files were included: the canonical Kit, embedded copies in examples, the demo, and the full Contraption Builder.

Commands/checks run:

- `find .. -name AGENTS.md -print` — no repo-scoped agent instruction files found.
- `rg --files -g '!**/.git/**' -g '!build/**' -g '!out/**' -g '!bin/**' -g '!obj/**' | sort` — enumerated project files.
- `wc -l ...` — counted 21,261 lines across tracked text files, including 8,978 lines in the Contraption Builder and 2,727 lines in the demo.
- `python3 tools/check-livecodescript.py src/box2dxt-kit.livecodescript examples/box2dxt-demo.livecodescript examples/box2dxt-contraption-builder.livecodescript` — LiveCodeScript checks passed.
- `cmake -S . -B build -DCMAKE_BUILD_TYPE=Release -DBOX2DXT_BUILD_TESTS=ON && cmake --build build --config Release && ctest --test-dir build --output-on-failure` — blocked by network/proxy 403 while cloning Box2D via FetchContent.
- `sha256sum prebuilt/...` — recorded hashes for committed binary artifacts.
- custom regex cross-check: all 368 `b2lc_*` C exports are bound in `src/box2dxt.lcb`, and all LCB foreign bindings resolve to a C export.
- custom regex cross-check: no duplicate handler/function/command names found in the canonical Kit, LCB binding, demo, or Contraption Builder.

## Severity legend

- **Critical:** can corrupt lifecycle/state, crash, or make releases unverifiable.
- **High:** likely to cause production defects, CI/release breakage, or significant maintenance cost.
- **Medium:** important quality gap with bounded runtime impact.
- **Low:** polish/documentation/style improvement.
- **Positive:** existing professional-strength practice worth preserving.

## Top findings and remediation plan

### 1. Critical — native handle free lists are not idempotent-safe

**Files/lines:** `src/box2d_lc.c` lines 56-92, 130-133, 176-179, 365-368, 563-566, 1035.

The generic table macro appends freed indexes to a free list but does not track whether a slot has already been freed and does not clear the stored Box2D id. Every destroy wrapper calls `*_free_handle(...)` even when the underlying Box2D id is already invalid. A double destroy can therefore enqueue the same slot more than once. Later creations can pop duplicate indexes and hand out multiple live handles backed by the same table slot.

**Why this matters:** LiveCode/xTalk code often calls cleanup from multiple paths (`closeCard`, reset buttons, teardown, object deletion). Idempotent cleanup is required for professional runtime code.

**Recommendation:** Add per-slot state or generation tracking in the handle table. Only free a handle if the slot is currently allocated. Clear the slot after destroying. Consider returning an error/status internally for double-free attempts and extend `tests/smoke_test.c` to stress repeated destroy calls.

### 2. Critical — world/body destruction invalidates child objects without recycling their handle slots

**Files/lines:** `src/box2d_lc.c` lines 130-133, 176-179, 299-303, 365-368, 563-566; `src/box2dxt-kit.livecodescript` lines 134-142 and 734-746.

Destroying a Box2D world destroys all bodies/shapes/joints in that world, and destroying a body destroys its attached shapes/joints. The shim handle tables for bodies, shapes, joints, and chains are independent and do not track ownership, so child handles invalidated by parent destruction are not recycled unless explicitly destroyed first.

**Why this matters:** The Kit tears down the world directly and resets script tables, while `b2kRemove` destroys bodies and deletes only script-side body/shape mappings. Long Contraption Builder sessions with repeated build/play/reset cycles can grow native handle tables indefinitely even if Box2D memory itself is freed.

**Recommendation:** Track ownership relationships in the shim (world -> bodies, body -> shapes/joints/chains), or expose a world teardown that walks Box2D objects and retires all matching handles before `b2DestroyWorld`. Add stress tests that repeatedly create/destroy worlds, bodies, shapes, and joints and assert handle reuse remains bounded.

### 3. High — unchecked `realloc` can crash or corrupt state on allocation failure

**Files/lines:** `src/box2d_lc.c` lines 68-72, 85-89, 637-642, 665-668, 881-895, 997-999, 1041-1047, 1198-1207.

The shim assigns `realloc` directly back to live pointers and immediately updates capacity. If allocation fails, the old pointer is lost or a NULL pointer is dereferenced on the next write.

**Recommendation:** Use temporary pointers, validate allocation success, and return safe failure values when buffers cannot grow. For the ABI, failing queries/events can return 0 and leave previous snapshots cleared.

### 4. High — chain segment shape handles appear unusable

**Files/lines:** `src/box2d_lc.c` lines 694-696, 1013-1033, 1041-1050.

`shape_h(...)` maps a Box2D shape to a public handle via shape userData. Regular shape creation calls `register_shape(...)`, which stamps userData. Chain creation calls `b2CreateChain(...)` and registers only the chain id, not the generated segment shape ids. `b2lc_chain_segment_at(...)` therefore returns `shape_h(segment)`, which is likely 0 for every segment because segment userData was never set.

**Recommendation:** After chain creation, retrieve generated segments, register/stamp each segment shape, and define how their lifetime is tied to the parent chain. Add smoke tests for `b2ChainSegmentCount` and `b2ChainSegmentAt` returning non-zero handles.

### 5. High — build reproducibility depends on live GitHub access during configure

**Files/lines:** `CMakeLists.txt` lines 14-28; `.github/workflows/build.yml` lines 68-75.

CMake uses `FetchContent` to clone Box2D from GitHub at configure time. This failed locally because the environment returned a CONNECT tunnel 403. Even when network works, configure-time network fetches make builds slower and less reproducible.

**Recommendation:** Add one of: a vendored submodule, a source archive URL with hash verification, or documented `FETCHCONTENT_SOURCE_DIR_BOX2D` override for offline builds. CI can still fetch, but release builds should have a verifiable dependency path.

### 6. High — SIMD build option is inconsistent between docs/CMake comments and CI

**Files/lines:** `CMakeLists.txt` lines 78-79; `docs/building.md` lines 77-86; `.github/workflows/build.yml` lines 46-61.

Docs and CMake comments say to use `-DBOX2D_DISABLE_SIMD=ON`. The workflow uses `-DBOX2D_AVX2=OFF`. One may be stale or both may be needed depending on Box2D's actual options. This is especially important because the prebuilt README claims committed Linux binaries are SIMD-disabled.

**Recommendation:** Confirm Box2D v3.1.0 option names, align CMake/docs/workflow, and add a CI log/assertion that shows the final SIMD/AVX setting.

### 7. High — committed binaries need provenance and manifest metadata

**Files/lines:** `prebuilt/README.md` lines 32-47; `.github/workflows/build.yml` lines 86-113.

The repository commits three native binaries but does not include a manifest with source commit, Box2D version, compiler/runners, build flags, hashes, signing/notarization status, or release tag linkage. The README correctly warns that committed artifacts can lag behind source.

**Observed hashes:**

- `prebuilt/box2dxt-windows-x64.dll`: `b17f018a870d55b1ee01b71f1c0c69093548999ad86f3307fa47b02bead2c244`
- `prebuilt/libbox2dxt-macos-universal.dylib`: `ade8f4c72340881e875dd6803e0f2f36358d2f7d2e499205e479e9e9a6acfb12`
- `prebuilt/linux-x86_64/libbox2dxt.so`: `36418e54935a9edf88f256f34500c1cdbb78dccc410aeebd44bdbbf79772afad`

**Recommendation:** Add `prebuilt/MANIFEST.md` or `prebuilt/manifest.json`, produced by CI, and consider removing committed binaries in favor of release assets unless the distribution story requires them.

### 8. Medium — event dispatch runs under screen lock and without structured cleanup

**Files/lines:** `src/box2dxt-kit.livecodescript` lines 1467-1493 and 1495-1508.

`b2kStep` locks the screen, syncs controls, dispatches contact/sensor/frame events, then unlocks. User event handlers can run arbitrary code during that locked period. If a handler throws, control may leave the block before `unlock screen`.

**Recommendation:** Keep only rendering in the locked section. Dispatch user events after unlocking, or use a robust error-handling pattern that guarantees unlock. Apply the same treatment to `b2kStepOnce`.

### 9. Medium — input validation is thin at public API boundaries

**Files/lines:** `src/box2d_lc.c` lines 160-170, 205-240, 264-284, 350-362; `src/box2dxt-kit.livecodescript` lines 231-246.

The project intentionally keeps the FFI scalar and permissive, but professional APIs should clamp or reject dangerous values: invalid body type codes, NaN/Inf coordinates, negative dimensions/radii, zero/negative scale, nonsensical substep counts, and out-of-range material values.

**Recommendation:** Add validation in the Kit for user-facing pixel APIs and in the C shim for engine-critical invariants. Document returned failure values consistently.

### 10. Medium — smoke test is good but not broad enough for ABI v3 surface

**Files/lines:** `tests/smoke_test.c` lines 471-500 and 536-743; `src/box2d_lc.c` lines 687-1285.

The smoke test covers important basics, but ABI v3 contains a much larger surface: sensors, hit events, body-move events, chains, generic body/shape/joint enumeration, advanced joint setters, overlap/shape casts, material ids, and world tuning. Several of the highest-risk lifecycle bugs above are not covered.

**Recommendation:** Expand tests into focused cases: handle double-destroy, repeated world teardown, chain segments, sensor begin/end, hit events, body move snapshots, query sorting, invalid input, and each joint family. Keep smoke fast but add a native test matrix.

### 11. Medium — root-level project presentation is missing a README

**Files/lines:** repository root file list; docs are present under `docs/`.

There is no root `README.md`. Professional open-source projects need an entry point with install instructions, quick start, architecture, binary provenance, support status, and links to docs.

**Recommendation:** Add a concise root README that links to `docs/getting-started.md`, `docs/building.md`, `docs/api-reference.md`, `docs/kit-guide.md`, and `prebuilt/README.md`.

### 12. Medium — CI actions are version-pinned but not SHA-pinned

**Files/lines:** `.github/workflows/build.yml` lines 35, 66, 86-87, 103.

Using `actions/checkout@v4`, `upload-artifact@v4`, and `download-artifact@v4` is normal, but professional/release-oriented workflows often pin actions by commit SHA to reduce supply-chain risk.

**Recommendation:** Pin third-party actions by SHA and document the update cadence, or accept tag pinning as a conscious policy.

### 13. Medium — `.gitignore` is too narrow

**Files/lines:** `.gitignore` lines 1-6.

The ignore file covers `/build/` and Python bytecode only. CMake, OS, editor, LiveCode, release, and test artifacts can easily leak into commits.

**Recommendation:** Add common CMake outputs (`CMakeUserPresets.json`, `CMakeFiles/`, `Testing/`, `compile_commands.json` if not desired), OS/editor files, dist/release folders, and LiveCode-generated temp artifacts if any.

### 14. Low — generated embedded Kit copies inflate review size

**Files/lines:** `examples/box2dxt-demo.livecodescript` lines 17-26; `examples/box2dxt-contraption-builder.livecodescript` lines 17-26; `tools/sync-embedded-kit.py` lines 391-415.

Embedding the Kit makes examples pasteable, which is valuable for the target audience. The tradeoff is very large diffs: any Kit change is duplicated into both examples.

**Recommendation:** Keep this workflow but mark embedded regions as generated in PR summaries and consider a release-time generation option if repository diff weight becomes a problem.

### 15. Low — documentation is strong but should distinguish stable API from alpha demo roadmap

**Files/lines:** `docs/ROADMAP.md` lines 1-17; `docs/api-reference.md` lines 1-28; `docs/kit-guide.md` lines 1-39.

Docs are unusually complete. The main presentation risk is that the Contraption Builder roadmap reads like an internal alpha backlog while API docs read like stable product documentation.

**Recommendation:** Add status badges/labels: core ABI status, Kit status, demo/Contraption Builder alpha status, binary release status.

## File-by-file audit notes

### Repository/configuration files

| File | Audit result |
|---|---|
| `.gitignore` | Too narrow; expand ignores for CMake, OS/editor, dist, and LiveCode artifacts. |
| `.github/workflows/build.yml` | Solid multi-platform CI concept with LiveCodeScript lint and smoke tests. Needs SIMD-option alignment, action SHA pinning, dependency-cache/offline strategy, and provenance generation. |
| `CMakeLists.txt` | Clear and simple CMake. Positives: pinned Box2D tag, warning-as-error mitigation for upstream, optional smoke tests. Risks: FetchContent network dependency, minimal install/package targets, no export/version metadata, SIMD option ambiguity. |
| `LICENSE` | MIT license text present. |
| `CODE_OF_CONDUCT.md` | Standard contributor conduct document present. |
| `CONTRIBUTING.md` | Good contributor workflow and embedded-Kit sync guidance. Add explicit binary/provenance release procedure and expected test matrix for ABI changes. |
| `CLAUDE.md` | Useful maintainer guidance. Consider renaming to a neutral contributor-maintainer note if this is meant for all contributors, not one tooling ecosystem. |
| `CHANGELOG.md` | Detailed but very large Unreleased section. For professional release flow, split shipped releases from internal work-in-progress and ensure each prebuilt binary maps to a tag. |

### Native C shim and tests

| File | Audit result |
|---|---|
| `src/box2d_lc.c` | Broad, consistent scalar ABI; all exports bind to LCB. Primary risks: handle lifecycle/double-free, unchecked allocation, parent-child destruction bookkeeping, chain segment handles, broad global scratch buffers that are not thread/reentrant safe, limited input validation. |
| `tests/smoke_test.c` | Valuable runtime test that exercises real engine behavior. Needs expansion for lifecycle stress, ABI v3 additions, invalid inputs, chain segment handles, sensors/hit/body-move events, and all query paths. |

### LCB binding

| File | Audit result |
|---|---|
| `src/box2dxt.lcb` | Large but mechanically consistent binding layer. Cross-check found all 368 C exports are bound and no bound symbol is missing. Main needs: generated binding table or script-assisted verification in CI, public docs for failure behavior, and possible grouping/version metadata for ABI growth. |

### LiveCode/xTalk Kit and examples

| File | Audit result |
|---|---|
| `src/box2dxt-kit.livecodescript` | Strong user-facing abstraction with good comments and broad functionality. LiveCodeScript linter passed. Key risks: teardown maps do not fully correspond to native lifecycle, event dispatch under screen lock, limited validation for scale/substeps/dimensions, and no automated runtime test under OXT/LiveCode. |
| `examples/box2dxt-demo.livecodescript` | Useful self-contained showcase; embedded Kit is in sync. Consider keeping generated Kit section read-only and adding a shorter minimal example for onboarding. |
| `examples/box2dxt-contraption-builder.livecodescript` | Impressive full app/livecode example. Linter passed and no duplicate handler names detected. Professionalization priorities: split into modules if the host allows, add manual QA checklist, isolate save/load schema tests, profile large scenes, and harden cleanup paths to avoid relying on native stale-handle tolerance. |

### Tooling

| File | Audit result |
|---|---|
| `tools/check-livecodescript.py` | Practical static guard for smart quotes, structure balance, and embedded Kit sync. Good CI value. Add tests for the checker itself and perhaps warnings for duplicate handler names or forbidden token stems. |
| `tools/sync-embedded-kit.py` | Simple and readable generation tool. Add encoding/newline consistency, dry-run output, and a documented generated-file policy. |

### Documentation

| File | Audit result |
|---|---|
| `docs/getting-started.md` | Good onboarding path. Should be linked from a root README. |
| `docs/building.md` | Good build docs. Align SIMD option with CI and add offline/vendor instructions. |
| `docs/architecture.md` | Clear layering explanation. Add lifecycle/ownership model once handle bookkeeping is fixed. |
| `docs/api-reference.md` | Broad and useful. Add failure-mode table and API stability/version sections. |
| `docs/kit-guide.md` | Very comprehensive. Add status labels and troubleshooting around native library naming/loading per platform. |
| `docs/kit-reference.md` | Good compact reference. Add explicit defaults and validation ranges. |
| `docs/ROADMAP.md` | Useful product backlog for Contraption Builder. Mark as alpha/internal roadmap so users do not confuse it with stable API documentation. |
| `prebuilt/README.md` | Honest deployment notes and lag warning. Needs generated manifest/hashes/provenance and clearer relation between committed binaries and release assets. |

### Binary artifacts

| File | Audit result |
|---|---|
| `prebuilt/box2dxt-windows-x64.dll` | Binary artifact present. Hash recorded above. Needs provenance/signature/manifest. |
| `prebuilt/libbox2dxt-macos-universal.dylib` | Binary artifact present. Hash recorded above. Needs provenance/signature/notarization statement if distributed to end users. |
| `prebuilt/linux-x86_64/libbox2dxt.so` | Binary artifact present. Hash recorded above. Needs provenance and confirmation of SIMD-disabled build flag. |

## Positive quality findings

- The project has a clear three-layer architecture: native C shim, LCB binding, and friendly Kit.
- The C ABI strategy is practical for LiveCode/xTalk FFI constraints: scalar handles, doubles for numbers, ints for booleans.
- The binding surface is internally consistent: all discovered C exports have matching LCB foreign bindings.
- The LiveCodeScript static checker passed for the canonical Kit and both examples.
- The embedded Kit synchronization workflow is explicit and enforced by tooling.
- Documentation volume and quality are above average for a small native-extension project.
- CI covers Linux/macOS/Windows builds conceptually and includes a native runtime smoke test.

## Recommended professionalization roadmap

### Phase 1 — harden correctness before adding features

1. Redesign handle tables to be allocation-state aware and double-destroy safe.
2. Track native ownership so world/body/chain destruction retires all dependent handles.
3. Add checked allocation helpers and safe failure returns.
4. Fix/register chain segment shape handles.
5. Add lifecycle stress tests and ABI v3 smoke coverage.

### Phase 2 — make builds and releases reproducible

1. Replace configure-time live clone with vendored/submodule/hash-verified dependency flow or offline override docs.
2. Align SIMD flags across CMake, docs, CI, and prebuilt claims.
3. Generate and commit or attach binary manifests with hashes, source commit, build flags, and toolchain versions.
4. Add root README and release checklist.
5. Pin CI actions by SHA or document tag-pinning policy.

### Phase 3 — improve LiveCode app maintainability

1. Move event dispatch outside screen locks or guarantee unlock on errors.
2. Add Kit-level validation for user-facing inputs.
3. Create manual QA scripts/checklists for OXT/LiveCode behavior not reproducible in CI.
4. Split Contraption Builder into modules if the runtime/tooling supports it; otherwise maintain generated indexes and save/load schema tests.
5. Add performance benchmarks for large scenes and stress-test thresholds.

## Final assessment

The project is promising and already beyond prototype quality in documentation and breadth. To reach professional quality, prioritize native lifecycle safety and reproducible releases over new API surface. The current architecture can support that path; the most important work is making cleanup, allocation failure, binary provenance, and long-running editor sessions boringly reliable.
