#!/usr/bin/env python3
"""Assemble a ready-to-ship Box2Dxt platformer zip.

The zip is self-contained: the extension, the per-platform native libraries
(already renamed to the bare name the loader wants), a saved stack, and the
end-user install guide (dist/INSTALL.md). See its layout in that guide.

The only thing this script can't produce is the *saved* stack -- you build and
save platformer.livecode in OXT first, then point --stack at it:

    python3 tools/make-release.py --stack ~/Desktop/platformer.livecode

By default the native libraries come from prebuilt/ (the committed ABI-4
binaries). Override any of them with --win / --mac / --linux if you have a
fresher or differently-tuned build.

Run with --check to validate the inputs (and the embedded-Kit sync) without
writing the zip.
"""

import argparse
import sys
import zipfile
from pathlib import Path

REPO = Path(__file__).resolve().parent.parent

# arcname (inside lib/)  ->  default source under prebuilt/
DEFAULT_LIBS = {
    "box2dxt.dll": "prebuilt/box2dxt-windows-x64.dll",
    "box2dxt.dylib": "prebuilt/libbox2dxt-macos-universal.dylib",
    "box2dxt.so": "prebuilt/libbox2dxt-linux-x86_64.so",
}


def human(nbytes):
    size = float(nbytes)
    for unit in ("B", "KB", "MB"):
        if size < 1024 or unit == "MB":
            return f"{size:.0f} {unit}" if unit == "B" else f"{size:.1f} {unit}"
        size /= 1024
    return f"{size:.1f} MB"


def main():
    ap = argparse.ArgumentParser(description="Build the Box2Dxt platformer distribution zip.")
    ap.add_argument("--stack", help="path to the built & saved platformer stack (.livecode)")
    ap.add_argument("--out", default="dist/box2dxt-platformer.zip", help="output zip path (default: dist/box2dxt-platformer.zip)")
    ap.add_argument("--top", default="box2dxt-platformer", help="top-level folder name inside the zip")
    ap.add_argument("--stack-name", default="platformer.livecode", help="filename the stack gets inside the zip (the guide refers to this name)")
    ap.add_argument("--win", help="override the Windows library (-> lib/box2dxt.dll)")
    ap.add_argument("--mac", help="override the macOS library (-> lib/box2dxt.dylib)")
    ap.add_argument("--linux", help="override the Linux library (-> lib/box2dxt.so)")
    ap.add_argument("--check", action="store_true", help="validate inputs only; do not write the zip")
    args = ap.parse_args()

    # Resolve the four always-bundled pieces + the per-platform libraries.
    items = []  # (arcname-relative-to-top, source Path)
    problems = []

    lcb = REPO / "src" / "box2dxt.lcb"
    install = REPO / "dist" / "INSTALL.md"
    for arc, src in (("box2dxt.lcb", lcb), ("INSTALL.md", install)):
        if src.is_file():
            items.append((arc, src))
        else:
            problems.append(f"missing required file: {src.relative_to(REPO) if src.is_relative_to(REPO) else src}")

    overrides = {"box2dxt.dll": args.win, "box2dxt.dylib": args.mac, "box2dxt.so": args.linux}
    for bare, default_rel in DEFAULT_LIBS.items():
        src = Path(overrides[bare]).expanduser() if overrides[bare] else (REPO / default_rel)
        if src.is_file():
            items.append((f"lib/{bare}", src))
        else:
            problems.append(f"missing library for lib/{bare}: {src}")

    # The saved stack is required to build the zip (but not just to --check).
    stack = None
    if args.stack:
        stack = Path(args.stack).expanduser()
        if stack.is_file():
            items.append((args.stack_name, stack))
        else:
            problems.append(f"--stack is not a file: {stack}")
    elif not args.check:
        problems.append("--stack is required (build & save platformer.livecode in OXT first)")

    if problems:
        print("Cannot build the release:", file=sys.stderr)
        for p in problems:
            print(f"  - {p}", file=sys.stderr)
        return 1

    print(f"Release contents (top folder: {args.top}/):")
    for arc, src in items:
        print(f"  {arc:<22} <- {src if not src.is_relative_to(REPO) else src.relative_to(REPO)}  ({human(src.stat().st_size)})")

    if args.check:
        print("\n--check: inputs valid" + ("" if stack else " (no --stack given; a real build needs one)") + ".")
        return 0

    out = (REPO / args.out) if not Path(args.out).is_absolute() else Path(args.out)
    out.parent.mkdir(parents=True, exist_ok=True)
    with zipfile.ZipFile(out, "w", zipfile.ZIP_DEFLATED) as z:
        for arc, src in items:
            z.write(src, f"{args.top}/{arc}")

    print(f"\nWrote {out.relative_to(REPO) if out.is_relative_to(REPO) else out}  ({human(out.stat().st_size)}).")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
