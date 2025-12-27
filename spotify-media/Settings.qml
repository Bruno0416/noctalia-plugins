import QtQuick
import QtQuick.Layouts
import qs.Commons
import qs.Widgets

ColumnLayout {
  id: root

  property var pluginApi

  // Local state variables
  property real minWidth: pluginApi?.pluginSettings?.minWidth || 240
  property string barVisualizer: pluginApi?.pluginSettings?.barVisualizer || "linear"
  property string panelVisualizer: pluginApi?.pluginSettings?.panelVisualizer || "linear"

  spacing: Style.marginL

  Component.onCompleted: {
    Logger.i("UpdateCount", "Settings UI loaded");
  }



  ColumnLayout {
    Layout.fillWidth: true
    spacing: Style.marginS


    // MinWidth section
    NTextInput {
        text: String(root.minWidth)

        onTextChanged: {
            const t = text.trim()
            if (t === "")      
                return

            const v = parseFloat(t)
            if (isNaN(v))       
                return

            root.minWidth = v
        }
    }


    // Widget Visualizer section
    NComboBox {
        label: "Widget Visualizer type"
        description: "Normal bar widget Visualizer Type"
        placeholder: "Select…"

        model: [
            { key: "linear", name: "Linear" },
            { key: "mirrored", name: "Mirrored" },
            { key: "wave",  name: "Wave" }
        ]

        currentKey: barVisualizer

        onSelected: (key) => {
            barVisualizer = key
        }
    }


    // Widget Visualizer section
    NComboBox {
        label: "Panel Visualizer Type"
        description: "Expanded widget Visualizer Type"
        placeholder: "Select…"

        model: [
            { key: "linear", name: "Linear" },
            { key: "mirrored", name: "Mirrored" },
            { key: "wave",  name: "Wave" }
        ]

        currentKey: panelVisualizer

        onSelected: (key) => {
            panelVisualizer = key
        }
    }
  }

  
    function saveSettings() {
      pluginApi.pluginSettings.minWidth = root.minWidth
      pluginApi.pluginSettings.barVisualizer = root.barVisualizer
      pluginApi.pluginSettings.panelVisualizer = root.panelVisualizer
      pluginApi.saveSettings()
    }
}
