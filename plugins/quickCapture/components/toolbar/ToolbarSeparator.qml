import QtQuick
import qs.Common
import "../core/Constants.js" as Constants

Rectangle {
    id: root

    property bool vertical: false

    width: vertical ? Constants.separatorThickness : Constants.separatorLength
    height: vertical ? Constants.separatorLength : Constants.separatorThickness
    color: Theme.withAlpha(Theme.outline, 0.2)
}
