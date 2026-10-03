// Notifications under Hyprland, in the bar's look, Quickshell being the notification server (dunst stays i3's
// and sway's). Toasts at the top right under the bar: the app, the summary, the body; a click runs its default
// action and the buttons under it the others, a right click dismisses it; gone after its timeout (5 s unless
// it says), a critical one stays. What
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

    // the OSD's text and level (a copy: a notification left untracked is gone once its handler returns), and how
    // long it stays
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
                // notify-send -i hands an icon name over as the image, image://icon/NAME
                const icon = n.appIcon || (n.image ?? "").replace(/^image:\/\/icon\//, "")
                notes.osd = { icon: icon, summary: n.summary, body: n.body, level: n.hints?.value }
                osdTimer.interval = n.expireTimeout > 0 ? n.expireTimeout : 1500
                osdTimer.restart()
                return
            }
            n.tracked = true
            n.closed.connect(() => notes.hide(n))
            if (!notes.dnd) notes.show(n)
        }
    }

    // the actions a notification offers beside its default one (a click on it), as buttons; each runs its
    // action and dismisses the notification
    component Actions: Flow {
        id: actions
        property var n
        Layout.fillWidth: true
        Layout.topMargin: 6
        spacing: 6
        visible: (n?.actions ?? []).some(a => a.identifier !== "default")
        Repeater {
            model: (actions.n?.actions ?? []).filter(a => a.identifier !== "default")
            MouseArea {
                id: btn
                required property var modelData
                implicitWidth: btnText.implicitWidth + 20
                implicitHeight: 26
                hoverEnabled: true
                cursorShape: Qt.PointingHandCursor
                onClicked: { btn.modelData.invoke(); actions.n.dismiss() }
                Rectangle {
                    anchors.fill: parent
                    radius: Theme.radius
                    color: btn.containsMouse ? Theme.accent : Theme.pill
                    border.color: Theme.rule
                }
                Text {
                    id: btnText
                    anchors.centerIn: parent
                    text: btn.modelData.text
                    color: btn.containsMouse ? Theme.inverse : Theme.fg
                    font.family: Theme.font
                    font.pointSize: 9.5
                }
            }
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
                        Actions { n: toast.n }
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
            readonly property var level: notes.osd?.level
            RowLayout {
              anchors { fill: parent; margins: 12; leftMargin: 16 }
              spacing: 14
              // what it is about: the speaker, the mic, the backlight, the touchpad...
              Icon {
                  visible: (notes.osd?.icon ?? "") !== ""
                  name: notes.osd?.icon ?? ""
                  implicitSize: 22
              }
              ColumnLayout {
                Layout.fillWidth: true
                spacing: 8
                Label {
                    Layout.fillWidth: true
                    horizontalAlignment: osdBox.level !== undefined ? Text.AlignLeft : Text.AlignHCenter
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
}
