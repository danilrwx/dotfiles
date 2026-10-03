// A tray item's menu (its DBusMenu: Discord's Quit and the rest) drawn in the bar's look rather than as Qt's
// platform menu: black, a 1px rule, the item under the pointer inverted, separators as rules, a submenu opening
// beside its entry. Closed by a pick or a click outside it.
import Quickshell
import Quickshell.Hyprland
import QtQuick
import QtQuick.Layouts

PopupWindow {
    id: menu
    // the menu handle to show, and the item it hangs under
    property var handle
    property Item anchorItem
    // the menu one level up, to close along with this one; null for the top
    property var parentMenu: null
    property bool open: false

    function close() {
        open = false
        if (parentMenu) parentMenu.close()
    }

    visible: open
    anchor.item: anchorItem
    anchor.edges: parentMenu ? Edges.Right | Edges.Top : Edges.Bottom | Edges.Right
    anchor.gravity: parentMenu ? Edges.Right | Edges.Bottom : Edges.Bottom | Edges.Left
    implicitWidth: Math.max(180, col.implicitWidth + 2)
    implicitHeight: col.implicitHeight + 2
    color: "transparent"

    // closed by a click outside it and the bar: Hyprland's focus grab, taken once the popup is up (taken as
    // it maps, it never lands), the bar in it so a click on the icon toggles rather than closes and reopens
    property var grabWith: []
    property bool grabbing: false
    onVisibleChanged: {
        grabbing = false
        if (visible && !parentMenu) grabTimer.restart()
    }
    Timer { id: grabTimer; interval: 50; onTriggered: menu.grabbing = true }
    HyprlandFocusGrab {
        active: menu.grabbing
        windows: [menu].concat(menu.grabWith)
        onCleared: menu.close()
    }

    QsMenuOpener { id: opener; menu: menu.handle }

    Rectangle {
        anchors.fill: parent
        color: Theme.popover
        border.color: Theme.fg
        border.width: 1

        ColumnLayout {
            id: col
            anchors { left: parent.left; right: parent.right; top: parent.top; margins: 1 }
            spacing: 0

            Repeater {
                model: opener.children
                Item {
                    id: entry
                    required property var modelData
                    // its submenu shown
                    property bool subOpen: false
                    Layout.fillWidth: true
                    implicitWidth: row.implicitWidth + 24
                    implicitHeight: modelData.isSeparator ? 9 : 28

                    Rectangle {
                        visible: entry.modelData.isSeparator
                        anchors { left: parent.left; right: parent.right; verticalCenter: parent.verticalCenter; margins: 6 }
                        height: 1
                        color: Theme.rule
                    }
                    MouseArea {
                        id: area
                        visible: !entry.modelData.isSeparator
                        anchors.fill: parent
                        hoverEnabled: true
                        enabled: entry.modelData.enabled
                        cursorShape: Qt.PointingHandCursor
                        onClicked: {
                            if (entry.modelData.hasChildren) {
                                entry.subOpen = !entry.subOpen
                            } else {
                                entry.modelData.triggered()
                                menu.close()
                            }
                        }
                        Rectangle { anchors.fill: parent; color: area.containsMouse ? Theme.accent : "transparent" }
                        RowLayout {
                            id: row
                            anchors { fill: parent; leftMargin: 12; rightMargin: 12 }
                            spacing: 8
                            Text {
                                // a check or radio entry: a mark while it is on
                                visible: entry.modelData.buttonType !== QsMenuButtonType.None
                                text: entry.modelData.checkState === Qt.Checked ? "■" : "□"
                                color: area.containsMouse ? Theme.inverse : Theme.fg
                                font.family: Theme.font
                                font.pointSize: 10
                            }
                            Text {
                                Layout.fillWidth: true
                                text: entry.modelData.text.replace(/&(?!&)/g, "")
                                color: !entry.modelData.enabled ? Theme.dim : area.containsMouse ? Theme.inverse : Theme.fg
                                font.family: Theme.font
                                font.pointSize: 10
                            }
                            Text {
                                visible: entry.modelData.hasChildren
                                text: "›"
                                color: area.containsMouse ? Theme.inverse : Theme.fg
                                font.family: Theme.font
                                font.pointSize: 11
                            }
                        }
                    }
                    // the submenu, this same file loaded again while it is open
                    Loader {
                        active: entry.subOpen
                        onLoaded: item.open = true
                        Component.onCompleted: setSource("TrayMenu.qml", { handle: entry.modelData, anchorItem: entry, parentMenu: menu })
                    }
                }
            }
        }
    }
}
