.pragma library
.import "Keysyms.js" as Keysyms

// Each key: { t: base char, s: shifted char } for typed keys,
// or { label, key: keysym/modifier-name, w: width factor } for special keys.
var rows = [
    [
        { label: "esc", key: "Escape", w: 1.25 },
        { label: "F1", key: "F1" }, { label: "F2", key: "F2" }, { label: "F3", key: "F3" },
        { label: "F4", key: "F4" }, { label: "F5", key: "F5" }, { label: "F6", key: "F6" },
        { label: "F7", key: "F7" }, { label: "F8", key: "F8" }, { label: "F9", key: "F9" },
        { label: "F10", key: "F10" }, { label: "F11", key: "F11" }, { label: "F12", key: "F12" },
        { label: "Delete", key: "Delete", w: 1.25 }
    ],
    [
        { t: "`", s: "~", k: "TLDE" }, { t: "1", s: "!", k: "AE01" }, { t: "2", s: "@", k: "AE02" }, { t: "3", s: "#", k: "AE03" },
        { t: "4", s: "$", k: "AE04" }, { t: "5", s: "%", k: "AE05" }, { t: "6", s: "^", k: "AE06" }, { t: "7", s: "&", k: "AE07" },
        { t: "8", s: "*", k: "AE08" }, { t: "9", s: "(", k: "AE09" }, { t: "0", s: ")", k: "AE10" }, { t: "-", s: "_", k: "AE11" },
        { t: "=", s: "+", k: "AE12" }, { label: "Backspace", key: "BackSpace", w: 1.5 }
    ],
    [
        { label: "Tab", key: "Tab", w: 1.4 },
        { t: "q", s: "Q", k: "AD01" }, { t: "w", s: "W", k: "AD02" }, { t: "e", s: "E", k: "AD03" }, { t: "r", s: "R", k: "AD04" },
        { t: "t", s: "T", k: "AD05" }, { t: "y", s: "Y", k: "AD06" }, { t: "u", s: "U", k: "AD07" }, { t: "i", s: "I", k: "AD08" },
        { t: "o", s: "O", k: "AD09" }, { t: "p", s: "P", k: "AD10" }, { t: "[", s: "{", k: "AD11" }, { t: "]", s: "}", k: "AD12" },
        { t: "\\", s: "|", k: "BKSL" }
    ],
    [
        { label: "Caps Lock", key: "caps", w: 1.75 },
        { t: "a", s: "A", k: "AC01" }, { t: "s", s: "S", k: "AC02" }, { t: "d", s: "D", k: "AC03" }, { t: "f", s: "F", k: "AC04" },
        { t: "g", s: "G", k: "AC05" }, { t: "h", s: "H", k: "AC06" }, { t: "j", s: "J", k: "AC07" }, { t: "k", s: "K", k: "AC08" },
        { t: "l", s: "L", k: "AC09" }, { t: ";", s: ":", k: "AC10" }, { t: "'", s: "\"", k: "AC11" },
        { label: "Enter", key: "Return", w: 1.75 }
    ],
    [
        { label: "Shift", key: "shift", w: 2.2 },
        { t: "z", s: "Z", k: "AB01" }, { t: "x", s: "X", k: "AB02" }, { t: "c", s: "C", k: "AB03" }, { t: "v", s: "V", k: "AB04" },
        { t: "b", s: "B", k: "AB05" }, { t: "n", s: "N", k: "AB06" }, { t: "m", s: "M", k: "AB07" }, { t: ",", s: "<", k: "AB08" },
        { t: ".", s: ">", k: "AB09" }, { t: "/", s: "?", k: "AB10" },
        { label: "Shift", key: "shift", w: 2.2 }
    ],
    [
        { label: "Ctrl", key: "ctrl", w: 1.25 },
        { label: "Super", key: "logo", w: 1.25 },
        { label: "Alt", key: "alt", w: 1.25 },
        { label: "", key: "emoji", w: 1.25 },
        { t: " ", label: "", w: 5.5, k: "SPCE" },
        { label: "AltGr", key: "altgr", w: 1.25 },
        { label: "Super", key: "logo", w: 1.25 },
        { label: "Ctrl", key: "ctrl", w: 1.25 },
        { cluster: "arrows", w: 3.75 }
    ]
]

function cloneKey(keyData) {
    var out = {}
    for (var field in keyData) {
        out[field] = keyData[field]
    }
    return out
}

function cloneRows(sourceRows) {
    var out = []
    for (var r = 0; r < sourceRows.length; r++) {
        var row = sourceRows[r]
        var clonedRow = []
        for (var c = 0; c < row.length; c++) {
            clonedRow.push(cloneKey(row[c]))
        }
        out.push(clonedRow)
    }
    return out
}

function tokenToText(token, fallback) {
    var normalized = String(token || "").trim()
    if (normalized === "") return fallback
    // Every keysym with a Unicode equivalent (generated, see tools/gen-keysyms.py).
    if (Keysyms.keysymChars.hasOwnProperty(normalized)) return Keysyms.keysymChars[normalized]
    if (/^U[0-9A-Fa-f]{4,6}$/.test(normalized)) {
        return String.fromCodePoint(parseInt(normalized.slice(1), 16))
    }
    // 0x0100XXXX is the X11 "Unicode keysym" form (0x01000000 + codepoint),
    // used by ru and others. Passing it to fromCodePoint raw would throw.
    if (/^0x0100[0-9A-Fa-f]{4}$/.test(normalized)) {
        return String.fromCodePoint(parseInt(normalized.slice(6), 16))
    }
    if (/^0x[0-9A-Fa-f]{2,6}$/.test(normalized)) {
        return String.fromCodePoint(parseInt(normalized, 16))
    }
    if (normalized.length === 1) return normalized
    if (/^[A-Za-z0-9]$/.test(normalized)) return normalized
    return fallback
}

// ---- Letter detection -------------------------------------------------------
//
// Kept here (not in Keyboard.qml) so tests/ can run it under node.

// xkb layout code -> BCP-47 tag for the languages whose case mapping differs
// from the default one. Anything else uses the plain, locale-independent
// toUpperCase()/toLowerCase().
var localeForLayout = { tr: "tr", az: "az", lt: "lt" }

function layoutLanguageTag(layoutCode) {
    var code = String(layoutCode || "").split("(")[0].trim().toLowerCase()
    return localeForLayout.hasOwnProperty(code) ? localeForLayout[code] : ""
}

function upperOf(text, lang) {
    return lang ? text.toLocaleUpperCase(lang) : text.toUpperCase()
}

function lowerOf(text, lang) {
    return lang ? text.toLocaleLowerCase(lang) : text.toLowerCase()
}

// Qt's JS engine has no \p{L}, so test Unicode category L*/M* against the
// generated range table (binary search over flat [start, end, ...] pairs).
function isLetterOrMark(char) {
    if (!char) return false
    var cp = String(char).codePointAt(0)
    var ranges = Keysyms.letterRanges
    var lo = 0, hi = (ranges.length >> 1) - 1
    while (lo <= hi) {
        var mid = (lo + hi) >> 1
        if (cp < ranges[mid * 2]) hi = mid - 1
        else if (cp > ranges[mid * 2 + 1]) lo = mid + 1
        else return true
    }
    return false
}

// Georgian Mkhedruli has Mtavruli capitals in recent Unicode, so the engine
// reports a case mapping, but Georgian keyboards treat it as caseless: Shift
// selects another letter and Caps Lock does nothing.
function isMkhedruli(char) {
    var cp = String(char).codePointAt(0)
    return (cp >= 0x10d0 && cp <= 0x10fa) || (cp >= 0x10fd && cp <= 0x10ff)
}

// Classifies a typed key:
//   "cased"    shift/caps swap case (a/A, ж/Ж, i/İ on tr). The shifted symbol is
//              the capital of the base, or the base is the lowercase of the
//              shifted one. Asking merely whether the base has a capital is not
//              enough: French AZERTY carries é on the same key as 2, and é does
//              have a capital, so Caps Lock would type 2 instead of É.
//   "caseless" a letter of a script without case (Arabic, Hebrew, Thai,
//              Georgian, Devanagari, CJK...). Caps Lock does nothing; Shift
//              gives keyData.s if present. Combining marks (Arabic harakat,
//              Thai vowels, Devanagari matras) count too, since those layouts
//              put them on keys of their own and they should not render as
//              stacked punctuation-style keys.
//   "other"    digits, punctuation, ß, é-over-2 and anything else: rendered as
//              dual keys, shift selects the second symbol.
function keyClass(keyData, lang) {
    var base = keyData.t || ""
    var shifted = keyData.s || ""
    if (base.length === 0) return "other"
    if (shifted.length > 0 && shifted !== base
            && (shifted === upperOf(base, lang) || lowerOf(shifted, lang) === base)) {
        return "cased"
    }
    if (isLetterOrMark(base)
            && ((upperOf(base, lang) === base && lowerOf(base, lang) === base) || isMkhedruli(base))) {
        return "caseless"
    }
    return "other"
}

function isLetterKey(keyData, lang) {
    return keyClass(keyData, lang) !== "other"
}

// upper: Caps xor Shift. shift: Shift alone.
function resolveTypedChar(keyData, upper, shift, lang) {
    if (keyClass(keyData, lang) === "cased") return upper && keyData.s ? keyData.s : keyData.t
    return shift && keyData.s ? keyData.s : keyData.t
}

function applyLanguage(rowsSource, layoutCode, symbolMap) {
    var layoutRows = cloneRows(rowsSource)
    var label = String(layoutCode || "us").toUpperCase()

    for (var r = 0; r < layoutRows.length; r++) {
        for (var c = 0; c < layoutRows[r].length; c++) {
            var keyData = layoutRows[r][c]
            if (keyData.key === "lang") {
                keyData.label = label
                continue
            }
            if (!keyData.k || !symbolMap || !symbolMap[keyData.k]) continue

            var symbols = symbolMap[keyData.k]
            if (!Array.isArray(symbols) || symbols.length === 0) continue

            keyData.t = tokenToText(symbols[0], keyData.t)
            if (symbols.length > 1) {
                keyData.s = tokenToText(symbols[1], keyData.s)
            }
        }
    }

    return layoutRows
}

// wtype command builders. Kept pure (no Quickshell import) so this file
// can stay a plain .pragma library script; QML side calls
// Quickshell.execDetached(KeyboardLayout.buildXxx(...)).

function buildTypeCommand(text) {
    return ["wtype", "--", text]
}

function buildKeyCommand(keysym) {
    return ["wtype", "-k", keysym]
}

// Held-modifier combo, e.g. Ctrl+C: wtype -M ctrl -p c -m ctrl
function normalizedModifiers(modifiers) {
    if (!Array.isArray(modifiers)) return [modifiers]
    return modifiers
}

// `wtype -k` wants a keysym, not a character. Latin letters double as valid
// keysym names, but anything outside ASCII does not: `wtype -k й` exits with
// "Unknown key 'й'", so Ctrl/Alt combinations silently failed on every
// non-Latin layout. libxkbcommon also accepts the U#### spelling, which covers
// any character without needing a name table.
function keysymForChar(character) {
    var text = String(character || "")
    if (text.length === 0) return text

    if (text === " ") return "space"

    var codePoint = text.codePointAt(0)
    if (codePoint < 0x80) return text

    var hex = codePoint.toString(16).toUpperCase()
    while (hex.length < 4) hex = "0" + hex
    return "U" + hex
}

function buildChordCommand(modifiers, key) {
    var mods = normalizedModifiers(modifiers).filter(function (mod) {
        return !!mod
    })
    var argv = ["wtype"]

    for (var i = 0; i < mods.length; i++) {
        argv.push("-M", mods[i])
    }
    argv.push("-k", key)
    for (var j = mods.length - 1; j >= 0; j--) {
        argv.push("-m", mods[j])
    }

    return argv
}

function buildModCharCommand(modifiers, char) {
    return buildChordCommand(modifiers, keysymForChar(char))
}

function buildModKeyCommand(modifiers, keysym) {
    return buildChordCommand(modifiers, keysym)
}
