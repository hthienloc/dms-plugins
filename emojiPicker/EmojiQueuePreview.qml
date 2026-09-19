import QtQuick
import QtQuick.Layouts
import qs.Common
import qs.Widgets

StyledRect {
    id: root

    required property string sequence

    signal copyRequested
    signal pasteRequested

    implicitHeight: previewLayout.implicitHeight + Theme.spacingS * 2
    radius: Theme.cornerRadius
    color: Theme.surfaceContainerHigh

    onSequenceChanged: Qt.callLater(() => sequenceFlickable.scrollToEnd())

    RowLayout {
        id: previewLayout
        anchors.fill: parent
        anchors.margins: Theme.spacingS
        spacing: Theme.spacingS

        Flickable {
            id: sequenceFlickable
            Layout.fillWidth: true
            Layout.preferredHeight: 28
            contentWidth: Math.max(width, sequenceLabel.implicitWidth)
            contentHeight: height
            clip: true
            boundsBehavior: Flickable.StopAtBounds

            function scrollToEnd() {
                contentX = Math.max(0, contentWidth - width);
            }

            StyledText {
                id: sequenceLabel
                height: parent.height
                text: root.sequence
                color: Theme.surfaceText
                font.pixelSize: Theme.fontSizeXLarge
                verticalAlignment: Text.AlignVCenter
            }
        }

        DankActionButton {
            iconName: "content_copy"
            iconSize: Theme.iconSize - 6
            iconColor: Theme.surfaceText
            onClicked: root.copyRequested()
        }

        DankActionButton {
            iconName: "content_paste"
            iconSize: Theme.iconSize - 6
            iconColor: Theme.surfaceText
            onClicked: root.pasteRequested()
        }
    }
}
