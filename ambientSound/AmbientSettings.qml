import QtQuick
import QtQuick.Controls
import qs.Common
import qs.Services
import qs.DCommon.Widgets
import qs.Modules.Plugins
import qs.Modals.FileBrowser
import "./shared"

PluginSettings {
    id: root
    pluginId: "ambientSound"

    property var customSounds: {
        settingChanged;
        return loadValue("customSounds", []);
    }

    function saveCustomSounds(newSounds) {
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

    property var autoStartStates: ({})
    property var presetOptions: [{ label: I18n.trFor("ambientSound", "None"), value: "" }]

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
        let opts = [{ label: I18n.trFor("ambientSound", "None"), value: "" }];
        let saved = root.loadValue("presets", []);
        for (let i = 0; i < saved.length; i++) {
            opts.push({ label: saved[i].name, value: saved[i].name });
        }
        presetOptions = opts;
    }

    Component.onCompleted: {
        updateAutoStartStates();
        updatePresetsList();
    }
    onSettingChanged: {
        updateAutoStartStates();
        updatePresetsList();
    }
    onPluginServiceChanged: {
        updateAutoStartStates();
        updatePresetsList();
    }

    SettingsCard {
        id: audioSection
        SectionTitle { 
            text: I18n.trFor("ambientSound", "Audio")
            icon: "volume_up" 
            showReset: defaultVolume.isDirty
            onResetClicked: defaultVolume.resetToDefault()
        }

        SliderSettingPlus {
            id: defaultVolume
            settingKey: "defaultVolume"
            label: I18n.trFor("ambientSound", "Default Volume")
            description: I18n.trFor("ambientSound", "Initial volume when starting.")
            minimum: 0
            maximum: 100
            unit: "%"
            defaultValue: 100
            leftLabel: "0%"
            rightLabel: "100%"
        }
    }

    SettingsCard {
        id: timerSection
        SectionTitle { 
            text: I18n.trFor("ambientSound", "Sleep Timer")
            icon: "timer" 
            showReset: enableSleepTimer.isDirty || defaultTimer.isDirty
            onResetClicked: {
                enableSleepTimer.resetToDefault();
                defaultTimer.resetToDefault();
            }
        }

        ToggleSettingPlus {
            id: enableSleepTimer
            settingKey: "enableSleepTimer"
            label: I18n.trFor("ambientSound", "Enable Sleep Timer")
            description: I18n.trFor("ambientSound", "Stop audio automatically after set duration.")
            defaultValue: true
        }

        Separator { visible: enableSleepTimer.value }

        SelectionSettingPlus {
            id: defaultTimer
            settingKey: "defaultTimer"
            label: I18n.trFor("ambientSound", "Default Duration")
            options: [
                { label: I18n.trFor("ambientSound", "15 minutes"), value: "15" },
                { label: I18n.trFor("ambientSound", "30 minutes"), value: "30" },
                { label: I18n.trFor("ambientSound", "45 minutes"), value: "45" },
                { label: I18n.trFor("ambientSound", "1 hour"), value: "60" },
                { label: I18n.trFor("ambientSound", "1.5 hours"), value: "90" },
                { label: I18n.trFor("ambientSound", "2 hours"), value: "120" }
            ]
            defaultValue: "30"
            visible: enableSleepTimer.value
        }
    }

    SettingsCard {
        SectionTitle { text: I18n.trFor("ambientSound", "Auto-start Mode"); icon: "play_arrow" }

        ButtonGroupSettingPlus {
            id: autoStartMode
            settingKey: "autoStartMode"
            label: I18n.trFor("ambientSound", "Select Mode")
            options: [
                { label: I18n.trFor("ambientSound", "Preset"), value: "preset" },
                { label: I18n.trFor("ambientSound", "Individual Sounds"), value: "individual" }
            ]
            defaultValue: "preset"
        }

        Separator { visible: autoStartMode.value === "preset" }

        SelectionSettingPlus {
            id: autoStartPreset
            settingKey: "autoStartPreset"
            label: I18n.trFor("ambientSound", "Auto-play Preset")
            description: I18n.trFor("ambientSound", "Select preset to play automatically when you log in.")
            options: root.presetOptions
            defaultValue: ""
            visible: autoStartMode.value === "preset"
        }

        Separator { visible: autoStartMode.value === "individual" }

        Flow {
            id: autoStartFlow
            width: parent.width
            spacing: 6
            visible: autoStartMode.value === "individual"

            Repeater {
                model: root.sounds
                delegate: Rectangle {
                    width: (autoStartFlow.width - 12) / 3
                    height: 36
                    radius: Theme.cornerRadius
                    
                    readonly property string sKey: root.autoStartKey(modelData.name)
                    readonly property bool isChecked: root.autoStartStates[sKey] ?? false
                    
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

    SettingsCard {
        id: behaviorSection
        SectionTitle { 
            text: I18n.trFor("ambientSound", "Behavior")
            icon: "settings" 
            showReset: showHints.isDirty || middleClickAction.isDirty
            onResetClicked: {
                showHints.resetToDefault();
                middleClickAction.resetToDefault();
            }
        }

        SelectionSettingPlus {
            id: middleClickAction
            settingKey: "middleClickAction"
            label: I18n.trFor("ambientSound", "Middle-click Preset")
            description: I18n.trFor("ambientSound", "Sound preset to play/toggle when middle-clicking the bar icon.")
            options: root.presetOptions
            defaultValue: ""
        }

        Separator {}

        ToggleSettingPlus {
            id: showHints
            settingKey: "showHints"
            label: I18n.trFor("ambientSound", "Show Hints")
            defaultValue: true
        }
    }

    SettingsCard {
        id: customSoundsSection
        SectionTitle {
            text: I18n.trFor("ambientSound", "Custom Sounds")
            icon: "music_note"
        }

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
    SettingsCard {
        SectionTitle { text: I18n.trFor("ambientSound", "Visible Sounds"); icon: "visibility" }

        Flow {
            id: visibleSoundsFlow
            width: parent.width
            spacing: 6

            Repeater {
                model: root.sounds
                delegate: Rectangle {
                    width: (visibleSoundsFlow.width - 12) / 3
                    height: 36
                    radius: Theme.cornerRadius
                    
                    readonly property bool isVisible: (root.loadValue("hiddenSounds", [])).indexOf(modelData.name) < 0
                    
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
                            let list = root.loadValue("hiddenSounds", []);
                            let idx = list.indexOf(modelData.name);
                            let newList = list.slice();
                            if (idx >= 0) {
                                newList.splice(idx, 1);
                            } else {
                                newList.push(modelData.name);
                            }
                            root.saveValue("hiddenSounds", newList);
                        }
                    }
                }
            }
        }
    }

    SettingsCard {
        SectionTitle { 
            id: usageTitle
            text: I18n.trFor("ambientSound", "Usage Guide")
            icon: "menu_book" 
            collapsible: true
            settingKey: "usageGuideExpanded"
        }

        UsageGuide {
            expanded: usageTitle.isExpanded
            items: [
                I18n.trFor("ambientSound", "<b>Left-click</b> the pill to open the sound selector."),
                I18n.trFor("ambientSound", "<b>Middle-click</b> the pill to toggle your chosen sound preset."),
                I18n.trFor("ambientSound", "<b>Right-click</b> the pill to toggle mute."),
                I18n.trFor("ambientSound", "You can play <b>multiple sounds</b> simultaneously to create your own atmosphere."),
                I18n.trFor("ambientSound", "Set the <b>Sleep Timer</b> in the popout to turn off sounds after a delay.")
            ]
        }
    }

    SettingsCard {
        SectionTitle {
            id: creditsTitle
            text: I18n.trFor("ambientSound", "Credits")
            icon: "favorite"
            collapsible: true
            settingKey: "creditsExpanded"
        }

        CreditsList {
            expanded: creditsTitle.isExpanded
            items: [
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
        }
    }
}
