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
        // background, subtle border, padding equal to the key gap, and
        // a radius 4px larger than the keys' own radius. No title bar —
        // the reference has none; its ✕ lives in the key grid itself.
        Rectangle {
            id: card
            width: Math.min(panel.width - Style.space(16), keyboard.implicitWidth + keyboard.gapPx * 2)
            x: (panel.width - width) / 2
            y: panel.height - height - Style.space(8)
            implicitHeight: keyboard.implicitHeight + keyboard.gapPx * 2 + dragArea.height
            radius: keyboard.keyRadius + Style.space(4)
            color: Color.popups.background
            border.color: keyboard.keyBorderColor
            border.width: 1

            MouseArea {
                id: dragArea
                width: parent.width
                height: Style.space(18)
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
