import QtQuick
import QtQuick.Layouts
import qs.Commons
import qs.Widgets

ColumnLayout {
  id: root

  property var pluginApi

  // Local state variables
  property bool showIndex: pluginApi?.pluginSettings?.showIndex || false
  property real padding: pluginApi?.pluginSettings?.padding || 4
  property real activeWidth: pluginApi?.pluginSettings?.activeWidth || 35

  spacing: Style.marginL

  Component.onCompleted: {
    Logger.i("UpdateCount", "Settings UI loaded");
  }



  ColumnLayout {
    Layout.fillWidth: true
    spacing: Style.marginS

    // Show index?
    // NToggle {
    //   Layout.fillWidth: true
    //   label: "Show Index"
    //   description: "Turn this feature on or off"
    //   checked: root.showIndex
    //   onCheckedChanged: root.showIndex = checked
    // }

    // Padding section
    NLabel {
      label: "Padding"
      description: "Widget Padding"
    }

    NSlider {
      Layout.fillWidth: true
      from: 4
      to: 10
      value: root.padding
      onValueChanged: root.padding = value
    }

    // Active Width section
    NLabel {
      label: "Active Width"
      description: "Active widget width"
    }

    NSlider {
      Layout.fillWidth: true
      from: Style.capsuleHeight - Style.marginS * 2
      to: 100
      value: root.activeWidth
      onValueChanged: root.activeWidth = value
    }
  }



  
    function saveSettings() {
      pluginApi.pluginSettings.showIndex = root.showIndex
      pluginApi.pluginSettings.padding = root.padding
      pluginApi.pluginSettings.activeWidth = root.activeWidth
      pluginApi.saveSettings()
    }
}
