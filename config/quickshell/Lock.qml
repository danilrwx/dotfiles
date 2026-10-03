// The lock screen under Hyprland, in the bar's look: black, the time large in the middle, the date under it, the
// password in a white-ruled box, a wrong one said in red. Through Wayland's session lock (the compositor shows
// nothing else until it lets go) and PAM's swaylock profile (login's auth). Locked by `quickshell ipc call
// lock lock`: $mod+Shift+x, the quick settings' button, swayidle on idle and before sleep (bin/wl-autostart).
import Quickshell
import Quickshell.Services.Pam
import Quickshell.Wayland
import QtQuick
import QtQuick.Layouts

Scope {
    id: lock
    property bool locked: false
    property string error: ""
    function engage() {
        error = ""
        locked = true
    }

    PamContext {
        id: pam
        config: "swaylock"
        property string password
        onPamMessage: if (responseRequired) respond(password)
        onCompleted: result => {
            password = ""
            if (result === PamResult.Success) lock.locked = false
            else lock.error = "Wrong password"
        }
        onError: {
            password = ""
            lock.error = "Could not check the password"
        }
    }
    function unlock(password) {
        if (pam.active || password === "") return
        error = ""
        pam.password = password
        pam.start()
    }

    SystemClock { id: clock; precision: SystemClock.Seconds }

    WlSessionLock {
        locked: lock.locked

        WlSessionLockSurface {
            color: "#000000"

            ColumnLayout {
                anchors.centerIn: parent
                spacing: 14

                Text {
                    Layout.alignment: Qt.AlignHCenter
                    text: Qt.formatDateTime(clock.date, "hh:mm")
                    color: Theme.fg
                    font.family: Theme.font
                    font.pointSize: 64
                }
                Text {
                    Layout.alignment: Qt.AlignHCenter
                    Layout.bottomMargin: 30
                    text: Qt.formatDateTime(clock.date, "dddd, d MMMM")
                    color: Theme.dim
                    font.family: Theme.font
                    font.pointSize: 13
                }
                Rectangle {
                    Layout.alignment: Qt.AlignHCenter
                    implicitWidth: 320
                    implicitHeight: 40
                    radius: Theme.radius
                    color: "#000000"
                    border.color: pam.active ? Theme.dim : Theme.fg
                    border.width: 1
                    TextInput {
                        id: input
                        anchors { fill: parent; leftMargin: 12; rightMargin: 12 }
                        verticalAlignment: TextInput.AlignVCenter
                        horizontalAlignment: TextInput.AlignHCenter
                        echoMode: TextInput.Password
                        passwordCharacter: "■"
                        color: Theme.fg
                        font.family: Theme.font
                        font.pointSize: 13
                        enabled: !pam.active
                        focus: true
                        onAccepted: { lock.unlock(text); text = "" }
                        Component.onCompleted: forceActiveFocus()
                    }
                    Text {
                        anchors.centerIn: parent
                        visible: input.text === "" && !pam.active
                        text: "password"
                        color: "#444444"
                        font.family: Theme.font
                        font.pointSize: 13
                    }
                }
                Text {
                    Layout.alignment: Qt.AlignHCenter
                    text: pam.active ? "…" : lock.error
                    color: pam.active ? Theme.dim : "#cd0000"
                    font.family: Theme.font
                    font.pointSize: 11
                }
            }
        }
    }
}
