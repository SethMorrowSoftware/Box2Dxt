# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## What this is

**Box2Dxt** is the Box2D **v3.1.0** physics engine packaged for **OpenXTalk (OXT)** and the
wider **xTalk** language family (also compatible with **LiveCode 9.6.3+**). It ships as three
stacked layers plus self-contained example stacks:

```
Box2D v3.1.0 (fetched by CMake)
   └─ C shim         src/box2d_lc.c        →  libbox2dxt.{so,dylib,dll}   (ABI symbols: b2lc_*)
        └─ LCB binding  src/box2dxt.lcb     →  raw  b2*   API  (metres, radians, int handles)
             └─ the Kit  src/box2dxt-kit.livecodescript → friendly b2k* API (pixels, degrees,
                          control-backed bodies, a per-frame render loop)  ← SINGLE SOURCE OF TRUTH
                  └─ examples/*.livecodescript  embed a *synced copy* of the Kit
```

- **C shim** (`src/box2d_lc.c`): exposes Box2D v3 across the LCB foreign-function interface.
  Box2D ids are small by-value structs, so every id is stored in a shim-side handle table and
  crosses the boundary as a **1-based 32-bit int handle (0 = null/invalid)**. Reals cross as
  `double`, booleans as `int`. Every handle is validated with Box2D's `b2*_IsValid` before use,
  so a stale/0 handle is a **harmless no-op** (getters return 0), never a crash. Exported C ABI
  symbols keep the historical **`b2lc_` prefix** for binary stability — **never rename them**.
- **LCB binding** (`src/box2dxt.lcb`, `library org.openxtalk.box2dxt`): declares `foreign handler`
  bindings to the shared library and public `b2PascalCase` handlers callable from xTalk. This API
  speaks **metres and radians**; body type codes are `0=static, 1=kinematic, 2=dynamic`.
- **The Kit** (`src/box2dxt-kit.livecodescript`): a pure-xTalk convenience layer (161 `b2k*`
  handlers) that speaks **screen pixels and degrees**, binds bodies to LiveCode controls, and runs
  the animation loop. This is what the examples and most users actually call.

Docs live in `docs/` (`architecture.md`, `building.md`, `getting-started.md`, `api-reference.md`,
`kit-guide.md`, `kit-reference.md`). Drop-in prebuilt binaries are in `prebuilt/`.

## The golden rule: the embedded-Kit sync

The example stacks are **deliberately self-contained** — you paste the whole `.livecodescript`
into a stack script and it runs — so **each example embeds a verbatim copy of the Kit** between
sentinel comments:

```
-- >>> BEGIN EMBEDDED KIT >>>      (e.g. line 36 in the contraption builder)
   ...the entire Kit, generated...
-- <<< END EMBEDDED KIT <<<        (e.g. line 1689 in the contraption builder)
```

Rules:
- **`src/box2dxt-kit.livecodescript` is the only source of truth for the Kit.** Edit it there.
- **Never hand-edit between the sentinels** in an example — the next sync overwrites it.
- After changing the Kit, **re-sync and commit the result**:
  ```sh
  python3 tools/sync-embedded-kit.py            # rewrite embedded copies
  python3 tools/sync-embedded-kit.py --check    # verify (CI gate; non-zero on drift)
  ```
- When auditing/linting an example's *own* code, **exclude the embedded region** (lines between
  the sentinels) so you don't double-count Kit handlers or trip over Kit code you can't edit here.

## Commands

**Native library + tests** (C; this is the only layer with an automated test suite):
```sh
cmake -S . -B build -DCMAKE_BUILD_TYPE=Release -DBOX2DXT_BUILD_TESTS=ON
cmake --build build --config Release
ctest --test-dir build --output-on-failure        # runs tests/smoke_test.c
```
CMake fetches Box2D v3.1.0 automatically (pinned `GIT_TAG v3.1.0`). See `docs/building.md`.

**Sync the embedded Kit** (run after every Kit edit): `python3 tools/sync-embedded-kit.py`

**Static verification for the script layer.** OXT/LiveCode is a GUI runtime — there is **no
headless way to compile or run the `.livecodescript` here**. The user compiles and tests in OXT.
Your job is to catch what's statically catchable *before* they do. One command bundles the gates
(and CI runs the same script):

```sh
python3 tools/check-livecodescript.py
```

It checks the Kit and every example for: **smart/curly quotes** (any one fails OXT compilation),
**handler balance** (every `on`/`command`/`function`/`getprop`/`setprop` has its `end <name>`),
**control-structure balance** (`if`/`repeat`/`switch`/`try` blocks closed inside their handler),
and **embedded-Kit drift** (delegates to `sync-embedded-kit.py --check`). Exit non-zero on any
failure. Run it after **every** `.livecodescript` edit.

**Do not claim runtime behavior you cannot observe** — say "verified statically; needs an OXT
pass" and let the user confirm.

## LiveCodeScript / OXT gotchas (learned the hard way)

OXT's compiler is **stricter than LiveCode's**. These are the recurring footguns:

1. **No smart quotes.** Curly `“ ” ‘ ’` (U+201C/201D/2018/2019) anywhere in the script — even inside
   a string literal or comment — fail to compile in OXT. Use straight ASCII `"` and `'` only.
   (Unicode *glyphs* in display strings, e.g. `▲ ↗ ◉ ·`, are fine.)
2. **Avoid property/variable names that shadow LiveCode tokens.** OXT chokes on custom names whose
   stem is an engine keyword/property even when prefixed. Real example that broke OXT compilation:
   `the uCat` / `the uMask` → renamed to **`uHitChans` / `uOnChans`**. Prefer **distinctive,
   multi-word stems** (`uHitChans`, not `uMask`). When in doubt, pick a longer, unambiguous name.
3. **Prefix conventions** (follow them; they also keep the audits clean):
   `u` = custom property on a control (`the uKind of grp`), `g` = script-local global,
   `t` = handler local, `p` = parameter, `k` = constant. Public API: `b2PascalCase` (extension),
   `b2kPascalCase` (Kit), `b2lc_snake_case` (C ABI).
4. **Control-structure shape matters.** Block form `if cond then` ⟶ … ⟶ `end if`; single-line form
   `if cond then doSomething` has **no** `end if`. A trailing `\` continues a logical line. Note:
   naive brace-counters (including the audit above) raise **known false positives** on a `\`-continued
   `if … then \` and on multi-line `else if` — verify by eye, don't "fix" valid code.
5. **`itemDelimiter` / `lineDelimiter` are global mutable state.** Set the delimiter immediately
   before parsing (`set the itemDelimiter to comma`) — never assume its current value. Points are
   `"x,y"` lines; many save records are tab-delimited; the two get interleaved constantly.
6. **Constants must be literals.** `constant k = "120"` is fine; `constant k = a*b` is not. Derive
   computed values at runtime (e.g. canvas edges in `prepArena`/`buildUI`, not as constants).
7. **Command results vs function returns.** A `b2k…` *command* reports via `the result` (or you
   `put` it). A *function* returns a value. `b2kSpawnBox` is a command → `put the result into tCtrl`.
8. **Custom properties are the per-object datastore, and everything is text.** Parts are LiveCode
   graphics carrying `uKind`, `uColor`, `uW/uH`, plus per-kind extras (`uLaserDir`, `uThrustPower`,
   `uFanDir`, …). Booleans round-trip as the strings `"true"`/`"false"`.
9. **Two coordinate systems, y flips.** The Kit is **screen pixels, degrees, y-DOWN**; the
   extension is **metres, radians, y-UP**. Kit wrappers do the conversion (divide by `sScale`,
   negate y — e.g. `b2kForce` passes `-fy`). If you add Kit code that calls the raw `b2*` API,
   mind the flip and the scale.

## The Contraption Builder (`examples/box2dxt-contraption-builder.livecodescript`)

The flagship example and the file most work happens in (~320 KB). Mental model:

- **It builds its own UI.** On open it programmatically constructs all chrome — top bar, palette,
  inspector, status bar — into the stack, then tags it with `kUIVersion`. **Bump `kUIVersion`
  whenever the built chrome changes** so older saved stacks rebuild once on load.
- **Parts are LiveCode graphics backed by Box2D bodies.** Placing a part creates a graphic, tags
  it (`tagPart` → sets `uKind`/`uColor`, calls `registerKind`), and (for body kinds) spawns a Kit
  body. `gParts` is the CR-list of part controls; joints live in parallel `gJ*` arrays.
- **The per-frame loop is `on b2kFrame`** (the Kit calls it each tick while running). It fans out to
  `renderJoints`, `updateFlashes`, `applyFieldForces`, `updateBombs`, `updateRings`,
  `updateLasers`, `updateThrusters`, `tickHud`. Build-mode redraws go through `renderBuild`.
- **No-body specials vs body parts.** Fans, magnets, and the laser have **no Box2D body** — they
  are pure graphics driven each frame. `kindHasBody(kind)` **must exclude them** (it returns false
  only for `fan`/`magnet`/`laser`), or body-only code (`b2kAngle`, `reseatDragged`, …) will error
  on them. `kindIsDynamic` lists the kinds that fans/magnets can push.
- **Save/load** is text: `serializeText` emits `part` / `joint` / `world` records; each part packs
  its extras via `partSpecial` (KV string like `"ldr=45;tpw=700"`) and restores them in
  `applyPartSpecial`. `partLine` saves a part's **anchor** = its `loc`, **except** kinds whose
  meaningful anchor isn't the bbox centre (the laser saves its **emitter** = point 1 of the beam).

### Recipe: adding a new part/special kind

Every kind must be wired through the **whole pipeline** or it half-works. Touch all of these
(grep an existing special like `fan` or `laser` as a template), then verify:

1. **Constants:** add the id to `kShapeTools`/`kSpecialTools`/`kTerrainTools` and its `…Labels`
   constant. **Bump `kUIVersion`** (palette changed).
2. **`placePart`:** add a `case "<id>"` → `place<Id>(pX,pY)`.
3. **`place<Id>()`:** create the graphic, set style/size and `u*` props, `tagPart` it, return the ref.
   Body kinds call `b2kSpawnBox/Ball/Capsule/…`; no-body kinds are just a graphic.
4. **`registerKind`/`unregisterKind`:** add the id to the tracked-kinds list **if it needs a
   per-frame tick** (so `gKindList[id]` is populated).
5. **Per-frame tick:** write `update<Id>s`, add it to `on b2kFrame` (and to `renderBuild` if it must
   refresh in build mode, like the laser beam).
6. **Classification:** `kindHasBody` (exclude no-body specials!) and `kindIsDynamic`.
7. **Inspector:** `partProps` (keys per kind; each tab's keys ≤ `kPropRows` = 10), `propGroup`
   (which tab: shape/physics/collide/special), `propLabel` (human label per key), `adjustPartProp`
   (the +/- stepper per key). For type-in values also `currentPropValue`/`applyPropValue`.
8. **Save/load:** `partSpecial` (pack KV, keys unique within the kind) and `applyPartSpecial`
   (restore). If the anchor isn't the graphic's `loc`, special-case `partLine`.
9. **Cosmetics:** `toolGlyph` (one glyph), `toolHelp` (two lines: short title + long help),
   `niceName`/`friendlyKind`.
10. **Verify:** smart-quote scan = 0, handler balance = 0, `sync --check` clean; confirm no tab
    exceeds 10 rows and no save-key collides. Then the user tests in OXT.

**Invariants the static audits should always hold:** every kind has a `placePart`/glyph/`toolHelp`/
`niceName`; every `partProps` key has both a `propLabel` and an `adjustPartProp` case; no tab > 10
rows; save-keys unique per kind; selection is non-destructive (`selectPart` stores `uSelFg`/`uSelLine`
and `deselectPart` restores them, so highlighting never corrupts a part's real colours).

## Contributing conventions (from CONTRIBUTING.md)

- **Units/types across the FFI:** reals `double`, booleans `int` (0/1), handles 1-based `int`
  (0 invalid). `b2*` = metres/radians, `b2k*` = pixels/degrees.
- **Safety first:** every handler tolerates stale/0 handles (validate with `b2*_IsValid` in C;
  getters return 0, actions no-op). Never let a bad handle reach Box2D.
- **Adding a raw handler:** `b2lc_*` in `src/box2d_lc.c` (validate inputs) → `foreign handler` +
  public `b2*` wrapper in `src/box2dxt.lcb` → bump `LC_ABI_VERSION` if the ABI changed → add a
  `tests/smoke_test.c` assertion. Keep the shim warning-clean (`-Wall -Wextra`, `/W3` on MSVC).
- **Match the surrounding style** — comment density, naming, idiom. This codebase comments the
  *why*, densely; mirror that.

## Git / workflow notes

- The session's working branch is set per-task (e.g. `claude/...`); develop, commit, and push there,
  then open a **draft PR** if none exists. Don't push to `main` without explicit permission.
- A Kit change is only complete when `tools/sync-embedded-kit.py` has been run and the re-synced
  examples are committed **in the same change** — CI's `--check` fails otherwise.
