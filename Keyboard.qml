import QtQuick
import Quickshell
import Quickshell.Io
import qs.Commons
import "KeyboardLayout.js" as Layout

Item {
    id: root
    implicitWidth: grid.implicitWidth
    implicitHeight: grid.implicitHeight
    signal closeRequested()

    // ---- Design tokens, copied 1:1 from the reference HTML/CSS ----
    readonly property real gapPx: Style.spacing.md
    readonly property real keyHeight: Style.space(42)
    readonly property real keyRadius: Style.cornerRadius
    readonly property real containerMaxWidth: Style.space(820)
    // Rows fill the same total width as the container minus its own
    // padding (which equals the gap), exactly like the CSS container's
    // `padding: var(--gap)` around `.keyboard-grid`.
    readonly property real rowWidth: containerMaxWidth - 2 * gapPx

    readonly property color keyBg: Util.alpha(Color.foreground, Style.normalFillAlpha)
    readonly property color keyHoverBg: Util.alpha(Color.foreground, Style.hoverFillAlpha)
    readonly property color keyActiveBg: Util.alpha(Color.foreground, Style.pressedFillAlpha)
    readonly property color keyBorderColor: Util.alpha(Color.foreground, Style.pressedFillAlpha)
    readonly property color accentColor: Util.alpha(Color.accent, Style.pressedFillAlpha)
    readonly property color textMain: Color.foreground
    readonly property color textDim: Color.muted
    readonly property color textHighlightColor: Color.foreground
    readonly property string keyboardFont: Style.font.family
    readonly property int keyBorderWidth: Style.normalBorderWidth
    readonly property int keyFontSize: Style.font.body
    readonly property int keySmallFontSize: Style.font.bodySmall

    property bool capsOn: false
    property bool shiftOn: false
    property bool shiftHeld: false
    property bool ctrlOn: false
    property bool ctrlHeld: false
    property bool altOn: false
    property bool altHeld: false
    property bool superOn: false
    property bool superHeld: false
    property bool altgrOn: false
    property bool altgrHeld: false
    property string currentLayout: "us"
    property var languageCycle: ["us"]
    property int layoutCycleIndex: 0
    property var layoutNameMap: ({})
    property string currentLayoutName: {
        var name = layoutNameMap[currentLayout]
        return name ? name : currentLayout.toUpperCase()
    }
    property var symbolMap: ({})
    property var layoutRows: Layout.applyLanguage(Layout.rows, currentLayout, symbolMap)

    function updateLayoutRows() {
        layoutRows = Layout.applyLanguage(Layout.rows, currentLayout, symbolMap)
    }

    function parseLayoutSymbolOutput(text) {
        var map = ({})
        var lines = String(text || "").split("\n")
        for (var i = 0; i < lines.length; i++) {
            var line = lines[i].trim()
            if (!line) continue
            var parts = line.split("\t")
            if (parts.length < 2) continue
            map[parts[0]] = [parts[1], parts.length > 2 ? parts[2] : ""]
        }
        symbolMap = map
        updateLayoutRows()
    }

    // The virtual keyboard owns its language state (Windows OSK behavior):
    // it always starts in English and never follows the physical layout.
    // Hyprland is only queried for the *available* layouts to populate
    // languageCycle (and their display names) — currentLayout is never
    // synced from the system, so Alt+Shift on the physical keyboard and the
    // virtual language button can never fight each other.

    function parseHyprLayoutOutput(text) {
        var lines = String(text || "").split("\n")
        var detected = []
        var names = ({})

        for (var i = 0; i < lines.length; i++) {
            var line = lines[i].trim()
            if (!line) continue
            var parts = line.split("\t")
            if (parts.length < 2) continue
            if (parts[0] === "LAYOUT") {
                detected.push(String(parts[1] || "").trim())
            }
            if (parts[0] === "NAME" && parts.length >= 3) {
                names[String(parts[1] || "").trim()] = String(parts[2] || "").trim()
            }
        }

        detected = detected.filter(function(layout) { return layout.length > 0 })
        if (detected.length > 0) {
            languageCycle = detected
        }
        // Merge any newly discovered names into the map
        var merged = ({})
        for (var k in layoutNameMap) merged[k] = layoutNameMap[k]
        for (var k in names) merged[k] = names[k]
        layoutNameMap = merged
    }

    function refreshLayoutsFromHypr() {
        layoutDetectProcess.running = false
        // Use the physical keyboard (not virtual) to detect active layout.
        // Filter out virtual keyboards (hl-virtual-*, keyd-virtual-*) which
        // always report index 0 and would make active detection unreliable.
        // Also emit NAME\t<code>\t<fullname> lines for the lang button label.
        layoutDetectProcess.command = ["bash", "-lc",
            "active_keymap=$(hyprctl devices -j | jq -r '.keyboards[] | select(.name | test(\"virtual\"; \"i\") | not) | .active_keymap' 2>/dev/null | head -n1); "
            + "active=$(awk -v target=\"$active_keymap\" 'BEGIN{s=0} /^! layout/{s=1;next} /^!/{if(s) exit} s && NF>=2 { code=$1; $1=\"\"; sub(/^ +/, \"\", $0); if ($0 == target) { print code; exit } }' /usr/share/X11/xkb/rules/base.lst 2>/dev/null); "
            + "if [[ -z \"$active\" ]]; then active=$(hyprctl devices -j | jq -r '.keyboards[] | select(.name | test(\"virtual\"; \"i\") | not) as $k | ($k.layout | split(\",\")[($k.active_layout_index // 0)])' 2>/dev/null | head -n1); fi; "
            + "printf 'ACTIVE\\t%s\\n' \"$active\"; "
            + "layouts=$(hyprctl devices -j | jq -r '(.keyboards[] | select(.name | test(\"virtual\"; \"i\") | not) | .layout)' | head -n1 | tr ',' '\\n' | sed '/^$/d'); "
            + "echo \"$layouts\" | awk '{print \"LAYOUT\\t\" $0}'; "
            + "echo \"$layouts\" | while read code; do "
            + "  name=$(awk -v c=\"$code\" 'BEGIN{s=0} /^! layout/{s=1;next} /^!/{if(s) exit} s && NF>=2 && $1==c { $1=\"\"; sub(/^ +/,\"\",$0); print $0; exit }' /usr/share/X11/xkb/rules/base.lst 2>/dev/null); "
            + "  [[ -n \"$name\" ]] && printf 'NAME\\t%s\\t%s\\n' \"$code\" \"$name\"; "
            + "done"]
        layoutDetectProcess.running = true
    }

    function loadLanguageLayout(layoutCode) {
        currentLayout = layoutCode
        updateLayoutRows()
        // Compile the layout with xkbcli rather than reading
        // /usr/share/X11/xkb/symbols/<code> directly: most layouts define their
        // real keys in an include (ua's default variant is `include "ua(legacy)"`
        // plus overrides, ru's is `include "ru(common)"`), so parsing the raw
        // file only ever sees the handful of override keys. A compiled keymap is
        // flat, so a plain line match over `key <X> { [ a, b ] }` is enough.
        // xkbcli ships with libxkbcommon, which Hyprland already depends on.
        // A Process that is already running ignores `running = true` and keeps
        // the command it started with, so a second switch while the first
        // compile is in flight would apply the old layout's symbols to the new
        // one and never correct itself. Stop it first.
        layoutLoadProcess.running = false
        // pipefail so a failed xkbcli is not masked by awk exiting 0, which
        // would install an empty map and silently leave the keyboard blank.
        layoutLoadProcess.command = ["bash", "-lc",
            // A key definition spans one line for simple keys but several when
            // it carries an explicit type, which is how xkbcli emits most
            // alphabetic keys on ara, in, il, kz, uz and lk:
            //     key <AD01> {
            //         type= "FOUR_LEVEL",
            //         symbols[1]= [ U094C, U0914, NoSymbol, NoSymbol ]
            //     };
            // Matching only the single-line form loses every letter on those
            // layouts and leaves a US keyboard on screen. Buffer the whole
            // definition instead, then take the symbol list from it. Reading
            // `symbols[N]=` first matters: `symbols[1]` would otherwise be
            // mistaken for the bracketed list by a plain `[...]` match.
            "set -o pipefail; xkbcli compile-keymap --layout \"$1\" 2>/dev/null | awk '\n"
            + " match($0, /key[[:space:]]*<([A-Z0-9]+)>/, k) { name=k[1]; buf=\"\"; inkey=1 }\n"
            + " inkey {\n"
            + "   buf = buf \" \" $0\n"
            + "   if (index($0, \"}\")) {\n"
            + "     if (match(buf, /symbols\\[[0-9]+\\][[:space:]]*=[[:space:]]*\\[([^]]+)\\]/, s) ||\n"
            + "         match(buf, /\\{[[:space:]]*\\[([^]]+)\\]/, s)) {\n"
            + "       split(s[1], arr, /,/)\n"
            + "       gsub(/[[:space:]]+/, \"\", arr[1])\n"
            + "       gsub(/[[:space:]]+/, \"\", arr[2])\n"
            + "       print name \"\\t\" arr[1] \"\\t\" arr[2]\n"
            + "     }\n"
            + "     inkey=0\n"
            + "   }\n"
            + " }\n"
            // Passed as an argument rather than concatenated into the script:
            // the code comes from hyprctl, and splicing it in would let a stray
            // space or shell metacharacter change the command.
            + "'", "onscreen-keyboard", layoutCode]
        layoutLoadProcess.running = true
    }

    function cycleLanguage() {
        if (languageCycle.length < 2) return
        // Virtual-only switch (Windows OSK behavior): only our own labels and
        // symbols change. The physical layout is never touched — no
        // `hyprctl switchxkblayout` — so Alt+Shift keeps working independently.
        // Typing goes through `wtype -- <text>`, which carries the visible
        // character itself. The index is derived from currentLayout (not the
        // stored counter) so a refreshed languageCycle can never desync it.
        layoutCycleIndex = languageCycle.indexOf(currentLayout)
        if (layoutCycleIndex < 0) layoutCycleIndex = 0
        layoutCycleIndex = (layoutCycleIndex + 1) % languageCycle.length
        loadLanguageLayout(languageCycle[layoutCycleIndex])
    }

    Component.onCompleted: refreshLayoutsFromHypr()

    Process {
        id: layoutDetectProcess
        property string collected: ""
        stdout: SplitParser {
            onRead: function(data) {
                layoutDetectProcess.collected += data + "\n"
            }
        }
        onRunningChanged: {
            if (running) collected = ""
        }
        onExited: function(exitCode, exitStatus) {
            if (exitCode !== 0 || exitStatus !== 0) return
            root.parseHyprLayoutOutput(layoutDetectProcess.collected)
        }
    }

    Process {
        id: layoutLoadProcess
        property string collected: ""
        stdout: SplitParser {
            onRead: function(data) {
                layoutLoadProcess.collected += data + "\n"
            }
        }
        onRunningChanged: {
            if (running) collected = ""
        }
        onExited: function(exitCode, exitStatus) {
            if (exitCode === 0 && exitStatus === 0) {
                root.parseLayoutSymbolOutput(layoutLoadProcess.collected)
                return
            }
            root.symbolMap = ({})
            root.updateLayoutRows()
        }
    }

    // Periodic sync: only refreshes languageCycle (available layouts) and
    // display names. currentLayout is virtual-owned and never overwritten.
    Timer {
        id: layoutSyncTimer
        interval: 5000
        repeat: true
        running: true
        onTriggered: root.refreshLayoutsFromHypr()
    }

    function activeModifiers() {
        var mods = []
        if (ctrlOn) mods.push("ctrl")
        if (altOn) mods.push("alt")
        if (superOn) mods.push("logo")
        if (altgrOn) mods.push("altgr")
        if (shiftOn) mods.push("shift")
        return mods
    }

    function clearComboMods() {
        shiftOn = shiftHeld
        ctrlOn = ctrlHeld
        altOn = altHeld
        superOn = superHeld
        altgrOn = altgrHeld
    }

    function isUpper() {
        return capsOn !== shiftOn
    }

    function isSymbolShiftActive() {
        return shiftOn
    }

    function isHoldableModifierKey(key) {
        switch (key) {
        case "shift":
        case "ctrl":
        case "alt":
        case "logo":
        case "altgr":
            return true
        }
        return false
    }

    function modifierHeld(key) {
        switch (key) {
        case "shift": return shiftHeld
        case "ctrl": return ctrlHeld
        case "alt": return altHeld
        case "logo": return superHeld
        case "altgr": return altgrHeld
        }
        return false
    }

    function setModifierHeld(key, held) {
        switch (key) {
        case "shift": shiftHeld = held; shiftOn = held; return
        case "ctrl": ctrlHeld = held; ctrlOn = held; return
        case "alt": altHeld = held; altOn = held; return
        case "logo": superHeld = held; superOn = held; return
        case "altgr": altgrHeld = held; altgrOn = held; return
        }
    }

    function toggleModifier(key, doubleClick) {
        if (doubleClick) {
            setModifierHeld(key, !modifierHeld(key))
            return
        }
        if (modifierHeld(key)) {
            setModifierHeld(key, false)
            return
        }
        switch (key) {
        case "shift": shiftOn = !shiftOn; return
        case "ctrl": ctrlOn = !ctrlOn; return
        case "alt": altOn = !altOn; return
        case "logo": superOn = !superOn; return
        case "altgr": altgrOn = !altgrOn; return
        }
    }

    // A letter key is one whose shifted symbol is simply the capital of its
    // base, which holds in any script and needs no per-alphabet table.
    // `/^[a-z]$/` recognised only Latin, so Cyrillic and Greek letters were
    // treated as punctuation: Caps Lock did nothing on them and they rendered
    // as stacked dual keys. Asking merely whether the base has a capital is not
    // enough either — French AZERTY carries é on the same key as 2, and é does
    // have a capital, so Caps Lock would type 2 instead of É.
    function isLetterKey(keyData) {
        var base = keyData.t || ""
        var shifted = keyData.s || ""
        return base.length > 0 && shifted.length > 0 && shifted === base.toUpperCase()
    }

    function resolvedTypedChar(keyData) {
        if (isLetterKey(keyData)) {
            return isUpper() && keyData.s ? keyData.s : keyData.t
        }
        return shiftOn && keyData.s ? keyData.s : keyData.t
    }

    // Punctuation/number keys show both symbols stacked (like the
    // reference's `.key.dual`); plain letter keys just swap case.
    function isDualKey(keyData) {
        return !!keyData.s && !isLetterKey(keyData)
    }

    // Every keystroke goes straight to wtype. This used to dispatch
    // `focuscurrentorlast` first, on the theory that it reclaimed focus for the
    // real target window — but that dispatcher *toggles* between the current and
    // previously focused window, so with two or more windows open every keypress
    // moved focus away and wtype typed into the wrong one. The panel is
    // `keyboardFocus: None`, so the target never loses focus and there is
    // nothing to reclaim.
    function sendKeys(argv) {
        Quickshell.execDetached(argv)
    }

    function pressChar(keyData) {
        var mods = activeModifiers()
        
        if (mods.length === 1 && mods[0] === "shift") {
            mods = []
        }

        if (mods.length > 0) {
            sendKeys(Layout.buildModCharCommand(mods, keyData.t))
            clearComboMods()
            return
        }
        var text = resolvedTypedChar(keyData)
        sendKeys(Layout.buildTypeCommand(text))
        shiftOn = shiftHeld
    }

    function pressSpecial(keyData, doubleClick) {
        switch (keyData.key) {
        case "close": closeRequested(); return
        case "emoji": Quickshell.execDetached(["omarchy-menu-emoji"]); return
        case "lang": cycleLanguage(); return
        case "caps": capsOn = !capsOn; return
        case "shift": toggleModifier("shift", doubleClick); return
        case "ctrl": toggleModifier("ctrl", doubleClick); return
        case "alt": toggleModifier("alt", doubleClick); return
        case "logo": toggleModifier("logo", doubleClick); return
        case "altgr": toggleModifier("altgr", doubleClick); return
        }
        var mods = activeModifiers()
        if (mods.length > 0) {
            sendKeys(Layout.buildModKeyCommand(mods, keyData.key))
        } else {
            sendKeys(Layout.buildKeyCommand(keyData.key))
        }
        clearComboMods()
    }

    function isToggled(keyData) {
        switch (keyData.key) {
        case "caps": return capsOn
        case "shift": return shiftOn
        case "ctrl": return ctrlOn
        case "alt": return altOn
        case "logo": return superOn
        case "altgr": return altgrOn
        }
        return false
    }

    Column {
        id: grid
        spacing: root.gapPx

        Repeater {
            model: root.layoutRows
            delegate: Row {
                id: rowItem
                spacing: root.gapPx
                readonly property var rowModel: modelData
                readonly property real flexSum: rowModel.reduce(function (acc, item) {
                    return acc + (item.w || 1)
                }, 0)
                readonly property real innerWidth: root.rowWidth - (rowModel.length - 1) * root.gapPx

                Repeater {
                    model: rowModel
                    delegate: Item {
                        id: keyDelegate
                        property var keyData: modelData
                        width: rowItem.innerWidth * (keyData.w || 1) / rowItem.flexSum
                        height: root.keyHeight

                        Rectangle {
                            id: keyRect
                            anchors.fill: parent
                            visible: keyData.cluster !== "arrows"
                            radius: root.keyRadius
                            border.width: root.keyBorderWidth

                            property bool toggled: root.isToggled(keyData)
                            property bool isLang: keyData.key === "lang"
                            property bool isDual: root.isDualKey(keyData)

                            color: isLang ? root.accentColor
                                : toggled ? root.accentColor
                                : mouseArea.pressed ? root.keyActiveBg
                                : mouseArea.containsMouse ? root.keyHoverBg
                                : root.keyBg
                            border.color: isLang ? root.accentColor
                                : toggled ? root.accentColor
                                : root.keyBorderColor

                            Text {
                                visible: !keyRect.isDual
                                anchors.centerIn: parent
                                text: keyData.label
                                    ? keyData.label
                                    : root.resolvedTypedChar(keyData)
                                color: keyRect.isLang || keyRect.toggled
                                    ? root.textHighlightColor
                                    : root.textMain
                                font.family: root.keyboardFont
                                font.pixelSize: root.keyFontSize
                            }

                            // Stacked dual symbols: shifted symbol on top
                            // (dim by default), base symbol on the bottom
                            // (bright by default) — swapping emphasis when
                            // Shift is held, mirroring `.key.dual.shift-active`.
                            Text {
                                visible: keyRect.isDual
                                text: keyData.s
                                anchors.top: parent.top
                                anchors.topMargin: root.gapPx
                                anchors.horizontalCenter: parent.horizontalCenter
                                color: root.isSymbolShiftActive() ? root.textHighlightColor : root.textDim
                                font.bold: root.isSymbolShiftActive()
                                font.family: root.keyboardFont
                                font.pixelSize: root.keySmallFontSize
                            }

                            Text {
                                visible: keyRect.isDual
                                text: keyData.t
                                anchors.bottom: parent.bottom
                                anchors.bottomMargin: root.gapPx
                                anchors.horizontalCenter: parent.horizontalCenter
                                color: root.isSymbolShiftActive() ? root.textDim : root.textMain
                                font.family: root.keyboardFont
                                font.pixelSize: root.keyFontSize
                            }

                            MouseArea {
                                id: mouseArea
                                anchors.fill: parent
                                hoverEnabled: true

                                Timer {
                                    id: modifierSingleClickDelay
                                    interval: 250
                                    repeat: false
                                    property var pendingKeyData: null
                                    onTriggered: {
                                        if (!pendingKeyData) return
                                        root.pressSpecial(pendingKeyData, false)
                                        pendingKeyData = null
                                    }
                                }

                                onClicked: {
                                    if (!keyData.key) {
                                        root.pressChar(keyData)
                                        return
                                    }
                                    if (!root.isHoldableModifierKey(keyData.key)) {
                                        root.pressSpecial(keyData, false)
                                        return
                                    }
                                    modifierSingleClickDelay.pendingKeyData = keyData
                                    modifierSingleClickDelay.restart()
                                }

                                onDoubleClicked: {
                                    if (!keyData.key || !root.isHoldableModifierKey(keyData.key)) return
                                    modifierSingleClickDelay.pendingKeyData = null
                                    modifierSingleClickDelay.stop()
                                    root.pressSpecial(keyData, true)
                                }
                            }
                        }

                        Row {
                            id: arrowRow
                            anchors.fill: parent
                            visible: keyData.cluster === "arrows"
                            spacing: root.gapPx
                            readonly property real subWidth: (width - 2 * root.gapPx) / 3

                            Rectangle {
                                width: arrowRow.subWidth
                                height: parent.height
                                radius: root.keyRadius
                                border.width: root.keyBorderWidth
                                border.color: root.keyBorderColor
                                color: leftArrowArea.pressed ? root.keyActiveBg
                                    : leftArrowArea.containsMouse ? root.keyHoverBg
                                    : root.keyBg
                                Text {
                                    anchors.centerIn: parent
                                    text: "\u25c0"
                                    color: root.textMain
                                    font.family: root.keyboardFont
                                    font.pixelSize: root.keyFontSize
                                }
                                MouseArea {
                                    id: leftArrowArea
                                    anchors.fill: parent
                                    hoverEnabled: true
                                    onClicked: root.pressSpecial({ key: "Left" })
                                }
                            }

                            Column {
                                width: arrowRow.subWidth
                                height: parent.height
                                spacing: root.gapPx

                                Rectangle {
                                    width: parent.width
                                    height: (parent.height - parent.spacing) / 2
                                    radius: root.keyRadius
                                    border.width: root.keyBorderWidth
                                    border.color: root.keyBorderColor
                                    color: upArrowArea.pressed ? root.keyActiveBg
                                        : upArrowArea.containsMouse ? root.keyHoverBg
                                        : root.keyBg
                                    Text {
                                        anchors.centerIn: parent
                                        text: "\u25b2"
                                        color: root.textMain
                                        font.family: root.keyboardFont
                                        font.pixelSize: root.keySmallFontSize
                                    }
                                    MouseArea {
                                        id: upArrowArea
                                        anchors.fill: parent
                                        hoverEnabled: true
                                        onClicked: root.pressSpecial({ key: "Up" })
                                    }
                                }

                                Rectangle {
                                    width: parent.width
                                    height: (parent.height - parent.spacing) / 2
                                    radius: root.keyRadius
                                    border.width: root.keyBorderWidth
                                    border.color: root.keyBorderColor
                                    color: downArrowArea.pressed ? root.keyActiveBg
                                        : downArrowArea.containsMouse ? root.keyHoverBg
                                        : root.keyBg
                                    Text {
                                        anchors.centerIn: parent
                                        text: "\u25bc"
                                        color: root.textMain
                                        font.family: root.keyboardFont
                                        font.pixelSize: root.keySmallFontSize
                                    }
                                    MouseArea {
                                        id: downArrowArea
                                        anchors.fill: parent
                                        hoverEnabled: true
                                        onClicked: root.pressSpecial({ key: "Down" })
                                    }
                                }
                            }

                            Rectangle {
                                width: arrowRow.subWidth
                                height: parent.height
                                radius: root.keyRadius
                                border.width: root.keyBorderWidth
                                border.color: root.keyBorderColor
                                color: rightArrowArea.pressed ? root.keyActiveBg
                                    : rightArrowArea.containsMouse ? root.keyHoverBg
                                    : root.keyBg
                                Text {
                                    anchors.centerIn: parent
                                    text: "\u25b6"
                                    color: root.textMain
                                    font.family: root.keyboardFont
                                    font.pixelSize: root.keyFontSize
                                }
                                MouseArea {
                                    id: rightArrowArea
                                    anchors.fill: parent
                                    hoverEnabled: true
                                    onClicked: root.pressSpecial({ key: "Right" })
                                }
                            }
                        }
                    }
                }
            }
        }
    }
}
