import QtQuick
import Quickshell
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
    readonly property color closeHoverColor: Util.alpha(Color.urgent, Style.pressedFillAlpha)
    readonly property color textMain: Color.foreground
    readonly property color textDim: Color.muted
    readonly property color textHighlightColor: Color.foreground
    readonly property string keyboardFont: Style.font.family
    readonly property int keyBorderWidth: Style.normalBorderWidth
    readonly property int keyFontSize: Style.font.body
    readonly property int keySmallFontSize: Style.font.bodySmall

    property bool capsOn: false
    property bool shiftOn: false
    property bool ctrlOn: false
    property bool altOn: false
    property bool superOn: false
    property bool altgrOn: false

    function activeModifier() {
        if (ctrlOn) return "ctrl"
        if (altOn) return "alt"
        if (superOn) return "logo"
        if (altgrOn) return "altgr"
        return ""
    }

    function clearComboMods() {
        ctrlOn = false
        altOn = false
        superOn = false
        altgrOn = false
    }

    function isUpper() {
        return capsOn !== shiftOn
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
        var mod = activeModifier()
        if (mod) {
            sendKeys(Layout.buildModCharCommand(mod, keyData.t))
            clearComboMods()
            return
        }
        var text = isUpper() && keyData.s ? keyData.s : keyData.t
        sendKeys(Layout.buildTypeCommand(text))
        shiftOn = false
    }

    function pressSpecial(keyData) {
        switch (keyData.key) {
        case "close": closeRequested(); return
        case "emoji": Quickshell.execDetached(["omarchy-menu-emoji"]); return
        case "caps": capsOn = !capsOn; return
        case "shift": shiftOn = !shiftOn; return
        case "ctrl": ctrlOn = !ctrlOn; return
        case "alt": altOn = !altOn; return
        case "logo": superOn = !superOn; return
        case "altgr": altgrOn = !altgrOn; return
        }
        var mod = activeModifier()
        if (mod) {
            sendKeys(Layout.buildModKeyCommand(mod, keyData.key))
        } else {
            sendKeys(Layout.buildKeyCommand(keyData.key))
        }
        clearComboMods()
        shiftOn = false
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
            model: Layout.rows
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
                            property bool isClose: keyData.key === "close"
                            property bool isDual: root.isDualKey(keyData)

                            color: toggled ? root.accentColor
                                : (isClose && mouseArea.containsMouse) ? root.closeHoverColor
                                : mouseArea.pressed ? root.keyActiveBg
                                : mouseArea.containsMouse ? root.keyHoverBg
                                : root.keyBg
                            border.color: toggled ? root.accentColor
                                : (isClose && mouseArea.containsMouse) ? root.closeHoverColor
                                : root.keyBorderColor

                            Text {
                                visible: !keyRect.isDual
                                anchors.centerIn: parent
                                text: keyData.label
                                    ? keyData.label
                                    : (root.isUpper() && keyData.s ? keyData.s : keyData.t)
                                color: keyRect.toggled || (keyRect.isClose && mouseArea.containsMouse)
                                    ? root.textHighlightColor
                                    : root.textMain
                                font.family: root.keyboardFont
                                font.pixelSize: root.keyFontSize
                            }

                            // Stacked dual symbols: shifted symbol on top
                            // (dim by default), base symbol on the bottom
                            // (bright by default) — swapping emphasis when
                            // shifted, mirroring `.key.dual.shift-active`.
                            Text {
                                visible: keyRect.isDual
                                text: keyData.s
                                anchors.top: parent.top
                                anchors.topMargin: root.gapPx
                                anchors.horizontalCenter: parent.horizontalCenter
                                color: root.isUpper() ? root.textHighlightColor : root.textDim
                                font.bold: root.isUpper()
                                font.family: root.keyboardFont
                                font.pixelSize: root.keySmallFontSize
                            }

                            Text {
                                visible: keyRect.isDual
                                text: keyData.t
                                anchors.bottom: parent.bottom
                                anchors.bottomMargin: root.gapPx
                                anchors.horizontalCenter: parent.horizontalCenter
                                color: root.isUpper() ? root.textDim : root.textMain
                                font.family: root.keyboardFont
                                font.pixelSize: root.keyFontSize
                            }

                            MouseArea {
                                id: mouseArea
                                anchors.fill: parent
                                hoverEnabled: true
                                onClicked: keyData.key
                                    ? root.pressSpecial(keyData)
                                    : root.pressChar(keyData)
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
