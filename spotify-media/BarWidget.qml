import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import Quickshell

import Quickshell.Services.Mpris 
import qs.Commons 
import qs.Services.UI 
import qs.Widgets 
import qs.Widgets.AudioSpectrum 
import qs.Modules.Bar.Extras 
import qs.Services.Media


Item {
  id: root

  
  property var pluginApi
  property var screen
  property string widgetId: ""
  property string section: ""
  property int sectionWidgetIndex: -1
  property int sectionWidgetsCount: 0

  
  property real scaling: 1.0

  // Plugin settings
  readonly property var ps: (pluginApi && pluginApi.pluginSettings) ? pluginApi.pluginSettings : ({})
  readonly property real effectiveScaling: (ps.scaling !== undefined) ? Number(ps.scaling) : scaling

  // Bar orientation
  readonly property bool isVertical: Settings.data.bar.position === "left" || Settings.data.bar.position === "right"

  // Settings 
  readonly property string hideMode: (ps.hideMode !== undefined) ? String(ps.hideMode) : "hidden" // hidden | idle | transparent
  readonly property bool hideWhenIdle: (ps.hideWhenIdle !== undefined) ? (ps.hideWhenIdle === true) : false
  readonly property bool showAlbumArt: (ps.showAlbumArt !== undefined) ? (ps.showAlbumArt === true) : true
  readonly property bool showArtistFirst: (ps.showArtistFirst !== undefined) ? (ps.showArtistFirst === true) : false
  readonly property bool showVisualizer: true
  readonly property string visualizerType: "wave" //(ps.visualizerType !== undefined && String(ps.visualizerType) !== "") ? String(ps.visualizerType): "linear" // linear | mirrored | wave | none
  readonly property string scrollingMode: (ps.scrollingMode !== undefined) ? String(ps.scrollingMode) : "hover" // hover | always | never
  readonly property bool showProgressRing: (ps.showProgressRing !== undefined) ? (ps.showProgressRing === true) : true
  readonly property bool useFixedWidth: (ps.useFixedWidth !== undefined) ? (ps.useFixedWidth === true) : false
  readonly property real maxWidth: (ps.maxWidth !== undefined)
                                   ? Number(ps.maxWidth)
                                   : (screen && screen.width ? Math.max(240, screen.width * 0.06) : 240)
  readonly property real volumeStep: (ps.volumeStep !== undefined) ? Number(ps.volumeStep) : 0.02

  
  readonly property int iconSize: Math.round(18 * effectiveScaling)
  readonly property int artSize: Math.round(21 * effectiveScaling)
  readonly property int verticalSize: Math.round((Style.baseWidgetSize - 5) * effectiveScaling)

  property var player: null

  function findSpotifyPlayer() {
    if (!Mpris.players || !Mpris.players.values) return null;
    for (var i = 0; i < Mpris.players.values.length; i++) {
      var p = Mpris.players.values[i];
      if (!p) continue;

      var id = p.identity ? String(p.identity) : "";
      var low = id.toLowerCase();
      if (id === "Spotify" || low.indexOf("spotify") !== -1)
        return p;
    }
    return null;
  }

  function updatePlayer() {
    root.player = findSpotifyPlayer();
  }

  
  Component.onCompleted: {
    updatePlayer();
    syncCava();
  }

  Connections {
    target: Mpris.players
    function onValuesChanged() { root.updatePlayer(); }
  }

  readonly property bool hasPlayer: root.player !== null
  readonly property bool isPlaying: hasPlayer ? (root.player.playing === true) : false

  readonly property bool spotifyPlaying: hasPlayer && (
  (player.playbackState !== undefined && player.playbackState === MprisPlaybackState.Playing) ||
  (player.playing === true)
    )   


  readonly property bool shouldHideIdle: ((hideMode === "idle") || (hideWhenIdle === true)) && (isPlaying === false)
  readonly property bool shouldHideEmpty: (hasPlayer === false) && (hideMode === "hidden")
  readonly property bool isHidden: (shouldHideIdle === true) || (shouldHideEmpty === true)

  readonly property string title: {
    if (!hasPlayer) return "Spotify";

    var a = root.player.trackArtist ? String(root.player.trackArtist) : "";
    var t = root.player.trackTitle ? String(root.player.trackTitle) : "";

    if (showArtistFirst === true) {
      return (a && t) ? (a + " - " + t) : (t || a || "Spotify");
    } else {
      return (a && t) ? (t + " - " + a) : (t || a || "Spotify");
    }
  }


  readonly property string cavaComponentId: "bar:spotify-media:" +
                                           (screen && screen.name ? screen.name : "noscreen") + ":" +
                                           section + ":" + sectionWidgetIndex

  readonly property bool needsCava: (showVisualizer === true)
                                 && (visualizerType !== "")
                                 && (visualizerType !== "none")



  onNeedsCavaChanged: syncCava()

function syncCava() {
  if (needsCava === true) CavaService.registerComponent(cavaComponentId);
  else CavaService.unregisterComponent(cavaComponentId);
}


  readonly property var cavaValues: {
  if (typeof CavaService === "undefined" || CavaService.values === undefined || CavaService.values === null)
    return [];

  var v = CavaService.values;

  
  if (Array.isArray(v)) return v;

  
  if (v && v[cavaComponentId] && Array.isArray(v[cavaComponentId])) return v[cavaComponentId];

  return [];
}


  onIsPlayingChanged: syncCava()
  onIsHiddenChanged: syncCava()
  onVisualizerTypeChanged: syncCava()
  onShowVisualizerChanged: syncCava()

  
  Component.onDestruction: {
    if (typeof CavaService === "undefined") return;
    CavaService.unregisterComponent(cavaComponentId);
  }


  NPopupContextMenu {
    id: contextMenu
    model: {
      var items = [];

      if (hasPlayer && (player.canTogglePlaying === true)) {
        items.push({
          "label": (player.playing === true) ? "Pause" : "Play",
          "action": "play-pause",
          "icon": (player.playing === true) ? "media-pause" : "media-play"
        });
      }
      if (hasPlayer && (player.canGoPrevious === true)) {
        items.push({ "label": "Previous", "action": "previous", "icon": "media-prev" });
      }
      if (hasPlayer && (player.canGoNext === true)) {
        items.push({ "label": "Next", "action": "next", "icon": "media-next" });
      }

      items.push({ "label": "Widget settings", "action": "plugin-settings", "icon": "settings" });
      return items;
    }

    onTriggered: function(action) {
      var popupWindow = PanelService.getPopupMenuWindow(screen);
      if (popupWindow) popupWindow.close();

      if (action === "play-pause" && hasPlayer && (player.canTogglePlaying === true)) player.togglePlaying();
      else if (action === "previous" && hasPlayer && (player.canGoPrevious === true)) player.previous();
      else if (action === "next" && hasPlayer && (player.canGoNext === true)) player.next();
      else if (action === "plugin-settings" && pluginApi) pluginApi.openPanel(screen);
    }
  }

  readonly property real contentWidth: {
    if (useFixedWidth === true) return maxWidth;

    var iconWidth = 0;
    if (!hasPlayer || ((showAlbumArt === false) && (showProgressRing === false))) iconWidth = iconSize;
    else iconWidth = artSize;

    var textWidth = 0;
    if (titleMetrics.contentWidth > 0) {
      textWidth = (Style.marginS * effectiveScaling) + titleMetrics.contentWidth + (Style.marginXXS * 2);
    }

    var margins = isVertical ? 0 : (Style.marginS * effectiveScaling * 2);
    var total = iconWidth + textWidth + margins;
    return hasPlayer ? Math.min(total, maxWidth) : total;
  }

  implicitWidth: visible ? (isVertical ? (isHidden ? 0 : verticalSize) : (isHidden ? 0 : contentWidth)) : 0
  implicitHeight: visible ? (isVertical ? (isHidden ? 0 : verticalSize) : Style.capsuleHeight) : 0
  visible: (!shouldHideIdle) && (hideMode !== "hidden" || opacity > 0)
  opacity: isHidden ? 0.0 : ((hideMode === "transparent" && !hasPlayer) ? 0.0 : 1.0)

  Behavior on opacity { NumberAnimation { duration: Style.animationNormal; easing.type: Easing.InOutCubic } }
  Behavior on implicitWidth { NumberAnimation { duration: Style.animationNormal; easing.type: Easing.InOutCubic } }
  Behavior on implicitHeight { NumberAnimation { duration: Style.animationNormal; easing.type: Easing.InOutCubic } }

  
  NText {
    id: titleMetrics
    visible: false
    text: root.title
    applyUiScale: false
    pointSize: Style.fontSizeS * effectiveScaling
    font.weight: Style.fontWeightMedium
  }

  // --------------------------
  // Main container
  // --------------------------
  Rectangle {
    id: container
    anchors.left: parent.left
    anchors.verticalCenter: parent.verticalCenter

    width: isVertical ? (isHidden ? 0 : verticalSize) : (isHidden ? 0 : contentWidth)
    height: isVertical ? (isHidden ? 0 : verticalSize) : Style.capsuleHeight
    radius: Style.radiusM
    color: Style.capsuleColor
    border.color: Style.capsuleBorderColor
    border.width: Style.capsuleBorderWidth

    Behavior on width { NumberAnimation { duration: Style.animationNormal; easing.type: Easing.InOutCubic } }
    Behavior on height { NumberAnimation { duration: Style.animationNormal; easing.type: Easing.InOutCubic } }

    Item {
      anchors.fill: parent
      anchors.leftMargin: isVertical ? 0 : Style.marginS * effectiveScaling
      anchors.rightMargin: isVertical ? 0 : Style.marginS * effectiveScaling
      clip: true

      // Visualizer (Cava)
      Loader {
        anchors.verticalCenter: parent.verticalCenter
        anchors.horizontalCenter: parent.horizontalCenter
        width: parent.width
        height: parent.height
        active: showVisualizer
        visible: showVisualizer
        opacity: spotifyPlaying ? 1.0 : 0.0
        z: 0
        sourceComponent: {
          if (!showVisualizer) return null;
          if (visualizerType === "linear") return linearSpectrum;
          if (visualizerType === "mirrored") return mirroredSpectrum;
          if (visualizerType === "wave") return waveSpectrum;
          return null;
        }
      }

      // Horizontal layout
      RowLayout {
        anchors.fill: parent
        spacing: Style.marginS * effectiveScaling
        visible: !isVertical
        z: 1

        // Prev
        Item {
          Layout.preferredWidth: iconSize
          Layout.preferredHeight: iconSize
          Layout.alignment: Qt.AlignVCenter

          NIcon {
            anchors.centerIn: parent
            icon: "media-prev"
            color: (hasPlayer && (player.canGoPrevious === true)) ? Color.mOnSurface : Qt.alpha(Color.mOnSurface, 0.35)
            pointSize: Style.fontSizeM * effectiveScaling
          }

          MouseArea {
            anchors.fill: parent
            enabled: hasPlayer && (player.canGoPrevious === true)
            cursorShape: enabled ? Qt.PointingHandCursor : Qt.ArrowCursor
            onClicked: { if (root.player) root.player.previous(); }
          }
        }

        // Album art
        Item {
          visible: hasPlayer && ((showAlbumArt === true) || (showProgressRing === true))
          Layout.preferredWidth: visible ? artSize : 0
          Layout.preferredHeight: visible ? artSize : 0
          Layout.alignment: Qt.AlignVCenter

          ProgressRing {
            anchors.fill: parent
            visible: showProgressRing === true
            progress: (hasPlayer && root.player.lengthSupported === true && root.player.length > 0)
                      ? (root.player.position / root.player.length)
                      : 0
            lineWidth: 2 * effectiveScaling
          }

          Item {
            anchors.fill: parent
            anchors.margins: (showProgressRing === true) ? (3 * effectiveScaling) : 0.5

            NImageRounded {
              visible: (showAlbumArt === true) && hasPlayer
              anchors.fill: parent
              radius: width / 2
              imagePath: (hasPlayer && spotifyPlaying) ? root.player.trackArtUrl : ""
              fallbackIcon: "media-pause"
              fallbackIconSize: (showProgressRing === true) ? 10 : 12
              borderWidth: 0
            }
          }
        }

        // Title
        Item {
          Layout.fillWidth: true
          Layout.alignment: Qt.AlignVCenter
          Layout.preferredHeight: titleMetrics.height

          ScrollingText {
            anchors.fill: parent
            text: root.title
            textColor: hasPlayer ? Color.mOnSurface : Color.mOnSurfaceVariant
            fontSize: Style.fontSizeS * effectiveScaling
            scrollMode: scrollingMode
            needsScroll: titleMetrics.contentWidth > parent.width
          }
        }

        // Next
        Item {
          Layout.preferredWidth: iconSize
          Layout.preferredHeight: iconSize
          Layout.alignment: Qt.AlignVCenter

          NIcon {
            anchors.centerIn: parent
            icon: "media-next"
            color: (hasPlayer && (player.canGoNext === true)) ? Color.mOnSurface : Qt.alpha(Color.mOnSurface, 0.35)
            pointSize: Style.fontSizeM * effectiveScaling
          }

          MouseArea {
            anchors.fill: parent
            enabled: hasPlayer && (player.canGoNext === true)
            cursorShape: enabled ? Qt.PointingHandCursor : Qt.ArrowCursor
            onClicked: { if (root.player) root.player.next(); }
          }
        }
      }

      // Vertical layout 
      Item {
        visible: isVertical
        anchors.centerIn: parent
        width: showProgressRing ? (Style.baseWidgetSize * 0.5 * effectiveScaling) : (verticalSize - 4 * effectiveScaling)
        height: width
        z: 1

        ProgressRing {
          anchors.fill: parent
          anchors.margins: -4
          visible: showProgressRing === true
          progress: (hasPlayer && root.player.lengthSupported === true && root.player.length > 0)
                    ? (root.player.position / root.player.length)
                    : 0
          lineWidth: 2.5 * effectiveScaling
        }

        NImageRounded {
          visible: (showAlbumArt === true) && hasPlayer
          anchors.fill: parent
          radius: width / 2
          imagePath: (hasPlayer && spotifyPlaying) ? root.player.trackArtUrl : ""
          fallbackIcon: "media-pause"
          fallbackIconSize: 12
          borderWidth: 0
        }

        NIcon {
          visible: (showAlbumArt === false) || (hasPlayer === false)
          anchors.centerIn: parent
          icon: hasPlayer ? (isPlaying ? "media-pause" : "media-play") : "disc"
          color: hasPlayer ? Color.mOnSurface : Color.mOnSurfaceVariant
          pointSize: Style.fontSizeM * effectiveScaling
        }
      }

      
      MouseArea {
        anchors.fill: parent
        hoverEnabled: true
        acceptedButtons: Qt.LeftButton | Qt.RightButton | Qt.MiddleButton
        cursorShape: hasPlayer ? Qt.PointingHandCursor : Qt.ArrowCursor

        
        onWheel: function(wheel) {
          if (!root.player) return;

          
          if (root.player.canControl !== true) return;
          if (root.player.volumeSupported !== true) return;
          if (root.player.volume === undefined) return;

          var delta = (wheel.angleDelta.y > 0) ? root.volumeStep : -root.volumeStep;
          var v = root.player.volume + delta;
          if (v < 0) v = 0;
          if (v > 1) v = 1;
          root.player.volume = v;

          wheel.accepted = true;
        }

        onClicked: function(mouse) {
          if (mouse.button === Qt.LeftButton && hasPlayer && (player.canTogglePlaying === true)) {
            player.togglePlaying();
          } else if (mouse.button === Qt.RightButton) {
            TooltipService.hide();
           
          } else if (mouse.button === Qt.MiddleButton && hasPlayer && (player.canGoPrevious === true)) {
            player.previous();
          }
        }

        onEntered: {
          if (isVertical || scrollingMode === "never") {
            TooltipService.show(root, root.title, BarService.getTooltipDirection());
          }
        }
        onExited: TooltipService.hide()
      }
    }
  }

  // ---- Visualizer components ----
  Component {
    id: linearSpectrum
    NLinearSpectrum {
      width: parent.width - Style.marginS
      height: 20
      values: root.spotifyPlaying ? CavaService.values : []
      fillColor: Color.mPrimary
      opacity: 0.4
      barPosition: Settings.data.bar.position
    }
  }

  Component {
    id: mirroredSpectrum
    NMirroredSpectrum {
      width: parent.width - Style.marginS
      height: parent.height - Style.marginS
      values: root.spotifyPlaying ? CavaService.values : []
      fillColor: Color.mPrimary
      opacity: 0.4
    }
  }

  Component {
    id: waveSpectrum
    NWaveSpectrum {
      width: parent.width - Style.marginS
      height: parent.height - Style.marginS
      values: root.spotifyPlaying ? CavaService.values : []
      fillColor: Color.mPrimary
      opacity: 0.4
    }
  }

  // ---- Progress Ring ----
  component ProgressRing: Canvas {
    property real progress: 0
    property real lineWidth: 2.5

    onProgressChanged: requestPaint()
    Component.onCompleted: requestPaint()

    onPaint: {
      if (width <= 0 || height <= 0) return;

      var ctx = getContext("2d");
      var centerX = width / 2;
      var centerY = height / 2;
      var r = Math.min(width, height) / 2 - lineWidth;

      ctx.reset();

      ctx.beginPath();
      ctx.arc(centerX, centerY, r, 0, 2 * Math.PI);
      ctx.lineWidth = lineWidth;
      ctx.strokeStyle = Qt.alpha(Color.mOnSurface, 0.4);
      ctx.stroke();

      ctx.beginPath();
      ctx.arc(centerX, centerY, r, -Math.PI / 2, -Math.PI / 2 + progress * 2 * Math.PI);
      ctx.lineWidth = lineWidth;
      ctx.strokeStyle = Color.mPrimary;
      ctx.lineCap = "round";
      ctx.stroke();
    }
  }

  
  component ScrollingText: Item {
    id: scrollText

    property string text
    property color textColor
    property real fontSize
    property string scrollMode
    property bool needsScroll

    clip: true
    implicitHeight: titleText.height

    property bool isScrolling: false
    property bool isResetting: false

    Timer {
      id: scrollTimer
      interval: 1000
      onTriggered: {
        if (scrollMode === "always" && needsScroll) {
          scrollText.isScrolling = true;
          scrollText.isResetting = false;
        }
      }
    }

    MouseArea {
      id: hoverArea
      anchors.fill: parent
      hoverEnabled: true
      acceptedButtons: Qt.NoButton
      cursorShape: Qt.ArrowCursor
    }

    function updateState() {
      if (scrollMode === "never") {
        isScrolling = false;
        isResetting = false;
      } else if (scrollMode === "always") {
        if (needsScroll) {
          if (hoverArea.containsMouse) {
            isScrolling = false;
            isResetting = true;
          } else {
            scrollTimer.restart();
          }
        }
      } else if (scrollMode === "hover") {
        isScrolling = hoverArea.containsMouse && needsScroll;
        isResetting = !hoverArea.containsMouse && needsScroll;
      }
    }

    onWidthChanged: updateState()
    Component.onCompleted: updateState()

    Connections {
      target: hoverArea
      function onContainsMouseChanged() { scrollText.updateState(); }
    }

    Item {
      id: scrollContainer
      height: parent.height
      property real scrollX: 0
      x: scrollX

      RowLayout {
        spacing: 50

        NText {
          id: titleText
          text: scrollText.text
          color: textColor
          pointSize: fontSize
          applyUiScale: false
          font.weight: Style.fontWeightMedium

          onTextChanged: {
            scrollText.isScrolling = false;
            scrollText.isResetting = false;
            scrollContainer.scrollX = 0;
            if (scrollText.needsScroll) scrollTimer.restart();
          }
        }

        NText {
          text: scrollText.text
          color: textColor
          pointSize: fontSize
          applyUiScale: false
          font.weight: Style.fontWeightMedium
          visible: scrollText.needsScroll && scrollText.isScrolling
        }
      }

      NumberAnimation on scrollX {
        running: scrollText.isResetting
        to: 0
        duration: 300
        easing.type: Easing.OutQuad
        onFinished: scrollText.isResetting = false
      }

      NumberAnimation on scrollX {
        running: scrollText.isScrolling && !scrollText.isResetting
        from: 0
        to: -(titleText.contentWidth + 50)
        duration: Math.max(4000, scrollText.text.length * 120)
        loops: Animation.Infinite
        easing.type: Easing.Linear
      }
    }
  }
}
