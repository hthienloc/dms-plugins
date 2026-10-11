import QtQuick
import qs.Common
import qs.Widgets

Column {
    id: root

    property alias items: repeater.model
    property bool expanded: true

    width: parent.width
    spacing: Theme.spacingXS
    visible: expanded
    topPadding: Theme.spacingXS
    bottomPadding: Theme.spacingXS

    Repeater {
        id: repeater

        delegate: StyledText {
            width: root.width
            wrapMode: Text.WordWrap
            font.pixelSize: Theme.fontSizeSmall
            color: index === 0 ? Theme.surfaceText : Theme.surfaceVariantText
            textFormat: Text.StyledText
            text: modelData
        }
    }
}
