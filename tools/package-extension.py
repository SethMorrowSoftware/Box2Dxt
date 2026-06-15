#!/usr/bin/env python3
"""Assemble a ready-to-Package LCB extension that bundles the native library.

This is the *intended* way to ship native code with a LiveCode Builder
extension: the per-platform shared library lives INSIDE the extension, under a
``code/<platform>/`` folder next to the ``.lcb``. The engine resolves the
``c:box2dxt>...`` foreign bindings from there at load time -- so the consumer
installs ONE extension and the library comes with it. No loose ``.so`` on a
search path, no ``/usr/lib``, no sudo, no ``LD_LIBRARY_PATH``, and no per-stack
loader code. Works the same on Linux, macOS and Windows.

Run this, then open the produced ``box2dxt.lcb`` in OXT's Extension Builder and
click Package -- the ``code/`` tree is rolled into the ``.lce``.

    python3 tools/package-extension.py            # -> dist/box2dxt-extension/
    python3 tools/package-extension.py --check    # validate inputs only

The native libraries come from prebuilt/ by default (the committed ABI-4
binaries); override any with --linux64 / --linux32 / --win64 / --win32 / --mac.

NOTE ON FOLDER NAMES: the engine's platform sub-folder names have drifted across
LiveCode/OXT releases (e.g. the macOS folder has been both ``mac`` and
``universal-mac``). The map below uses the current LiveCode docs' spelling;
if OXT looks elsewhere, adjust CODE_LAYOUT (or pass --mac-folder) to match what
your OXT build expects -- confirm against an existing native extension's layout.
"""

import argparse
import os
import shutil
import sys

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))

# The extension source (the single source of truth for the binding layer).
LCB_SRC = "src/box2dxt.lcb"

# code/<platform>/<bare-name>  <-  default committed binary in prebuilt/.
# The bare name must match the library token in the binding string ("box2dxt"),
# so the engine maps c:box2dxt> to box2dxt.{so,dll,dylib} inside the folder.
CODE_LAYOUT = {
    "linux-x86_64":  ("prebuilt/libbox2dxt-linux-x86_64.so",     "box2dxt.so"),
    "linux-x86":     ("prebuilt/libbox2dxt-linux-i686.so",       "box2dxt.so"),
    "win-x86_64":    ("prebuilt/box2dxt-windows-x64.dll",        "box2dxt.dll"),
    "win-x86":       ("prebuilt/box2dxt-windows-x86.dll",        "box2dxt.dll"),
    "universal-mac": ("prebuilt/libbox2dxt-macos-universal.dylib", "box2dxt.dylib"),
}


def main():
    ap = argparse.ArgumentParser(description="Assemble the code/<platform>/ extension package.")
    ap.add_argument("--out", default="dist/box2dxt-extension",
                    help="output folder (default: dist/box2dxt-extension)")
    ap.add_argument("--linux64", help="override the 64-bit Linux .so")
    ap.add_argument("--linux32", help="override the 32-bit Linux .so")
    ap.add_argument("--win64", help="override the 64-bit Windows .dll")
    ap.add_argument("--win32", help="override the 32-bit Windows .dll")
    ap.add_argument("--mac", help="override the macOS .dylib")
    ap.add_argument("--mac-folder", default="universal-mac",
                    help="platform folder name for macOS (some builds use 'mac')")
    ap.add_argument("--check", action="store_true",
                    help="validate inputs without writing anything")
    args = ap.parse_args()

    overrides = {
        "linux-x86_64": args.linux64,
        "linux-x86": args.linux32,
        "win-x86_64": args.win64,
        "win-x86": args.win32,
        "universal-mac": args.mac,
    }

    # Resolve every input first; report ALL problems before touching the disk.
    lcb_abs = os.path.join(ROOT, LCB_SRC)
    plan = []          # (dest_relpath, src_abspath)
    problems = []
    if not os.path.isfile(lcb_abs):
        problems.append(f"missing extension source: {LCB_SRC}")
    else:
        plan.append(("box2dxt.lcb", lcb_abs))

    for platform, (default_src, bare) in CODE_LAYOUT.items():
        folder = args.mac_folder if platform == "universal-mac" else platform
        src = overrides[platform] or default_src
        src_abs = src if os.path.isabs(src) else os.path.join(ROOT, src)
        if os.path.isfile(src_abs):
            plan.append((os.path.join("code", folder, bare), src_abs))
        else:
            problems.append(f"missing library for code/{folder}/{bare}: {src}")

    if problems:
        print("Cannot package -- inputs missing:", file=sys.stderr)
        for p in problems:
            print(f"  - {p}", file=sys.stderr)
        return 1

    if args.check:
        print("All inputs present. Would assemble:")
        for dest, _ in plan:
            print(f"  {args.out}/{dest}")
        return 0

    out_abs = os.path.join(ROOT, args.out) if not os.path.isabs(args.out) else args.out
    if os.path.isdir(out_abs):
        shutil.rmtree(out_abs)
    for dest, src_abs in plan:
        dest_abs = os.path.join(out_abs, dest)
        os.makedirs(os.path.dirname(dest_abs), exist_ok=True)
        shutil.copy2(src_abs, dest_abs)
        print(f"  + {dest}")

    print()
    print(f"Extension assembled at: {args.out}")
    print("Next: open that box2dxt.lcb in OXT's Extension Builder and click Package.")
    print("The code/<platform>/ libraries are rolled into the .lce automatically.")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
