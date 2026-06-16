#!/usr/bin/env python3
"""Populate code/<platform-id>/ beside the extension source with the native libs.

This is the intended, cross-platform way to ship native code with a LiveCode
Builder extension: the per-platform shared library lives INSIDE the extension,
in a code/<platform-id>/ folder next to the .lcb. When the extension is built
and installed, the IDE maps each library into `the revLibraryMapping` and the
engine resolves the c:box2dxt> bindings from there -- so the consumer installs
ONE extension and the library comes with it. No loose .so/.dll/.dylib, no
/usr/lib, no sudo, no LD_LIBRARY_PATH, no "next to the stack". Same on Linux,
macOS and Windows, on LiveCode 9.6.3 and OpenXTalk.

Because the libs live next to src/box2dxt.lcb, that folder IS the ready-to-build
extension: open src/box2dxt.lcb in OXT's Extension Builder and Package -> .lce.

    python3 tools/package-extension.py            # populate src/code/<id>/
    python3 tools/package-extension.py --check    # validate inputs only

Libs come from prebuilt/ by default; override with --linux64 / --linux32 /
--win64 / --win32 / --mac.

PLATFORM-ID FORMAT: <architecture>-<platform>, verified against the LiveCode/OXT
engine + IDE source (the IDE's code-folder matcher filters on `the processor`
first, then the platform). The architecture comes FIRST -- e.g. x86_64-linux,
NOT linux-x86_64. Windows uses the -win32 suffix for both bitnesses.
"""

import argparse
import os
import shutil
import sys

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))

# The extension source; its folder is where the code/ tree is written.
LCB_SRC = "src/box2dxt.lcb"

# code/<platform-id>/<bare-name>  <-  default committed binary in prebuilt/.
# <platform-id> is "<arch>-<platform>" (arch FIRST) -- this is what the engine/
# IDE actually match. The bare name must equal the binding token "box2dxt"
# (the engine maps c:box2dxt> to box2dxt.{so,dll,dylib} -- no "lib" prefix).
CODE_LAYOUT = {
    "x86_64-linux":  ("prebuilt/libbox2dxt-linux-x86_64.so",       "box2dxt.so"),
    "x86-linux":     ("prebuilt/libbox2dxt-linux-i686.so",         "box2dxt.so"),
    "x86_64-win32":  ("prebuilt/box2dxt-windows-x64.dll",          "box2dxt.dll"),
    "x86-win32":     ("prebuilt/box2dxt-windows-x86.dll",          "box2dxt.dll"),
    "universal-mac": ("prebuilt/libbox2dxt-macos-universal.dylib", "box2dxt.dylib"),
}


def main():
    ap = argparse.ArgumentParser(description="Populate code/<platform-id>/ beside the extension source.")
    ap.add_argument("--linux64", help="override the 64-bit Linux .so")
    ap.add_argument("--linux32", help="override the 32-bit Linux .so")
    ap.add_argument("--win64", help="override the 64-bit Windows .dll")
    ap.add_argument("--win32", help="override the 32-bit Windows .dll")
    ap.add_argument("--mac", help="override the macOS .dylib")
    ap.add_argument("--check", action="store_true", help="validate inputs without writing")
    args = ap.parse_args()

    overrides = {
        "x86_64-linux": args.linux64,
        "x86-linux": args.linux32,
        "x86_64-win32": args.win64,
        "x86-win32": args.win32,
        "universal-mac": args.mac,
    }

    code_root = os.path.join(ROOT, os.path.dirname(LCB_SRC), "code")
    plan = []          # (dest_abspath, src_abspath)
    problems = []
    if not os.path.isfile(os.path.join(ROOT, LCB_SRC)):
        problems.append(f"missing extension source: {LCB_SRC}")

    for platform_id, (default_src, bare) in CODE_LAYOUT.items():
        src = overrides[platform_id] or default_src
        src_abs = src if os.path.isabs(src) else os.path.join(ROOT, src)
        if os.path.isfile(src_abs):
            plan.append((os.path.join(code_root, platform_id, bare), src_abs))
        else:
            problems.append(f"missing library for code/{platform_id}/{bare}: {src}")

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
    print("src/box2dxt.lcb + src/code/ is now the ready-to-build extension.")
    print("Open src/box2dxt.lcb in OXT's Extension Builder and Package -> .lce.")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
