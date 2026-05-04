#!/usr/bin/env python3
"""
SwiftPM on Xcode 26 can fail resolving SideStore/AltSign with:
  the package manifest at '/Package.swift' cannot be accessed

The CAltSign target uses `path: ""` for the package root; use `path: "."` instead.
Run after `git submodule update --init` so Dependencies/AltSign/Package.swift exists.
"""
from __future__ import annotations

import re
import sys
from pathlib import Path

ROOT = Path(__file__).resolve().parents[2]
PKG = ROOT / "Dependencies" / "AltSign" / "Package.swift"


def main() -> int:
    if not PKG.is_file():
        print(f"error: missing {PKG} (init submodules?)", file=sys.stderr)
        return 1
    text = PKG.read_text(encoding="utf-8")
    # AltSign indents with a leading space before `.target(` — match that too.
    pattern = r'(\s*\.target\(\s*\n\s*name:\s*"CAltSign",[\s\S]*?)path:\s*""\s*,'
    new, n = re.subn(pattern, r'\1path: ".",', text, count=1)
    if n == 1:
        PKG.write_text(new, encoding="utf-8")
        print(f"Patched {PKG} (CAltSign path \"\" -> \".\").")
        return 0
    if re.search(
        r'\s*\.target\(\s*\n\s*name:\s*"CAltSign",[\s\S]*?path:\s*"\."\s*,',
        text,
    ):
        print("AltSign CAltSign already uses path: '.'; nothing to do.")
        return 0
    print("error: could not find CAltSign target with path: \"\" to patch", file=sys.stderr)
    return 1


if __name__ == "__main__":
    sys.exit(main())
