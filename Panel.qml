import Quickshell
import Quickshell.Wayland
import Quickshell.Io
import QtQuick
import qs.Commons
import qs.Ui

Item {
    id: root

    property var shell: null
    property var manifest: null
    property bool opened: false
    property bool dependenciesReady: true

    function checkDependencies() {
        dependencyCheck.running = true
    }

    function installDependencies() {
        if (dependencyInstall.running) return
        dependencyInstall.running = true
    }

    function open(payloadJson) {
        root.opened = true
    }

    function close() {
        root.opened = false
    }

    function toggle() {
        root.opened = !root.opened
    }

    Component.onCompleted: root.checkDependencies()

    Process {
        id: dependencyCheck
        command: ["bash", "-c", "command -v wtype >/dev/null && command -v hyprctl >/dev/null"]
        onExited: function(exitCode, exitStatus) {
            root.dependenciesReady = exitCode === 0 && exitStatus === 0
        }
    }

    Process {
        id: dependencyInstall
        command: ["xdg-terminal-exec", "--app-id=org.omarchy.terminal",
            "--title=Install On-Screen Keyboard dependencies", "omarchy", "pkg",
            "add", "wtype", "hyprland"]
        onExited: function(exitCode, exitStatus) {
            root.dependenciesReady = false
            root.checkDependencies()
        }
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
        BorderSurface {
            id: card
            width: Math.min(panel.width - Style.spacing.popupPadding, keyboard.implicitWidth + keyboard.gapPx * 2) + Style.spacing.popupPadding
            x: (panel.width - width) / 2
            y: panel.height - height - Style.spacing.lg
            implicitHeight: keyboard.implicitHeight + keyboard.gapPx * 2 + dragBar.height
                + (dependencyNotice.visible ? dependencyNotice.height + keyboard.gapPx : 0)
                + Style.spacing.popupPadding / 2
            radius: Style.cornerRadius
            color: Color.popups.background
            borderSpec: Border.hyprlandActiveSpec(Color.accent, 2)

            Item {
                id: dragBar
                width: parent.width
                height: Style.space(30) + keyboard.gapPx * 3

                MouseArea {
                    id: dragArea
                    anchors.fill: parent
                    cursorShape: Qt.SizeAllCursor
                    drag.target: card
                    drag.axis: Drag.XAndYAxis
                    drag.minimumX: 0
                    drag.maximumX: panel.width - card.width
                    drag.minimumY: 0
                    drag.maximumY: panel.height - card.height
                }

                Text {
                    anchors {
                        horizontalCenter: parent.horizontalCenter
                        verticalCenter: languageSwitch.verticalCenter
                    }
                    text: "\u2328 Drag to move \u00b7 Double press Shift/Ctrl/Alt/Super to lock"
                    color: Color.muted
                    font.family: Style.font.family
                    font.pixelSize: Style.font.bodySmall
                    z: 1
                }

                Rectangle {
                    id: languageSwitch
                    anchors {
                        left: parent.left
                        leftMargin: keyboard.gapPx * 2
                        bottom: parent.bottom
                        bottomMargin: keyboard.gapPx
                    }
                    width: langLabel.implicitWidth + keyboard.gapPx * 3
                    height: Style.space(30)
                    radius: Style.cornerRadius
                    color: languageArea.containsMouse ? (languageArea.pressed ? Color.accent : Util.alpha(Color.foreground, Style.hoverFillAlpha)) : Util.alpha(Color.foreground, Style.normalFillAlpha)
                    border.color: Util.alpha(Color.foreground, Style.pressedFillAlpha)
                    border.width: Style.normalBorderWidth
                    z: 2

                    Text {
                        id: langLabel
                        anchors.centerIn: parent
                        text: keyboard.currentLayoutName
                        color: Color.foreground
                        font.family: Style.font.family
                        font.pixelSize: Style.font.bodySmall
                        font.bold: true
                    }

                    MouseArea {
                        id: languageArea
                        anchors.fill: parent
                        onClicked: keyboard.cycleLanguage()
                    }
                }

                Rectangle {
                    id: closeButton
                    anchors {
                        right: parent.right
                        rightMargin: keyboard.gapPx * 2
                        bottom: parent.bottom
                        bottomMargin: keyboard.gapPx
                    }
                    width: Style.space(30)
                    height: Style.space(30)
                    radius: Style.cornerRadius
                    color: closeArea.pressed ? Color.urgent
                        : closeArea.containsMouse ? Util.alpha(Color.urgent, Style.hoverFillAlpha)
                        : Util.alpha(Color.foreground, Style.normalFillAlpha)
                    border.color: closeArea.containsMouse ? Util.alpha(Color.urgent, Style.pressedFillAlpha) : Util.alpha(Color.foreground, Style.pressedFillAlpha)
                    border.width: Style.normalBorderWidth
                    z: 2

                    Text {
                        id: closeLabel
                        anchors.centerIn: parent
                        text: "\u2715"
                        color: closeArea.containsMouse ? Color.urgent : Color.foreground
                        font.family: Style.font.family
                        font.pixelSize: Style.font.bodySmall
                    }

                    MouseArea {
                        id: closeArea
                        anchors.fill: parent
                        hoverEnabled: true
                        onClicked: root.close()
                    }
                }
            }

            Keyboard {
                id: keyboard
                anchors {
                    horizontalCenter: parent.horizontalCenter
                    top: parent.top
                    topMargin: dragBar.height + keyboard.gapPx
                }
                onCloseRequested: root.close()
            }

            Rectangle {
                id: dependencyNotice
                visible: !root.dependenciesReady
                anchors {
                    horizontalCenter: parent.horizontalCenter
                    top: keyboard.bottom
                    topMargin: keyboard.gapPx
                }
                width: keyboard.rowWidth
                height: Style.space(36)
                radius: Style.cornerRadius
                color: Color.popups.background
                border.color: Color.accent
                border.width: Style.normalBorderWidth

                Text {
                    anchors {
                        left: parent.left
                        leftMargin: Style.spacing.md
                        verticalCenter: parent.verticalCenter
                    }
                    text: dependencyInstall.running
                        ? "Installing keyboard dependencies..."
                        : "Keyboard dependencies are missing"
                    color: Color.foreground
                    font.family: Style.font.family
                    font.pixelSize: Style.font.bodySmall
                }

                Rectangle {
                    anchors {
                        right: parent.right
                        rightMargin: Style.spacing.sm
                        verticalCenter: parent.verticalCenter
                    }
                    width: installLabel.implicitWidth + Style.spacing.lg
                    height: Style.space(28)
                    radius: Style.cornerRadius
                    color: installArea.pressed ? Color.accent : Color.foreground

                    Text {
                        id: installLabel
                        anchors.centerIn: parent
                        text: dependencyInstall.running ? "Working..." : "Install"
                        color: Color.background
                        font.family: Style.font.family
                        font.pixelSize: Style.font.bodySmall
                    }

                    MouseArea {
                        id: installArea
                        anchors.fill: parent
                        enabled: !dependencyInstall.running
                        onClicked: root.installDependencies()
                    }
                }
            }
        }
    }
}
