import QtQuick
import qs.Common
import qs.DCommon.Widgets
import qs.Services

Column {
    id: root
    width: parent.width
    spacing: Theme.spacingXS

    property string label: ""
    property string text: ""
    property bool isCopied: false

    function triggerCopy() {
        Proc.runCommand("copy-ipc", ["dms", "cl", "copy", root.text], function() {
            root.isCopied = true;
            copyTimer.restart();
            ToastService.showInfo(I18n.tr("Copied to clipboard"));
        });
    }

    Timer {
        id: copyTimer
        interval: 1500
        repeat: false
        onTriggered: {
            root.isCopied = false;
        }
    }

    StyledText {
        width: parent.width
        text: root.label
        font.pixelSize: Theme.fontSizeSmall
        font.bold: true
        color: Theme.surfaceVariantText
        visible: text !== ""
    }

    Rectangle {
        id: bgRect
        width: parent.width
        height: Math.max(Theme.buttonHeightS, cmdRow.implicitHeight + Theme.spacingL)
        color: Theme.surfaceContainerHigh
        border.color: copyMouseArea.containsMouse ? Theme.withAlpha(Theme.primary, 0.7) : Theme.withAlpha(Theme.primary, 0.0)
        border.width: 1
        radius: Theme.cornerRadius

        Behavior on border.color { ColorAnimation { duration: 150 } }

        Row {
            id: cmdRow
            width: parent.width - Theme.spacingL
            anchors.centerIn: parent
            spacing: Theme.spacingS

            StyledText {
                width: parent.width - Theme.iconSize - Theme.spacingS
                text: root.text
                isMonospace: true
                font.pixelSize: Theme.fontSizeSmall
                color: Theme.secondary
                wrapMode: Text.Wrap
            }

            DButton {
                width: Theme.iconSize
                height: Theme.iconSize
                iconName: root.isCopied ? "check" : "content_copy"
                backgroundColor: "transparent"
                textColor: root.isCopied ? Theme.success : Theme.primary
                anchors.verticalCenter: parent.verticalCenter
                onClicked: root.triggerCopy()
            }
        }

        MouseArea {
            id: copyMouseArea
            anchors.fill: parent
            hoverEnabled: true
            z: 1
            cursorShape: Qt.PointingHandCursor
            onClicked: root.triggerCopy()
        }
    }
}
