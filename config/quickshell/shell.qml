//@ pragma IconTheme Adwaita
// The bar under Hyprland (config/eww is i3's), the old look (Theme.qml): the workspaces as GNOME's dots at the
// left, the clock in the middle as GNOME has it (a click: the calendar), at the right the keyboard
// layout, the tray (StatusNotifierItem, Discord's menu included) and the status as one block, Wi-Fi, VPN, sound
// and battery in Adwaita's symbolic icons (a click: the quick settings, the wheel: the volume). Sound, battery,
// tray, workspaces and the clock from Quickshell's own services and the layout from Hyprland's event, live;
// the rest from wmd (wmd/), on every change. bin/wl-autostart starts it; linked to ~/.config/quickshell by
// install.
import Quickshell
import Quickshell.Hyprland
import Quickshell.Io
import Quickshell.Services.Pipewire
import Quickshell.Services.SystemTray
import Quickshell.Services.UPower
import Quickshell.Wayland
import Quickshell.Widgets
import QtQuick
import QtQuick.Layouts

ShellRoot {
    id: root

    readonly property string bin: Quickshell.env("HOME") + "/dotfiles/bin/"
    readonly property string fnkeys: bin + "wm-fnkeys"

    // the state from wmd (wmd/, go install): Wi-Fi, Bluetooth, power, brightness, the layout, the sound devices,
    // VLESS, OpenVPN, a JSON line on every change
    readonly property string wmd: Quickshell.env("HOME") + "/go/bin/wmd"
    property var net: ({ wifi: {}, bt: {} })
    Process {
        id: watcher
        command: [root.wmd, "watch"]
        running: true
        stdout: SplitParser { onRead: line => { try { root.net = JSON.parse(line) } catch (e) {} } }
        // back in a second should it ever exit
        onExited: rewatch.start()
    }
    Timer { id: rewatch; interval: 1000; onTriggered: watcher.running = true }
    // after a switch: wmd brings the change itself, so nothing is to be fetched again
    function refresh() {}

    PwObjectTracker { objects: [Pipewire.defaultAudioSink, Pipewire.defaultAudioSource] }
    readonly property var sink: Pipewire.defaultAudioSink?.audio ?? null
    readonly property var source: Pipewire.defaultAudioSource?.audio ?? null
    readonly property var battery: UPower.displayDevice

    SystemClock { id: clock; precision: SystemClock.Minutes }

    // run CMD...: a command, detached
    function run(cmd) { Quickshell.execDetached(cmd) }

    // the icons the status shows, GNOME's names for the state
    function volumeIcon(a) {
        if (!a || a.muted || a.volume === 0) return "audio-volume-muted-symbolic"
        return a.volume < 0.34 ? "audio-volume-low-symbolic" : a.volume < 0.67 ? "audio-volume-medium-symbolic"
                                                                              : "audio-volume-high-symbolic"
    }
    function micIcon(a) {
        if (!a || a.muted || a.volume === 0) return "microphone-sensitivity-muted-symbolic"
        return a.volume < 0.34 ? "microphone-sensitivity-low-symbolic"
             : a.volume < 0.67 ? "microphone-sensitivity-medium-symbolic" : "microphone-sensitivity-high-symbolic"
    }
    function wifiIcon() {
        const w = net.wifi
        if (!w.on) return "network-wireless-disabled-symbolic"
        if (!w.ssid) return "network-wireless-offline-symbolic"
        return "network-wireless-signal-" + ["none", "weak", "ok", "good", "excellent"][w.signal] + "-symbolic"
    }
    // the battery's icon as UPower names it, for every state it knows: charging, plugged in but held (a
    // charge threshold), full, low
    function batteryIcon() { return battery.iconName || "battery-missing-symbolic" }
    readonly property bool plugged: battery.state === UPowerDeviceState.Charging
        || battery.state === UPowerDeviceState.PendingCharge || battery.state === UPowerDeviceState.FullyCharged
    // the keyboard layout, Hyprland's word on every switch, at once, and wmd's besides (at the start)
    property bool ru: false
    onNetChanged: ru = /Russian/.test(net.keymap ?? "")
    Connections {
        target: Hyprland
        function onRawEvent(event) {
            if (event.name === "activelayout") root.ru = /Russian/.test(event.data)
            // a Super combination done (a workspace, a window): Hyprland skips the release bind after
            // another key, so the peek ends here instead
            else if (root.peeking && root.comboEvents.indexOf(event.name) >= 0) root.peeking = false
        }
    }
    // the bar's alpha, bin/theme's ALPHA under dark-wall and 1 under dark, followed as bin/theme rewrites it
    FileView {
        id: alphaFile
        path: Quickshell.env("HOME") + "/.cache/theme/alpha"
        watchChanges: true
        onFileChanged: reload()
    }
    readonly property real alpha: parseFloat(alphaFile.text()) || 1
    // the battery's icon colour: white, turning red from 30% down, all red at 10%; white while plugged in
    readonly property color batteryTint: {
        if (plugged) return Theme.fg
        const t = Math.min(1, Math.max(0, (0.30 - battery.percentage) / 0.20))
        return Qt.rgba(1, 1 - t * 0.89, 1 - t * 0.86, 1)
    }
    // the battery's time as UPower reckons it: "2 h 05 min left", "full in 40 min", "" while it cannot tell
    function duration(s) {
        const h = Math.floor(s / 3600), m = Math.round(s % 3600 / 60)
        return h > 0 ? h + " h " + String(m).padStart(2, "0") + " min" : m + " min"
    }
    readonly property string batteryTime: {
        if (battery.state === UPowerDeviceState.Charging)
            return battery.timeToFull > 0 ? "full in " + duration(battery.timeToFull) : "charging"
        if (battery.state === UPowerDeviceState.FullyCharged) return "full"
        if (battery.state === UPowerDeviceState.PendingCharge) return "not charging"
        return battery.timeToEmpty > 0 ? duration(battery.timeToEmpty) + " left" : ""
    }
    readonly property bool vpn: (net.vless?.how ?? "off") !== "off" || (net.openvpn?.profile ?? "") !== ""

    // the panels, one at a time (QuickSettings.qml, CalendarPopup.qml)
    QuickSettings { id: qs; shell: root }
    CalendarPopup { id: cal; notes: notes; shell: root }
    function panel(which) {
        (which === qs ? cal : qs).open = false
        which.toggle()
    }
    // and from outside: quickshell ipc call panel ctl|calendar (a key, a script)
    IpcHandler {
        target: "panel"
        function ctl(): void { root.panel(qs) }
        // the quick settings with one of their menus unfolded (wifi, bt, night, outs, ...)
        function menu(name: string): void { cal.open = false; qs.open = true; qs.menu = name }
        function calendar(): void { root.panel(cal) }
    }
    // notifications, their history and the OSD (Notifications.qml)
    Notifications { id: notes }

    // the lock screen (Lock.qml): quickshell ipc call lock lock
    Lock { id: lockScreen }
    function lockNow() { lockScreen.engage() }
    IpcHandler {
        target: "lock"
        function lock(): void { root.lockNow() }
    }

    // the launcher in the bar, dmenu's way, over the apps ($mod+d: quickshell ipc call launcher toggle) or the
    // clipboard's history ($mod+Shift+v: quickshell ipc call launcher clipboard); "" while closed
    property string mode: ""
    readonly property bool launching: mode !== ""
    function close() { mode = "" }
    IpcHandler {
        target: "launcher"
        function toggle(): void { root.mode = root.mode === "apps" ? "" : "apps" }
        function clipboard(): void {
            if (root.mode === "clip") { root.mode = ""; return }
            clipList.running = true
            root.mode = "clip"
        }
    }
    // the clipboard's history, newest first, from cliphist (wl-paste stores into it, bin/wl-autostart): its
    // lines "ID<tab>PREVIEW", as cliphist decode and delete take them back
    property var clips: []
    Process {
        id: clipList
        command: ["cliphist", "list"]
        stdout: StdioCollector {
            onStreamFinished: root.clips = text.split("\n").filter(l => l !== "")
                .map(l => ({ line: l, name: l.replace(/^[0-9]+\t/, "").replace(/\s+/g, " ").slice(0, 60) }))
        }
    }
    function clipHits(query) {
        const q = query.toLowerCase()
        return clips.filter(c => c.name.toLowerCase().includes(q))
    }
    // a history entry back on the clipboard, or out of the history
    function copyClip(c) {
        close()
        if (c) run(["sh", "-c", 'printf "%s" "$1" | cliphist decode | wl-copy', "sh", c.line])
    }
    function deleteClip(c) {
        if (!c) return
        run(["sh", "-c", 'printf "%s" "$1" | cliphist delete', "sh", c.line])
        clips = clips.filter(x => x !== c)
    }
    // the apps an app menu shows, by name, a name starting with the query first, then one holding it
    function apps(query) {
        const q = query.toLowerCase()
        const all = DesktopEntries.applications.values.filter(e => !e.noDisplay)
        const hit = all.filter(e => e.name.toLowerCase().includes(q))
        const starts = hit.filter(e => e.name.toLowerCase().startsWith(q))
        const rest = hit.filter(e => !e.name.toLowerCase().startsWith(q))
        const byName = (a, b) => a.name.localeCompare(b.name)
        return starts.sort(byName).concat(rest.sort(byName))
    }
    // launch an app, a terminal one in alacritty; or, with none picked, what was typed as a command
    function launch(entry, typed) {
        close()
        if (entry) {
            if (entry.runInTerminal) run(["alacritty", "-e"].concat(entry.command))
            else entry.execute()
        } else if (typed.trim() !== "") {
            run(["sh", "-c", typed])
        }
    }

    // the bar's mode, i3's bar mode toggle: docked, or hidden and shown over the windows while Super is held.
    // quickshell ipc call bar toggle ($mod+b), peek and unpeek (Super down and up, config/hypr)
    property bool docked: true
    property bool peeking: false
    readonly property var comboEvents: ["workspacev2", "focusedmonv2", "activewindowv2", "openwindow", "closewindow",
        "movewindowv2", "changefloatingmode", "fullscreen"]
    IpcHandler {
        target: "bar"
        function toggle(): void { root.docked = !root.docked }
        function peek(): void { root.peeking = true }
        function unpeek(): void { root.peeking = false }
        function state(): string { return (root.docked ? "docked" : "hidden") + (root.peeking ? " peeking" : "") }
    }

    // a pill of the bar: rounded, lit under the pointer, what it holds in a row; clicks and the wheel given
    component Pill: MouseArea {
        id: pill
        default property alias content: row.data
        property bool lit: false
        // the space either side of what it holds
        property int pad: 10
        signal wheelUp
        signal wheelDown
        implicitWidth: row.implicitWidth + 2 * pad
        implicitHeight: 25
        hoverEnabled: true
        cursorShape: Qt.PointingHandCursor
        acceptedButtons: Qt.LeftButton | Qt.RightButton
        onWheel: w => w.angleDelta.y > 0 ? wheelUp() : wheelDown()
        Rectangle {
            anchors.fill: parent
            anchors.margins: 2
            radius: Theme.radius
            color: pill.lit || pill.containsMouse ? Theme.hover : "transparent"
            Behavior on color { ColorAnimation { duration: Theme.quick } }
        }
        RowLayout { id: row; anchors.centerIn: parent; spacing: 7 }
    }
    component BarText: Text {
        color: Theme.dim
        font.family: Theme.font
        font.pointSize: 11
    }

    Variants {
        model: Quickshell.screens

        PanelWindow {
            id: bar
            required property var modelData
            screen: modelData
            visible: root.docked || root.peeking || root.launching
            // the keyboard while the launcher is open, and only then
            WlrLayershell.keyboardFocus: root.launching ? WlrKeyboardFocus.Exclusive : WlrKeyboardFocus.None
            anchors { top: true; left: true; right: true }
            implicitHeight: 25
            // docked it takes its strip from the windows; hidden it comes over them
            exclusiveZone: root.docked ? implicitHeight : 0
            WlrLayershell.layer: root.docked ? WlrLayer.Top : WlrLayer.Overlay
            // black, see-through over a wallpaper (bin/theme's dark-wall): drawn by a rectangle on a clear window,
            // as a see-through window colour builds up darker frame by frame where the content changes
            color: "transparent"
            Rectangle {
                anchors.fill: parent
                color: Qt.rgba(0, 0, 0, root.alpha)
            }

            // the workspaces as GNOME's dots: a dot each, the focused one a longer pill, an urgent one green, the
            // one under the pointer white; a click to go there, the wheel through them
            Row {
                id: workspaces
                anchors { left: parent.left; leftMargin: 12; verticalCenter: parent.verticalCenter }
                spacing: 6
                Repeater {
                    model: Hyprland.workspaces.values.filter(w => w.id > 0).sort((a, b) => a.id - b.id)
                    MouseArea {
                        id: ws
                        required property var modelData
                        readonly property bool focused: modelData.id === Hyprland.focusedWorkspace?.id
                        width: focused ? 28 : 8
                        height: 8
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onClicked: Hyprland.dispatch("workspace " + modelData.id)
                        onWheel: w => Hyprland.dispatch(w.angleDelta.y > 0 ? "workspace e-1" : "workspace e+1")
                        Behavior on width { NumberAnimation { duration: Theme.quick } }
                        Rectangle {
                            anchors.fill: parent
                            radius: height / 2
                            color: ws.modelData.urgent ? Theme.urgent : ws.focused || ws.containsMouse ? Theme.fg : "#666666"
                        }
                    }
                }
            }

            // the launcher, dmenu in the bar: from past the workspaces to the status, what is typed, then the
            // apps (or clipboard entries) it matches in a row, the picked one inverted. Left, Right and Tab
            // move, Enter launches (or copies), Delete drops a clipboard entry, Escape closes
            Item {
                id: launcher
                visible: root.launching
                anchors { left: workspaces.right; leftMargin: 12; right: status.left; rightMargin: 12; top: parent.top; bottom: parent.bottom }
                readonly property bool clip: root.mode === "clip"
                property var hits: clip ? root.clipHits(query.text) : root.apps(query.text)
                function pick(i, typed) {
                    if (clip) root.copyClip(hits[i])
                    else root.launch(hits[i], typed)
                }
                property int picked: 0
                onVisibleChanged: if (visible) { query.text = ""; picked = 0; query.forceActiveFocus() }
                // a switch between apps and the clipboard while open starts afresh too
                onClipChanged: { query.text = ""; picked = 0 }
                Text {
                    id: prompt
                    anchors { left: parent.left; verticalCenter: parent.verticalCenter }
                    text: launcher.clip ? "clip" : "run"
                    color: Theme.dim
                    font.family: Theme.font
                    font.pointSize: 11
                }
                TextInput {
                    id: query
                    anchors { left: prompt.right; leftMargin: 10; verticalCenter: parent.verticalCenter }
                    width: 220
                    color: Theme.fg
                    font.family: Theme.font
                    font.pointSize: 11
                    onTextChanged: launcher.picked = 0
                    Keys.onPressed: e => {
                        const n = launcher.hits.length
                        if (e.key === Qt.Key_Escape) { root.close() }
                        else if (e.key === Qt.Key_Return || e.key === Qt.Key_Enter) { launcher.pick(launcher.picked, text) }
                        else if (e.key === Qt.Key_Delete && launcher.clip) { root.deleteClip(launcher.hits[launcher.picked]) }
                        else if ((e.key === Qt.Key_Right || e.key === Qt.Key_Tab) && n > 0) { launcher.picked = (launcher.picked + 1) % n }
                        else if ((e.key === Qt.Key_Left || e.key === Qt.Key_Backtab) && n > 0) { launcher.picked = (launcher.picked - 1 + n) % n }
                        else return
                        e.accepted = true
                    }
                }
                ListView {
                    id: list
                    anchors { left: query.right; leftMargin: 10; right: parent.right; top: parent.top; bottom: parent.bottom }
                    orientation: ListView.Horizontal
                    clip: true
                    model: launcher.hits
                    currentIndex: launcher.picked
                    highlightMoveDuration: 0
                    boundsBehavior: Flickable.StopAtBounds
                    delegate: MouseArea {
                        id: hit
                        required property var modelData
                        required property int index
                        readonly property bool picked: index === launcher.picked
                        width: name.implicitWidth + 20
                        height: list.height
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onClicked: launcher.pick(index, "")
                        Rectangle { anchors.fill: parent; color: hit.picked ? Theme.accent : hit.containsMouse ? Theme.hover : "transparent" }
                        Text {
                            id: name
                            anchors.centerIn: parent
                            text: hit.modelData.name
                            color: hit.picked ? Theme.inverse : Theme.fg
                            font.family: Theme.font
                            font.pointSize: 11
                        }
                    }
                }
            }

            // the clock in the middle, GNOME's "Sat Oct 3  13:31"; gone while the launcher takes the bar
            Pill {
                visible: !root.launching
                anchors.centerIn: parent
                lit: cal.open
                onClicked: root.panel(cal)
                // the weather first, where wmd location has put the machine
                Icon { visible: root.net.weather ? true : false; name: root.net.weather?.icon ?? "" }
                BarText { visible: root.net.weather ? true : false; text: (root.net.weather?.temp ?? "") + "°"; color: Theme.fg }
                BarText { text: Qt.formatDateTime(clock.date, "ddd MMM d  hh:mm"); color: Theme.fg }
            }

            RowLayout {
                id: status
                anchors { right: parent.right; rightMargin: 6; verticalCenter: parent.verticalCenter }
                spacing: 2

                Pill {
                    BarText { text: root.ru ? "RU" : "US"; color: Theme.fg }
                }

                // the tray: a click activates, a right click opens the item's menu
                Repeater {
                    model: SystemTray.items
                    Pill {
                        id: item
                        required property SystemTrayItem modelData
                        pad: 5
                        onClicked: m => {
                            if (m.button === Qt.RightButton || modelData.onlyMenu) {
                                if (modelData.hasMenu) menu.open = !menu.open
                            } else {
                                modelData.activate()
                            }
                        }
                        // the item's menu in the bar's look (TrayMenu.qml), not Qt's
                        TrayMenu {
                            id: menu
                            handle: item.modelData.menu
                            anchorItem: item
                            grabWith: [bar]
                        }
                        IconImage { implicitSize: 15; source: item.modelData.icon }
                    }
                }

                // the status: Wi-Fi, VPN, Bluetooth while a device is on, sound, the mic while muted, battery
                Pill {
                    lit: qs.open
                    onClicked: root.panel(qs)
                    onWheelUp: root.run([root.fnkeys, "vol-up"])
                    onWheelDown: root.run([root.fnkeys, "vol-down"])
                    Icon { name: root.wifiIcon() }
                    Icon { visible: root.vpn; name: "network-vpn-symbolic" }
                    Icon { visible: (root.net.bt.connected ?? "") !== ""; name: "bluetooth-active-symbolic" }
                    Icon { name: root.volumeIcon(root.sink) }
                    Icon { visible: root.source?.muted ?? false; name: "microphone-disabled-symbolic" }
                    Icon {
                        id: batIcon
                        visible: root.battery.isLaptopBattery
                        name: root.batteryIcon()
                        tint: root.batteryTint
                        HoverHandler { id: batHover }
                        // under the pointer: the percentage and the time left, in a tip under the icon
                        PopupWindow {
                            visible: batHover.hovered
                            anchor.item: batIcon
                            anchor.edges: Edges.Bottom
                            anchor.gravity: Edges.Bottom
                            anchor.margins.top: 8
                            implicitWidth: tip.implicitWidth + 20
                            implicitHeight: tip.implicitHeight + 12
                            color: "transparent"
                            Rectangle {
                                anchors.fill: parent
                                radius: Theme.radius
                                color: Theme.popover
                                border.color: Theme.fg
                                Text {
                                    id: tip
                                    anchors.centerIn: parent
                                    text: Math.round(root.battery.percentage * 100) + "%"
                                        + (root.batteryTime ? ", " + root.batteryTime : "")
                                    color: Theme.fg
                                    font.family: Theme.font
                                    font.pointSize: 10
                                }
                            }
                        }
                    }
                }

            }
        }
    }
}
