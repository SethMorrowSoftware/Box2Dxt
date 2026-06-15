#!/usr/bin/env python3
"""Place the native libraries beside the extension source as code/<platform>/.

This is the *intended* way to ship native code with a LiveCode Builder
extension: the per-platform shared library lives INSIDE the extension, in a
``code/<platform>/`` folder right next to the ``.lcb``. The engine resolves the
``c:box2dxt>...`` foreign bindings from there at load time -- so the consumer
installs ONE extension and the library comes with it. No loose ``.so`` on a
search path, no ``/usr/lib``, no sudo, no ``LD_LIBRARY_PATH``, no per-stack
loader code. Same story on Linux, macOS and Windows.

Because the libraries live next to ``src/box2dxt.lcb``, that folder *is* the
ready-to-Package extension: open ``src/box2dxt.lcb`` in OXT's Extension Builder
and click Package -- the ``code/`` tree is rolled into the ``.lce``. (We keep
the binaries beside the real source rather than copying the ``.lcb`` into a
separate package folder, so there is never a second copy of the script to drift.)

    python3 tools/package-extension.py            # populate src/code/<platform>/
    python3 tools/package-extension.py --check    # validate inputs only

The native libraries come from prebuilt/ by default (the committed ABI-4
binaries); override any with --linux64 / --linux32 / --win64 / --win32 / --mac.

NOTE ON FOLDER NAMES: the engine's platform sub-folder names have drifted across
LiveCode/OXT releases (e.g. the macOS folder has been both ``mac`` and
``universal-mac``). The map below uses the current LiveCode docs' spelling; if
OXT looks elsewhere, adjust CODE_LAYOUT (or pass --mac-folder) to match what your
OXT build expects -- confirm against an existing native extension's layout.
"""

import argparse
import os
import shutil
import sys

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))

# The extension source. Its folder is where the code/ tree is written, so the
# library sits beside the .lcb exactly as the Extension Builder expects.
LCB_SRC = "src/box2dxt.lcb"

# code/<platform>/<bare-name>  <-  default committed binary in prebuilt/.
# The bare name must match the library token in the binding string ("box2dxt"),
# so the engine maps c:box2dxt> to box2dxt.{so,dll,dylib} inside the folder.
CODE_LAYOUT = {
    "linux-x86_64":  ("prebuilt/libbox2dxt-linux-x86_64.so",      "box2dxt.so"),
    "linux-x86":     ("prebuilt/libbox2dxt-linux-i686.so",        "box2dxt.so"),
    "win-x86_64":    ("prebuilt/box2dxt-windows-x64.dll",         "box2dxt.dll"),
    "win-x86":       ("prebuilt/box2dxt-windows-x86.dll",         "box2dxt.dll"),
    "universal-mac": ("prebuilt/libbox2dxt-macos-universal.dylib", "box2dxt.dylib"),
}


def main():
    ap = argparse.ArgumentParser(description="Populate code/<platform>/ beside the extension source.")
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

    code_root = os.path.join(ROOT, os.path.dirname(LCB_SRC), "code")

    # Resolve every input first; report ALL problems before touching the disk.
    plan = []          # (dest_abspath, src_abspath)
    problems = []
    if not os.path.isfile(os.path.join(ROOT, LCB_SRC)):
        problems.append(f"missing extension source: {LCB_SRC}")

    for platform, (default_src, bare) in CODE_LAYOUT.items():
        folder = args.mac_folder if platform == "universal-mac" else platform
        src = overrides[platform] or default_src
        src_abs = src if os.path.isabs(src) else os.path.join(ROOT, src)
        if os.path.isfile(src_abs):
            plan.append((os.path.join(code_root, folder, bare), src_abs))
        else:
            problems.append(f"missing library for code/{folder}/{bare}: {src}")

    if problems:
        print("Cannot package -- inputs missing:", file=sys.stderr)
        for p in problems:
            print(f"  - {p}", file=sys.stderr)
        return 1

    rel = lambda p: os.path.relpath(p, ROOT)
    if args.check:
        print("All inputs present. Would write:")
        for dest, _ in plan:
            print(f"  {rel(dest)}")
        return 0

    for dest_abs, src_abs in plan:
        os.makedirs(os.path.dirname(dest_abs), exist_ok=True)
        shutil.copy2(src_abs, dest_abs)
        print(f"  + {rel(dest_abs)}")

    print()
    print("src/box2dxt.lcb + src/code/ is now the ready-to-Package extension.")
    print("Open src/box2dxt.lcb in OXT's Extension Builder and click Package -> .lce.")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
