import QtQuick
import qs.Common
import qs.DCommon.Widgets
import qs.Modals.FileBrowser
import qs.Modules.Plugins
import qs.Modules.Settings.Widgets
import qs.Services

PluginSettings {
    id: root
    pluginId: "ambientSound"

    readonly property int defaultDefaultVolume: 100
    readonly property bool defaultEnableSleepTimer: true
    readonly property string defaultDefaultTimer: "30"
    readonly property string defaultAutoStartMode: "preset"
    readonly property string defaultAutoStartPreset: ""
    readonly property string defaultMiddleClickAction: ""
    readonly property bool defaultShowHints: true

    property int defaultVolume: defaultDefaultVolume
    property bool enableSleepTimer: defaultEnableSleepTimer
    property string defaultTimer: defaultDefaultTimer
    property string autoStartMode: defaultAutoStartMode
    property string autoStartPreset: defaultAutoStartPreset
    property string middleClickAction: defaultMiddleClickAction
    property bool showHints: defaultShowHints

    property var customSounds: []
    property var hiddenSounds: []
    property var autoStartStates: ({})
    property var presetLabels: [I18n.trFor("ambientSound", "None")]
    property var presetValues: [""]

    function saveCustomSounds(newSounds) {
        customSounds = newSounds;
        saveValue("customSounds", newSounds);
    }

    readonly property var sounds: [
        { name: "rain", icon: "water_drop" },
        { name: "storm", icon: "thunderstorm" },
        { name: "wind", icon: "air" },
        { name: "waves", icon: "waves" },
        { name: "stream", icon: "water" },
        { name: "birds", icon: "flutter_dash" },
        { name: "forest", icon: "forest" },
        { name: "summer-night", icon: "dark_mode" },
        { name: "fireplace", icon: "local_fire_department" },
        { name: "coffee-shop", icon: "local_cafe" },
        { name: "city", icon: "location_city" },
        { name: "train", icon: "train" },
        { name: "boat", icon: "sailing" },
        { name: "guitar", icon: "music_note" },
        { name: "warm-piano", icon: "piano" },
        { name: "ambient-music", icon: "library_music" },
        { name: "lofi-beats", icon: "headphones" },
        { name: "fan", icon: "mode_fan" },
        { name: "airplane", icon: "flight" },
        { name: "laundry-room", icon: "local_laundry_service" },
        { name: "white-noise", icon: "blur_on" },
        { name: "pink-noise", icon: "blur_linear" },
        { name: "brown-noise", icon: "blur_circular" },
        { name: "green-noise", icon: "lens_blur" }
    ]

    function autoStartKey(soundName) {
        return "autoStart" + soundName.charAt(0).toUpperCase() + soundName.slice(1).replace("-", "");
    }

    function updateAutoStartStates() {
        let states = {};
        for (let i = 0; i < sounds.length; i++) {
            let key = autoStartKey(sounds[i].name);
            states[key] = root.loadValue(key, false);
        }
        autoStartStates = states;
    }

    function updatePresetsList() {
        let labels = [I18n.trFor("ambientSound", "None")];
        let values = [""];
        let saved = root.loadValue("presets", []);
        for (let i = 0; i < saved.length; i++) {
            labels.push(saved[i].name);
            values.push(saved[i].name);
        }
        presetLabels = labels;
        presetValues = values;
    }

    function loadSettings() {
        if (!pluginService)
            return;
        defaultVolume = loadValue("defaultVolume", defaultDefaultVolume);
        enableSleepTimer = loadValue("enableSleepTimer", defaultEnableSleepTimer);
        defaultTimer = loadValue("defaultTimer", defaultDefaultTimer);
        autoStartMode = loadValue("autoStartMode", defaultAutoStartMode);
        autoStartPreset = loadValue("autoStartPreset", defaultAutoStartPreset);
        middleClickAction = loadValue("middleClickAction", defaultMiddleClickAction);
        showHints = loadValue("showHints", defaultShowHints);
        customSounds = loadValue("customSounds", []);
        hiddenSounds = loadValue("hiddenSounds", []);
        usageSection.expanded = loadValue("usageGuideExpanded", true);
        creditsSection.expanded = loadValue("creditsExpanded", true);
        updateAutoStartStates();
        updatePresetsList();
    }

    Component.onCompleted: loadSettings()
    onPluginServiceChanged: loadSettings()
    onSettingChanged: {
        if (!pluginService)
            return;
        customSounds = loadValue("customSounds", []);
        hiddenSounds = loadValue("hiddenSounds", []);
        updateAutoStartStates();
        updatePresetsList();
    }

    Column {
        width: parent ? parent.width : 0
        spacing: 0

        SettingsSectionLabel {
            width: parent.width
            text: I18n.trFor("ambientSound", "Audio")
        }

        SettingsGroup {
            width: parent.width
            slotColor: SettingsMetrics.controlColor

            SettingsSliderRow {
                text: I18n.trFor("ambientSound", "Default Volume")
                description: I18n.trFor("ambientSound", "Initial volume when starting.")
                minimum: 0
                maximum: 100
                step: 5
                unit: "%"
                value: root.defaultVolume
                modified: root.defaultVolume !== root.defaultDefaultVolume
                resetByKeys: false
                onResetRequested: {
                    root.defaultVolume = root.defaultDefaultVolume;
                    root.saveValue("defaultVolume", root.defaultDefaultVolume);
                }
                onSliderDragFinished: finalValue => {
                    root.defaultVolume = finalValue;
                    root.saveValue("defaultVolume", finalValue);
                }
            }
        }
    }

    Column {
        width: parent ? parent.width : 0
        spacing: 0

        SettingsSectionLabel {
            width: parent.width
            text: I18n.trFor("ambientSound", "Sleep Timer")
        }

        SettingsGroup {
            width: parent.width
            slotColor: SettingsMetrics.controlColor

            SettingsToggleRow {
                text: I18n.trFor("ambientSound", "Enable Sleep Timer")
                description: I18n.trFor("ambientSound", "Stop audio automatically after set duration.")
                checked: root.enableSleepTimer
                modified: root.enableSleepTimer !== root.defaultEnableSleepTimer
                resetByKeys: false
                onResetRequested: {
                    root.enableSleepTimer = root.defaultEnableSleepTimer;
                    root.saveValue("enableSleepTimer", root.defaultEnableSleepTimer);
                }
                onToggled: isChecked => {
                    root.enableSleepTimer = isChecked;
                    root.saveValue("enableSleepTimer", isChecked);
                }
            }

            SettingsDropdownRow {
                visible: root.enableSleepTimer
                text: I18n.trFor("ambientSound", "Default Duration")
                options: [
                    I18n.trFor("ambientSound", "15 minutes"),
                    I18n.trFor("ambientSound", "30 minutes"),
                    I18n.trFor("ambientSound", "45 minutes"),
                    I18n.trFor("ambientSound", "1 hour"),
                    I18n.trFor("ambientSound", "1.5 hours"),
                    I18n.trFor("ambientSound", "2 hours")
                ]
                optionValues: ["15", "30", "45", "60", "90", "120"]
                currentValue: root.defaultTimer
                modified: root.defaultTimer !== root.defaultDefaultTimer
                resetByKeys: false
                onResetRequested: {
                    root.defaultTimer = root.defaultDefaultTimer;
                    root.saveValue("defaultTimer", root.defaultDefaultTimer);
                }
                onValueChanged: newValue => {
                    root.defaultTimer = newValue;
                    root.saveValue("defaultTimer", newValue);
                }
            }
        }
    }

    Column {
        width: parent ? parent.width : 0
        spacing: 0

        SettingsSectionLabel {
            width: parent.width
            text: I18n.trFor("ambientSound", "Auto-start Mode")
        }

        SettingsGroup {
            width: parent.width
            slotColor: SettingsMetrics.controlColor

            SettingsButtonGroupRow {
                text: I18n.trFor("ambientSound", "Select Mode")
                model: [
                    I18n.trFor("ambientSound", "Preset"),
                    I18n.trFor("ambientSound", "Individual Sounds")
                ]
                values: ["preset", "individual"]
                value: root.autoStartMode
                modified: root.autoStartMode !== root.defaultAutoStartMode
                resetByKeys: false
                onResetRequested: {
                    root.autoStartMode = root.defaultAutoStartMode;
                    root.saveValue("autoStartMode", root.defaultAutoStartMode);
                }
                onValueSelected: newValue => {
                    root.autoStartMode = newValue;
                    root.saveValue("autoStartMode", newValue);
                }
            }

            SettingsDropdownRow {
                visible: root.autoStartMode === "preset"
                text: I18n.trFor("ambientSound", "Auto-play Preset")
                description: I18n.trFor("ambientSound", "Select preset to play automatically when you log in.")
                options: root.presetLabels
                optionValues: root.presetValues
                currentValue: root.autoStartPreset
                modified: root.autoStartPreset !== root.defaultAutoStartPreset
                resetByKeys: false
                onResetRequested: {
                    root.autoStartPreset = root.defaultAutoStartPreset;
                    root.saveValue("autoStartPreset", root.defaultAutoStartPreset);
                }
                onValueChanged: newValue => {
                    root.autoStartPreset = newValue;
                    root.saveValue("autoStartPreset", newValue);
                }
            }

            Flow {
                id: autoStartFlow
                width: parent.width
                spacing: 6
                visible: root.autoStartMode === "individual"

                Repeater {
                    model: root.sounds
                    delegate: Rectangle {
                        required property var modelData
                        width: (autoStartFlow.width - 12) / 3
                        height: 36
                        radius: Theme.cornerRadius

                        readonly property string sKey: root.autoStartKey(modelData.name)
                        readonly property bool isChecked: root.autoStartStates[sKey] || false

                        color: isChecked ? Theme.primary : Theme.surfaceContainerHigh

                        Row {
                            anchors.centerIn: parent
                            spacing: 6
                            DIcon {
                                name: modelData.icon || "music_note"
                                size: 16
                                color: isChecked ? Theme.onPrimary : Theme.surfaceVariantText
                            }
                            StyledText {
                                text: I18n.trFor("ambientSound", modelData.name.replace("-", " "))
                                font.pixelSize: Theme.fontSizeSmall
                                font.weight: isChecked ? Font.Bold : Font.Normal
                                color: isChecked ? Theme.onPrimary : Theme.surfaceText
                            }
                        }

                        MouseArea {
                            anchors.fill: parent
                            cursorShape: Qt.PointingHandCursor
                            onClicked: {
                                root.saveValue(sKey, !isChecked);
                            }
                        }
                    }
                }
            }
        }
    }

    Column {
        width: parent ? parent.width : 0
        spacing: 0

        SettingsSectionLabel {
            width: parent.width
            text: I18n.trFor("ambientSound", "Behavior")
        }

        SettingsGroup {
            width: parent.width
            slotColor: SettingsMetrics.controlColor

            SettingsDropdownRow {
                text: I18n.trFor("ambientSound", "Middle-click Preset")
                description: I18n.trFor("ambientSound", "Sound preset to play/toggle when middle-clicking the bar icon.")
                options: root.presetLabels
                optionValues: root.presetValues
                currentValue: root.middleClickAction
                modified: root.middleClickAction !== root.defaultMiddleClickAction
                resetByKeys: false
                onResetRequested: {
                    root.middleClickAction = root.defaultMiddleClickAction;
                    root.saveValue("middleClickAction", root.defaultMiddleClickAction);
                }
                onValueChanged: newValue => {
                    root.middleClickAction = newValue;
                    root.saveValue("middleClickAction", newValue);
                }
            }

            SettingsToggleRow {
                text: I18n.trFor("ambientSound", "Show Hints")
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
        width: parent ? parent.width : 0
        spacing: 0

        SettingsSectionLabel {
            width: parent.width
            text: I18n.trFor("ambientSound", "Custom Sounds")
        }

        SettingsGroup {
            width: parent.width
            slotColor: SettingsMetrics.controlColor

            DButton {
                text: I18n.trFor("ambientSound", "Add Custom Sound")
                iconName: "add"
                backgroundColor: Theme.primary
                width: parent.width
                onClicked: customSoundBrowser.open()
            }

            Column {
                width: parent.width
                spacing: Theme.spacingS
                visible: customSoundsRepeater.count > 0

                Repeater {
                    id: customSoundsRepeater
                    model: root.customSounds

                    delegate: StyledRect {
                        required property var modelData
                        required property int index
                        width: parent.width
                        height: 40
                        color: Theme.surfaceContainerHigh
                        radius: Theme.cornerRadius

                        Row {
                            anchors.fill: parent
                            anchors.leftMargin: Theme.spacingM
                            anchors.rightMargin: Theme.spacingM
                            spacing: Theme.spacingM

                            DIcon {
                                name: "audiotrack"
                                size: 16
                                color: Theme.primary
                                anchors.verticalCenter: parent.verticalCenter
                            }

                            StyledText {
                                text: modelData.name
                                font.pixelSize: Theme.fontSizeSmall
                                color: Theme.surfaceText
                                anchors.verticalCenter: parent.verticalCenter
                                width: parent.width - 64
                                elide: Text.ElideRight
                            }

                            DIcon {
                                name: "delete"
                                size: 16
                                color: Theme.error
                                anchors.verticalCenter: parent.verticalCenter

                                MouseArea {
                                    anchors.fill: parent
                                    cursorShape: Qt.PointingHandCursor
                                    onClicked: {
                                        let updated = JSON.parse(JSON.stringify(root.customSounds));
                                        updated.splice(index, 1);
                                        root.saveCustomSounds(updated);
                                    }
                                }
                            }
                        }
                    }
                }
            }
        }
    }

    FileBrowserModal {
        id: customSoundBrowser
        browserTitle: I18n.trFor("ambientSound", "Select Audio File")
        fileExtensions: ["*.ogg", "*.mp3", "*.wav", "*.m4a"]
        onFileSelected: (filePath) => {
            let cleanPath = filePath;
            if (cleanPath.startsWith("file://")) {
                cleanPath = cleanPath.substring(7);
            }

            let parts = cleanPath.split('/');
            let fileName = parts[parts.length - 1];
            let nameWithoutExt = fileName.replace(/\.[^/.]+$/, "");

            let updated = JSON.parse(JSON.stringify(root.customSounds));
            if (!updated.some(item => item.path === cleanPath)) {
                updated.push({ name: nameWithoutExt, path: cleanPath });
                root.saveCustomSounds(updated);
                ToastService.showInfo(I18n.trFor("ambientSound", "Added custom sound!"));
            } else {
                ToastService.showWarning(I18n.trFor("ambientSound", "Sound already exists."));
            }
        }
    }

    Column {
        width: parent ? parent.width : 0
        spacing: 0

        SettingsSectionLabel {
            width: parent.width
            text: I18n.trFor("ambientSound", "Visible Sounds")
        }

        SettingsGroup {
            width: parent.width
            slotColor: SettingsMetrics.controlColor

            Flow {
                id: visibleSoundsFlow
                width: parent.width
                spacing: 6

                Repeater {
                    model: root.sounds
                    delegate: Rectangle {
                        required property var modelData
                        width: (visibleSoundsFlow.width - 12) / 3
                        height: 36
                        radius: Theme.cornerRadius

                        readonly property bool isVisible: root.hiddenSounds.indexOf(modelData.name) < 0

                        color: isVisible ? Theme.primary : Theme.surfaceContainerHigh

                        Row {
                            anchors.centerIn: parent
                            spacing: 6
                            DIcon {
                                name: modelData.icon || "music_note"
                                size: 16
                                color: isVisible ? Theme.onPrimary : Theme.surfaceVariantText
                            }
                            StyledText {
                                text: I18n.trFor("ambientSound", modelData.name.replace("-", " "))
                                font.pixelSize: Theme.fontSizeSmall
                                font.weight: isVisible ? Font.Bold : Font.Normal
                                color: isVisible ? Theme.onPrimary : Theme.surfaceText
                            }
                        }

                        MouseArea {
                            anchors.fill: parent
                            cursorShape: Qt.PointingHandCursor
                            onClicked: {
                                let idx = root.hiddenSounds.indexOf(modelData.name);
                                let newList = root.hiddenSounds.slice();
                                if (idx >= 0) {
                                    newList.splice(idx, 1);
                                } else {
                                    newList.push(modelData.name);
                                }
                                root.hiddenSounds = newList;
                                root.saveValue("hiddenSounds", newList);
                            }
                        }
                    }
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
            text: I18n.trFor("ambientSound", "Usage Guide")
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
                        I18n.trFor("ambientSound", "<b>Left-click</b> the pill to open the sound selector."),
                        I18n.trFor("ambientSound", "<b>Middle-click</b> the pill to toggle your chosen sound preset."),
                        I18n.trFor("ambientSound", "<b>Right-click</b> the pill to toggle mute."),
                        I18n.trFor("ambientSound", "You can play <b>multiple sounds</b> simultaneously to create your own atmosphere."),
                        I18n.trFor("ambientSound", "Set the <b>Sleep Timer</b> in the popout to turn off sounds after a delay.")
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

    Column {
        id: creditsSection
        width: parent ? parent.width : 0
        spacing: 0

        property bool expanded: true

        SettingsSectionLabel {
            width: parent.width
            text: I18n.trFor("ambientSound", "Credits")
            collapsible: true
            expanded: creditsSection.expanded
            onToggleRequested: {
                creditsSection.expanded = !creditsSection.expanded;
                if (root.pluginService)
                    root.saveValue("creditsExpanded", creditsSection.expanded);
            }
        }

        SettingsGroup {
            width: parent.width
            slotColor: SettingsMetrics.controlColor
            visible: creditsSection.expanded

            Repeater {
                model: [
                    {
                        author: "Zurvan",
                        url: "https://github.com/georgestafilidis",
                        role: I18n.trFor("ambientSound", "UI redesign concept and aesthetics."),
                        icon: "palette"
                    },
                    {
                        author: "Blankie",
                        url: "https://github.com/codybrom/Blankie",
                        role: I18n.trFor("ambientSound", "Sound assets and inspiration."),
                        icon: "library_music"
                    },
                    {
                        author: "Blanket",
                        url: "https://github.com/rafaelmardojai/blanket",
                        role: I18n.trFor("ambientSound", "Sound assets and audio player inspiration."),
                        icon: "library_music"
                    }
                ]

                delegate: SettingsRow {
                    required property var modelData
                    title: modelData.author
                    subtitle: modelData.role
                    iconName: modelData.icon
                    iconBox: true
                    clickable: true
                    showChevron: true
                    onClicked: Qt.openUrlExternally(modelData.url)
                }
            }
        }
    }
}
