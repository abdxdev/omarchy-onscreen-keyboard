// Loads KeyboardLayout.js / Keysyms.js (QML-flavoured JS) under node.
// Strips the `.pragma` / `.import` directives and wires the import by hand.
const fs = require("fs")
const path = require("path")
const vm = require("vm")
const execFileSync = require("child_process").execFileSync

const root = path.join(__dirname, "..")

function evalLibrary(file, globals) {
    const src = fs.readFileSync(path.join(root, file), "utf8").replace(/^\.(pragma|import)\b.*$/gm, "")
    const ctx = vm.createContext(Object.assign({}, globals))
    vm.runInContext(src, ctx, { filename: file })
    return ctx
}

const Keysyms = evalLibrary("Keysyms.js")
const Layout = evalLibrary("KeyboardLayout.js", { Keysyms })

// Same extraction as the awk script in Keyboard.qml (loadLanguageLayout):
// compile the layout with xkbcli, buffer each `key <NAME> { ... }` definition,
// and take the first two symbols of its symbols[N]= list (or the bare list).
function symbolMapFor(layout) {
    const text = execFileSync("xkbcli", ["compile-keymap", "--layout", layout], {
        encoding: "utf8", stdio: ["ignore", "pipe", "ignore"], maxBuffer: 1 << 26 })
    const map = {}
    let name = null, buf = ""
    for (const line of text.split("\n")) {
        const k = line.match(/key\s*<([A-Z0-9]+)>/)
        if (k) { name = k[1]; buf = "" }
        if (name === null) continue
        buf += " " + line
        if (line.includes("}")) {
            const s = buf.match(/symbols\[\d+\]\s*=\s*\[([^\]]+)\]/) || buf.match(/\{\s*\[([^\]]+)\]/)
            if (s) {
                const arr = s[1].split(",").map(x => x.replace(/\s+/g, ""))
                map[name] = [arr[0], arr[1] || ""]
            }
            name = null
        }
    }
    return map
}

// Rows of keys for a layout, with the plugin's own applyLanguage().
function rowsFor(layout) {
    return Layout.applyLanguage(Layout.rows, layout, symbolMapFor(layout))
}

// Finds a key by xkb key name (AD01...) in the resolved rows.
function keyOf(rows, k) {
    for (const row of rows) for (const key of row) if (key.k === k) return key
    throw new Error("no key " + k)
}

module.exports = { Layout, Keysyms, symbolMapFor, rowsFor, keyOf }
