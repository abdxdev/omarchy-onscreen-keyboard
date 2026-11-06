#!/usr/bin/env python3
"""Generate Keysyms.js from xkbcommon-keysyms.h (python3 stdlib only).

Usage: tools/gen-keysyms.py [path/to/xkbcommon-keysyms.h] [output.js]

Emits two tables:
  keysymChars  keysym name -> character, for every keysym that maps to Unicode.
  letterRanges flat [start, end, start, end, ...] code point ranges whose
               Unicode general category is L* or M* (letters and combining
               marks). Qt's JS engine has no \\p{L}, so this stands in for it.
"""
import os
import re
import subprocess
import sys
import unicodedata

DEFAULT_HEADER = "/usr/include/xkbcommon/xkbcommon-keysyms.h"
OUT_DEFAULT = os.path.join(os.path.dirname(os.path.abspath(__file__)), "..", "Keysyms.js")

DEFINE = re.compile(r"^#define\s+XKB_KEY_(\w+)\s+(0x[0-9a-fA-F]+)\s*(.*)$")
# Exact mappings only: "/* U+0627 ARABIC ... */". Approximate ones, written
# "/*<U+...>*/" or "/*(U+...)*/" (keypad keys etc.), are skipped.
EXACT = re.compile(r"^/\*\s+U\+([0-9A-Fa-f]{4,6})\b")


def js_char(cp):
    if cp > 0xFFFF:
        cp -= 0x10000
        return "\\u%04x\\u%04x" % (0xD800 + (cp >> 10), 0xDC00 + (cp & 0x3FF))
    return "\\u%04x" % cp


def parse(path):
    entries = []  # (name, value, codepoint or None)
    with open(path, encoding="utf-8") as f:
        for line in f:
            m = DEFINE.match(line)
            if not m:
                continue
            name, value, rest = m.group(1), int(m.group(2), 16), m.group(3)
            cp = None
            e = EXACT.match(rest)
            if e:
                cp = int(e.group(1), 16)
            elif 0x01000100 <= value <= 0x0110FFFF:
                cp = value - 0x01000000
            entries.append((name, value, cp))
    # Aliases ("deprecated", "non-deprecated alias for ...") share a value with
    # a keysym that carries the U+ comment, so inherit by value.
    by_value = {v: cp for _, v, cp in entries if cp is not None}
    table = {}
    for name, value, cp in entries:
        if cp is None:
            cp = by_value.get(value)
        if cp is not None:
            table[name] = cp
    return table


def letter_ranges():
    ranges = []
    start = prev = None
    for cp in range(0x110000):
        if 0xD800 <= cp <= 0xDFFF:
            continue
        if unicodedata.category(chr(cp))[0] in "LM":
            if start is None:
                start = prev = cp
            elif cp == prev + 1:
                prev = cp
            else:
                ranges += [start, prev]
                start = prev = cp
    if start is not None:
        ranges += [start, prev]
    return ranges


def key(name):
    return name if re.match(r"^[A-Za-z_]\w*$", name) else '"%s"' % name


def main():
    header = sys.argv[1] if len(sys.argv) > 1 else DEFAULT_HEADER
    out = sys.argv[2] if len(sys.argv) > 2 else OUT_DEFAULT
    table = parse(header)
    try:
        ver = subprocess.run(["pacman", "-Q", "libxkbcommon"], capture_output=True,
                             text=True, check=True).stdout.strip()
    except Exception:
        ver = "unknown version"
    lines = [
        ".pragma library",
        "",
        "// GENERATED FILE - do not edit. Run tools/gen-keysyms.py to regenerate.",
        "// Source: %s (%s)" % (os.path.basename(header), ver),
        "// Unicode data for letterRanges: python %s, Unicode %s" % (
            sys.version.split()[0], unicodedata.unidata_version),
        "",
        "// keysym name -> character, for every keysym that maps to Unicode.",
        "var keysymChars = {",
    ]
    items = sorted(table.items(), key=lambda kv: kv[0])
    for i, (name, cp) in enumerate(items):
        lines.append('    %s: "%s"%s' % (key(name), js_char(cp), "," if i < len(items) - 1 else ""))
    lines += ["}", "",
              "// Flat [start, end, ...] code point ranges of Unicode categories L* and M*.",
              "var letterRanges = ["]
    r = letter_ranges()
    for i in range(0, len(r), 12):
        chunk = ", ".join("0x%x" % x for x in r[i:i + 12])
        lines.append("    " + chunk + ("," if i + 12 < len(r) else ""))
    lines += ["]", ""]
    with open(out, "w", encoding="ascii") as f:
        f.write("\n".join(lines))
    print("%d keysyms, %d letter ranges -> %s" % (len(table), len(r) // 2, out))


if __name__ == "__main__":
    main()
