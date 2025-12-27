import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Hyprland

import qs.Commons 
import qs.Services.Compositor 

Rectangle {
  id: root
  
  property var pluginApi
  property var screen
  property string widgetId
  property string section

  function s(key, fallback) {
    return (pluginApi && pluginApi.pluginSettings && pluginApi.pluginSettings[key] !== undefined)
      ? pluginApi.pluginSettings[key]
      : fallback
  }

  readonly property bool showIndex: s("showIndex", false)
  readonly property real padding: s("padding", 4)
  readonly property real activeWidth: s("activeWidth", 35)

  
  visible: true

  
  readonly property string barPosition: (Settings && Settings.data && Settings.data.bar && Settings.data.bar.position) ? Settings.data.bar.position : "top"
  readonly property bool isVertical: barPosition === "left" || barPosition === "right"

  readonly property string screenName: (screen && screen.name) ? screen.name : ""

      
  readonly property bool showCapsule: (Settings && Settings.data && Settings.data.bar && Settings.data.bar.showCapsule !== undefined)? Settings.data.bar.showCapsule: true

    
  readonly property bool showOutline: (Settings && Settings.data && Settings.data.bar && Settings.data.bar.showOutline !== undefined)? Settings.data.bar.showOutline: true


  
  function hasKeys(obj) {
    if (!obj) return false
    return Object.keys(obj).length > 0
  }

  function effectiveMonitorMapping() {
    
    var userMap = (pluginApi && pluginApi.pluginSettings) ? pluginApi.pluginSettings.monitors : null
    if (hasKeys(userMap)) return userMap

    var defMap = (pluginApi && pluginApi.manifest && pluginApi.manifest.metadata
                  && pluginApi.manifest.metadata.defaultSettings)
                 ? pluginApi.manifest.metadata.defaultSettings.monitors
                 : null
    if (hasKeys(defMap)) return defMap

    return {}
  }

  function getConfiguredIdsForScreen() {
    var mapping = effectiveMonitorMapping()
    if (!mapping || !screenName) return []

    var keys = Object.keys(mapping)
    var sn = screenName.toLowerCase()

    
    for (var i = 0; i < keys.length; i++) {
      if (keys[i].toLowerCase() === sn) {
        var list = mapping[keys[i]]
        return Array.isArray(list) ? list : []
      }
    }
    return []
  }

  
  function findWorkspaceObject(outputName, workspaceId) {
    if (!CompositorService || !CompositorService.workspaces) return null
    if (!outputName) return null

    var out = outputName.toLowerCase()

    for (var i = 0; i < CompositorService.workspaces.count; i++) {
      var ws = CompositorService.workspaces.get(i)
      if (!ws) continue
      if (!ws.output || ws.output.toLowerCase() !== out) continue
      if (ws.id === workspaceId) return ws
    }
    return null
  }

  
  property ListModel localIds: ListModel {}

  function refreshIds() {
    localIds.clear()

    var ids = getConfiguredIdsForScreen()
    for (var i = 0; i < ids.length; i++) {
      
      localIds.append({ "id": ids[i] })
    }
  }

  Component.onCompleted: refreshIds()
  onScreenChanged: refreshIds()
  onPluginApiChanged: refreshIds()

  
  Connections {
    target: CompositorService
    function onWorkspacesChanged() { localIdsChanged() }
  }

  
  Loader {
    id: contentLoader
    anchors.centerIn: parent 
    sourceComponent: root.isVertical ? verticalContent : horizontalContent
  }

  Component {
    id: horizontalContent
    Row {
      id: row
      spacing: Style.marginS / 1.5

      Repeater {
        model: root.localIds

        delegate: Rectangle {
          readonly property int wsId: model.id
          readonly property var wsObj: root.findWorkspaceObject(root.screenName, wsId)
          readonly property bool isFocused: wsObj ? (wsObj.isFocused === true) : false
          readonly property bool isOccupied: wsObj ? (wsObj.isOccupied === true) : false

          height: Style.capsuleHeight - root.padding * 2
          radius: height / 2

          
          width: isFocused ? root.activeWidth : height
          Behavior on width { NumberAnimation { duration: 350; easing.type: Easing.OutCubic } }

          
          color: isFocused ? Color.mPrimary :  Qt.alpha(Color.mSecondary, 0.55)
          Behavior on color { ColorAnimation { duration: 280; easing.type: Easing.OutCubic } }
          

          border.color: Color.mOutline
          border.width: 1
          opacity: isFocused ? 1.0 : 0.90

        

          MouseArea {
            anchors.fill: parent
            cursorShape: Qt.PointingHandCursor
            hoverEnabled: true

            
            onClicked: mouse => {
              if (mouse.button === Qt.LeftButton){
                 if (wsObj) {
                  CompositorService.switchToWorkspace(wsObj)
                } else {
                  Hyprland.dispatch("workspace " + wsId)
                }
              } else if (mouse.button === Qt.RightButon){
                // TODO: Agregar dropdow para configuracion
              }
            }

            onEntered: parent.opacity = 1.0
            onExited: parent.opacity = isFocused ? 1.0 : 0.90
          }
        }
      }
    }
  }

  Component {
    id: verticalContent
    Column {
      id: col
      spacing: Style.marginS

      Repeater {
        model: root.localIds

        delegate: Rectangle {
          readonly property int wsId: model.id
          readonly property var wsObj: root.findWorkspaceObject(root.screenName, wsId)
          readonly property bool isFocused: wsObj ? (wsObj.isFocused === true) : false
          readonly property bool isOccupied: wsObj ? (wsObj.isOccupied === true) : false

          width: Style.capsuleHeight - Style.marginS * 2
          height: width
          radius: height / 2


          color: isFocused ? Color.mPrimary : (isOccupied ? Color.mSurfaceVariant : Qt.alpha(Color.mSurfaceVariant, 0.55))
          Behavior on width { NumberAnimation { duration: 350; easing.type: Easing.OutCubic } }
          Behavior on color { ColorAnimation { duration: 280; easing.type: Easing.OutCubic } }

          

          MouseArea {
            anchors.fill: parent
            cursorShape: Qt.PointingHandCursor
            hoverEnabled: true

            onClicked: {
              if (wsObj) {
                CompositorService.switchToWorkspace(wsObj)
              } else {
                Hyprland.dispatch("workspace " + wsId)
              }
            }

            onEntered: parent.opacity = 1.0
            onExited: parent.opacity = isFocused ? 1.0 : 0.90
          }
        }
      }
    }
  }



  implicitWidth: isVertical ? Style.capsuleHeight : ((contentLoader.item ? contentLoader.item.implicitWidth : 0) + root.padding * 2)
  implicitHeight: isVertical ? ((contentLoader.item ? contentLoader.item.implicitHeight : 0) + root.padding  * 2) : Style.capsuleHeight

  radius: height / 2

  
    
    color: showCapsule
        ? Style.capsuleColor
        : Color.transparent

    
    border.width: (showCapsule && showOutline) ? 1 : 0
    border.color: Color.mPrimary

}
