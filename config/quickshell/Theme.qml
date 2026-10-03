// The old look of the bar and its panels (i3bar's, rofi's): black, white for what is on or picked, gray for
// the rest, green only for urgent; Iosevka, square corners, 1px rules. What is on is inverted, black on white
pragma Singleton
import QtQuick
import Quickshell

Singleton {
    readonly property color accent: "#ffffff"     // what is on, picked, filled
    readonly property color inverse: "#000000"   // text and icons on it
    readonly property color urgent: "#00cd00"
    readonly property color fg: "#ffffff"
    readonly property color dim: "#888888"
    readonly property color popover: "#000000"
    readonly property color card: "#0d0d0d"
    readonly property color rule: "#333333"       // borders and tracks
    readonly property color hover: "#262626"
    readonly property color pill: "#1a1a1a"
    readonly property string font: "Iosevka"
    readonly property int quick: 100   // ms, every motion
}
