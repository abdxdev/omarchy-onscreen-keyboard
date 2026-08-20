import Quickshell
import Quickshell.Wayland
import QtQuick
import qs.Commons

Item {
    id: root

    property var shell: null
    property var manifest: null
    property bool opened: false

    function open(payloadJson) {
        root.opened = true
    }

    function close() {
        root.opened = false
    }

    function toggle() {
        root.opened = !root.opened
    }

    PanelWindow {
        id: panel
        visible: root.opened
        anchors {
            top: true
            bottom: true
            left: true
            right: true
        }
        color: "transparent"
        mask: Region {
            item: card
        }

        // The whole point: never take keyboard focus, so the app window
        // you're typing into keeps it, and wtype has something to type
        // into. Clicks on the keys still work fine with keyboardFocus: None
        // — only keyboard input routing is refused at the compositor level.
        WlrLayershell.namespace: "io.github.abdxdev.onscreen-keyboard"
        WlrLayershell.layer: WlrLayer.Overlay
        WlrLayershell.keyboardFocus: WlrKeyboardFocus.None
        exclusionMode: ExclusionMode.Ignore

        // Mirrors the reference `.keyboard-container`: solid panel
        // background, subtle border, and padding equal to the key gap.
        // Corner rounding follows Omarchy's shared style token.
        // No title bar — the reference has none; its ✕ lives in the
        // key grid itself.
        Rectangle {
            id: card
            width: Math.min(panel.width - Style.spacing.popupPadding, keyboard.implicitWidth + keyboard.gapPx * 2) + Style.spacing.popupPadding
            x: (panel.width - width) / 2
            y: panel.height - height - Style.spacing.lg
            implicitHeight: keyboard.implicitHeight + keyboard.gapPx * 2 + dragArea.height + Style.spacing.popupPadding / 2
            radius: Style.cornerRadius
            color: Color.popups.background
            border.color: Color.accent
            border.width: 2

            MouseArea {
                id: dragArea
                width: parent.width
                height: 25
                cursorShape: Qt.SizeAllCursor
                drag.target: card
                drag.axis: Drag.XAndYAxis
                drag.minimumX: 0
                drag.maximumX: panel.width - card.width
                drag.minimumY: 0
                drag.maximumY: panel.height - card.height
            }

            Keyboard {
                id: keyboard
                anchors {
                    horizontalCenter: parent.horizontalCenter
                    top: parent.top
                    topMargin: dragArea.height + keyboard.gapPx
                }
                onCloseRequested: root.close()
            }
        }
    }
}
