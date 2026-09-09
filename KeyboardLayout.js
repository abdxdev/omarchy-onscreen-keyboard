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
    degree: "\u00b0",
    idotless: "\u0131",
    numerosign: "\u2116",
    endash: "\u2013",
    emdash: "\u2014",
    doublelowquotemark: "\u201e",
    leftdoublequotemark: "\u201c",
    rightdoublequotemark: "\u201d",
    brokenbar: "\u00a6",
    currency: "\u00a4",
    EuroSign: "\u20ac"
}

// X11 Cyrillic keysym names -> characters. Cyrillic layouts (ua, ru, bg,
// by, rs, mk) spell their symbols as named keysyms rather than U#### escapes,
// so without this every key falls back to its Latin label.
var cyrillicCharMap = {
    Cyrillic_IO: "\u0401",
    Serbian_DJE: "\u0402",
    Macedonia_GJE: "\u0403",
    Ukrainian_IE: "\u0404",
    Macedonia_DSE: "\u0405",
    Ukrainian_I: "\u0406",
    Ukrainian_YI: "\u0407",
    Cyrillic_JE: "\u0408",
    Cyrillic_LJE: "\u0409",
    Cyrillic_NJE: "\u040a",
    Serbian_TSHE: "\u040b",
    Macedonia_KJE: "\u040c",
    Byelorussian_SHORTU: "\u040e",
    Cyrillic_DZHE: "\u040f",
    Cyrillic_A: "\u0410",
    Cyrillic_BE: "\u0411",
    Cyrillic_VE: "\u0412",
    Cyrillic_GHE: "\u0413",
    Cyrillic_DE: "\u0414",
    Cyrillic_IE: "\u0415",
    Cyrillic_ZHE: "\u0416",
    Cyrillic_ZE: "\u0417",
    Cyrillic_I: "\u0418",
    Cyrillic_SHORTI: "\u0419",
    Cyrillic_KA: "\u041a",
    Cyrillic_EL: "\u041b",
    Cyrillic_EM: "\u041c",
    Cyrillic_EN: "\u041d",
    Cyrillic_O: "\u041e",
    Cyrillic_PE: "\u041f",
    Cyrillic_ER: "\u0420",
    Cyrillic_ES: "\u0421",
    Cyrillic_TE: "\u0422",
    Cyrillic_U: "\u0423",
    Cyrillic_EF: "\u0424",
    Cyrillic_HA: "\u0425",
    Cyrillic_TSE: "\u0426",
    Cyrillic_CHE: "\u0427",
    Cyrillic_SHA: "\u0428",
    Cyrillic_SHCHA: "\u0429",
    Cyrillic_HARDSIGN: "\u042a",
    Cyrillic_YERU: "\u042b",
    Cyrillic_SOFTSIGN: "\u042c",
    Cyrillic_E: "\u042d",
    Cyrillic_YU: "\u042e",
    Cyrillic_YA: "\u042f",
    Cyrillic_a: "\u0430",
    Cyrillic_be: "\u0431",
    Cyrillic_ve: "\u0432",
    Cyrillic_ghe: "\u0433",
    Cyrillic_de: "\u0434",
    Cyrillic_ie: "\u0435",
    Cyrillic_zhe: "\u0436",
    Cyrillic_ze: "\u0437",
    Cyrillic_i: "\u0438",
    Cyrillic_shorti: "\u0439",
    Cyrillic_ka: "\u043a",
    Cyrillic_el: "\u043b",
    Cyrillic_em: "\u043c",
    Cyrillic_en: "\u043d",
    Cyrillic_o: "\u043e",
    Cyrillic_pe: "\u043f",
    Cyrillic_er: "\u0440",
    Cyrillic_es: "\u0441",
    Cyrillic_te: "\u0442",
    Cyrillic_u: "\u0443",
    Cyrillic_ef: "\u0444",
    Cyrillic_ha: "\u0445",
    Cyrillic_tse: "\u0446",
    Cyrillic_che: "\u0447",
    Cyrillic_sha: "\u0448",
    Cyrillic_shcha: "\u0449",
    Cyrillic_hardsign: "\u044a",
    Cyrillic_yeru: "\u044b",
    Cyrillic_softsign: "\u044c",
    Cyrillic_e: "\u044d",
    Cyrillic_yu: "\u044e",
    Cyrillic_ya: "\u044f",
    Cyrillic_io: "\u0451",
    Serbian_dje: "\u0452",
    Macedonia_gje: "\u0453",
    Ukrainian_ie: "\u0454",
    Macedonia_dse: "\u0455",
    Ukrainian_i: "\u0456",
    Ukrainian_yi: "\u0457",
    Cyrillic_je: "\u0458",
    Cyrillic_lje: "\u0459",
    Cyrillic_nje: "\u045a",
    Serbian_tshe: "\u045b",
    Macedonia_kje: "\u045c",
    Byelorussian_shortu: "\u045e",
    Cyrillic_dzhe: "\u045f",
    Ukrainian_GHE_WITH_UPTURN: "\u0490",
    Ukrainian_ghe_with_upturn: "\u0491",
    Cyrillic_GHE_bar: "\u0492",
    Cyrillic_ghe_bar: "\u0493",
    Cyrillic_ZHE_descender: "\u0496",
    Cyrillic_zhe_descender: "\u0497",
    Cyrillic_KA_descender: "\u049a",
    Cyrillic_ka_descender: "\u049b",
    Cyrillic_KA_vertstroke: "\u049c",
    Cyrillic_ka_vertstroke: "\u049d",
    Cyrillic_EN_descender: "\u04a2",
    Cyrillic_en_descender: "\u04a3",
    Cyrillic_U_straight: "\u04ae",
    Cyrillic_u_straight: "\u04af",
    Cyrillic_U_straight_bar: "\u04b0",
    Cyrillic_u_straight_bar: "\u04b1",
    Cyrillic_HA_descender: "\u04b2",
    Cyrillic_ha_descender: "\u04b3",
    Cyrillic_CHE_descender: "\u04b6",
    Cyrillic_che_descender: "\u04b7",
    Cyrillic_CHE_vertstroke: "\u04b8",
    Cyrillic_che_vertstroke: "\u04b9",
    Cyrillic_SHHA: "\u04ba",
    Cyrillic_shha: "\u04bb",
    Cyrillic_SCHWA: "\u04d8",
    Cyrillic_schwa: "\u04d9",
    Cyrillic_I_macron: "\u04e2",
    Cyrillic_i_macron: "\u04e3",
    Cyrillic_O_bar: "\u04e8",
    Cyrillic_o_bar: "\u04e9",
    Cyrillic_U_macron: "\u04ee",
    Cyrillic_u_macron: "\u04ef"
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
    if (cyrillicCharMap.hasOwnProperty(normalized)) return cyrillicCharMap[normalized]
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

// Chromium (and Electron) drops characters that arrive as the very first
// key event of a wtype invocation — in practice every symbol (space, !, #,
// :, ., ...) the on-screen keyboard clicks. Each click is its own fresh
// wtype process, so every character is "first". Letters and digits survive,
// which is why only symbols and the space bar fail. A void keysym
// press+release before the text works around this, exactly like the
// workaround Valve added to gamescope for Steam/Chromium:
// https://github.com/atx/wtype/issues/31
// VoidSymbol produces no character, so it is ignored by every other app.
function buildTypeCommand(text) {
    return ["wtype", "-k", "VoidSymbol", "--", text]
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
