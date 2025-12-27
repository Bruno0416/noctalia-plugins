import QtQuick
import QtQuick.Layouts
import QtQuick.Controls
import QtQuick.Controls.Basic
import QtQuick.Effects

import Quickshell.Services.Mpris
import Quickshell.Widgets
import Quickshell.Io

import qs.Commons
import qs.Widgets

import qs.Widgets.AudioSpectrum
import qs.Services.Media

Item {
  id: root
  anchors.fill: parent

  // Plugin API (injected by PluginPanelSlot)
  property var pluginApi: null
  readonly property var ps: (pluginApi && pluginApi.pluginSettings) ? pluginApi.pluginSettings : ({})

  // SmartPanel properties (required for panel behavior)
  readonly property var geometryPlaceholder: panelContainer
  readonly property bool allowAttach: true

  // Preferred dimensions
  property real contentPreferredWidth: 600 * Style.uiScaleRatio
  property real contentPreferredHeight: 160 * Style.uiScaleRatio

  // Spotify state (for metadata/art + isPlaying)
  property var player: null
  property string currentArtist: ""
  property string currentTitle: ""
  property int currentState: MprisPlaybackState.Stopped
  property bool isPlaying: currentState === MprisPlaybackState.Playing

  Component.onCompleted: updatePlayer()

  Connections {
    target: Mpris.players
    function onValuesChanged() { root.updatePlayer() }
  }

  Connections {
    target: root.player
    function onMetadataChanged() { root.updateMetadata() }
    function onPlaybackStateChanged() { root.currentState = root.player.playbackState }
  }

  function updateMetadata() {
    if (!player || !player.metadata) return
    let meta = player.metadata

    let artist = meta["xesam:artist"]
    if (Array.isArray(artist)) currentArtist = artist.join(", ")
    else if (typeof artist === "string") currentArtist = artist
    else currentArtist = artist ? String(artist) : ""

    currentTitle = meta["xesam:title"] || ""
  }

  function updatePlayer() {
    player = null
    if (!Mpris.players.values) return

    for (let i = 0; i < Mpris.players.values.length; i++) {
      let p = Mpris.players.values[i]
      if (p.identity === "Spotify" || (p.identity && p.identity.toLowerCase().includes("spotify"))) {
        player = p
        currentState = player.playbackState
        updateMetadata()
        break
      }
    }
  }

  function closeThisPanel() {
    if (!pluginApi || !pluginApi.screens || pluginApi.screens.length === 0) return
    pluginApi.closePanel(pluginApi.screens[0])
  }

  function formatTime(microseconds) {
    if (!microseconds || microseconds <= 0) return "0:00"
    let totalSeconds = Math.floor(microseconds / 1000000)
    let minutes = Math.floor(totalSeconds / 60)
    let seconds = totalSeconds % 60
    return minutes + ":" + (seconds < 10 ? "0" : "") + seconds
  }

  // --------------------------
  // Cava (Visualizer)
  // --------------------------
  readonly property bool showVisualizer: true
  readonly property string visualizerType: (ps.panelVisualizer !== undefined && String(ps.panelVisualizer) !== "") ? String(ps.panelVisualizer): "linear" // linear | mirrored | wave | none

  readonly property string cavaComponentId: "panel:spotify:" +
    (pluginApi && pluginApi.screens && pluginApi.screens[0] ? pluginApi.screens[0].name : "noscreen")

  readonly property bool needsCava: showVisualizer && visualizerType !== "" && visualizerType !== "none"

  function syncCava() {
    if (typeof CavaService === "undefined") return;
    if (needsCava) CavaService.registerComponent(cavaComponentId);
    else CavaService.unregisterComponent(cavaComponentId);
  }

  onNeedsCavaChanged: syncCava()
  onVisibleChanged: syncCava()

  
  Component.onDestruction: {
    if (typeof CavaService === "undefined") return;
    CavaService.unregisterComponent(cavaComponentId);
  }

  readonly property var cavaValues: {
    if (typeof CavaService === "undefined" || CavaService.values === undefined || CavaService.values === null)
      return [];

    var v = CavaService.values;
    if (Array.isArray(v)) return v;
    if (v && v[cavaComponentId] && Array.isArray(v[cavaComponentId])) return v[cavaComponentId];
    return [];
  }

  // --------------------------
  // SmartPanel geometry placeholder
  // --------------------------
  Item {
    id: panelContainer
    width: root.contentPreferredWidth
    height: root.contentPreferredHeight
    anchors.centerIn: parent
  }

  ClippingRectangle {
    id: visualCard
    anchors.fill: panelContainer
    radius: 20 * Style.uiScaleRatio
    color: "transparent"
    border.color: Color.mOutline
    border.width: Style.borderS

    

    // Visualizer behind content
    Item {
      id: cavaLayer
      anchors.fill: parent
      clip: true
      z: 0

      Loader {
        anchors.fill: parent
        active: needsCava && root.isPlaying
        visible: active
        opacity: root.isPlaying ? 0.35 : 0.0

        sourceComponent: {
          if (!needsCava) return null
          if (visualizerType === "linear") return linearSpectrum
          if (visualizerType === "mirrored") return mirroredSpectrum
          if (visualizerType === "wave") return waveSpectrum
          return null
        }
      }
    }



    Item {
      id: innerContent
      anchors.fill: parent
      opacity: 1
      z: 1

      WrapperItem {
        margin: Style.marginM

        Row {
          id: mainRow
          anchors.verticalCenter: parent.verticalCenter
          anchors.horizontalCenter: parent.horizontalCenter
          spacing: 10

          // 1. Album Image
          ClippingRectangle {
            width: panelContainer.height - Style.marginM*2
            height: panelContainer.height - Style.marginM*2
            radius: (20 - Style.marginM) * Style.uiScaleRatio
            color: Color.mOutline
            clip: true

            Image {
              anchors.fill: parent
              source: root.player && root.player.metadata ? (root.player.metadata["mpris:artUrl"] || "") : ""
              fillMode: Image.PreserveAspectCrop
            }
          }

          // 2. Text + Controls
          Column {
            anchors.verticalCenter: parent.verticalCenter
            spacing: 2

            NText {
              text: root.currentTitle
              color: Color.mOnSurface
              pointSize: Style.fontSizeL
              font.weight: Style.fontWeightBold
              width: panelContainer.width - panelContainer.height - 20
              elide: Text.ElideRight
            }

            NText {
              text: root.currentArtist
              color: Color.mOnSurfaceVariant
              pointSize: Style.fontSizeS
              elide: Text.ElideRight
            }

            Column {
              id: playerController
              width: parent.width
              spacing: 2

              property real trackLength: (root.player && root.player.metadata && root.player.metadata["mpris:length"])
                                        ? root.player.metadata["mpris:length"] : 1
              property bool isSeeking: false

              property bool isShuffle: false
              property string loopStatus: "None"
              property real volumeLevel: 1.0
              property bool volumeLock: false

              // ---- Readers (playerctl) ----
              Process {
                id: shuffleReader
                command: ["playerctl", "-p", "spotify", "shuffle"]
                stdout: StdioCollector {
                  onStreamFinished: playerController.isShuffle = (text.trim() === "On")
                }
              }

              Process {
                id: loopReader
                command: ["playerctl", "-p", "spotify", "loop"]
                stdout: StdioCollector {
                  onStreamFinished: playerController.loopStatus = text.trim()
                }
              }

              Process {
                id: volumeReader
                command: ["playerctl", "-p", "spotify", "volume"]
                stdout: StdioCollector {
                  onStreamFinished: {
                    var safeText = text.trim().replace(',', '.')
                    var vol = parseFloat(safeText)
                    if (!isNaN(vol) && !playerController.volumeLock) {
                      playerController.volumeLevel = vol
                    }
                  }
                }
              }

              Process {
                id: positionReader
                command: ["playerctl", "-p", "spotify", "position"]
                stdout: StdioCollector {
                  onStreamFinished: {
                    var secs = parseFloat(text.trim())
                    if (!isNaN(secs) && !playerController.isSeeking && !musicSlider.pressed) {
                      musicSlider.value = secs * 1000000
                    }
                  }
                }
              }

              Timer {
                interval: 500
                repeat: true
                running: root.visible && root.player
                onTriggered: {
                  positionReader.running = false; positionReader.running = true
                  shuffleReader.running = false;  shuffleReader.running = true
                  loopReader.running = false;     loopReader.running = true
                  volumeReader.running = false;   volumeReader.running = true
                }
              }

              // ---- Commands ----
              Process { id: cmdShuffle; command: ["playerctl", "-p", "spotify", "shuffle", "Toggle"] }
              Process { id: cmdLoop;    command: ["playerctl", "-p", "spotify", "loop", "None"] }
              Process { id: cmdVol;     command: ["playerctl", "-p", "spotify", "volume", (volSlider.value).toString()] }

              Process { id: cmdPrev; command: ["playerctl", "-p", "spotify", "previous"] }
              Process { id: cmdPlay; command: ["playerctl", "-p", "spotify", "play-pause"] }
              Process { id: cmdNext; command: ["playerctl", "-p", "spotify", "next"] }

              Process {
                id: seekProcess
                command: ["playerctl", "-p", "spotify", "position", (musicSlider.value / 1000000).toString()]
              }

              // ---- Timeline ----
              NSlider {
                id: musicSlider
                height: 20
                width: parent.width
                from: 0
                to: playerController.trackLength
                heightRatio: 0.45

                onPressedChanged: {
                  if (pressed) {
                    playerController.isSeeking = true
                  } else {
                    playerController.isSeeking = false
                    seekProcess.running = false
                    seekProcess.running = true
                  }
                }
              }

              Item {
                width: parent.width
                height: 15

                NText {
                  anchors.left: parent.left
                  text: root.formatTime(musicSlider.value)
                  color: Color.mOnSurfaceVariant
                  pointSize: Style.fontSizeXS
                }

                NText {
                  anchors.right: parent.right
                  text: root.formatTime(playerController.trackLength)
                  color: Color.mOnSurfaceVariant
                  pointSize: Style.fontSizeXS
                }
              }

              // ---- Buttons row  ----
              Row {
                anchors.horizontalCenter: parent.horizontalCenter
                spacing: Style.marginS
                topPadding: Style.marginXS

                Rectangle { width: Style.marginL * 4; height: 1; color: "transparent" }

                NButton {
                  icon: "arrows-shuffle"
                  tooltipText: "Shuffle"
                  outlined: false
                  backgroundColor: playerController.isShuffle ? Color.mPrimary : "transparent"
                  textColor: playerController.isShuffle ? Color.mOnPrimary : Color.mPrimary
                  hoverColor: Qt.alpha(Color.mHover, playerController.isShuffle ? 1 : 0.3)
                  onClicked: { cmdShuffle.running = false; cmdShuffle.running = true }
                }
                

                NButton {
                  icon: "media-prev"
                  tooltipText: "Previous"
                  outlined: false
                  backgroundColor: "transparent"
                  textColor: Color.mPrimary
                  hoverColor: Qt.alpha(Color.mHover, 0.3)
                  onClicked: { cmdPrev.running = false; cmdPrev.running = true }
                }

                NButton {
                  icon: root.isPlaying ? "media-pause" : "media-play"
                  tooltipText: "Play/Pause"
                  outlined: false
                  backgroundColor: Color.mPrimary
                  textColor: Color.mOnPrimary
                  hoverColor: Color.mHover
                  buttonRadius: 999
                  onClicked: { cmdPlay.running = false; cmdPlay.running = true }
                }

                NButton {
                  icon: "media-next"
                  tooltipText: "Next"
                  outlined: false
                  backgroundColor: "transparent"
                  textColor: Color.mPrimary
                  hoverColor: Qt.alpha(Color.mHover, 0.3)
                  onClicked: { cmdNext.running = false; cmdNext.running = true }
                }

                NButton {
                  text: (playerController.loopStatus === "None") ? "" : ""
                  tooltipText: "Loop"
                  outlined: false
                  backgroundColor: (playerController.loopStatus === "Track") ? Color.mPrimary : "transparent"
                  textColor: (playerController.loopStatus === "Track") ? Color.mOnPrimary : Color.mPrimary
                  hoverColor: Qt.alpha(Color.mHover, (playerController.loopStatus === "Track") ? 1 : 0.3)
                  onClicked: {
                    var current = playerController.loopStatus
                    var nextState = "Playlist"
                    if (current === "Playlist") nextState = "Track"
                    else if (current === "Track") nextState = "None"

                    cmdLoop.command = ["playerctl", "-p", "spotify", "loop", nextState]
                    cmdLoop.running = false
                    cmdLoop.running = true
                    playerController.loopStatus = nextState
                  }
                }

                Rectangle { width: Style.marginL ; height: 1; color: "transparent" }

                Item {
                  id: volBox
                  anchors.verticalCenter: parent.verticalCenter
                  implicitHeight: Math.max(volIcon.implicitHeight, volSlider.implicitHeight)
                  implicitWidth: volIcon.implicitWidth + Style.marginXS + volSlider.width

                  NIcon {
                    id: volIcon
                    anchors.left: parent.left
                    anchors.verticalCenter: parent.verticalCenter
                    icon: volSlider.value === 0 ? "volume-off"
                          : (volSlider.value < 0.5 ? "volume-2" : "volume")
                    pointSize: Style.fontSizeL
                    color: Color.mOnSurfaceVariant
                  }

                  NSlider {
                    id: volSlider
                    anchors.left: volIcon.right
                    anchors.leftMargin: Style.marginXS
                    anchors.verticalCenter: parent.verticalCenter
                    width: 80
                    height: 10
                    from: 0.0
                    to: 1.0
                    heightRatio: 0.3

                    value: (!pressed) ? playerController.volumeLevel : value
                    onPressedChanged: {
                      if (pressed) playerController.volumeLock = true
                      else {
                        cmdVol.running = false
                        cmdVol.running = true
                        playerController.volumeLock = false
                      }
                    }
                    onMoved: playerController.volumeLevel = value
                  }
                }
              }
            }
          }
        }
      }
    }
  }

  // --------------------------
  // Visualizer components
  // --------------------------
  Component {
    id: linearSpectrum
    NLinearSpectrum {
      width: visualCard.width - Style.marginS
      height: 20
      values: root.isPlaying ? root.cavaValues : []
      fillColor: Color.mPrimary
      opacity: 0.4
    }
  }

  Component {
    id: mirroredSpectrum
    NMirroredSpectrum {
      width: visualCard.width - Style.marginS
      height: visualCard.height - Style.marginS
      values: root.isPlaying ? root.cavaValues : []
      fillColor: Color.mPrimary
      opacity: 0.4
    }
  }

  Component {
    id: waveSpectrum
    NWaveSpectrum {
      width: visualCard.width - Style.marginS
      height: visualCard.height - Style.marginS
      values: root.isPlaying ? root.cavaValues : []
      fillColor: Color.mPrimary
      opacity: 0.4
    }
  }
}
