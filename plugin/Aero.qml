import QtQuick
import Quickshell
import Quickshell.Io
import Quickshell.Wayland
import qs.Commons

// Aero-flip badges for the minimized-window preview.
//
// The companion Hyprland config (see ../hypr/aero-bindings.lua) shrinks
// windows on the special:minimized workspace into small cards; this service
// floats a numbered chip on the top-left corner of every card while that
// workspace is visible. Numbers match the omarchy-minimized-restore script
// (oldest window = 1), which the number keys of the "minimized" submap run.
//
// Windows are created through Variants — a plain Repeater cannot parent a
// PanelWindow and fails silently.

Item {
  id: root

  property string badgesJson: "[]"
  property var badges: []

  function refresh() {
    if (!pollProcess.running) pollProcess.running = true
  }

  Timer {
    interval: 450
    running: true
    repeat: true
    triggeredOnStart: true
    onTriggered: root.refresh()
  }

  Process {
    id: pollProcess
    running: false
    command: ["omarchy-minimized-badges"]

    stdout: StdioCollector {
      waitForEnd: true
      onStreamFinished: {
        // Do not shadow `text`: a local `var text` would be hoisted over
        // the collector property and always read as undefined.
        var raw = String(text || "").trim()
        // Same JSON, same badges: keep the windows alive instead of tearing
        // them down and recreating them every poll.
        if (raw === root.badgesJson) return
        root.badgesJson = raw
        try {
          var parsed = JSON.parse(raw || "[]")
          root.badges = Array.isArray(parsed) ? parsed : []
        } catch (e) {
          root.badges = []
        }
      }
    }

    stderr: StdioCollector {}
  }

  Variants {
    model: root.badges

    PanelWindow {
      id: badge

      required property var modelData

      // Absolute position on the monitor: top-left anchoring with margins
      // lands the chip inside the card's top-left corner.
      anchors {
        top: true
        left: true
      }
      margins {
        left: badge.modelData.x + 10
        top: badge.modelData.y + 10
      }
      width: row.implicitWidth + Style.spacing.xl
      height: Math.max(Style.space(28), Style.font.title + Style.spacing.controlPaddingY * 2)
      color: "transparent"
      visible: true

      WlrLayershell.namespace: "aero-minimize-badges"
      WlrLayershell.layer: WlrLayer.Overlay
      WlrLayershell.keyboardFocus: WlrKeyboardFocus.None
      exclusionMode: ExclusionMode.Ignore

      Rectangle {
        id: chip
        anchors.fill: parent
        radius: Style.cornerRadius
        color: Color.accent
        border.width: 1
        border.color: Color.background

        Row {
          id: row
          anchors.centerIn: parent
          spacing: Style.spacing.md

          Text {
            text: String(badge.modelData.index)
            color: Color.background
            font.family: Style.font.menuFamily
            font.pixelSize: Style.font.title
            font.bold: true
          }

          Text {
            property real maxTitleWidth: Style.space(320)
            width: Math.min(implicitWidth, maxTitleWidth)
            text: String(badge.modelData.title || "")
            color: Color.background
            font.family: Style.font.menuFamily
            font.pixelSize: Style.font.body
            elide: Text.ElideRight
          }
        }

        MouseArea {
          anchors.fill: parent
          cursorShape: Qt.PointingHandCursor
          onClicked: Quickshell.execDetached(["omarchy-minimized-restore", String(badge.modelData.index)])
        }
      }
    }
  }
}
