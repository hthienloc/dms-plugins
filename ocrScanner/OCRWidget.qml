import QtQuick
import QtQuick.Controls
import Quickshell.Io
import qs.Common
import qs.Services
import qs.DCommon.Widgets
import qs.Modules.Plugins
import qs.Modals.FileBrowser
import "./shared"

PluginComponent {
    id: pluginRoot

    popoutWidth: 780
    popoutHeight: 0 // auto from content

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
    property var pendingPopoutAction: null

    property bool isTemporaryAction: false

    Timer {
        id: popoutCloseTimer
        interval: Math.max(50, (Theme.popoutAnimationDuration ?? 200) + 50)
        onTriggered: {
            const action = pluginRoot.pendingPopoutAction;
            pluginRoot.pendingPopoutAction = null;
            if (action) action();
        }
    }

    function runAfterPopoutClosed(action) {
        pluginRoot.isTemporaryAction = true;
        pluginRoot.pendingPopoutAction = action;
        pluginRoot.closePopout();
        popoutCloseTimer.restart();
    }

    readonly property string cacheDir: {
        const base = Paths.xdgCache ? Paths.strip(Paths.xdgCache) : Paths.expandTilde("~/.cache");
        return base + "/dms-ocr";
    }

    Component.onCompleted: {
        Proc.runCommand("ocr-init-dir", ["mkdir", "-p", cacheDir], null, 0);
    }

    function scanFromClipboard() {
        if (isScanning || isAutoScanning) return;
        
        const now = Date.now();
        if (now - lastScanTime < 2000) return;
        lastScanTime = now;

        const tempImage = cacheDir + "/dms_ocr_input.png";

        Proc.runCommand(
            "get-clipboard-image",
            ["sh", "-c", 'mkdir -p "$1" && dms cl paste > "$2" 2>/dev/null', "_", cacheDir, tempImage],
            (stdout, exitCode) => {
                if (exitCode === 0) {
                    Proc.runCommand(
                        "check-image-type",
                        ["file", "--mime-type", "-b", tempImage],
                        (checkOut, checkCode) => {
                            if (checkCode === 0 && checkOut.trim().startsWith("image/")) {
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
        runAfterPopoutClosed(() => {
            isScanning = true;
            const tempPath = cacheDir + "/dms_ocr_screenshot.png";

            Proc.runCommand(
                "screenshot-ocr",
                ["dms", "screenshot", "region", "--no-confirm", "--no-notify", "--dir", cacheDir, "--filename", "dms_ocr_screenshot.png"],
                (stdout, exitCode) => {
                    pluginRoot.isTemporaryAction = false;
                    if (exitCode === 0) {
                        sourceImage = tempPath;
                        imageTrigger++;
                        runTesseract(tempPath);
                    } else {
                        isScanning = false;
                        ToastService.showError("Failed to take screenshot or selection cancelled.");
                    }
                    pluginRoot.triggerPopout();
                },
                0
            );
        });
    }

    function selectFileAndScan() {
        isTemporaryAction = true;
        pluginRoot.closePopout();
        fileBrowserModal.open();
    }

    function scanFromUrl(url) {
        if (!url || isScanning) return;
        
        const convertSvgToPng = function(inputPath, callback, cleanupInput) {
            const outputPath = cacheDir + "/dms_ocr_svg_" + Date.now() + ".png";
            Proc.runCommand(
                "svg-convert",
                ["rsvg-convert", "-w", "2000", "-h", "2000", "-f", "png", "-o", outputPath, inputPath],
                (stdout, exitCode) => {
                    if (exitCode === 0) {
                        callback(outputPath, cleanupInput ? [inputPath, outputPath] : [outputPath]);
                    } else {
                        Proc.runCommand(
                            "svg-convert-fallback",
                            ["convert", "-background", "white", "-alpha", "remove", inputPath, outputPath],
                            (stdout2, exitCode2) => {
                                if (exitCode2 === 0) {
                                    callback(outputPath, cleanupInput ? [inputPath, outputPath] : [outputPath]);
                                } else {
                                    if (cleanupInput) Proc.runCommand("ocr-clean", ["rm", "-f", inputPath], null, 0);
                                    callback(null, []);
                                }
                            },
                            0
                        );
                    }
                },
                0
            );
        };

        const processImage = function(path, isTemp) {
            if (path.toLowerCase().endsWith(".svg")) {
                convertSvgToPng(path, function(convertedPath, toClean) {
                    if (convertedPath) {
                        sourceImage = convertedPath;
                        imageTrigger++;
                        isScanning = true;
                        runTesseract(convertedPath, false, toClean);
                    } else {
                        ToastService.showError("Failed to convert SVG to PNG. Install rsvg-convert or imagemagick.");
                    }
                }, isTemp);
            } else {
                sourceImage = path;
                imageTrigger++;
                isScanning = true;
                runTesseract(path, false, isTemp ? [path] : []);
            }
        };

        if (url.startsWith("file://")) {
            processImage(url.substring(7), false);
        } else if (url.startsWith("http://") || url.startsWith("https://")) {
            const tempFile = cacheDir + "/dms_ocr_dl_" + Date.now();
            Proc.runCommand("download-image", ["dms", "dl", url, "-o", tempFile], (stdout, exitCode) => {
                if (exitCode === 0) {
                    processImage(tempFile, true);
                } else {
                    ToastService.showError("Failed to download image from URL.");
                }
            });
        } else if (url.startsWith("/")) {
            processImage(url, false);
        } else {
            ToastService.showError("Invalid image source.");
        }
    }

    function runTesseract(imagePath, skipAutoCopy, cleanupFiles) {
        if (imagePath.includes("dms_ocr_input.png")) {
            sourceImage = imagePath;
            imageTrigger++;
        }

        let lang = pluginService.loadPluginData(pluginRoot.pluginId, "ocrLanguage", "eng");
        if (!lang || lang === "") lang = "eng";

        Proc.runCommand(
            "run-tesseract",
            ["tesseract", imagePath, "-", "-l", lang],
            (stdout, exitCode) => {
                isScanning = false;
                isAutoScanning = false;
                if (Array.isArray(cleanupFiles) && cleanupFiles.length > 0) {
                    Proc.runCommand("ocr-cleanup", ["rm", "-f"].concat(cleanupFiles), null, 0);
                }
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

                DIcon {
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
        fileExtensions: ["*.png", "*.jpg", "*.jpeg", "*.webp", "*.bmp"]
        onFileSelected: path => {
            pluginRoot.isScanning = true;
            pluginRoot.sourceImage = path;
            pluginRoot.imageTrigger++;
            pluginRoot.runTesseract(path);
            close();
        }
        onDialogClosed: {
            pluginRoot.isTemporaryAction = false;
            pluginRoot.triggerPopout();
        }
    }

    FileBrowserModal {
        id: saveBrowserModal
        browserTitle: "Save OCR Result"
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
            width: root.popoutWidth
            headerText: ""
            focus: true

            property var parentPopout: null

            Component.onDestruction: {
                if (!pluginRoot.isSaving && !pluginRoot.isTemporaryAction && pluginRoot.pluginData && !(pluginRoot.pluginData.keepResults ?? true)) {
                    resultText = "";
                    sourceImage = "";
                }
            }

            Column {
                id: contentColumn
                width: parent.width
                spacing: Theme.spacingM

                // ── Two Columns Workspace (Image & Text) ─────────────────────
                Row {
                    width: parent.width
                    spacing: Theme.spacingM

                    // Left Column: Source Image & Actions
                    Column {
                        width: (parent.width - Theme.spacingM) / 2
                        spacing: Theme.spacingM

                        DCard {
                            width: parent.width
                            height: 380
                            restRadius: Theme.cornerRadiusL
                            color: Theme.surfaceContainer
                            pad: 0
                            clipContent: true

                            Image {
                                id: sourceImg
                                anchors.fill: parent
                                anchors.margins: Theme.spacingM
                                fillMode: Image.PreserveAspectFit
                                asynchronous: true
                                source: pluginRoot.sourceImage ? "file://" + pluginRoot.sourceImage + "?t=" + pluginRoot.imageTrigger : ""

                                Column {
                                    anchors.centerIn: parent
                                    spacing: Theme.spacingS
                                    visible: sourceImg.status !== Image.Ready && !pluginRoot.isScanning

                                    DIcon {
                                        name: "image"
                                        size: Theme.iconSizeLarge
                                        color: Theme.outlineVariant
                                        anchors.horizontalCenter: parent.horizontalCenter
                                    }

                                    StyledText {
                                        text: I18n.trFor("ocrScanner", "No image scanned yet")
                                        color: Theme.outlineVariant
                                        font.pixelSize: Theme.fontSizeMedium
                                        anchors.horizontalCenter: parent.horizontalCenter
                                    }
                                }
                            }

                            // Clear Image Button inside Card
                            DButton {
                                anchors.top: parent.top
                                anchors.right: parent.right
                                anchors.margins: Theme.spacingS
                                width: 32
                                height: 32
                                iconName: "close"
                                tooltipText: I18n.trFor("ocrScanner", "Clear Image & Text")
                                onClicked: {
                                    pluginRoot.sourceImage = "";
                                    pluginRoot.resultText = "";
                                }
                                visible: (pluginRoot.sourceImage !== "" || pluginRoot.resultText !== "") && !pluginRoot.isScanning
                                backgroundColor: Theme.withAlpha(Theme.surfaceContainerHighest, 0.8)
                                textColor: Theme.surfaceText
                            }
                        }

                        // Left Action Buttons (Scan Inputs)
                        Row {
                            width: parent.width
                            spacing: Theme.spacingS

                            readonly property real totalGaps: Theme.spacingS * 2
                            readonly property real availableW: parent.width - totalGaps

                            DButton {
                                text: I18n.trFor("ocrScanner", "Screenshot")
                                width: parent.availableW * 0.5
                                iconName: "crop_free"
                                onClicked: pluginRoot.scanFromScreenshot()
                                enabled: !pluginRoot.isScanning
                                backgroundColor: Theme.primaryContainer
                                textColor: Theme.primary
                            }

                            DButton {
                                width: parent.availableW * 0.25
                                iconName: "content_paste"
                                tooltipText: I18n.trFor("ocrScanner", "Scan Clipboard")
                                onClicked: pluginRoot.scanFromClipboard()
                                enabled: !pluginRoot.isScanning
                                backgroundColor: Theme.surfaceContainerHigh
                                textColor: Theme.surfaceText
                            }

                            DButton {
                                width: parent.availableW * 0.25
                                iconName: "folder"
                                tooltipText: I18n.trFor("ocrScanner", "Select File")
                                onClicked: pluginRoot.selectFileAndScan()
                                enabled: !pluginRoot.isScanning
                                backgroundColor: Theme.surfaceContainerHigh
                                textColor: Theme.surfaceText
                            }
                        }
                    }

                    // Right Column: Result Text & Output Actions
                    Column {
                        width: (parent.width - Theme.spacingM) / 2
                        spacing: Theme.spacingM

                        DTextEdit {
                            id: resultArea
                            width: parent.width
                            height: 380
                            cornerRadius: Theme.cornerRadiusL
                            backgroundColor: Theme.surfaceContainer
                            placeholderText: I18n.trFor("ocrScanner", "Text will appear here...")
                            text: pluginRoot.resultText
                            wrapMode: TextEdit.Wrap
                            onTextEdited: pluginRoot.resultText = text

                            Component.onCompleted: {
                                for (let i = 0; i < children.length; i++) {
                                    if (children[i].text !== undefined && children[i].wrapMode !== undefined) {
                                        children[i].verticalAlignment = Text.AlignTop;
                                    }
                                }
                            }
                        }

                        // Right Action Buttons (Copy / Save)
                        Row {
                            width: parent.width
                            spacing: Theme.spacingS

                            DButton {
                                text: I18n.trFor("ocrScanner", "Copy Text")
                                width: (parent.width - Theme.spacingS) / 2
                                iconName: "content_copy"
                                onClicked: pluginRoot.copyToClipboard(pluginRoot.resultText)
                                enabled: pluginRoot.resultText !== "" && !pluginRoot.isScanning
                                backgroundColor: Theme.primaryContainer
                                textColor: Theme.primary
                            }

                            DButton {
                                text: I18n.trFor("ocrScanner", "Save Text")
                                width: (parent.width - Theme.spacingS) / 2
                                iconName: "save"
                                onClicked: pluginRoot.saveResultToFile()
                                enabled: pluginRoot.resultText !== "" && !pluginRoot.isScanning
                                backgroundColor: Theme.surfaceContainerHigh
                                textColor: Theme.surfaceText
                            }
                        }
                    }
                }
            }
        }
    }

}
