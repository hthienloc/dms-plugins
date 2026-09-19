import QtQuick
import QtQuick.Controls
import Quickshell.Io
import qs.Common
import qs.Services
import qs.Widgets
import qs.Modules.Plugins
import qs.Modals.FileBrowser
import "./dms-common"

PluginComponent {
    id: pluginRoot

    popoutWidth: 800
    popoutHeight: (pluginData.showHints ?? true) ? 660 : 600

    pillRightClickAction: () => {
        const showPopout = pluginData.showPopoutOnRightClick ?? true;
        if (showPopout) pluginRoot.triggerPopout();
        pluginRoot.scanFromClipboard();
    }

    property string resultText: ""
    property bool isScanning: false
    property bool isSaving: false
    property bool isAutoScanning: false
    property string sourceImage: ""
    property int imageTrigger: 0
    property int lastScanTime: 0

    function scanFromClipboard() {
        if (isScanning || isAutoScanning) return;
        
        const now = Date.now();
        if (now - lastScanTime < 2000) return;
        lastScanTime = now;

        const tempImage = "/tmp/dms_ocr_input.png";
        const getClipCmd = "wl-paste -t image/png > " + tempImage + " 2>/dev/null";

        Proc.runCommand(
            "get-clipboard-image",
            ["sh", "-c", getClipCmd],
            (stdout, exitCode) => {
                if (exitCode === 0) {
                    const checkCmd = "file --mime-type -b " + tempImage + " | grep -q image && echo HAS_IMAGE";
                    Proc.runCommand(
                        "check-image-type",
                        ["sh", "-c", checkCmd],
                        (checkOut, checkCode) => {
                            if (checkCode === 0 && checkOut.trim() === "HAS_IMAGE") {
                                isScanning = true;
                                isAutoScanning = true;
                                runTesseract(tempImage, true);
                            } else {
                                ToastService.showError("No image found in clipboard!");
                            }
                        },
                        0
                    );
                } else {
                    ToastService.showError("No image found in clipboard!");
                }
            },
            0
        );
    }

    function scanFromScreenshot() {
        isScanning = true;
        const tempPath = "/tmp/dms_ocr_screenshot.png";

        Proc.runCommand(
            "screenshot-ocr",
            ["dms", "screenshot", "region", "--no-confirm", "--no-notify", "--dir", "/tmp", "--filename", "dms_ocr_screenshot.png"],
            (stdout, exitCode) => {
                if (exitCode === 0) {
                    sourceImage = tempPath;
                    imageTrigger++;
                    runTesseract(tempPath);
                    pluginRoot.triggerPopout();
                } else {
                    isScanning = false;
                    ToastService.showError("Failed to take screenshot or selection cancelled.");
                }
            },
            0
        );
    }

    function selectFileAndScan() {
        pluginRoot.closePopout();
        fileBrowserModal.open();
    }

    function scanFromUrl(url) {
        if (!url || isScanning) return;
        
        const convertSvgToPng = function(inputPath, callback) {
            const outputPath = "/tmp/dms_ocr_svg_" + Date.now() + ".png";
            Proc.runCommand(
                "svg-convert",
                ["rsvg-convert", "-w", "2000", "-h", "2000", "-f", "png", "-o", outputPath, inputPath],
                (stdout, exitCode) => {
                    if (exitCode === 0) {
                        callback(outputPath);
                    } else {
                        Proc.runCommand(
                            "svg-convert-fallback",
                            ["convert", "-background", "white", "-alpha", "remove", inputPath, outputPath],
                            (stdout2, exitCode2) => {
                                if (exitCode2 === 0) {
                                    callback(outputPath);
                                } else {
                                    callback(null);
                                }
                            },
                            0
                        );
                    }
                },
                0
            );
        };

        const processImage = function(path) {
            if (path.toLowerCase().endsWith(".svg")) {
                convertSvgToPng(path, function(convertedPath) {
                    if (convertedPath) {
                        sourceImage = convertedPath;
                        imageTrigger++;
                        isScanning = true;
                        runTesseract(convertedPath);
                    } else {
                        ToastService.showError("Failed to convert SVG to PNG. Install rsvg-convert or imagemagick.");
                    }
                });
            } else {
                sourceImage = path;
                imageTrigger++;
                isScanning = true;
                runTesseract(path);
            }
        };

        if (url.startsWith("file://")) {
            processImage(url.substring(7));
        } else if (url.startsWith("http://") || url.startsWith("https://")) {
            const tempFile = "/tmp/dms_ocr_dl_" + Date.now();
            Proc.runCommand("download-image", ["curl", "-L", url, "-o", tempFile], (stdout, exitCode) => {
                if (exitCode === 0) {
                    processImage(tempFile);
                } else {
                    ToastService.showError("Failed to download image from URL.");
                }
            });
        } else if (url.startsWith("/")) {
            processImage(url);
        } else {
            ToastService.showError("Invalid image source.");
        }
    }

    function runTesseract(imagePath, skipAutoCopy) {
        if (imagePath.includes("/tmp/dms_ocr_input.png")) {
            sourceImage = imagePath;
            imageTrigger++;
        }

        let lang = pluginService.loadPluginData(pluginRoot.pluginId, "ocrLanguage", "eng");
        if (!lang || lang === "") lang = "eng";
        const tesseractCmd = "tesseract '" + imagePath + "' - -l " + lang;

        Proc.runCommand(
            "run-tesseract",
            ["sh", "-c", tesseractCmd],
            (stdout, exitCode) => {
                isScanning = false;
                isAutoScanning = false;
                if (exitCode === 0) {
                    const result = stdout.trim();
                    if (result === "") {
                        ToastService.showInfo("No text detected.");
                    } else {
                        resultText = result;
                        ToastService.showInfo("Scan complete!");
                        if (!skipAutoCopy && (pluginData.autoCopy ?? true)) {
                            copyToClipboard(result);
                        }
                    }
                } else {
                    if (stdout && stdout.includes("Invalid")) {
                        ToastService.showError("Invalid or unsupported image format.");
                    } else if (stdout && stdout.includes("read")) {
                        ToastService.showError("Could not read the file. Make sure it's a valid image.");
                    } else {
                        ToastService.showError("Tesseract failed. Is it installed?");
                    }
                }
            },
            0
        );
    }

    function copyToClipboard(text) {
        if (!text) return;
        DMSService.sendRequest("clipboard.copy", { "text": text }, function(response) {
            if (!response.error) {
                ToastService.showInfo("Copied to clipboard!");
            }
        });
    }

    function saveResultToFile() {
        if (!resultText) return;
        isSaving = true;
        pluginRoot.closePopout();
        saveBrowserModal.open();
    }

    horizontalBarPill: Component {
        Item {
            implicitWidth: horizontalRow.implicitWidth
            implicitHeight: Theme.iconSize
            anchors.verticalCenter: parent.verticalCenter

            property bool draggingOver: false

            Row {
                id: horizontalRow
                spacing: Theme.spacingXS
                anchors.verticalCenter: parent.verticalCenter
                scale: draggingOver ? 1.2 : 1.0
                Behavior on scale { NumberAnimation { duration: 200; easing.type: Easing.OutBack } }

                DankIcon {
                    name: "document_scanner"
                    size: Theme.iconSizeSmall
                    color: draggingOver ? Theme.primary : (pluginRoot.isScanning ? Theme.primary : Theme.surfaceVariantText)
                    anchors.verticalCenter: parent.verticalCenter
                }
            }

            DropArea {
                anchors.fill: parent
                onEntered: draggingOver = true
                onExited: draggingOver = false
                onDropped: (drop) => {
                    draggingOver = false;
                    let urls = [];
                    if (drop.hasUrls) {
                        urls = drop.urls.map(url => url.toString());
                    } else if (drop.hasText) {
                        urls = [drop.text];
                    }
                    pluginRoot.triggerPopout();
                    if (urls.length > 0) {
                        urls.forEach(url => pluginRoot.scanFromUrl(url));
                    }
                }
            }

            MouseArea {
                anchors.fill: parent
                acceptedButtons: Qt.MiddleButton
                cursorShape: Qt.PointingHandCursor
                onClicked: (mouse) => {
                    if (mouse.button === Qt.MiddleButton) {
                        pluginRoot.scanFromScreenshot();
                    }
                }
            }
        }
    }

    FileBrowserModal {
        id: fileBrowserModal
        browserTitle: "Select Image to Scan"
        browserIcon: "image"
        fileExtensions: ["*.png", "*.jpg", "*.jpeg", "*.webp", "*.bmp"]
        onFileSelected: path => {
            pluginRoot.isScanning = true;
            pluginRoot.sourceImage = path;
            pluginRoot.imageTrigger++;
            pluginRoot.runTesseract(path);
            close();
        }
        onDialogClosed: {
            pluginRoot.triggerPopout();
        }
    }

    FileBrowserModal {
        id: saveBrowserModal
        browserTitle: "Save OCR Result"
        browserIcon: "save"
        saveMode: true
        defaultFileName: "ocr_result.txt"
        fileExtensions: ["*.txt"]
        onFileSelected: filePath => {
            isSaving = true;
            
            let cleanPath = filePath;
            if (cleanPath.startsWith("file://")) {
                cleanPath = cleanPath.substring(7);
            } else if (cleanPath.startsWith("file: ")) {
                cleanPath = cleanPath.substring(6);
            }
            
            Proc.runCommand(
                "write-file",
                ["sh", "-c", "printf '%s' \"$1\" > \"$2\"", "sh", resultText, cleanPath],
                (stdout, exitCode) => {
                    isSaving = false;
                    if (exitCode === 0) {
                        ToastService.showInfo("Saved successfully!");
                    } else {
                        ToastService.showError("Failed to save: " + exitCode);
                    }
                },
                0
            );
            close();
        }
        onDialogClosed: isSaving = false
    }

    verticalBarPill: horizontalBarPill

    popoutContent: Component {
        PopoutComponent {
            id: popout
            width: parent ? parent.width : 0
            headerText: "OCR Scanner"
            detailsText: pluginRoot.isScanning ? "Processing..." : "Ready to scan"
            showCloseButton: true
            focus: true

            property var parentPopout: null

            Component.onDestruction: {
                if (!pluginRoot.isSaving && pluginRoot.pluginData && !(pluginRoot.pluginData.keepResults ?? true)) {
                    resultText = "";
                    sourceImage = "";
                }
            }

            DankFlickable {
                width: parent.width
                height: Math.min(contentHeight, pluginRoot.popoutHeight - popout.headerHeight - popout.detailsHeight - Theme.spacingM)
                contentHeight: contentColumn.implicitHeight
                contentWidth: width
                clip: true

                Column {
                    id: contentColumn
                    width: parent.width
                    spacing: Theme.spacingM

                    HintSection {
                        showHints: (pluginData.showHints ?? true)
                        width: parent.width

                        HintItem {
                            icon: "file_download"
                            text: I18n.tr("Drop an image or URL onto the pill icon to scan it instantly")
                        }
                        HintItem {
                            icon: "mouse"
                            text: I18n.tr("Right-click to scan clipboard, Middle-click to scan screenshot")
                        }
                    }

                    Row {
                        width: parent.width
                        spacing: Theme.spacingM

                        Column {
                            width: (parent.width - Theme.spacingM) / 2
                            spacing: Theme.spacingM

                            StyledRect {
                                width: parent.width
                                height: 380
                                radius: Theme.cornerRadius
                                color: Theme.surfaceContainer
                                border.color: Theme.outlineVariant
                                border.width: 1
                                clip: true

                                Image {
                                    id: sourceImg
                                    anchors.fill: parent
                                    anchors.margins: Theme.spacingM
                                    fillMode: Image.PreserveAspectFit
                                    asynchronous: true
                                    source: pluginRoot.sourceImage ? "file://" + pluginRoot.sourceImage + "?t=" + pluginRoot.imageTrigger : ""

                                    StyledText {
                                        anchors.centerIn: parent
                                        text: I18n.tr("No image scanned yet")
                                        color: Theme.outlineVariant
                                        visible: sourceImg.status !== Image.Ready && !pluginRoot.isScanning
                                        font.pixelSize: Theme.fontSizeMedium
                                    }
                                }

                                DankButton {
                                    anchors.top: parent.top
                                    anchors.right: parent.right
                                    anchors.margins: Theme.spacingS
                                    width: 32
                                    height: 32
                                    iconName: "delete"
                                    onClicked: {
                                        pluginRoot.sourceImage = ""
                                        pluginRoot.resultText = ""
                                    }
                                    enabled: (pluginRoot.sourceImage !== "" || pluginRoot.resultText !== "") && !pluginRoot.isScanning
                                    backgroundColor: Theme.errorContainer
                                    textColor: Theme.error
                                }
                            }

                            Row {
                                width: parent.width
                                spacing: Theme.spacingS

                                DankButton {
                                    text: I18n.tr("Scan Clipboard")
                                    width: (parent.width - Theme.spacingS) / 2
                                    iconName: "content_paste"
                                    onClicked: pluginRoot.scanFromClipboard()
                                    enabled: !pluginRoot.isScanning
                                    backgroundColor: Theme.primaryContainer
                                    textColor: Theme.primary
                                }

                                DankButton {
                                    text: I18n.tr("Select File")
                                    width: (parent.width - Theme.spacingS) / 2
                                    iconName: "image"
                                    onClicked: pluginRoot.selectFileAndScan()
                                    enabled: !pluginRoot.isScanning
                                    backgroundColor: Theme.surfaceContainerHighest
                                    textColor: Theme.surfaceText
                                }
                            }
                        }

                        Column {
                            width: (parent.width - Theme.spacingM) / 2
                            spacing: Theme.spacingM

                            StyledRect {
                                width: parent.width
                                height: 380
                                radius: Theme.cornerRadius
                                color: Theme.surfaceContainer
                                border.color: pluginRoot.isScanning ? Theme.primary : Theme.outlineVariant
                                border.width: 1

                                DankFlickable {
                                    anchors.fill: parent
                                    anchors.margins: Theme.spacingM
                                    contentWidth: width - (Theme.spacingM * 2)
                                    contentHeight: resultArea.implicitHeight
                                    clip: true

                                    TextEdit {
                                        id: resultArea
                                        width: parent.width
                                        text: pluginRoot.resultText
                                        wrapMode: TextEdit.Wrap
                                        font.pixelSize: Theme.fontSizeMedium
                                        color: Theme.surfaceText
                                        selectByMouse: true
                                        onTextChanged: pluginRoot.resultText = text

                                        Text {
                                            text: I18n.tr("Text will appear here...")
                                            color: Theme.outlineVariant
                                            visible: resultArea.text === ""
                                            font: resultArea.font
                                        }
                                    }
                                }
                            }

                            Row {
                                width: parent.width
                                spacing: Theme.spacingS

                                DankButton {
                                    text: I18n.tr("Copy Text")
                                    width: (parent.width - Theme.spacingS) / 2
                                    iconName: "content_copy"
                                    onClicked: pluginRoot.copyToClipboard(pluginRoot.resultText)
                                    enabled: pluginRoot.resultText !== "" && !pluginRoot.isScanning
                                    backgroundColor: Theme.primaryContainer
                                    textColor: Theme.primary
                                }

                                DankButton {
                                    text: I18n.tr("Save Text")
                                    width: (parent.width - Theme.spacingS) / 2
                                    iconName: "save"
                                    onClicked: pluginRoot.saveResultToFile()
                                    enabled: pluginRoot.resultText !== "" && !pluginRoot.isScanning
                                    backgroundColor: Theme.surfaceContainerHighest
                                    textColor: Theme.surfaceText
                                }
                            }
                        }
                    }
                }
            }
        }
    }

}
