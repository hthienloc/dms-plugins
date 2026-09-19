import QtQuick
import qs.Common
import qs.Modules.Plugins
import "./dms-common"

PluginSettings {
    id: root
    pluginId: "activateLinux"

    SettingsCard {
        id: appearanceSection
        SectionTitle { 
            text: I18n.tr("Appearance")
            icon: "palette" 
            showReset: watermarkOpacity.isDirty || firstLineSize.isDirty || secondLineSize.isDirty
            onResetClicked: {
                watermarkOpacity.resetToDefault();
                firstLineSize.resetToDefault();
                secondLineSize.resetToDefault();
            }
        }

        SliderSettingPlus {
            id: watermarkOpacity
            settingKey: "watermarkOpacity"
            label: I18n.tr("Opacity")
            description: I18n.tr("Adjust the transparency of the watermark.")
            defaultValue: 40
            minimum: 0
            maximum: 100
            unit: "%"
            leftLabel: "0%"
            rightLabel: "100%"
        }

        Separator {}

        SliderSettingPlus {
            id: firstLineSize
            settingKey: "firstLineSize"
            label: I18n.tr("First Line Font Size")
            defaultValue: 22
            minimum: 8
            maximum: 72
            leftLabel: "8"
            rightLabel: "72"
        }

        Separator {}

        SliderSettingPlus {
            id: secondLineSize
            settingKey: "secondLineSize"
            label: I18n.tr("Second Line Font Size")
            defaultValue: 14
            minimum: 8
            maximum: 48
            leftLabel: "8"
            rightLabel: "48"
        }
    }

    SettingsCard {
        id: customizationSection
        SectionTitle { 
            text: I18n.tr("Customization")
            icon: "edit" 
            showReset: customizeText.isDirty || firstLine.isDirty || secondLine.isDirty
            onResetClicked: {
                customizeText.resetToDefault();
                firstLine.resetToDefault();
                secondLine.resetToDefault();
            }
        }

        ToggleSettingPlus {
            id: customizeText
            settingKey: "customizeText"
            label: I18n.tr("Customize Text")
            description: I18n.tr("Enable manual override for the watermark text.")
            defaultValue: false
        }

        Separator { visible: customizeText.value }

        StringSettingPlus {
            id: firstLine
            settingKey: "firstLine"
            label: I18n.tr("First Line")
            defaultValue: "Activate Linux"
            visible: customizeText.value
        }

        Separator { visible: customizeText.value }

        StringSettingPlus {
            id: secondLine
            settingKey: "secondLine"
            label: I18n.tr("Second Line")
            defaultValue: "Go to Settings to activate Linux."
            visible: customizeText.value
        }
    }

    SettingsCard {
        SectionTitle { 
            id: usageTitle
            text: I18n.tr("Usage Guide")
            icon: "menu_book" 
            collapsible: true
            settingKey: "usageGuideExpanded"
        }

        UsageGuide {
            expanded: usageTitle.isExpanded
            items: [
                I18n.tr("This plugin displays a non-intrusive watermark on your desktop."),
                I18n.tr("Enable <b>Customize Text</b> to override the default message."),
                I18n.tr("You can adjust <b>font sizes</b> and <b>opacity</b> to match your background.")
            ]
        }
    }

    PluginAbout {
        repoUrl: "https://github.com/hthienloc/dms-activate-linux"
    }
}
