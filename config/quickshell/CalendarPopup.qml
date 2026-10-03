// The calendar under the bar's clock, GNOME's date menu in the old look (Theme.qml): at the left the
// notifications' history with Do Not Disturb and Clear; at the right today's weekday and date, then the month
// with today inverted, arrows through the months. Fades in in 100 ms; closed by a click outside it or
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
    // the notifications' history (Notifications.qml), at the left as in GNOME's date menu
    property var notes
    implicitWidth: 680
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
        Rectangle { anchors.fill: parent; radius: Theme.radius; color: parent.containsMouse ? Theme.hover : "transparent" }
        Icon { anchors.centerIn: parent; name: parent.icon }
    }

    Rectangle {
        id: card
        width: parent.width
        height: Math.max(col.implicitHeight, 300) + 28
        radius: Theme.round
        color: Theme.popover
        border.color: Theme.fg
        border.width: 1
        opacity: popup.visible ? 1 : 0
        Behavior on opacity { NumberAnimation { duration: Theme.quick } }

        RowLayout {
          anchors { fill: parent; margins: 14 }
          spacing: 14

          // the notifications: the newest first, a click dismisses one; Do Not Disturb and Clear under them
          ColumnLayout {
            Layout.fillWidth: true
            Layout.fillHeight: true
            spacing: 6
            Label {
                Layout.fillWidth: true; horizontalAlignment: Text.AlignLeft; leftPadding: 6
                text: "Notifications"; font.bold: true
            }
            Flickable {
                Layout.fillWidth: true
                Layout.fillHeight: true
                contentHeight: list.implicitHeight
                clip: true
                ColumnLayout {
                    id: list
                    width: parent.width
                    spacing: 6
                    Label {
                        visible: (popup.notes?.history ?? []).length === 0
                        Layout.fillWidth: true; Layout.topMargin: 40
                        text: "No notifications"; color: Theme.dim
                    }
                    Repeater {
                        model: popup.notes?.history ?? []
                        MouseArea {
                            id: note
                            required property var modelData
                            Layout.fillWidth: true
                            implicitHeight: noteText.implicitHeight + 16
                            hoverEnabled: true
                            cursorShape: Qt.PointingHandCursor
                            onClicked: note.modelData.dismiss()
                            Rectangle {
                                anchors.fill: parent
                                radius: Theme.radius
                                color: note.containsMouse ? Theme.hover : Theme.card
                                border.color: Theme.rule
                            }
                            ColumnLayout {
                                id: noteText
                                anchors { left: parent.left; right: parent.right; top: parent.top; margins: 8 }
                                spacing: 1
                                Label {
                                    Layout.fillWidth: true; horizontalAlignment: Text.AlignLeft
                                    text: note.modelData.appName; color: Theme.dim; font.pointSize: 8.5
                                }
                                Label {
                                    Layout.fillWidth: true; horizontalAlignment: Text.AlignLeft
                                    text: note.modelData.summary; font.bold: true; elide: Text.ElideRight
                                }
                                Label {
                                    Layout.fillWidth: true; horizontalAlignment: Text.AlignLeft
                                    visible: text !== ""; text: note.modelData.body
                                    wrapMode: Text.Wrap; maximumLineCount: 3; elide: Text.ElideRight
                                }
                                // its actions beside the default one, a button each
                                Flow {
                                    Layout.fillWidth: true
                                    Layout.topMargin: 4
                                    spacing: 6
                                    visible: (note.modelData.actions ?? []).some(a => a.identifier !== "default")
                                    Repeater {
                                        model: (note.modelData.actions ?? []).filter(a => a.identifier !== "default")
                                        MouseArea {
                                            id: act
                                            required property var modelData
                                            implicitWidth: actText.implicitWidth + 20
                                            implicitHeight: 24
                                            hoverEnabled: true
                                            cursorShape: Qt.PointingHandCursor
                                            onClicked: { act.modelData.invoke(); note.modelData.dismiss() }
                                            Rectangle {
                                                anchors.fill: parent
                                                radius: Theme.radius
                                                color: act.containsMouse ? Theme.accent : Theme.pill
                                                border.color: Theme.rule
                                            }
                                            Label {
                                                id: actText
                                                anchors.centerIn: parent
                                                text: act.modelData.text; font.pointSize: 9
                                                color: act.containsMouse ? Theme.inverse : Theme.fg
                                            }
                                        }
                                    }
                                }
                            }
                        }
                    }
                }
            }
            RowLayout {
                Layout.fillWidth: true
                spacing: 8
                // Do Not Disturb: inverted while on
                MouseArea {
                    implicitWidth: dndText.implicitWidth + 20; implicitHeight: 30
                    cursorShape: Qt.PointingHandCursor
                    onClicked: popup.notes.dnd = !popup.notes.dnd
                    Rectangle {
                        anchors.fill: parent
                        radius: Theme.radius
                        color: popup.notes?.dnd ? Theme.accent : Theme.pill
                        border.color: popup.notes?.dnd ? Theme.accent : Theme.rule
                    }
                    Label { id: dndText; anchors.centerIn: parent; text: "Do Not Disturb"; color: popup.notes?.dnd ? Theme.inverse : Theme.fg }
                }
                Item { Layout.fillWidth: true }
                MouseArea {
                    visible: (popup.notes?.history ?? []).length > 0
                    implicitWidth: clearText.implicitWidth + 20; implicitHeight: 30
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    onClicked: popup.notes.clear()
                    Rectangle { anchors.fill: parent; radius: Theme.radius; color: parent.containsMouse ? Theme.hover : Theme.pill; border.color: Theme.rule }
                    Label { id: clearText; anchors.centerIn: parent; text: "Clear" }
                }
            }
          }

          Rectangle { Layout.fillHeight: true; implicitWidth: 1; color: Theme.rule }

        ColumnLayout {
            id: col
            Layout.preferredWidth: 302
            Layout.alignment: Qt.AlignTop
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
                radius: Theme.radius
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
                                width: 32; height: 32; radius: Theme.radius
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
}
