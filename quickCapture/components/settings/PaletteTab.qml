import QtQuick
import qs.Common
import qs.DCommon.Widgets
import qs.Modules.Settings.Widgets
import "../core/Defaults.js" as Defaults

Column {
    id: root

    property QtObject config: null
    property var settings: null

    width: parent ? parent.width : 0
    spacing: Theme.spacingM

    property string color_palette_preset: Defaults.values.color_palette_preset
    property string registry_theme_variant: Defaults.values.registry_theme_variant
    property string catppuccin_variant: Defaults.values.catppuccin_variant

    readonly property bool customPalette: color_palette_preset === "custom"
    readonly property bool registryPalette: !["adaptive", "classic", "custom", "catppuccin"].includes(color_palette_preset)

    function slotOverride(index) {
        if (root.customPalette || !root.config)
            return null;
        if (root.color_palette_preset !== "adaptive")
            return root.config.defaultAccentColors[index];
        return index === 0 ? Theme.primary : root.config.adaptiveColors[index - 1];
    }

    function loadValue() {
        if (!settings)
            return;
        color_palette_preset = settings.loadValue("color_palette_preset", Defaults.values.color_palette_preset);
        registry_theme_variant = settings.loadValue("registry_theme_variant", Defaults.values.registry_theme_variant);
        catppuccin_variant = settings.loadValue("catppuccin_variant", Defaults.values.catppuccin_variant);
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
            text: I18n.trFor("quickCapture", "Toolbar Palette")
        }

        SettingsGroup {
            width: parent.width
            slotColor: SettingsMetrics.controlColor

            SettingsNoteRow {
                noteIconName: "info"
                tint: Theme.primary
                tintBackground: Theme.withAlpha(Theme.primary, 0.08)
                text: I18n.trFor("quickCapture", "Pick a palette preset or customize individual color slots.")
            }

            SettingsDropdownRow {
                text: I18n.trFor("quickCapture", "Palette Preset")
                options: [
                    I18n.trFor("quickCapture", "Adaptive"),
                    "Classic (Tailwind)",
                    "Nord",
                    "Dracula",
                    "Gruvbox Material",
                    "Catppuccin",
                    "Everforest",
                    "Rosé Pine",
                    "Kanagawa",
                    "Tokyo Night",
                    "Synthwave Electric",
                    "Dank Violet",
                    I18n.trFor("quickCapture", "Custom")
                ]
                optionValues: [
                    "adaptive",
                    "classic",
                    "nord",
                    "dracula",
                    "gruvbox",
                    "catppuccin",
                    "everforest",
                    "rosePine",
                    "kanagawaWl",
                    "tokyoNight",
                    "synthwaveElectric",
                    "dankViolet",
                    "custom"
                ]
                currentValue: root.color_palette_preset
                modified: root.color_palette_preset !== Defaults.values.color_palette_preset
                resetByKeys: false
                onResetRequested: {
                    root.color_palette_preset = Defaults.values.color_palette_preset;
                    root.save("color_palette_preset", Defaults.values.color_palette_preset);
                }
                onValueChanged: val => {
                    root.color_palette_preset = val;
                    root.save("color_palette_preset", val);
                }
            }

            SettingsButtonGroupRow {
                visible: root.registryPalette
                text: I18n.trFor("quickCapture", "Variant")
                model: [
                    I18n.trFor("quickCapture", "Dark"),
                    I18n.trFor("quickCapture", "Light")
                ]
                values: ["dark", "light"]
                value: root.registry_theme_variant
                modified: root.registry_theme_variant !== Defaults.values.registry_theme_variant
                resetByKeys: false
                onResetRequested: {
                    root.registry_theme_variant = Defaults.values.registry_theme_variant;
                    root.save("registry_theme_variant", Defaults.values.registry_theme_variant);
                }
                onValueSelected: val => {
                    root.registry_theme_variant = val;
                    root.save("registry_theme_variant", val);
                }
            }

            SettingsDropdownRow {
                visible: root.color_palette_preset === "catppuccin"
                text: I18n.trFor("quickCapture", "Variant")
                options: ["Latte", "Frappé", "Macchiato", "Mocha"]
                optionValues: ["latte", "frappe", "macchiato", "mocha"]
                currentValue: root.catppuccin_variant
                modified: root.catppuccin_variant !== Defaults.values.catppuccin_variant
                resetByKeys: false
                onResetRequested: {
                    root.catppuccin_variant = Defaults.values.catppuccin_variant;
                    root.save("catppuccin_variant", Defaults.values.catppuccin_variant);
                }
                onValueChanged: val => {
                    root.catppuccin_variant = val;
                    root.save("catppuccin_variant", val);
                }
            }

            Item {
                width: parent.width
                height: slotsGrid.implicitHeight + Theme.spacingM * 2

                Grid {
                    id: slotsGrid
                    anchors.left: parent.left
                    anchors.right: parent.right
                    anchors.verticalCenter: parent.verticalCenter
                    anchors.margins: Theme.spacingM
                    columns: 4
                    rowSpacing: Theme.spacingM
                    columnSpacing: Theme.spacingM

                    Repeater {
                        model: 8

                        delegate: CompactColorSetting {
                            required property int index
                            settingKey: index === 0 ? "toolbar_color_primary" : "toolbar_color_" + (index - 1)
                            label: I18n.trFor("quickCapture", "Slot %1").arg(index + 1)
                            defaultValue: index === 0 ? "primary" : (root.config ? root.config.adaptiveColors[index - 1] : "#ffffff")
                            readOnly: !root.customPalette
                            overrideColor: root.slotOverride(index)
                        }
                    }
                }
            }
        }
    }
}
