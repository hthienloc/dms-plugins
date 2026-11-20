import QtQuick
import qs.Common
import qs.DCommon.Widgets
import qs.Modules.Plugins
import qs.Modules.Settings.Widgets
import "./shared"

PluginSettings {
    id: root
    pluginId: "bongoCat"

    readonly property string defaultCatSkin: "classic"
    readonly property int defaultCatSizePercent: 100
    readonly property int defaultCatYOffset: 0
    readonly property string defaultPixelSkinColor: "white"
    readonly property string defaultCatColorMode: "classic"
    readonly property bool defaultClassicIdle: false
    readonly property bool defaultEnableBlinking: true
    readonly property int defaultWaitingTimeout: 5
    readonly property int defaultPawHoldTime: 0
    readonly property bool defaultDoubleSlam: true
    readonly property bool defaultMouseEnabled: false
    readonly property bool defaultShowMetrics: false
    readonly property bool defaultMetricsInBar: false
    readonly property int defaultMetricsWindowSec: 60
    readonly property bool defaultSoundEnabled: false
    readonly property string defaultSoundProfile: "bongo"
    readonly property int defaultSoundVolume: 60
    readonly property bool defaultSoundOnMouse: false
    readonly property int defaultDesktopBackgroundOpacity: 0
    readonly property bool defaultDesktopShowMetrics: false
    readonly property bool defaultShowHints: true

    property string catSkin: defaultCatSkin
    property int catSizePercent: defaultCatSizePercent
    property int catYOffset: defaultCatYOffset
    property string pixelSkinColor: defaultPixelSkinColor
    property string catColorMode: defaultCatColorMode
    property bool classicIdle: defaultClassicIdle
    property bool enableBlinking: defaultEnableBlinking
    property int waitingTimeout: defaultWaitingTimeout
    property int pawHoldTime: defaultPawHoldTime
    property bool doubleSlam: defaultDoubleSlam
    property bool mouseEnabled: defaultMouseEnabled
    property bool showMetrics: defaultShowMetrics
    property bool metricsInBar: defaultMetricsInBar
    property int metricsWindowSec: defaultMetricsWindowSec
    property bool soundEnabled: defaultSoundEnabled
    property string soundProfile: defaultSoundProfile
    property int soundVolume: defaultSoundVolume
    property bool soundOnMouse: defaultSoundOnMouse
    property int desktopBackgroundOpacity: defaultDesktopBackgroundOpacity
    property bool desktopShowMetrics: defaultDesktopShowMetrics
    property bool showHints: defaultShowHints

    function loadSettings() {
        if (!pluginService)
            return;
        catSkin = loadValue("catSkin", defaultCatSkin);
        catSizePercent = loadValue("catSizePercent", defaultCatSizePercent);
        catYOffset = loadValue("catYOffset", defaultCatYOffset);
        pixelSkinColor = loadValue("pixelSkinColor", defaultPixelSkinColor);
        catColorMode = loadValue("catColorMode", defaultCatColorMode);
        classicIdle = loadValue("classicIdle", defaultClassicIdle);
        enableBlinking = loadValue("enableBlinking", defaultEnableBlinking);
        waitingTimeout = loadValue("waitingTimeout", defaultWaitingTimeout);
        pawHoldTime = loadValue("pawHoldTime", defaultPawHoldTime);
        doubleSlam = loadValue("doubleSlam", defaultDoubleSlam);
        mouseEnabled = loadValue("mouseEnabled", defaultMouseEnabled);
        showMetrics = loadValue("showMetrics", defaultShowMetrics);
        metricsInBar = loadValue("metricsInBar", defaultMetricsInBar);
        metricsWindowSec = loadValue("metricsWindowSec", defaultMetricsWindowSec);
        soundEnabled = loadValue("soundEnabled", defaultSoundEnabled);
        soundProfile = loadValue("soundProfile", defaultSoundProfile);
        soundVolume = loadValue("soundVolume", defaultSoundVolume);
        soundOnMouse = loadValue("soundOnMouse", defaultSoundOnMouse);
        desktopBackgroundOpacity = loadValue("desktopBackgroundOpacity", defaultDesktopBackgroundOpacity);
        desktopShowMetrics = loadValue("desktopShowMetrics", defaultDesktopShowMetrics);
        showHints = loadValue("showHints", defaultShowHints);
        usageSection.expanded = loadValue("usageGuideExpanded", true);
        creditsSection.expanded = loadValue("creditsExpanded", true);
    }

    Component.onCompleted: loadSettings()
    onPluginServiceChanged: loadSettings()

    Column {
        width: parent ? parent.width : 0
        spacing: 0

        SettingsSectionLabel {
            width: parent.width
            text: I18n.trFor("bongoCat", "Appearance")
        }

        SettingsGroup {
            width: parent.width
            slotColor: SettingsMetrics.controlColor

            SettingsDropdownRow {
                text: I18n.trFor("bongoCat", "Cat Skin")
                description: I18n.trFor("bongoCat", "Choose between the classic vector font cat or the pixel doodle sprite skin.")
                options: [
                    I18n.trFor("bongoCat", "Classic (Vector)"),
                    I18n.trFor("bongoCat", "Pixel Doodle")
                ]
                optionValues: ["classic", "pixel"]
                currentValue: root.catSkin
                modified: root.catSkin !== root.defaultCatSkin
                resetByKeys: false
                onResetRequested: {
                    root.catSkin = root.defaultCatSkin;
                    root.saveValue("catSkin", root.defaultCatSkin);
                }
                onValueChanged: newValue => {
                    root.catSkin = newValue;
                    root.saveValue("catSkin", newValue);
                }
            }

            SettingsSliderRow {
                text: I18n.trFor("bongoCat", "Cat Size")
                minimum: 50
                maximum: 200
                step: 5
                unit: "%"
                value: root.catSizePercent
                modified: root.catSizePercent !== root.defaultCatSizePercent
                resetByKeys: false
                onResetRequested: {
                    root.catSizePercent = root.defaultCatSizePercent;
                    root.saveValue("catSizePercent", root.defaultCatSizePercent);
                }
                onSliderDragFinished: finalValue => {
                    root.catSizePercent = finalValue;
                    root.saveValue("catSizePercent", finalValue);
                }
            }

            SettingsSliderRow {
                text: I18n.trFor("bongoCat", "Vertical Offset")
                minimum: -10
                maximum: 10
                step: 1
                unit: "px"
                value: root.catYOffset
                modified: root.catYOffset !== root.defaultCatYOffset
                resetByKeys: false
                onResetRequested: {
                    root.catYOffset = root.defaultCatYOffset;
                    root.saveValue("catYOffset", root.defaultCatYOffset);
                }
                onSliderDragFinished: finalValue => {
                    root.catYOffset = finalValue;
                    root.saveValue("catYOffset", finalValue);
                }
            }

            SettingsDropdownRow {
                visible: root.catSkin === "pixel"
                text: I18n.trFor("bongoCat", "Cat Color")
                description: I18n.trFor("bongoCat", "Choose a color pattern for the Pixel Doodle skin.")
                options: [
                    I18n.trFor("bongoCat", "Classic White"),
                    I18n.trFor("bongoCat", "Midnight Black"),
                    I18n.trFor("bongoCat", "Ginger Orange"),
                    I18n.trFor("bongoCat", "Calico"),
                    I18n.trFor("bongoCat", "Siamese"),
                    I18n.trFor("bongoCat", "Sakura Pink"),
                    I18n.trFor("bongoCat", "Cyberpunk"),
                    I18n.trFor("bongoCat", "Zombie")
                ]
                optionValues: ["white", "black", "orange", "calico", "siamese", "pink", "cyberpunk", "zombie"]
                currentValue: root.pixelSkinColor
                modified: root.pixelSkinColor !== root.defaultPixelSkinColor
                resetByKeys: false
                onResetRequested: {
                    root.pixelSkinColor = root.defaultPixelSkinColor;
                    root.saveValue("pixelSkinColor", root.defaultPixelSkinColor);
                }
                onValueChanged: newValue => {
                    root.pixelSkinColor = newValue;
                    root.saveValue("pixelSkinColor", newValue);
                }
            }

            SettingsDropdownRow {
                visible: root.catSkin !== "pixel"
                text: I18n.trFor("bongoCat", "Cat Color")
                description: I18n.trFor("bongoCat", "Recolor the cat. Classic keeps the theme's default black and white, Primary follows the system accent, or pick a custom color.")
                options: [
                    I18n.trFor("bongoCat", "Classic B/W"),
                    I18n.trFor("bongoCat", "Theme Primary"),
                    I18n.trFor("bongoCat", "Custom")
                ]
                optionValues: ["classic", "primary", "custom"]
                currentValue: root.catColorMode
                modified: root.catColorMode !== root.defaultCatColorMode
                resetByKeys: false
                onResetRequested: {
                    root.catColorMode = root.defaultCatColorMode;
                    root.saveValue("catColorMode", root.defaultCatColorMode);
                }
                onValueChanged: newValue => {
                    root.catColorMode = newValue;
                    root.saveValue("catColorMode", newValue);
                }
            }

            ColorSettingPlus {
                id: catCustomColor
                visible: root.catSkin !== "pixel" && root.catColorMode === "custom"
                settingKey: "catCustomColor"
                label: I18n.trFor("bongoCat", "Custom Color")
                description: I18n.trFor("bongoCat", "Used when Cat Color is set to Custom.")
                defaultValue: Theme.primary
            }

            SettingsToggleRow {
                visible: root.catSkin !== "pixel"
                text: I18n.trFor("bongoCat", "Classic Color on Idle")
                description: I18n.trFor("bongoCat", "Return the cat to the classic black and white color when sleeping or idle.")
                checked: root.classicIdle
                modified: root.classicIdle !== root.defaultClassicIdle
                resetByKeys: false
                onResetRequested: {
                    root.classicIdle = root.defaultClassicIdle;
                    root.saveValue("classicIdle", root.defaultClassicIdle);
                }
                onToggled: isChecked => {
                    root.classicIdle = isChecked;
                    root.saveValue("classicIdle", isChecked);
                }
            }

            SettingsToggleRow {
                text: I18n.trFor("bongoCat", "Enable Blinking")
                checked: root.enableBlinking
                modified: root.enableBlinking !== root.defaultEnableBlinking
                resetByKeys: false
                onResetRequested: {
                    root.enableBlinking = root.defaultEnableBlinking;
                    root.saveValue("enableBlinking", root.defaultEnableBlinking);
                }
                onToggled: isChecked => {
                    root.enableBlinking = isChecked;
                    root.saveValue("enableBlinking", isChecked);
                }
            }
        }
    }

    Column {
        width: parent ? parent.width : 0
        spacing: 0

        SettingsSectionLabel {
            width: parent.width
            text: I18n.trFor("bongoCat", "Input & Behavior")
        }

        SettingsGroup {
            width: parent.width
            slotColor: SettingsMetrics.controlColor

            SettingsSliderRow {
                text: I18n.trFor("bongoCat", "Sleep Timeout")
                description: I18n.trFor("bongoCat", "Inactivity time before the cat falls asleep.")
                minimum: 1
                maximum: 10
                step: 1
                unit: "s"
                value: root.waitingTimeout
                modified: root.waitingTimeout !== root.defaultWaitingTimeout
                resetByKeys: false
                onResetRequested: {
                    root.waitingTimeout = root.defaultWaitingTimeout;
                    root.saveValue("waitingTimeout", root.defaultWaitingTimeout);
                }
                onSliderDragFinished: finalValue => {
                    root.waitingTimeout = finalValue;
                    root.saveValue("waitingTimeout", finalValue);
                }
            }

            SettingsSliderRow {
                text: I18n.trFor("bongoCat", "Paw Hold Duration")
                description: I18n.trFor("bongoCat", "How long the paws stay down after a key press (0 for instant).")
                minimum: 0
                maximum: 100
                step: 5
                unit: "ms"
                value: root.pawHoldTime
                modified: root.pawHoldTime !== root.defaultPawHoldTime
                resetByKeys: false
                onResetRequested: {
                    root.pawHoldTime = root.defaultPawHoldTime;
                    root.saveValue("pawHoldTime", root.defaultPawHoldTime);
                }
                onSliderDragFinished: finalValue => {
                    root.pawHoldTime = finalValue;
                    root.saveValue("pawHoldTime", finalValue);
                }
            }

            SettingsToggleRow {
                text: I18n.trFor("bongoCat", "Space/Enter Double Slam")
                description: I18n.trFor("bongoCat", "Pressing Space or Enter triggers both paws to slam the table.")
                checked: root.doubleSlam
                modified: root.doubleSlam !== root.defaultDoubleSlam
                resetByKeys: false
                onResetRequested: {
                    root.doubleSlam = root.defaultDoubleSlam;
                    root.saveValue("doubleSlam", root.defaultDoubleSlam);
                }
                onToggled: isChecked => {
                    root.doubleSlam = isChecked;
                    root.saveValue("doubleSlam", isChecked);
                }
            }

            SettingsToggleRow {
                text: I18n.trFor("bongoCat", "Mouse Interaction")
                description: I18n.trFor("bongoCat", "Paws react to mouse input: left and right click hold the matching paw, other buttons slam both, scrolling drums with alternating paws.")
                checked: root.mouseEnabled
                modified: root.mouseEnabled !== root.defaultMouseEnabled
                resetByKeys: false
                onResetRequested: {
                    root.mouseEnabled = root.defaultMouseEnabled;
                    root.saveValue("mouseEnabled", root.defaultMouseEnabled);
                }
                onToggled: isChecked => {
                    root.mouseEnabled = isChecked;
                    root.saveValue("mouseEnabled", isChecked);
                }
            }

            SettingsToggleRow {
                text: I18n.trFor("bongoCat", "Show Typing Metrics")
                description: I18n.trFor("bongoCat", "Display live typing speed (WPM) and correction rate in the popout. Only keystroke timing is counted; no key contents are stored.")
                checked: root.showMetrics
                modified: root.showMetrics !== root.defaultShowMetrics
                resetByKeys: false
                onResetRequested: {
                    root.showMetrics = root.defaultShowMetrics;
                    root.saveValue("showMetrics", root.defaultShowMetrics);
                }
                onToggled: isChecked => {
                    root.showMetrics = isChecked;
                    root.saveValue("showMetrics", isChecked);
                }
            }

            SettingsToggleRow {
                visible: root.showMetrics
                text: I18n.trFor("bongoCat", "Show Metrics in Bar")
                description: I18n.trFor("bongoCat", "Also show WPM and correction rate next to the cat in the bar.")
                checked: root.metricsInBar
                modified: root.metricsInBar !== root.defaultMetricsInBar
                resetByKeys: false
                onResetRequested: {
                    root.metricsInBar = root.defaultMetricsInBar;
                    root.saveValue("metricsInBar", root.defaultMetricsInBar);
                }
                onToggled: isChecked => {
                    root.metricsInBar = isChecked;
                    root.saveValue("metricsInBar", isChecked);
                }
            }

            SettingsSliderRow {
                visible: root.showMetrics
                text: I18n.trFor("bongoCat", "Measurement Window")
                description: I18n.trFor("bongoCat", "Time span the speed and correction rate are averaged over.")
                minimum: 5
                maximum: 120
                step: 5
                unit: "s"
                value: root.metricsWindowSec
                modified: root.metricsWindowSec !== root.defaultMetricsWindowSec
                resetByKeys: false
                onResetRequested: {
                    root.metricsWindowSec = root.defaultMetricsWindowSec;
                    root.saveValue("metricsWindowSec", root.defaultMetricsWindowSec);
                }
                onSliderDragFinished: finalValue => {
                    root.metricsWindowSec = finalValue;
                    root.saveValue("metricsWindowSec", finalValue);
                }
            }
        }
    }

    Column {
        width: parent ? parent.width : 0
        spacing: 0

        SettingsSectionLabel {
            width: parent.width
            text: I18n.trFor("bongoCat", "Sounds")
        }

        SettingsGroup {
            width: parent.width
            slotColor: SettingsMetrics.controlColor

            SettingsToggleRow {
                text: I18n.trFor("bongoCat", "Enable Sounds")
                description: I18n.trFor("bongoCat", "Play a soft key-click sound as you type.")
                checked: root.soundEnabled
                modified: root.soundEnabled !== root.defaultSoundEnabled
                resetByKeys: false
                onResetRequested: {
                    root.soundEnabled = root.defaultSoundEnabled;
                    root.saveValue("soundEnabled", root.defaultSoundEnabled);
                }
                onToggled: isChecked => {
                    root.soundEnabled = isChecked;
                    root.saveValue("soundEnabled", isChecked);
                }
            }

            SettingsDropdownRow {
                visible: root.soundEnabled
                text: I18n.trFor("bongoCat", "Sound Profile")
                description: I18n.trFor("bongoCat", "Choose the type of key-click sound.")
                options: [
                    I18n.trFor("bongoCat", "Bongo"),
                    I18n.trFor("bongoCat", "Pop")
                ]
                optionValues: ["bongo", "pop"]
                currentValue: root.soundProfile
                modified: root.soundProfile !== root.defaultSoundProfile
                resetByKeys: false
                onResetRequested: {
                    root.soundProfile = root.defaultSoundProfile;
                    root.saveValue("soundProfile", root.defaultSoundProfile);
                }
                onValueChanged: newValue => {
                    root.soundProfile = newValue;
                    root.saveValue("soundProfile", newValue);
                }
            }

            SettingsSliderRow {
                visible: root.soundEnabled
                text: I18n.trFor("bongoCat", "Volume")
                minimum: 0
                maximum: 100
                step: 5
                unit: "%"
                value: root.soundVolume
                modified: root.soundVolume !== root.defaultSoundVolume
                resetByKeys: false
                onResetRequested: {
                    root.soundVolume = root.defaultSoundVolume;
                    root.saveValue("soundVolume", root.defaultSoundVolume);
                }
                onSliderDragFinished: finalValue => {
                    root.soundVolume = finalValue;
                    root.saveValue("soundVolume", finalValue);
                }
            }

            SettingsToggleRow {
                visible: root.soundEnabled && root.mouseEnabled
                text: I18n.trFor("bongoCat", "Mouse Clicks")
                description: I18n.trFor("bongoCat", "Also play a click on mouse buttons.")
                checked: root.soundOnMouse
                modified: root.soundOnMouse !== root.defaultSoundOnMouse
                resetByKeys: false
                onResetRequested: {
                    root.soundOnMouse = root.defaultSoundOnMouse;
                    root.saveValue("soundOnMouse", root.defaultSoundOnMouse);
                }
                onToggled: isChecked => {
                    root.soundOnMouse = isChecked;
                    root.saveValue("soundOnMouse", isChecked);
                }
            }
        }
    }

    Column {
        width: parent ? parent.width : 0
        spacing: 0

        SettingsSectionLabel {
            width: parent.width
            text: I18n.trFor("bongoCat", "Setup")
        }

        SettingsGroup {
            width: parent.width
            slotColor: SettingsMetrics.controlColor

            SettingsNoteRow {
                noteIconName: "info"
                tint: Theme.primary
                tintBackground: Theme.withAlpha(Theme.primary, 0.08)
                text: I18n.trFor("bongoCat", "Add your user to the 'input' group to detect keyboard activity:")
            }

            Column {
                width: parent.width
                spacing: Theme.spacingS

                Repeater {
                    model: [
                        { cmd: "sudo usermod -aG input $USER", label: I18n.trFor("bongoCat", "Add to input group") }
                    ]

                    delegate: CopyBox {
                        required property var modelData
                        label: modelData.label
                        text: modelData.cmd
                    }
                }
            }

            SettingsNoteRow {
                noteIconName: "info"
                tint: Theme.primary
                tintBackground: Theme.withAlpha(Theme.primary, 0.08)
                text: I18n.trFor("bongoCat", "After running the command, logout and login again for changes to take effect.")
            }
        }
    }

    Column {
        width: parent ? parent.width : 0
        spacing: 0

        SettingsSectionLabel {
            width: parent.width
            text: I18n.trFor("bongoCat", "Desktop Widget")
        }

        SettingsGroup {
            width: parent.width
            slotColor: SettingsMetrics.controlColor

            SettingsSliderRow {
                text: I18n.trFor("bongoCat", "Background Opacity")
                description: I18n.trFor("bongoCat", "Adjust transparency of the desktop widget card.")
                minimum: 0
                maximum: 100
                step: 5
                unit: "%"
                value: root.desktopBackgroundOpacity
                modified: root.desktopBackgroundOpacity !== root.defaultDesktopBackgroundOpacity
                resetByKeys: false
                onResetRequested: {
                    root.desktopBackgroundOpacity = root.defaultDesktopBackgroundOpacity;
                    root.saveValue("desktopBackgroundOpacity", root.defaultDesktopBackgroundOpacity);
                }
                onSliderDragFinished: finalValue => {
                    root.desktopBackgroundOpacity = finalValue;
                    root.saveValue("desktopBackgroundOpacity", finalValue);
                }
            }

            SettingsToggleRow {
                text: I18n.trFor("bongoCat", "Show Typing Metrics")
                description: I18n.trFor("bongoCat", "Display live WPM and accuracy underneath the cat on the desktop.")
                checked: root.desktopShowMetrics
                modified: root.desktopShowMetrics !== root.defaultDesktopShowMetrics
                resetByKeys: false
                onResetRequested: {
                    root.desktopShowMetrics = root.defaultDesktopShowMetrics;
                    root.saveValue("desktopShowMetrics", root.defaultDesktopShowMetrics);
                }
                onToggled: isChecked => {
                    root.desktopShowMetrics = isChecked;
                    root.saveValue("desktopShowMetrics", isChecked);
                }
            }
        }
    }

    Column {
        width: parent ? parent.width : 0
        spacing: 0

        SettingsSectionLabel {
            width: parent.width
            text: I18n.trFor("bongoCat", "Behavior")
        }

        SettingsGroup {
            width: parent.width
            slotColor: SettingsMetrics.controlColor

            SettingsToggleRow {
                text: I18n.trFor("bongoCat", "Show Hints")
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
            text: I18n.trFor("bongoCat", "Usage Guide")
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
                        I18n.trFor("bongoCat", "<b>Left-click</b> the cat to open the settings popout."),
                        I18n.trFor("bongoCat", "<b>Right-click</b> the cat to manually toggle <b>Sleep Mode</b>."),
                        I18n.trFor("bongoCat", "The cat will automatically tap its paws as you type.")
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
            text: I18n.trFor("bongoCat", "Credits")
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
                        author: "@StrayRogue",
                        url: "https://x.com/StrayRogue",
                        role: I18n.trFor("bongoCat", "Creator of the original Bongo Cat artwork."),
                        icon: "brush"
                    },
                    {
                        author: "StrawberryMatchaArt",
                        url: "https://www.etsy.com/shop/StrawberryMatchaArt",
                        role: I18n.trFor("bongoCat", "Creator of the Pixel Doodle Bongo Cat artwork."),
                        icon: "palette"
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
