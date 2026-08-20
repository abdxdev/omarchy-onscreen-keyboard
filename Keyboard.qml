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

    // Called on startup only — reads the system's current layout and populates
    // languageCycle. After the user manually cycles, we stop syncing currentLayout
    // from the system (the virtual keyboard always reports index 0, so syncing
    // would constantly fight the user's choice).
    property bool initialSyncDone: false

    function parseHyprLayoutOutput(text) {
        var lines = String(text || "").split("\n")
        var active = ""
        var detected = []
        var names = ({})

        for (var i = 0; i < lines.length; i++) {
            var line = lines[i].trim()
            if (!line) continue
            var parts = line.split("\t")
            if (parts.length < 2) continue
            if (parts[0] === "ACTIVE") {
                active = String(parts[1] || "").trim()
                continue
            }
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

        // Only sync currentLayout from system on first load, not on periodic polls.
        // The virtual keyboard (.main == true) always stays at index 0, so subsequent
        // syncs would permanently fight any manual language switch by the user.
        if (!initialSyncDone) {
            initialSyncDone = true
            var selected = active
            if (!selected && detected.length > 0) selected = detected[0]
            if (selected && selected !== currentLayout) {
                layoutCycleIndex = Math.max(0, detected.indexOf(selected))
                loadLanguageLayout(selected)
            } else {
                layoutCycleIndex = Math.max(0, detected.indexOf(currentLayout))
            }
        }
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
        layoutLoadProcess.command = ["bash", "-lc",
            "file=/usr/share/X11/xkb/symbols/" + layoutCode + "; "
            + "[[ -f \"$file\" ]] || exit 1; "
            + "awk '\n"
            + " /^[[:space:]]*xkb_symbols[[:space:]]*\"/ && !seen { seen=1; inblock=1 }\n"
            + " inblock {\n"
            + "   if ($0 ~ /\\{/) depth++\n"
            + "   if (match($0, /key[[:space:]]*<([A-Z0-9]+)>[[:space:]]*\\{[[:space:]]*\\[([^]]+)\\]/, m)) {\n"
            + "     n=split(m[2], arr, /,/)\n"
            + "     gsub(/[[:space:]]+/, \"\", arr[1])\n"
            + "     gsub(/[[:space:]]+/, \"\", arr[2])\n"
            + "     print m[1] \"\\t\" arr[1] \"\\t\" arr[2]\n"
            + "   }\n"
            + "   if ($0 ~ /\\}/) { depth--; if (seen && depth <= 0) exit }\n"
            + " }\n"
            + "' \"$file\""]
        layoutLoadProcess.running = true
    }

    function cycleLanguage() {
        if (languageCycle.length < 2) return
        // Advance our local index so we know exactly what layout is next,
        // independent of the system's virtual keyboard reporting wrong index.
        layoutCycleIndex = (layoutCycleIndex + 1) % languageCycle.length
        var nextLayout = languageCycle[layoutCycleIndex]
        Quickshell.execDetached(["hyprctl", "switchxkblayout", "all", "next"])
        loadLanguageLayout(nextLayout)
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

    // Periodic sync: only updates languageCycle (available layouts), never
    // overrides currentLayout after the user has manually cycled (initialSyncDone=true).
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

    function isLetterKey(keyData) {
        return /^[a-z]$/.test(keyData.t || "")
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
        return !!keyData.s && !/^[a-z]$/.test(keyData.t || "")
    }

    // Every keystroke goes through here: dispatch focuscurrentorlast to
    // reclaim focus on the real target window first, then fire the wtype
    // command a beat later so Hyprland has processed the focus change.
    Timer {
        id: focusDelay
        interval: 25
        repeat: false
        property var pendingArgv: []
        onTriggered: Quickshell.execDetached(focusDelay.pendingArgv)
    }

    function sendKeys(argv) {
        Quickshell.execDetached(Layout.buildFocusCommand())
        focusDelay.pendingArgv = argv
        focusDelay.restart()
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
