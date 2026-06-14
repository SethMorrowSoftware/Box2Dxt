# Box2Dxt Platformer — Install & Run

Everything needed to run the **Box2Dxt** physics platformer is in this folder.
No C compiler, no internet, no extra downloads — just these files and an
**OpenXTalk (OXT)** or **LiveCode 9.6.3+** IDE you already have installed.

## What's in this package

```
box2dxt-platformer/
├── INSTALL.md           ← you are here
├── box2dxt.lcb          ← the Box2Dxt extension (the b2… physics API)
├── platformer.livecode  ← the platformer stack (you open this last)
└── lib/
    ├── box2dxt.dll      ← native library — Windows (x64)
    ├── box2dxt.dylib    ← native library — macOS (Intel + Apple Silicon)
    └── box2dxt.so       ← native library — Linux (x86-64)
```

You only need the **one** `lib/` file for your operating system.

---

## Step 1 · Put the native library where the engine can find it

Box2Dxt's physics run in a small native library. Copy the file for your OS:

| Your OS | Copy this file | To here |
|---------|----------------|---------|
| **Windows** | `lib/box2dxt.dll` | the **same folder** as `platformer.livecode` |
| **macOS** | `lib/box2dxt.dylib` | the **same folder** as `platformer.livecode` |
| **Linux** | `lib/box2dxt.so` | a library search path — see the note below |

**Do not rename these files.** They are already the bare name the loader looks
for (`box2dxt`, with no `lib` prefix). Renaming is the #1 cause of "unable to
load foreign library".

> **Linux only.** The dynamic loader does *not* search the stack's folder. Put
> `box2dxt.so` somewhere the loader looks:
> ```
> sudo cp lib/box2dxt.so /usr/lib/ && sudo ldconfig
> ```
> (or place it next to the OXT engine binary, or add its folder to
> `LD_LIBRARY_PATH` before launching OXT).

---

## Step 2 · Install the extension

The extension `box2dxt.lcb` adds the `b2…` physics handlers to the IDE.

1. Launch **OXT / LiveCode**.
2. Open **Tools → Extension Manager**.
3. Click **+ (Add)**, choose **`box2dxt.lcb`** from this folder, then click
   **Load**.

> Alternatively: **Tools → Extension Builder**, open `box2dxt.lcb`, and click
> **Test** — that compiles and loads it in one step.

**Confirm it worked:** open the **Message Box** (the small toolbar icon, or
Ctrl/Cmd-M) and type:

```
put b2Version()
```

Press Enter. You should see **`4`**. If you get an error, see *Troubleshooting*.

---

## Step 3 · Open the platformer

Open **`platformer.livecode`** (File → Open Stack…, or double-click it). The
game builds itself and starts immediately.

- **First run** may ask you to locate a spritesheet folder. Click **Cancel** to
  play with the built-in placeholder art, or point it at a Kenney spritesheet
  folder if you have one. Once you **save** the stack, the artwork is remembered
  and loads instantly every time after.
- **Controls:** **arrows** or **WASD** to move · **Space** to jump · **↓** to
  duck. Grab the coins and touch the flag to advance — there are four levels.

That's it. Enjoy the physics.

---

## Troubleshooting

| Symptom | Fix |
|---------|-----|
| `b2Version()` errors, or "handler not found" | The extension isn't loaded. Redo **Step 2** (Extension Manager → Load `box2dxt.lcb`). It loads per IDE session. |
| First physics call says **"unable to load foreign library"** | The native library isn't found. Make sure the `lib/` file for your OS sits **next to `platformer.livecode`** (Windows/macOS) or on a loader path (Linux). Don't rename it. *Tip: launch OXT from a terminal — it prints the exact filename it's looking for.* |
| `b2Version()` returns a number **other than 4** | Your `box2dxt.lcb` and the native library are from different builds. Use the `.lcb` and the `lib/` file **from this same package** together. |
| The window opens but nothing moves, or a `b2…` call errors | The extension loaded but the native library didn't (or is the wrong build). Re-check Steps 1–2 and confirm `put b2Version()` is `4` before opening the stack. |

---

*Box2Dxt is the Box2D v3 physics engine packaged for OpenXTalk and the xTalk
language family. The platformer is one of several example games. For the full
toolkit, source, and documentation, see the project repository.*
