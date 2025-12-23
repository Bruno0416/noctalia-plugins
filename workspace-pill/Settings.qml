import QtQuick
import QtQuick.Controls

Item {
  id: root

  
  required property var pluginApi

  
  function getSettings() {
    return pluginApi.pluginSettings || {}
  }

  function updateSettings(newSettings) {
    pluginApi.updateSettings(newSettings)
  }

  Column {
    anchors.fill: parent
    anchors.margins: 16
    spacing: 12

    Text {
      text: "Monitors workspaces"
      font.pixelSize: 16
    }

    Repeater {
      model: Object.keys(getSettings().monitors || {})

      delegate: Row {
        spacing: 8

        property string monitorName: modelData
        property var currentList: (getSettings().monitors || {})[monitorName] || []

        Text {
          text: monitorName
          width: 100
        }

        TextField {
          id: wsField
          text: currentList.join(", ")
          placeholderText: "1, 2, 3, 4, 5"
          width: 200

          onEditingFinished: {
            const parts = text.split(",").map(function(p) {
              return parseInt(p.trim())
            }).filter(function(n) { return !isNaN(n) })

            const settings = getSettings()
            if (!settings.monitors)
              settings.monitors = {}

            settings.monitors[monitorName] = parts
            updateSettings(settings)
          }
        }
      }
    }

  }
}
