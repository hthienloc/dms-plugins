import QtQuick
import QtQuick.Layouts
import qs.Common
import qs.Modules.Plugins
import "./dms-common"

DesktopPluginComponent {
    id: root

    minWidth: 400
    minHeight: 60

    readonly property bool customizeText: pluginData.customizeText ?? false
    readonly property string firstLine: customizeText
        ? (pluginData.firstLine || I18n.tr("Activate Linux"))
        : I18n.tr("Activate Linux")

    readonly property string secondLine: customizeText
        ? (pluginData.secondLine || I18n.tr("Go to Settings to activate Linux."))
        : I18n.tr("Go to Settings to activate Linux.")

    readonly property real watermarkOpacity: (pluginData.watermarkOpacity ?? 40) / 100.0
    readonly property int firstLineSize: pluginData.firstLineSize ?? 22
    readonly property int secondLineSize: pluginData.secondLineSize ?? 14

    Rectangle {
        anchors.fill: parent
        color: "transparent"

        RowLayout {
            anchors.right: parent.right
            anchors.bottom: parent.bottom
            anchors.rightMargin: 50
            anchors.bottomMargin: 50

            ColumnLayout {
                spacing: 2

                Text {
                    text: firstLine
                    color: Theme.surfaceVariantText
                    font.pointSize: firstLineSize
                    font.weight: Font.Light
                    opacity: watermarkOpacity
                }

                Text {
                    text: secondLine
                    color: Theme.surfaceVariantText
                    font.pointSize: secondLineSize
                    opacity: watermarkOpacity
                }
            }
        }
    }
}