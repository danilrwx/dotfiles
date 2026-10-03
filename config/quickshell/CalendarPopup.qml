// The calendar under the bar's clock, the control panel's look: a month, today in blue, arrows through the
// months. Fades in in 100 ms; closed by a click outside it or on the clock again.
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
    anchors { top: true; right: true }
    margins { top: 4; right: 6 }
    exclusiveZone: 0
    implicitWidth: 300
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
        color: "#ffffff"
        font.family: "Noto Sans"
        font.pointSize: 10
        horizontalAlignment: Text.AlignHCenter
    }
    component Step: MouseArea {
        property string glyph
        implicitWidth: 26; implicitHeight: 26
        hoverEnabled: true
        cursorShape: Qt.PointingHandCursor
        Rectangle { anchors.fill: parent; radius: 13; color: parent.containsMouse ? Qt.rgba(1, 1, 1, 0.10) : "transparent" }
        Label { anchors.centerIn: parent; text: parent.glyph; font.pointSize: 12 }
    }

    Rectangle {
        id: card
        width: parent.width
        height: col.implicitHeight + 24
        radius: 18
        color: Qt.rgba(28 / 255, 28 / 255, 30 / 255, 0.92)
        border.color: Qt.rgba(1, 1, 1, 0.12)
        border.width: 1
        opacity: popup.visible ? 1 : 0
        Behavior on opacity { NumberAnimation { duration: 100 } }

        ColumnLayout {
            id: col
            anchors { left: parent.left; right: parent.right; top: parent.top; margins: 12 }
            spacing: 6

            RowLayout {
                Layout.fillWidth: true
                Step { glyph: "‹"; onClicked: popup.shown = new Date(popup.shown.getFullYear(), popup.shown.getMonth() - 1, 1) }
                Label {
                    Layout.fillWidth: true
                    text: popup.shown.toLocaleDateString(Qt.locale("en_US"), "MMMM yyyy")
                    font.bold: true
                }
                Step { glyph: "›"; onClicked: popup.shown = new Date(popup.shown.getFullYear(), popup.shown.getMonth() + 1, 1) }
            }
            DayOfWeekRow {
                Layout.fillWidth: true
                locale: Qt.locale("en_GB")
                delegate: Label { required property string shortName; text: shortName; color: Qt.rgba(1, 1, 1, 0.55) }
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
                    implicitWidth: 36
                    implicitHeight: 32
                    Rectangle {
                        anchors.centerIn: parent
                        width: 30; height: 30; radius: 15
                        color: parent.today ? "#0a84ff" : "transparent"
                    }
                    Label {
                        anchors.centerIn: parent
                        text: parent.day
                        color: parent.month === popup.shown.getMonth() ? "#ffffff" : Qt.rgba(1, 1, 1, 0.25)
                    }
                }
            }
        }
    }
}
