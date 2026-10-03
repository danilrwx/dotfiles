// The bar under Hyprland (config/eww is i3's): Hyprland's workspaces, the tray (StatusNotifierItem, Discord's
// menu included), and the status, i3bar's look. Sound, battery, tray, workspaces and the clock from
// Quickshell's own services, live; memory, brightness, the layout and VLESS and OpenVPN from bin/wm-status,
// once a second. The wheel on the volume, mic and brightness turns them, a right click mutes (bin/wm-fnkeys,
// for its card). bin/wl-autostart starts it; linked to ~/.config/quickshell by install.
import Quickshell
import Quickshell.Hyprland
import Quickshell.Io
import Quickshell.Services.Pipewire
import Quickshell.Services.SystemTray
import Quickshell.Services.UPower
import Quickshell.Widgets
import QtQuick
import QtQuick.Layouts

ShellRoot {
    id: root

    readonly property color fg: "#ffffff"
    readonly property color gray: "#888888"
    readonly property color accent: "#00cd00"
    readonly property string fnkeys: Quickshell.env("HOME") + "/dotfiles/bin/wm-fnkeys"

    // bin/wm-status's last line
    property var status: ({})
    Process {
        command: [Quickshell.env("HOME") + "/dotfiles/bin/wm-status"]
        running: true
        stdout: SplitParser {
            onRead: line => {
                try { root.status = JSON.parse(line) } catch (e) {}
            }
        }
    }

    PwObjectTracker {
        objects: [Pipewire.defaultAudioSink, Pipewire.defaultAudioSource]
    }
    readonly property var sink: Pipewire.defaultAudioSink?.audio ?? null
    readonly property var source: Pipewire.defaultAudioSource?.audio ?? null

    SystemClock {
        id: clock
        precision: SystemClock.Minutes
    }

    // run CMD...: a command, detached
    function run(cmd) { Quickshell.execDetached(cmd) }

    // a block: an emoji a size below the text, then the text; the wheel and clicks run what is given
    component Block: MouseArea {
        id: block
        property string icon
        property string text
        property var onWheelUp: null
        property var onWheelDown: null
        property var onLeft: null
        property var onRight: null
        implicitWidth: row.implicitWidth
        implicitHeight: row.implicitHeight
        acceptedButtons: Qt.LeftButton | Qt.RightButton
        cursorShape: (onLeft || onRight) ? Qt.PointingHandCursor : Qt.ArrowCursor
        onClicked: m => {
            if (m.button === Qt.RightButton && block.onRight) block.onRight()
            else if (m.button === Qt.LeftButton && block.onLeft) block.onLeft()
        }
        onWheel: w => {
            if (w.angleDelta.y > 0 && block.onWheelUp) block.onWheelUp()
            else if (w.angleDelta.y < 0 && block.onWheelDown) block.onWheelDown()
        }
        RowLayout {
            id: row
            spacing: 4
            Text {
                visible: block.icon !== ""
                text: block.icon
                font.family: "Noto Color Emoji"
                font.pointSize: 9
            }
            Text {
                text: block.text
                color: root.gray
                font.family: "Iosevka"
                font.pointSize: 11
            }
        }
    }

    Variants {
        model: Quickshell.screens

        PanelWindow {
            id: bar
            required property var modelData
            screen: modelData
            anchors { top: true; left: true; right: true }
            implicitHeight: 25
            color: "#000000"

            // workspaces, Hyprland's own, a click to go there
            RowLayout {
                anchors { left: parent.left; leftMargin: 12; verticalCenter: parent.verticalCenter }
                spacing: 0
                Repeater {
                    model: Hyprland.workspaces.values.filter(w => w.id > 0).sort((a, b) => a.id - b.id)
                    MouseArea {
                        required property var modelData
                        implicitWidth: label.implicitWidth + 12
                        implicitHeight: bar.height
                        cursorShape: Qt.PointingHandCursor
                        onClicked: Hyprland.dispatch("workspace " + modelData.id)
                        Text {
                            id: label
                            anchors.centerIn: parent
                            text: modelData.name
                            color: modelData.urgent ? root.accent
                                 : modelData.id === Hyprland.focusedWorkspace?.id ? root.fg : root.gray
                            font.family: "Iosevka"
                            font.pointSize: 11
                        }
                    }
                }
            }

            RowLayout {
                anchors { right: parent.right; rightMargin: 12; verticalCenter: parent.verticalCenter }
                spacing: 12

                Block { visible: (root.status.vless ?? "") !== ""; text: root.status.vless ?? "" }
                Block { visible: (root.status.openvpn ?? "") !== ""; text: root.status.openvpn ?? "" }
                Block {
                    icon: "🧠"; text: root.status.mem ?? ""
                    onLeft: () => root.run(["alacritty", "-e", "htop"])
                }
                Block {
                    icon: root.sink?.muted ? "🔇" : "🔊"
                    text: Math.round((root.sink?.volume ?? 0) * 100) + "%"
                    onWheelUp: () => root.run([root.fnkeys, "vol-up"])
                    onWheelDown: () => root.run([root.fnkeys, "vol-down"])
                    onRight: () => root.run([root.fnkeys, "vol-mute"])
                }
                Block {
                    icon: root.source?.muted ? "🙊" : "🎙️"
                    text: Math.round((root.source?.volume ?? 0) * 100) + "%"
                    onWheelUp: () => root.run([root.fnkeys, "mic-up"])
                    onWheelDown: () => root.run([root.fnkeys, "mic-down"])
                    onRight: () => root.run([root.fnkeys, "mic"])
                }
                Block {
                    readonly property var dev: UPower.displayDevice
                    visible: dev.isLaptopBattery
                    icon: dev.state === UPowerDeviceState.Charging ? "⚡" : dev.percentage < 0.2 ? "🪫" : "🔋"
                    text: Math.round(dev.percentage * 100) + "%"
                }
                Block {
                    icon: "🌞"; text: (root.status.bri ?? 0) + "%"
                    onWheelUp: () => root.run([root.fnkeys, "bright-up"])
                    onWheelDown: () => root.run([root.fnkeys, "bright-down"])
                }
                Block {
                    icon: root.status.ru ? "🇷🇺" : "🇺🇸"
                    text: root.status.ru ? "RU" : "US"
                }
                Block { text: Qt.formatDateTime(clock.date, "dd/MM/yyyy hh:mm") }

                // the tray: a click activates, a right click opens the item's menu
                Repeater {
                    model: SystemTray.items
                    MouseArea {
                        id: item
                        required property SystemTrayItem modelData
                        implicitWidth: 16
                        implicitHeight: 16
                        acceptedButtons: Qt.LeftButton | Qt.RightButton
                        cursorShape: Qt.PointingHandCursor
                        onClicked: m => {
                            if (m.button === Qt.RightButton || modelData.onlyMenu) {
                                if (modelData.hasMenu) menu.open()
                            } else {
                                modelData.activate()
                            }
                        }
                        QsMenuAnchor {
                            id: menu
                            menu: item.modelData.menu
                            anchor.item: item
                            anchor.edges: Edges.Bottom
                        }
                        IconImage {
                            anchors.fill: parent
                            source: item.modelData.icon
                        }
                    }
                }
            }
        }
    }
}
