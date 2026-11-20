import QtQuick
import qs.Common
import qs.DCommon.Widgets
import qs.Modals.FileBrowser
import qs.Modules.Settings.Widgets
import "../core" as Core
import "../core/Defaults.js" as Defaults

Column {
    id: root

    property QtObject config: null
    property var settings: null

    width: parent ? parent.width : 0
    spacing: Theme.spacingM

    property string doneAction: Defaults.values.doneAction
    property string saveDirectory: Core.CapturePaths.defaultSaveDirectory
    property string saveFilenamePattern: Defaults.values.saveFilenamePattern
    property string outputFormat: Defaults.values.outputFormat
    property int jpegQuality: Defaults.values.jpegQuality
    property int webpQuality: Defaults.values.webpQuality
    property string postNotification: Defaults.values.postNotification

    function cleanPath(url) {
        let path = url.toString();
        if (path.startsWith("file://"))
            path = path.substring(7);
        if (path.length > 1 && path.endsWith("/"))
            path = path.substring(0, path.length - 1);
        return path;
    }

    function loadValue() {
        if (!settings)
            return;
        doneAction = settings.loadValue("doneAction", Defaults.values.doneAction);
        saveDirectory = settings.loadValue("saveDirectory", Core.CapturePaths.defaultSaveDirectory);
        saveFilenamePattern = settings.loadValue("saveFilenamePattern", Defaults.values.saveFilenamePattern);
        outputFormat = settings.loadValue("outputFormat", Defaults.values.outputFormat);
        jpegQuality = settings.loadValue("jpegQuality", Defaults.values.jpegQuality);
        webpQuality = settings.loadValue("webpQuality", Defaults.values.webpQuality);
        postNotification = settings.loadValue("postNotification", Defaults.values.postNotification);
    }

    function save(key, val) {
        if (settings)
            settings.saveValue(key, val);
    }

    onSettingsChanged: loadValue()
    Component.onCompleted: loadValue()

    Column {
        width: parent.width
        spacing: 0

        SettingsSectionLabel {
            width: parent.width
            text: I18n.trFor("quickCapture", "Save")
        }

        SettingsGroup {
            width: parent.width
            slotColor: SettingsMetrics.controlColor

            SettingsButtonGroupRow {
                text: I18n.trFor("quickCapture", "Action on %1").arg("Enter")
                model: [
                    I18n.trFor("quickCapture", "Copy"),
                    I18n.trFor("quickCapture", "Save"),
                    I18n.trFor("quickCapture", "Copy & Save")
                ]
                values: ["clipboard", "file", "both"]
                value: root.doneAction
                modified: root.doneAction !== Defaults.values.doneAction
                resetByKeys: false
                onResetRequested: {
                    root.doneAction = Defaults.values.doneAction;
                    root.save("doneAction", Defaults.values.doneAction);
                }
                onValueSelected: val => {
                    root.doneAction = val;
                    root.save("doneAction", val);
                }
            }

            SettingsTextFieldRow {
                id: saveDirectoryField
                text: I18n.trFor("quickCapture", "Screenshot Folder")
                placeholderText: Core.CapturePaths.defaultSaveDirectory
                value: root.saveDirectory
                modified: root.saveDirectory !== Core.CapturePaths.defaultSaveDirectory
                onResetRequested: {
                    root.saveDirectory = Core.CapturePaths.defaultSaveDirectory;
                    saveDirectoryField.value = Core.CapturePaths.defaultSaveDirectory;
                    root.save("saveDirectory", Core.CapturePaths.defaultSaveDirectory);
                }
                onValueEdited: val => {
                    root.saveDirectory = val;
                    root.save("saveDirectory", val);
                }
                actions: DActionButton {
                    iconName: "folder_open"
                    tooltipText: I18n.trFor("quickCapture", "Browse")
                    onClicked: saveDirBrowser.open()
                }
            }

            SettingsTextFieldRow {
                id: saveFilenamePatternField
                text: I18n.trFor("quickCapture", "Filename Pattern")
                placeholderText: Defaults.values.saveFilenamePattern
                value: root.saveFilenamePattern
                modified: root.saveFilenamePattern !== Defaults.values.saveFilenamePattern
                onResetRequested: {
                    root.saveFilenamePattern = Defaults.values.saveFilenamePattern;
                    saveFilenamePatternField.value = Defaults.values.saveFilenamePattern;
                    root.save("saveFilenamePattern", Defaults.values.saveFilenamePattern);
                }
                onValueEdited: val => {
                    root.saveFilenamePattern = val;
                    root.save("saveFilenamePattern", val);
                }
            }

            SettingsNoteRow {
                noteIconName: "info"
                tint: Theme.primary
                tintBackground: Theme.withAlpha(Theme.primary, 0.08)
                text: I18n.trFor("quickCapture", "Format tokens: %Y (Year), %y (2-digit year), %m (Month), %d (Day), %H (Hour), %M (Minute), %S (Second), {zzz} (Ms)")
            }

            SettingsButtonGroupRow {
                text: I18n.trFor("quickCapture", "Output Format")
                model: ["PNG", "JPEG", "WebP", "PDF", "PPM"]
                values: ["png", "jpg", "webp", "pdf", "ppm"]
                value: root.outputFormat
                modified: root.outputFormat !== Defaults.values.outputFormat
                resetByKeys: false
                onResetRequested: {
                    root.outputFormat = Defaults.values.outputFormat;
                    root.save("outputFormat", Defaults.values.outputFormat);
                }
                onValueSelected: val => {
                    root.outputFormat = val;
                    root.save("outputFormat", val);
                }
            }

            SettingsNoteRow {
                noteIconName: "info"
                tint: Theme.primary
                tintBackground: Theme.withAlpha(Theme.primary, 0.08)
                text: I18n.trFor("quickCapture", "Output format applies only to disk saves. Clipboard copies are always PNG.")
            }

            SettingsSliderRow {
                visible: root.outputFormat === "jpg"
                text: I18n.trFor("quickCapture", "JPEG Quality")
                value: root.jpegQuality
                minimum: 1
                maximum: 100
                step: 1
                unit: "%"
                modified: root.jpegQuality !== Defaults.values.jpegQuality
                resetByKeys: false
                onResetRequested: {
                    root.jpegQuality = Defaults.values.jpegQuality;
                    root.save("jpegQuality", Defaults.values.jpegQuality);
                }
                onSliderDragFinished: finalValue => {
                    root.jpegQuality = finalValue;
                    root.save("jpegQuality", finalValue);
                }
            }

            SettingsSliderRow {
                visible: root.outputFormat === "webp"
                text: I18n.trFor("quickCapture", "WebP Quality")
                value: root.webpQuality
                minimum: 1
                maximum: 100
                step: 1
                unit: "%"
                modified: root.webpQuality !== Defaults.values.webpQuality
                resetByKeys: false
                onResetRequested: {
                    root.webpQuality = Defaults.values.webpQuality;
                    root.save("webpQuality", Defaults.values.webpQuality);
                }
                onSliderDragFinished: finalValue => {
                    root.webpQuality = finalValue;
                    root.save("webpQuality", finalValue);
                }
            }
        }
    }

    Column {
        width: parent.width
        spacing: 0

        SettingsSectionLabel {
            width: parent.width
            text: I18n.trFor("quickCapture", "Notifications")
        }

        SettingsGroup {
            width: parent.width
            slotColor: SettingsMetrics.controlColor

            SettingsButtonGroupRow {
                text: I18n.trFor("quickCapture", "Post-Capture Notification")
                description: I18n.trFor("quickCapture", "Choose notifications shown after copy or save.")
                model: [
                    I18n.trFor("quickCapture", "Notification"),
                    I18n.trFor("quickCapture", "Toast"),
                    I18n.trFor("quickCapture", "Both"),
                    I18n.trFor("quickCapture", "None")
                ]
                values: ["notification", "toast", "both", "none"]
                value: root.postNotification
                modified: root.postNotification !== Defaults.values.postNotification
                resetByKeys: false
                onResetRequested: {
                    root.postNotification = Defaults.values.postNotification;
                    root.save("postNotification", Defaults.values.postNotification);
                }
                onValueSelected: val => {
                    root.postNotification = val;
                    root.save("postNotification", val);
                }
            }
        }
    }

    FileBrowserSurfaceModal {
        id: saveDirBrowser
        browserTitle: I18n.trFor("quickCapture", "Screenshot Folder")
        browserType: "folder_picker"
        folderMode: true
        saveMode: false
        fileExtensions: []
        revealPath: root.saveDirectory
        onAccepted: paths => {
            if (paths && paths.length > 0) {
                const cleaned = root.cleanPath(paths[0]);
                root.saveDirectory = cleaned;
                saveDirectoryField.value = cleaned;
                root.save("saveDirectory", cleaned);
            }
        }
    }
}
