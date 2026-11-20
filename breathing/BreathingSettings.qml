import QtQuick
import qs.Common
import qs.DCommon.Widgets
import qs.Modals.FileBrowser
import qs.Modules.Plugins
import qs.Modules.Settings.Widgets

PluginSettings {
    id: root
    pluginId: "breathing"

    readonly property bool defaultEnableAutoStart: false
    readonly property string defaultAutoStartExercise: "0"
    readonly property int defaultDefaultDuration: 5
    readonly property bool defaultEnableHaptic: true
    readonly property bool defaultEnableSound: true
    readonly property bool defaultEnableTwoTone: false
    readonly property string defaultSoundType: "chime"
    readonly property int defaultDefaultSoundVolume: 80
    readonly property string defaultCustomSoundPath: ""
    readonly property string defaultAnimationStyle: "pulse"
    readonly property bool defaultShowHints: true

    property bool enableAutoStart: defaultEnableAutoStart
    property string autoStartExercise: defaultAutoStartExercise
    property int defaultDuration: defaultDefaultDuration
    property bool enableHaptic: defaultEnableHaptic
    property bool enableSound: defaultEnableSound
    property bool enableTwoTone: defaultEnableTwoTone
    property string soundType: defaultSoundType
    property int defaultSoundVolume: defaultDefaultSoundVolume
    property string customSoundPath: defaultCustomSoundPath
    property string animationStyle: defaultAnimationStyle
    property bool showHints: defaultShowHints

    function cleanPath(path) {
        if (!path)
            return "";
        return String(path).replace(/^file:\/\//, "");
    }

    function loadSettings() {
        if (!pluginService)
            return;
        enableAutoStart = loadValue("enableAutoStart", defaultEnableAutoStart);
        autoStartExercise = loadValue("autoStartExercise", defaultAutoStartExercise);
        defaultDuration = loadValue("defaultDuration", defaultDefaultDuration);
        enableHaptic = loadValue("enableHaptic", defaultEnableHaptic);
        enableSound = loadValue("enableSound", defaultEnableSound);
        enableTwoTone = loadValue("enableTwoTone", defaultEnableTwoTone);
        soundType = loadValue("soundType", defaultSoundType);
        defaultSoundVolume = loadValue("defaultSoundVolume", defaultDefaultSoundVolume);
        customSoundPath = loadValue("customSoundPath", defaultCustomSoundPath);
        animationStyle = loadValue("animationStyle", defaultAnimationStyle);
        showHints = loadValue("showHints", defaultShowHints);
        usageSection.expanded = loadValue("usageGuideExpanded", true);
    }

    Component.onCompleted: loadSettings()
    onPluginServiceChanged: loadSettings()

    Column {
        width: parent ? parent.width : 0
        spacing: 0

        SettingsSectionLabel {
            width: parent.width
            text: I18n.trFor("breathing", "Session Defaults")
        }

        SettingsGroup {
            width: parent.width
            slotColor: SettingsMetrics.controlColor

            SettingsToggleRow {
                text: I18n.trFor("breathing", "Auto-start Exercise")
                description: I18n.trFor("breathing", "Start exercise automatically on login.")
                checked: root.enableAutoStart
                modified: root.enableAutoStart !== root.defaultEnableAutoStart
                resetByKeys: false
                onResetRequested: {
                    root.enableAutoStart = root.defaultEnableAutoStart;
                    root.saveValue("enableAutoStart", root.defaultEnableAutoStart);
                }
                onToggled: isChecked => {
                    root.enableAutoStart = isChecked;
                    root.saveValue("enableAutoStart", isChecked);
                }
            }

            SettingsDropdownRow {
                text: I18n.trFor("breathing", "Default Exercise")
                options: [
                    I18n.trFor("breathing", "Deep Breathing"),
                    I18n.trFor("breathing", "4-7-8 Breathing"),
                    I18n.trFor("breathing", "Box Breathing"),
                    I18n.trFor("breathing", "Equal Breathing"),
                    I18n.trFor("breathing", "Resonance"),
                    I18n.trFor("breathing", "Alternate Nostril")
                ]
                optionValues: ["0", "1", "2", "3", "4", "5"]
                currentValue: root.autoStartExercise
                modified: root.autoStartExercise !== root.defaultAutoStartExercise
                resetByKeys: false
                onResetRequested: {
                    root.autoStartExercise = root.defaultAutoStartExercise;
                    root.saveValue("autoStartExercise", root.defaultAutoStartExercise);
                }
                onValueChanged: val => {
                    root.autoStartExercise = val;
                    root.saveValue("autoStartExercise", val);
                }
            }

            SettingsSliderRow {
                text: I18n.trFor("breathing", "Default Duration")
                description: I18n.trFor("breathing", "Session length for auto-started exercises.")
                minimum: 1
                maximum: 30
                step: 1
                unit: I18n.trFor("breathing", "min")
                value: root.defaultDuration
                modified: root.defaultDuration !== root.defaultDefaultDuration
                resetByKeys: false
                onResetRequested: {
                    root.defaultDuration = root.defaultDefaultDuration;
                    root.saveValue("defaultDuration", root.defaultDefaultDuration);
                }
                onSliderDragFinished: finalValue => {
                    root.defaultDuration = finalValue;
                    root.saveValue("defaultDuration", finalValue);
                }
            }
        }
    }

    Column {
        width: parent ? parent.width : 0
        spacing: 0

        SettingsSectionLabel {
            width: parent.width
            text: I18n.trFor("breathing", "Feedback")
        }

        SettingsGroup {
            width: parent.width
            slotColor: SettingsMetrics.controlColor

            SettingsToggleRow {
                text: I18n.trFor("breathing", "Haptic Feedback")
                checked: root.enableHaptic
                modified: root.enableHaptic !== root.defaultEnableHaptic
                resetByKeys: false
                onResetRequested: {
                    root.enableHaptic = root.defaultEnableHaptic;
                    root.saveValue("enableHaptic", root.defaultEnableHaptic);
                }
                onToggled: isChecked => {
                    root.enableHaptic = isChecked;
                    root.saveValue("enableHaptic", isChecked);
                }
            }

            SettingsToggleRow {
                text: I18n.trFor("breathing", "Sound Cues")
                checked: root.enableSound
                modified: root.enableSound !== root.defaultEnableSound
                resetByKeys: false
                onResetRequested: {
                    root.enableSound = root.defaultEnableSound;
                    root.saveValue("enableSound", root.defaultEnableSound);
                }
                onToggled: isChecked => {
                    root.enableSound = isChecked;
                    root.saveValue("enableSound", isChecked);
                }
            }

            SettingsToggleRow {
                text: I18n.trFor("breathing", "Two-Tone Model")
                description: I18n.trFor("breathing", "Play falling pitch during exhale (default is inhale only).")
                checked: root.enableTwoTone
                visible: root.enableSound
                modified: root.enableTwoTone !== root.defaultEnableTwoTone
                resetByKeys: false
                onResetRequested: {
                    root.enableTwoTone = root.defaultEnableTwoTone;
                    root.saveValue("enableTwoTone", root.defaultEnableTwoTone);
                }
                onToggled: isChecked => {
                    root.enableTwoTone = isChecked;
                    root.saveValue("enableTwoTone", isChecked);
                }
            }

            SettingsDropdownRow {
                text: I18n.trFor("breathing", "Sound Cue Type")
                options: [
                    I18n.trFor("breathing", "Singing Bowl Chime"),
                    I18n.trFor("breathing", "Ambient Meditation"),
                    I18n.trFor("breathing", "Custom Sound File")
                ]
                optionValues: ["chime", "meditation", "custom"]
                currentValue: root.soundType
                visible: root.enableSound
                modified: root.soundType !== root.defaultSoundType
                resetByKeys: false
                onResetRequested: {
                    root.soundType = root.defaultSoundType;
                    root.saveValue("soundType", root.defaultSoundType);
                }
                onValueChanged: val => {
                    root.soundType = val;
                    root.saveValue("soundType", val);
                }
            }

            SettingsSliderRow {
                text: I18n.trFor("breathing", "Sound Volume")
                minimum: 0
                maximum: 100
                step: 5
                unit: "%"
                value: root.defaultSoundVolume
                visible: root.enableSound
                modified: root.defaultSoundVolume !== root.defaultDefaultSoundVolume
                resetByKeys: false
                onResetRequested: {
                    root.defaultSoundVolume = root.defaultDefaultSoundVolume;
                    root.saveValue("defaultSoundVolume", root.defaultDefaultSoundVolume);
                }
                onSliderDragFinished: finalValue => {
                    root.defaultSoundVolume = finalValue;
                    root.saveValue("defaultSoundVolume", finalValue);
                }
            }

            SettingsTextFieldRow {
                id: customSoundField
                text: I18n.trFor("breathing", "Custom Sound File")
                description: I18n.trFor("breathing", "Absolute path to custom audio.")
                placeholderText: "/home/user/sounds/my-sound.ogg"
                value: root.customSoundPath
                visible: root.enableSound && root.soundType === "custom"
                modified: root.customSoundPath !== root.defaultCustomSoundPath
                resetByKeys: false
                onResetRequested: {
                    root.customSoundPath = root.defaultCustomSoundPath;
                    customSoundField.value = root.defaultCustomSoundPath;
                    root.saveValue("customSoundPath", root.defaultCustomSoundPath);
                }
                onValueEdited: newValue => {
                    root.customSoundPath = newValue;
                    root.saveValue("customSoundPath", newValue);
                }
                actions: DActionButton {
                    iconName: "folder_open"
                    backgroundColor: Theme.surfaceContainerHigh
                    iconColor: Theme.primary
                    tooltipText: I18n.trFor("breathing", "Select File")
                    onClicked: soundBrowserModal.open()
                }
            }
        }
    }

    Column {
        width: parent ? parent.width : 0
        spacing: 0

        SettingsSectionLabel {
            width: parent.width
            text: I18n.trFor("breathing", "Appearance")
        }

        SettingsGroup {
            width: parent.width
            slotColor: SettingsMetrics.controlColor

            SettingsDropdownRow {
                text: I18n.trFor("breathing", "Animation Style")
                options: [
                    I18n.trFor("breathing", "Classic Card"),
                    I18n.trFor("breathing", "Expanding Circle"),
                    I18n.trFor("breathing", "Flowing Wave"),
                    I18n.trFor("breathing", "Pulsating Glow")
                ]
                optionValues: ["classic", "circle", "wave", "pulse"]
                currentValue: root.animationStyle
                modified: root.animationStyle !== root.defaultAnimationStyle
                resetByKeys: false
                onResetRequested: {
                    root.animationStyle = root.defaultAnimationStyle;
                    root.saveValue("animationStyle", root.defaultAnimationStyle);
                }
                onValueChanged: val => {
                    root.animationStyle = val;
                    root.saveValue("animationStyle", val);
                }
            }
        }
    }

    Column {
        width: parent ? parent.width : 0
        spacing: 0

        SettingsSectionLabel {
            width: parent.width
            text: I18n.trFor("breathing", "Behavior")
        }

        SettingsGroup {
            width: parent.width
            slotColor: SettingsMetrics.controlColor

            SettingsToggleRow {
                text: I18n.trFor("breathing", "Show Hints")
                checked: root.showHints
                modified: root.showHints !== root.defaultShowHints
                resetByKeys: false
                onResetRequested: {
                    root.showHints = root.defaultShowHints;
                    root.saveValue("showHints", root.defaultShowHints);
                }
                onToggled: isChecked => {
                    root.showHints = isChecked;
                    root.saveValue("showHints", isChecked);
                }
            }
        }
    }

    Column {
        id: usageSection
        width: parent ? parent.width : 0
        spacing: 0

        property bool expanded: true

        SettingsSectionLabel {
            width: parent.width
            text: I18n.trFor("breathing", "How to Use")
            collapsible: true
            expanded: usageSection.expanded
            onToggleRequested: {
                usageSection.expanded = !usageSection.expanded;
                if (root.pluginService)
                    root.saveValue("usageGuideExpanded", usageSection.expanded);
            }
        }

        SettingsGroup {
            width: parent.width
            slotColor: SettingsMetrics.controlColor
            visible: usageSection.expanded

            Column {
                width: parent.width
                spacing: Theme.spacingS

                Repeater {
                    model: [
                        I18n.trFor("breathing", "<b>Left-click</b> the pill to start/pause the breathing session."),
                        I18n.trFor("breathing", "<b>Right-click</b> the pill to stop and reset the session."),
                        I18n.trFor("breathing", "Open the <b>Popout</b> to choose different breathing techniques."),
                        I18n.trFor("breathing", "Follow the <b>visual guide</b> and <b>sound cues</b> to sync your breath.")
                    ]

                    delegate: Row {
                        required property string modelData
                        width: parent.width
                        spacing: Theme.spacingS

                        StyledText {
                            id: bullet
                            text: "•"
                            color: Theme.primary
                            font.pixelSize: Theme.fontSizeSmall
                            font.weight: Font.Bold
                        }

                        StyledText {
                            width: parent.width - bullet.width - parent.spacing
                            text: modelData
                            color: Theme.surfaceVariantText
                            font.pixelSize: Theme.fontSizeSmall
                            wrapMode: Text.WordWrap
                            textFormat: Text.StyledText
                        }
                    }
                }
            }
        }
    }

    FileBrowserSurfaceModal {
        id: soundBrowserModal
        browserTitle: I18n.trFor("breathing", "Custom Sound File")
        browserType: "file_picker"
        folderMode: false
        saveMode: false
        fileExtensions: [
            I18n.trFor("breathing", "Audio files") + " (*.mp3 *.wav *.ogg *.oga *.flac)",
            I18n.trFor("breathing", "All files") + " (*)"
        ]
        revealPath: root.customSoundPath !== "" ? root.customSoundPath : ""
        onAccepted: paths => {
            if (paths && paths.length > 0) {
                const cleaned = root.cleanPath(paths[0]);
                root.customSoundPath = cleaned;
                customSoundField.value = cleaned;
                root.saveValue("customSoundPath", cleaned);
            }
        }
    }
}
