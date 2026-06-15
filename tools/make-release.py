#!/usr/bin/env python3
"""Assemble a ready-to-ship Box2Dxt platformer package.

The zip is self-contained and matches dist/INSTALL.md:

    NewPlateformerDemo.oxtstack    (your saved stack -- --stack)
    INSTALL.md
    source/      box2dxt.lcb, box2d_lc.c, box2dxt-kit.livecodescript
    libraries/   box2dxt.dll, box2dxt.dylib, box2dxt.so  (renamed to the bare name)
    spritesheets/  the platformer's PNG + XML sheets

The only thing this script can't produce is the *saved* stack -- build and save
it in OXT first, then point --stack at it:

    python3 tools/make-release.py --stack ~/Desktop/NewPlateformerDemo.oxtstack

By default the native libraries come from prebuilt/ (the committed ABI-4
binaries) and the art from Spritesheets/. Override the libs with --win / --mac /
--linux, or the art folder with --sheets. --check validates the inputs only.
"""

import argparse
import sys
import zipfile
from pathlib import Path

REPO = Path(__file__).resolve().parent.parent

# the extension, the C shim, and the Kit  ->  source/
SOURCE_FILES = ["box2dxt.lcb", "box2d_lc.c", "box2dxt-kit.livecodescript"]

# bare deploy name  ->  default committed binary  (goes to libraries/)
DEFAULT_LIBS = {
    "box2dxt.dll": "prebuilt/box2dxt-windows-x64.dll",
    "box2dxt.dylib": "prebuilt/libbox2dxt-macos-universal.dylib",
    "box2dxt.so": "prebuilt/libbox2dxt-linux-x86_64.so",
}

# the spritesheets the platformer loads (PNG + XML each)  ->  spritesheets/
PLATFORMER_SHEETS = [
    "spritesheet-characters-default", "spritesheet-enemies-default",
    "spritesheet-tiles-default", "spritesheet-backgrounds-default", "enemies",
]


def human(nbytes):
    size = float(nbytes)
    for unit in ("B", "KB", "MB"):
        if size < 1024 or unit == "MB":
            return f"{size:.0f} {unit}" if unit == "B" else f"{size:.1f} {unit}"
        size /= 1024
    return f"{size:.1f} MB"


def rel(src):
    return src.relative_to(REPO) if src.is_relative_to(REPO) else src


def main():
    ap = argparse.ArgumentParser(description="Build the Box2Dxt platformer distribution zip.")
    ap.add_argument("--stack", help="path to the built & saved platformer stack (.oxtstack)")
    ap.add_argument("--out", default="dist/NewPlateformerDemo.zip", help="output zip path")
    ap.add_argument("--top", default="NewPlateformerDemo", help="top-level folder name inside the zip")
    ap.add_argument("--stack-name", default="NewPlateformerDemo.oxtstack", help="filename the stack gets inside the zip (the guide refers to this name)")
    ap.add_argument("--sheets", default="Spritesheets", help="folder holding the platformer's spritesheets")
    ap.add_argument("--win", help="override the Windows library (-> libraries/box2dxt.dll)")
    ap.add_argument("--mac", help="override the macOS library (-> libraries/box2dxt.dylib)")
    ap.add_argument("--linux", help="override the Linux library (-> libraries/box2dxt.so)")
    ap.add_argument("--check", action="store_true", help="validate inputs only; do not write the zip")
    args = ap.parse_args()

    items = []  # (arcname-relative-to-top, source Path)
    problems = []

    # source/ : the extension, the C shim, the Kit
    for name in SOURCE_FILES:
        src = REPO / "src" / name
        if src.is_file():
            items.append((f"source/{name}", src))
        else:
            problems.append(f"missing source file: src/{name}")

    # the install guide, at the root
    install = REPO / "dist" / "INSTALL.md"
    if install.is_file():
        items.append(("INSTALL.md", install))
    else:
        problems.append("missing dist/INSTALL.md")

    # libraries/ : the per-platform native libs, renamed to the bare name
    overrides = {"box2dxt.dll": args.win, "box2dxt.dylib": args.mac, "box2dxt.so": args.linux}
    for bare, default_rel in DEFAULT_LIBS.items():
        src = Path(overrides[bare]).expanduser() if overrides[bare] else (REPO / default_rel)
        if src.is_file():
            items.append((f"libraries/{bare}", src))
        else:
            problems.append(f"missing library for libraries/{bare}: {src}")

    # spritesheets/ : the demo's art (PNG + XML pairs)
    sheets_dir = Path(args.sheets).expanduser()
    if not sheets_dir.is_absolute():
        sheets_dir = REPO / args.sheets
    for base in PLATFORMER_SHEETS:
        for ext in ("png", "xml"):
            src = sheets_dir / f"{base}.{ext}"
            if src.is_file():
                items.append((f"spritesheets/{base}.{ext}", src))
            else:
                problems.append(f"missing spritesheet: {src}")

    # the saved stack, at the root (required to build the zip, not just to --check)
    stack = None
    if args.stack:
        stack = Path(args.stack).expanduser()
        if stack.is_file():
            items.append((args.stack_name, stack))
        else:
            problems.append(f"--stack is not a file: {stack}")
    elif not args.check:
        problems.append("--stack is required (build & save the .oxtstack in OXT first)")

    if problems:
        print("Cannot build the release:", file=sys.stderr)
        for p in problems:
            print(f"  - {p}", file=sys.stderr)
        return 1

    print(f"Release contents (top folder: {args.top}/):")
    for arc, src in items:
        print(f"  {arc:<34} <- {rel(src)}  ({human(src.stat().st_size)})")

    if args.check:
        print("\n--check: inputs valid" + ("" if stack else " (no --stack given; a real build needs one)") + ".")
        return 0

    out = Path(args.out) if Path(args.out).is_absolute() else (REPO / args.out)
    out.parent.mkdir(parents=True, exist_ok=True)
    with zipfile.ZipFile(out, "w", zipfile.ZIP_DEFLATED) as z:
        for arc, src in items:
            z.write(src, f"{args.top}/{arc}")

    print(f"\nWrote {rel(out)}  ({human(out.stat().st_size)}).")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
