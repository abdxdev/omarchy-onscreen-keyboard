// Run with: node tests/run.js   (needs xkbcli, i.e. libxkbcommon, installed)
const { Layout, Keysyms, rowsFor, keyOf } = require("./loader")

let pass = 0, fail = 0
function eq(name, got, want) {
    if (got === want) { pass++ } else { fail++; console.log("FAIL " + name + ": got " + JSON.stringify(got) + ", want " + JSON.stringify(want)) }
}

const cache = {}
function rows(l) { return cache[l] || (cache[l] = rowsFor(l)) }
function cls(l, k) { return Layout.keyClass(keyOf(rows(l), k), Layout.layoutLanguageTag(l)) }
function typed(l, k, caps, shift) {
    return Layout.resolveTypedChar(keyOf(rows(l), k), caps !== shift, shift, Layout.layoutLanguageTag(l))
}
function labels(l, k) { const key = keyOf(rows(l), k); return key.t + "|" + (key.s || "") }

// --- keysym table ---
eq("tokenToText Arabic_alef", Layout.tokenToText("Arabic_alef", "?"), "ا")
eq("tokenToText alias Arabic_heh", Layout.tokenToText("Arabic_heh", "?"), "ه")
eq("tokenToText Cyrillic_zhe", Layout.tokenToText("Cyrillic_zhe", "?"), "ж")
eq("tokenToText gbreve", Layout.tokenToText("gbreve", "?"), "ğ")
eq("tokenToText Iabovedot", Layout.tokenToText("Iabovedot", "?"), "İ")
eq("tokenToText Thai", Layout.tokenToText("Thai_kokai", "?"), "ก")
eq("tokenToText Hebrew", Layout.tokenToText("hebrew_qoph", "?"), "ק")
eq("tokenToText Greek", Layout.tokenToText("Greek_alpha", "?"), "α")
eq("tokenToText Armenian-style U+ form", Layout.tokenToText("U0561", "?"), "ա")
eq("tokenToText 0x0100XXXX", Layout.tokenToText("0x01000561", "?"), "ա")
eq("tokenToText unknown keeps fallback", Layout.tokenToText("dead_grave", "x"), "x")
eq("tokenToText empty", Layout.tokenToText("", "f"), "f")
eq("tokenToText single char", Layout.tokenToText("q", "f"), "q")
eq("table has >1500 entries", Object.keys(Keysyms.keysymChars).length > 1500, true)

// --- us ---
eq("us a class", cls("us", "AC01"), "cased")
eq("us a caps", typed("us", "AC01", true, false), "A")
eq("us a shift", typed("us", "AC01", false, true), "A")
eq("us a caps+shift", typed("us", "AC01", true, true), "a")
eq("us 1 class", cls("us", "AE01"), "other")
eq("us 1 shift", typed("us", "AE01", false, true), "!")
eq("us 1 caps ignored", typed("us", "AE01", true, false), "1")
eq("us ; class", cls("us", "AC10"), "other")

// --- ru: parity with the old cyrillicCharMap ---
eq("ru й", labels("ru", "AD01"), "й|Й")
eq("ru ж class", cls("ru", "AC10"), "cased")
eq("ru ж caps", typed("ru", "AC10", true, false), "Ж")
eq("ru ё", labels("ru", "TLDE"), "ё|Ё")
eq("ru № key", labels("ru", "AE03"), "3|№")
eq("ru all letter keys cased", ["AD01","AD02","AD03","AD04","AD05","AD06","AD07","AD08","AD09","AD10","AD11","AD12","AC01","AC02","AC03","AC04","AC05","AC06","AC07","AC08","AC09","AC10","AC11","AB01","AB02","AB03","AB04","AB05","AB06","AB07","AB08","AB09"].every(k => cls("ru", k) === "cased"), true)

// --- ara ---
eq("ara ب", labels("ara", "AC04").split("|")[0], "ب")
eq("ara ب class", cls("ara", "AC04"), "caseless")
eq("ara ب caps does nothing", typed("ara", "AC04", true, false), "ب")
eq("ara ب shift gives s", typed("ara", "AC04", false, true), "[")
eq("ara ض shift gives fatha", typed("ara", "AD01", false, true), "َ")
eq("ara 1 digit is other", cls("ara", "AE01"), "other")
eq("ara every letter key renders non-empty", rows("ara").flat().filter(k => k.k && k.t).every(k => k.t.length > 0), true)

// --- ir (Persian) ---
eq("ir ی (farsi yeh)", labels("ir", "AC03").split("|")[0], "ی")
eq("ir ک (keheh)", labels("ir", "AC10").split("|")[0], "ک")
eq("ir ب class", cls("ir", "AC04"), "caseless")
eq("ir ۱ digit", labels("ir", "AE01").split("|")[0], "۱")
eq("ir ۱ class", cls("ir", "AE01"), "other")
eq("ir ۱ shift", typed("ir", "AE01", false, true), "!")

// --- il (Hebrew) ---
eq("il ק", labels("il", "AD03").split("|")[0], "ק")
eq("il ק class", cls("il", "AD03"), "caseless")
eq("il ק caps", typed("il", "AD03", true, false), "ק")
eq("il ק shift", typed("il", "AD03", false, true), "E")
eq("il / key is other", cls("il", "AD01"), "other")

// --- gr ---
eq("gr α cased", cls("gr", "AC01"), "cased")
eq("gr α caps", typed("gr", "AC01", true, false), "Α")
eq("gr ς caps", typed("gr", "AD02", true, false), "Σ")
eq("gr ς label", labels("gr", "AD02"), "ς|Σ")

// --- th ---
eq("th ก", labels("th", "AC03").split("|")[0], "ก")
eq("th ก caseless", cls("th", "AC03"), "caseless")
eq("th ก caps", typed("th", "AC03", true, false), "ก")
eq("th vowel mark ิ (Mn) caseless", cls("th", "AB05"), "caseless")
eq("th ๅ caseless", cls("th", "AE01"), "caseless")
eq("th ๅ shift", typed("th", "AE01", false, true), "+")

// --- ge ---
eq("ge ა", labels("ge", "AC01").split("|")[0], "ა")
eq("ge ა caseless", cls("ge", "AC01"), "caseless")
eq("ge ა caps does nothing", typed("ge", "AC01", true, false), "ა")
eq("ge ა shift", typed("ge", "AC01", false, true), "A")
eq("ge წ shift", typed("ge", "AD02", false, true), "ჭ")

// --- am ---
eq("am ա", labels("am", "AC05"), "ա|Ա")
eq("am ա cased", cls("am", "AC05"), "cased")
eq("am ա caps", typed("am", "AC05", true, false), "Ա")

// --- tr ---
eq("tr i label", labels("tr", "AC11"), "i|İ")
eq("tr i cased", cls("tr", "AC11"), "cased")
eq("tr i caps -> İ", typed("tr", "AC11", true, false), "İ")
eq("tr ı label", labels("tr", "AD08"), "ı|I")
eq("tr ı cased", cls("tr", "AD08"), "cased")
eq("tr ı caps -> I", typed("tr", "AD08", true, false), "I")
eq("tr ş", labels("tr", "AC10"), "ş|Ş")
eq("tr ğ", labels("tr", "AD11"), "ğ|Ğ")
eq("tr lang tag", Layout.layoutLanguageTag("tr"), "tr")
eq("tr(f) lang tag", Layout.layoutLanguageTag("tr(f)"), "tr")
eq("us lang tag", Layout.layoutLanguageTag("us"), "")
// Case pairs resolved by locale, independent of layout
eq("tr locale i->İ", Layout.keyClass({ t: "i", s: "İ" }, "tr"), "cased")
eq("no locale i->İ not a pair", Layout.keyClass({ t: "i", s: "İ" }, ""), "other")
eq("no locale i->I pair", Layout.keyClass({ t: "i", s: "I" }, ""), "cased")
eq("az i -> İ", cls("az", "AD08"), "cased")
eq("az ı -> I", cls("az", "AC10"), "cased")
eq("az ə", labels("az", "AC11"), "ə|Ə")
eq("lt ą", labels("lt", "AE01"), "ą|Ą")

// --- fr: é shares a key with 2 and must not count as a letter ---
eq("fr é label", labels("fr", "AE02"), "é|2")
eq("fr é not letter", cls("fr", "AE02"), "other")
eq("fr é caps does not give 2", typed("fr", "AE02", true, false), "é")
eq("fr é shift gives 2", typed("fr", "AE02", false, true), "2")
eq("fr a cased", cls("fr", "AD01"), "cased")
eq("fr à not letter", cls("fr", "AE10"), "other")

// --- de ---
eq("de ß label", labels("de", "AE11"), "ß|?")
eq("de ß not letter (ß uppercases to SS)", cls("de", "AE11"), "other")
eq("de ß caps stays ß", typed("de", "AE11", true, false), "ß")
eq("de ß shift ?", typed("de", "AE11", false, true), "?")
eq("de ü cased", cls("de", "AD11"), "cased")
eq("de ü caps", typed("de", "AD11", true, false), "Ü")

// --- in (Devanagari): matras + letters caseless ---
eq("in क caseless", cls("in", "AC08"), "caseless")
eq("in ा (mark) caseless", cls("in", "AD03"), "caseless")

// --- wtype chord keysym for non-Latin ---
eq("keysymForChar arabic", Layout.keysymForChar("ب"), "U0628")

// --- range table sanity ---
eq("isLetterOrMark ب", Layout.isLetterOrMark("ب"), true)
eq("isLetterOrMark fatha", Layout.isLetterOrMark("َ"), true)
eq("isLetterOrMark 1", Layout.isLetterOrMark("1"), false)
eq("isLetterOrMark !", Layout.isLetterOrMark("!"), false)
eq("isLetterOrMark astral CJK ext B", Layout.isLetterOrMark("\u{20000}"), true)
eq("isLetterOrMark CJK", Layout.isLetterOrMark("中"), true)
eq("isLetterOrMark hangul", Layout.isLetterOrMark("한"), true)
eq("isLetterOrMark empty", Layout.isLetterOrMark(""), false)

console.log((fail ? "FAILED" : "OK") + ": " + pass + " passed, " + fail + " failed")
process.exit(fail ? 1 : 0)
