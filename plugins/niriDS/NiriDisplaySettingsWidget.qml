import QtQuick
import Quickshell
import qs.Common
import qs.Services
import qs.Modules.Plugins
import "."

PluginComponent {
    id: root
    pluginId: "niriDS"
    pluginService: PluginService

    // Control Center Integration
    ccWidgetIcon: "computer"
    ccWidgetPrimaryText: "Display Settings"
    ccWidgetSecondaryText: {
        const displays = NiriDS.displays || [];
        const enabledCount = displays.filter(d => !d.disabled).length;
        return enabledCount + " active display" + (enabledCount === 1 ? "" : "s");
    }
    ccWidgetIsActive: NiriDS.modalVisible

    onCcWidgetToggled: {
        root.toggleMenu();
    }

    Connections {
        target: NiriDS
        function onModalVisibleChanged() {
            if (NiriDS.modalVisible) {
                NiriDS.setDisplays();
                NiriDS.modal?.openCentered();
            } else {
                NiriDS.modal?.close();
            }
        }
    }

    function toggleMenu() {
        if (NiriDS.modalVisible) {
            NiriDS.modal?.close();
            NiriDS.modalVisible = false;
        } else {
            NiriDS.setDisplays();
            NiriDS.modal?.openCentered();
            NiriDS.modalVisible = true;
        }
    }
}