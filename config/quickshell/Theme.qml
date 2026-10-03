// GNOME's dark look (libadwaita), shared by the bar and its panels
pragma Singleton
import QtQuick
import Quickshell

Singleton {
    readonly property color accent: "#3584e4"
    readonly property color fg: "#ffffff"
    readonly property color dim: Qt.rgba(1, 1, 1, 0.55)
    readonly property color popover: "#2e2e32"
    readonly property color card: Qt.rgba(1, 1, 1, 0.08)
    readonly property color hover: Qt.rgba(1, 1, 1, 0.14)
    readonly property color pill: Qt.rgba(1, 1, 1, 0.10)
    readonly property string font: "Noto Sans"
    readonly property int quick: 100   // ms, every motion
}
