// Notifications under Hyprland, in the bar's look, Quickshell being the notification server (dunst stays i3's
// and sway's). Toasts at the top right under the bar: the app, the summary, the body; a click runs its default
// action, a right click dismisses it; gone after its timeout (5 s unless it says), a critical one stays. What
// bin/wm-fnkeys sends (app "fnkeys": volume, mic, brightness as a level, the touchpad, power profile and camera
// as a word) is the OSD instead, a box at the bottom centre. Every other notification stays in the history the
// quick settings list until dismissed; Do Not Disturb keeps the toasts back, not the history.
import Quickshell
import Quickshell.Services.Notifications
import Quickshell.Wayland
import QtQuick
import QtQuick.Layouts

Scope {
    id: notes

    property bool dnd: false
    // the history, newest first
    readonly property var history: server.trackedNotifications.values.slice().reverse()
    function clear() {
        for (const n of server.trackedNotifications.values.slice()) n.dismiss()
    }

    // the toasts up now, each with when it goes
    property var toasts: []
    function show(n) {
        const ms = n.urgency === NotificationUrgency.Critical ? 0 : n.expireTimeout > 0 ? n.expireTimeout : 5000
        toasts = toasts.filter(t => t.n !== n).concat([{ n: n, until: ms ? Date.now() + ms : 0 }])
        sweep.restart()
    }
    function hide(n) { toasts = toasts.filter(t => t.n !== n) }
    Timer {
        id: sweep
        interval: 250; repeat: true
        running: notes.toasts.some(t => t.until)
        onTriggered: notes.toasts = notes.toasts.filter(t => !t.until || t.until > Date.now())
    }

    // the OSD's notification, and how long it stays
    property var osd: null
    Timer { id: osdTimer; interval: 1500; onTriggered: notes.osd = null }

    NotificationServer {
        id: server
        keepOnReload: true
        bodySupported: true
        bodyMarkupSupported: false
        actionsSupported: true
        persistenceSupported: true
        onNotification: n => {
            if (n.appName === "fnkeys") {
                notes.osd = n
                osdTimer.interval = n.expireTimeout > 0 ? n.expireTimeout : 1500
                osdTimer.restart()
                return
            }
            n.tracked = true
            n.closed.connect(() => notes.hide(n))
            if (!notes.dnd) notes.show(n)
        }
    }

    component Label: Text {
        color: Theme.fg
        font.family: Theme.font
        font.pointSize: 10
        wrapMode: Text.Wrap
    }

    // the toasts, top right under the bar
    PanelWindow {
        visible: notes.toasts.length > 0
        anchors { top: true; right: true }
        margins { top: 4; right: 6 }
        exclusiveZone: 0
        implicitWidth: 360
        implicitHeight: stack.implicitHeight
        color: "transparent"
        WlrLayershell.layer: WlrLayer.Overlay
        WlrLayershell.namespace: "quickshell-notifications"

        ColumnLayout {
            id: stack
            width: parent.width
            spacing: 6
            Repeater {
                model: notes.toasts
                MouseArea {
                    id: toast
                    required property var modelData
                    readonly property var n: modelData.n
                    Layout.fillWidth: true
                    implicitHeight: body.implicitHeight + 20
                    acceptedButtons: Qt.LeftButton | Qt.RightButton
                    cursorShape: Qt.PointingHandCursor
                    onClicked: m => {
                        if (m.button === Qt.LeftButton) {
                            const act = toast.n.actions.find(a => a.identifier === "default") ?? toast.n.actions[0]
                            if (act) act.invoke()
                        }
                        toast.n.dismiss()
                    }
                    Rectangle {
                        anchors.fill: parent
                        radius: Theme.round
                        color: Theme.popover
                        border.color: toast.n.urgency === NotificationUrgency.Critical ? "#cd0000" : Theme.fg
                        border.width: 1
                    }
                    ColumnLayout {
                        id: body
                        anchors { left: parent.left; right: parent.right; top: parent.top; margins: 10 }
                        spacing: 2
                        Label { text: toast.n.appName; color: Theme.dim; font.pointSize: 8.5; Layout.fillWidth: true }
                        Label { text: toast.n.summary; font.bold: true; Layout.fillWidth: true; visible: text !== "" }
                        Label {
                            text: toast.n.body; Layout.fillWidth: true; visible: text !== ""
                            maximumLineCount: 4; elide: Text.ElideRight
                        }
                    }
                }
            }
        }
    }

    // the OSD, bottom centre: a level as a bar with its number, a state as its words
    PanelWindow {
        visible: notes.osd !== null
        anchors { bottom: true }
        margins { bottom: 80 }
        exclusiveZone: 0
        implicitWidth: 300
        implicitHeight: 64
        color: "transparent"
        WlrLayershell.layer: WlrLayer.Overlay
        WlrLayershell.namespace: "quickshell-osd"

        Rectangle {
            id: osdBox
            anchors.fill: parent
            radius: Theme.round
            color: Theme.popover
            border.color: Theme.fg
            border.width: 1
            readonly property var level: notes.osd?.hints?.value
            ColumnLayout {
                anchors { fill: parent; margins: 12 }
                spacing: 8
                Label {
                    Layout.fillWidth: true
                    horizontalAlignment: Text.AlignHCenter
                    text: (notes.osd?.summary ?? "") + (notes.osd?.body ? "  " + notes.osd.body : "")
                    font.bold: true
                }
                Rectangle {
                    visible: osdBox.level !== undefined
                    Layout.fillWidth: true
                    implicitHeight: 10
                    radius: 5
                    color: Theme.rule
                    Rectangle {
                        radius: 5
                        width: parent.width * Math.min(1, (osdBox.level ?? 0) / 100)
                        height: parent.height
                        color: Theme.accent
                    }
                }
            }
        }
    }
}
