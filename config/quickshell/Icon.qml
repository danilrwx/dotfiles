// A symbolic icon of the Adwaita theme, GNOME's own, drawn in the colour given (white by default): the theme
// draws them dark, so the effect takes the dark to the colour
import Quickshell
import Quickshell.Widgets
import QtQuick
import QtQuick.Effects

IconImage {
    property string name
    property color tint: "#ffffff"
    implicitSize: 16
    source: Quickshell.iconPath(name, true)
    layer.enabled: true
    layer.effect: MultiEffect {
        brightness: 1.0
        colorization: 1.0
        colorizationColor: tint
    }
}
