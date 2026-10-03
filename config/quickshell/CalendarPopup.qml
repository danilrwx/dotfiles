// The calendar under the bar's clock, GNOME's date menu in the old look (Theme.qml): today's weekday and date
// up top, then the month with today inverted, arrows through the months. Fades in in 100 ms; closed by a click outside it or
// on the clock again.
import Quickshell
import Quickshell.Hyprland
import Quickshell.Wayland
import QtQuick
import QtQuick.Controls
import QtQuick.Layouts

PanelWindow {
    id: popup
    property bool open: false
    function toggle() { open = !open }
    // the month shown, back to this one on every opening
    property date shown: new Date()
    onOpenChanged: if (open) shown = new Date()

    visible: open
    // the top edge alone: centred under the clock
    anchors { top: true }
    margins { top: 4 }
    exclusiveZone: 0
    implicitWidth: 330
    implicitHeight: card.height
    color: "transparent"
    WlrLayershell.layer: WlrLayer.Overlay
    WlrLayershell.namespace: "quickshell-panel"

    HyprlandFocusGrab {
        active: popup.visible
        windows: [popup]
        onCleared: popup.open = false
    }

    component Label: Text {
        color: Theme.fg
        font.family: Theme.font
        font.pointSize: 10
        horizontalAlignment: Text.AlignHCenter
    }
    component Step: MouseArea {
        property string icon
        implicitWidth: 32; implicitHeight: 32
        hoverEnabled: true
        cursorShape: Qt.PointingHandCursor
        Rectangle { anchors.fill: parent; radius: 0; color: parent.containsMouse ? Theme.hover : "transparent" }
        Icon { anchors.centerIn: parent; name: parent.icon }
    }

    Rectangle {
        id: card
        width: parent.width
        height: col.implicitHeight + 28
        radius: 0
        color: Theme.popover
        border.color: Theme.fg
        border.width: 1
        opacity: popup.visible ? 1 : 0
        Behavior on opacity { NumberAnimation { duration: Theme.quick } }

        ColumnLayout {
            id: col
            anchors { left: parent.left; right: parent.right; top: parent.top; margins: 14 }
            spacing: 4

            Label {
                Layout.fillWidth: true; horizontalAlignment: Text.AlignLeft; leftPadding: 6
                text: new Date().toLocaleDateString(Qt.locale("en_US"), "dddd"); color: Theme.dim
            }
            Label {
                Layout.fillWidth: true; horizontalAlignment: Text.AlignLeft; leftPadding: 6; bottomPadding: 8
                text: new Date().toLocaleDateString(Qt.locale("en_US"), "MMMM d yyyy")
                font.bold: true; font.pointSize: 14
            }
            Rectangle {
                Layout.fillWidth: true
                implicitHeight: month.implicitHeight + 16
                radius: 0
                color: Theme.card
                border.color: Theme.rule
                ColumnLayout {
                    id: month
                    anchors { left: parent.left; right: parent.right; top: parent.top; margins: 8 }
                    spacing: 2
                    RowLayout {
                        Layout.fillWidth: true
                        Step { icon: "go-previous-symbolic"; onClicked: popup.shown = new Date(popup.shown.getFullYear(), popup.shown.getMonth() - 1, 1) }
                        Label {
                            Layout.fillWidth: true; font.bold: true
                            text: popup.shown.toLocaleDateString(Qt.locale("en_US"), "MMMM yyyy")
                        }
                        Step { icon: "go-next-symbolic"; onClicked: popup.shown = new Date(popup.shown.getFullYear(), popup.shown.getMonth() + 1, 1) }
                    }
                    DayOfWeekRow {
                        Layout.fillWidth: true
                        locale: Qt.locale("en_GB")
                        delegate: Label {
                            required property string shortName
                            text: shortName.charAt(0); color: Theme.dim; font.pointSize: 8.5; font.bold: true
                        }
                    }
                    MonthGrid {
                        Layout.fillWidth: true
                        locale: Qt.locale("en_GB")
                        month: popup.shown.getMonth()
                        year: popup.shown.getFullYear()
                        delegate: Item {
                            required property int day
                            required property int month
                            required property bool today
                            implicitWidth: 38
                            implicitHeight: 34
                            Rectangle {
                                anchors.centerIn: parent
                                width: 32; height: 32; radius: 0
                                color: parent.today ? Theme.accent : "transparent"
                            }
                            Label {
                                anchors.centerIn: parent
                                text: parent.day
                                font.bold: parent.today
                                color: parent.today ? Theme.inverse : parent.month === popup.shown.getMonth() ? Theme.fg : "#444444"
                            }
                        }
                    }
                }
            }
        }
    }
}
