.pragma library

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

var tokenCharMap = {
    space: " ",
    grave: "`",
    asciitilde: "~",
    exclam: "!",
    at: "@",
    numbersign: "#",
    dollar: "$",
    percent: "%",
    asciicircum: "^",
    ampersand: "&",
    asterisk: "*",
    parenleft: "(",
    parenright: ")",
    minus: "-",
    underscore: "_",
    equal: "=",
    plus: "+",
    bracketleft: "[",
    braceleft: "{",
    bracketright: "]",
    braceright: "}",
    backslash: "\\",
    bar: "|",
    semicolon: ";",
    colon: ":",
    apostrophe: "'",
    quotedbl: "\"",
    comma: ",",
    less: "<",
    period: ".",
    greater: ">",
    slash: "/",
    question: "?",
    guillemotleft: "\u00ab",
    guillemotright: "\u00bb",
    ccedilla: "\u00e7",
    Ccedilla: "\u00c7",
    ntilde: "\u00f1",
    Ntilde: "\u00d1",
    adiaeresis: "\u00e4",
    Adiaeresis: "\u00c4",
    odiaeresis: "\u00f6",
    Odiaeresis: "\u00d6",
    udiaeresis: "\u00fc",
    Udiaeresis: "\u00dc",
    eacute: "\u00e9",
    Eacute: "\u00c9",
    aacute: "\u00e1",
    Aacute: "\u00c1",
    iacute: "\u00ed",
    Iacute: "\u00cd",
    oacute: "\u00f3",
    Oacute: "\u00d3",
    uacute: "\u00fa",
    Uacute: "\u00da",
    ssharp: "\u00df",
    section: "\u00a7",
    degree: "\u00b0"
}

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
    if (tokenCharMap.hasOwnProperty(normalized)) return tokenCharMap[normalized]
    if (/^U[0-9A-Fa-f]{4,6}$/.test(normalized)) {
        return String.fromCodePoint(parseInt(normalized.slice(1), 16))
    }
    if (/^0x[0-9A-Fa-f]{2,6}$/.test(normalized)) {
        return String.fromCodePoint(parseInt(normalized, 16))
    }
    if (normalized.length === 1) return normalized
    if (/^[A-Za-z0-9]$/.test(normalized)) return normalized
    return fallback
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
    return buildChordCommand(modifiers, char)
}

function buildModKeyCommand(modifiers, keysym) {
    return buildChordCommand(modifiers, keysym)
}

// Refocus the last real app window via Hyprland before every keystroke.
// Layer-shell clicks can otherwise leave hyprctl's "current window"
// pointed at nothing real even with keyboardFocus: None, so this forces
// wtype to land on the right target every time.
function buildFocusCommand() {
    return ["hyprctl", "dispatch", "focuscurrentorlast"]
}
