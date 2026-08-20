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
        { label: "\u2715", key: "close" }
    ],
    [
        { t: "`", s: "~" }, { t: "1", s: "!" }, { t: "2", s: "@" }, { t: "3", s: "#" },
        { t: "4", s: "$" }, { t: "5", s: "%" }, { t: "6", s: "^" }, { t: "7", s: "&" },
        { t: "8", s: "*" }, { t: "9", s: "(" }, { t: "0", s: ")" }, { t: "-", s: "_" },
        { t: "=", s: "+" }, { label: "Backspace", key: "BackSpace", w: 1.5 }
    ],
    [
        { label: "Tab", key: "Tab", w: 1.4 },
        { t: "q", s: "Q" }, { t: "w", s: "W" }, { t: "e", s: "E" }, { t: "r", s: "R" },
        { t: "t", s: "T" }, { t: "y", s: "Y" }, { t: "u", s: "U" }, { t: "i", s: "I" },
        { t: "o", s: "O" }, { t: "p", s: "P" }, { t: "[", s: "{" }, { t: "]", s: "}" },
        { t: "\\", s: "|" }
    ],
    [
        { label: "Caps Lock", key: "caps", w: 1.75 },
        { t: "a", s: "A" }, { t: "s", s: "S" }, { t: "d", s: "D" }, { t: "f", s: "F" },
        { t: "g", s: "G" }, { t: "h", s: "H" }, { t: "j", s: "J" }, { t: "k", s: "K" },
        { t: "l", s: "L" }, { t: ";", s: ":" }, { t: "'", s: "\"" },
        { label: "Enter", key: "Return", w: 1.75 }
    ],
    [
        { label: "Shift", key: "shift", w: 2.2 },
        { t: "z", s: "Z" }, { t: "x", s: "X" }, { t: "c", s: "C" }, { t: "v", s: "V" },
        { t: "b", s: "B" }, { t: "n", s: "N" }, { t: "m", s: "M" }, { t: ",", s: "<" },
        { t: ".", s: ">" }, { t: "/", s: "?" },
        { label: "Shift", key: "shift", w: 2.2 }
    ],
    [
        { label: "Ctrl", key: "ctrl", w: 1.25 },
        { label: "Super", key: "logo", w: 1.25 },
        { label: "Alt", key: "alt", w: 1.25 },
        { label: "", key: "emoji", w: 1.25 },
        { t: " ", label: "", w: 5.5 },
        { label: "AltGr", key: "altgr", w: 1.25 },
        { label: "Super", key: "logo", w: 1.25 },
        { label: "Ctrl", key: "ctrl", w: 1.25 },
        { cluster: "arrows", w: 3.75 }
    ]
]

// wtype command builders. Kept pure (no Quickshell import) so this file
// can stay a plain .pragma library script; QML side calls
// Quickshell.execDetached(KeyboardLayout.buildXxx(...)).

function buildTypeCommand(text) {
    return ["wtype", text]
}

function buildKeyCommand(keysym) {
    return ["wtype", "-k", keysym]
}

// Held-modifier combo, e.g. Ctrl+C: wtype -M ctrl -p c -m ctrl
function buildModCharCommand(modifier, char) {
    return ["wtype", "-M", modifier, "-p", char, "-m", modifier]
}

function buildModKeyCommand(modifier, keysym) {
    return ["wtype", "-M", modifier, "-p", keysym, "-m", modifier]
}

// Refocus the last real app window via Hyprland before every keystroke.
// Layer-shell clicks can otherwise leave hyprctl's "current window"
// pointed at nothing real even with keyboardFocus: None, so this forces
// wtype to land on the right target every time.
function buildFocusCommand() {
    return ["hyprctl", "dispatch", "focuscurrentorlast"]
}
