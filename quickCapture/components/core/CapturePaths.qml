pragma Singleton

import QtQuick
import QtCore
import qs.Common
import "Defaults.js" as Defaults

QtObject {
    readonly property string defaultSaveDirectory: Paths.strip(Paths.pictures) + "/Screenshots"
    readonly property string defaultRecordingDirectory: Paths.strip(StandardPaths.writableLocation(StandardPaths.MoviesLocation)) + "/Recordings"

    function defaultValue(key) {
        if (key === "saveDirectory")
            return defaultSaveDirectory;
        if (key === "recordingDirectory")
            return defaultRecordingDirectory;
        return Defaults.values[key];
    }

    function setting(pluginData, key) {
        return Defaults.get(pluginData, key, defaultValue(key));
    }
}
