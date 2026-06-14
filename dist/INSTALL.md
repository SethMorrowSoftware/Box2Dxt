# Box2Dxt Platformer — Install & Run

Everything needed to run the **Box2Dxt** physics platformer is in this package —
no C compiler, no internet, no extra downloads. You just need **OpenXTalk (OXT)**
installed (the demo is an OXT `.oxtstack`; OXT is the OpenXTalk fork of LiveCode,
and the extension/engine are also compatible with **LiveCode 9.6.3+**).

## What's in this package

```
NewPlateformerDemo.oxtstack    ← the platformer stack (you open this)
source/
├── box2dxt.lcb                ← the Box2Dxt extension (the b2… physics API)
├── box2d_lc.c                 ← the C shim it binds to (source, for rebuilding)
└── box2dxt-kit.livecodescript ← the Kit (the friendly b2k… layer; also embedded
                                  in the stack, so the demo runs on its own)
libraries/
├── box2dxt.dll                ← native library — Windows (x64)
├── box2dxt.dylib              ← native library — macOS (Intel + Apple Silicon)
└── box2dxt.so                 ← native library — Linux (x86-64)
spritesheets/                  ← the demo's art (point the stack here on first run)
```

To **run** the demo you only touch three things, in order: a native library
(Step 1), the extension (Step 2), and the stack (Step 3). The `box2d_lc.c` and
the standalone Kit in `source/` are there for reference / rebuilding — you don't
need them to play.

---

## Step 1 · Put the native library where the engine can find it

Box2Dxt's physics run in a small native library. Copy the **one file for your
OS** from `libraries/`:

| Your OS | Copy this file | To here |
|---------|----------------|---------|
| **Windows** | `libraries/box2dxt.dll` | the **same folder** as `NewPlateformerDemo.oxtstack` |
| **macOS** | `libraries/box2dxt.dylib` | the **same folder** as `NewPlateformerDemo.oxtstack` |
| **Linux** | `libraries/box2dxt.so` | a library search path — see the note below |

**Do not rename these files.** They are already the bare name the loader looks
for (`box2dxt`, with no `lib` prefix). Renaming is the #1 cause of "unable to
load foreign library".

> **Linux only.** The dynamic loader does *not* search the stack's folder. Put
> `box2dxt.so` somewhere the loader looks:
> ```
> sudo cp libraries/box2dxt.so /usr/lib/ && sudo ldconfig
> ```
> (or place it next to the OXT engine binary, or add its folder to
> `LD_LIBRARY_PATH` before launching OXT).

---

## Step 2 · Install the extension

The extension `source/box2dxt.lcb` adds the `b2…` physics handlers to the IDE.

1. Launch **OXT**.
2. Open **Tools → Extension Manager**.
3. Click **+ (Add)**, choose **`source/box2dxt.lcb`** from this package, then
   click **Load**.

> Alternatively: **Tools → Extension Builder**, open `source/box2dxt.lcb`, and
> click **Test** — that compiles and loads it in one step.

**Confirm it worked:** open the **Message Box** (the small toolbar icon, or
Ctrl/Cmd-M) and type:

```
put b2Version()
```

Press Enter. You should see **`4`**. If you get an error, see *Troubleshooting*.

---

## Step 3 · Open the platformer

Open **`NewPlateformerDemo.oxtstack`** (File → Open Stack…, or double-click it).
The game builds itself and starts immediately.

- **First run** asks you to locate a spritesheet folder — choose the
  **`spritesheets/`** folder in this package. After you **save** the stack the
  art is remembered (and cached), so it loads instantly every time after.
- **Controls:** **arrows / WASD** move · **Space** jump (press again in mid-air
  to **double-jump**, or off a wall to **wall-jump**) · **SHIFT / X** dash ·
  **↓** duck · **R** restart · **M** mute. Grab every coin (the flag turns gold)
  and touch the flag to advance — there are four levels.

That's it. Enjoy the physics.

---

## Troubleshooting

| Symptom | Fix |
|---------|-----|
| `b2Version()` errors, or "handler not found" | The extension isn't loaded. Redo **Step 2** (Extension Manager → Load `source/box2dxt.lcb`). It loads per IDE session. |
| First physics call says **"unable to load foreign library"** | The native library isn't found. Make sure the `libraries/` file for your OS sits **next to `NewPlateformerDemo.oxtstack`** (Windows/macOS) or on a loader path (Linux). Don't rename it. *Tip: launch OXT from a terminal — it prints the exact filename it's looking for.* |
| `b2Version()` returns a number **other than 4** | Your `box2dxt.lcb` and the native library are from different builds. Use the `source/box2dxt.lcb` and the `libraries/` file **from this same package** together. |
| The level loads with plain placeholder shapes (no art) | On first run, point the spritesheet prompt at this package's **`spritesheets/`** folder, then **save** the stack. (Hold **Shift** while pressing **R** to re-pick the folder.) |
| The window opens but nothing moves, or a `b2…` call errors | The extension loaded but the native library didn't (or is the wrong build). Re-check Steps 1–2 and confirm `put b2Version()` is `4` before opening the stack. |

---

*Box2Dxt is the Box2D v3 physics engine packaged for OpenXTalk and the xTalk
language family. The platformer is one of several example games. The `source/`
folder holds the full extension, its C shim, and the Kit; for the complete
toolkit and documentation, see the project repository.*
