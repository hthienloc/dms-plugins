import QtQuick
import Quickshell
import qs.Common
import qs.Services
import qs.Modules.Plugins
import "./P5CalendarLogic.js" as Logic

DesktopPluginComponent {
    id: root

    // Native asset dimensions: 835 x 653
    readonly property real nativeWidth: 835
    readonly property real nativeHeight: 653
    readonly property real nativeAspectRatio: nativeWidth / nativeHeight

    minWidth: 200
    minHeight: Math.round(200 / nativeAspectRatio)
    widgetWidth: 400
    widgetHeight: Math.round(400 / nativeAspectRatio)
    property real defaultWidth: 400
    property real defaultHeight: Math.round(400 / nativeAspectRatio)

    // Plugin settings
    readonly property string themeVersionSetting: pluginData.themeVersion ?? "dynamic" // "dynamic", "vanilla", "royal"
    readonly property string todModeSetting: pluginData.todMode ?? "game"               // "game", "solar"
    readonly property bool animateWeather: pluginData.animateWeather ?? false
    readonly property int animInterval: pluginData.animInterval ?? 300
    readonly property real widgetOpacity: (pluginData.widgetOpacity ?? 100) / 100.0
    readonly property bool showWeather: pluginData.showWeather ?? true
    readonly property string clickAction: pluginData.clickAction ?? "refresh"            // "refresh", "dateInfo", "none"

    // Time & Date via Quickshell SystemClock
    SystemClock {
        id: systemClock
        precision: SystemClock.Minutes
    }

    readonly property var now: systemClock.date || new Date()
    readonly property int currentDay: now.getDate()
    readonly property int currentMonth: now.getMonth() + 1
    readonly property int currentHour: now.getHours()
    readonly property int dayOfWeek: now.getDay()
    readonly property var dayNames: ["Sunday", "Monday", "Tuesday", "Wednesday", "Thursday", "Friday", "Saturday"]
    readonly property string currentDayName: dayNames[dayOfWeek]

    // P5 Version: 0 = Vanilla, 1 = Royal
    readonly property int effectiveVersion: {
        if (themeVersionSetting === "royal") return 1;
        if (themeVersionSetting === "vanilla") return 0;
        return (currentMonth < 3) ? 1 : 0;
    }

    // Month asset code: shifted left (* 100) if day has 2 digits
    readonly property int monthNumber: (currentDay < 10) ? currentMonth : (currentMonth * 100)

    // Time of Day (1..6)
    readonly property int timeOfDay: Logic.getTimeOfDay(currentHour, todModeSetting, WeatherService, now)

    // Weather resolution
    readonly property string weatherCode: {
        if (!showWeather) return "";
        if (!WeatherService || !WeatherService.weather || !WeatherService.weather.available) {
            return (WeatherService && WeatherService.weather && WeatherService.weather.isDay === false) ? "01n" : "01d";
        }
        return Logic.getWeatherIconCode(WeatherService.weather.wCode, WeatherService.weather.isDay);
    }

    // Weather animation cycling (0..2)
    property int animFrame: 0

    Timer {
        id: animTimer
        interval: Math.max(100, root.animInterval)
        running: root.animateWeather && root.showWeather && root.visible
        repeat: true
        onTriggered: {
            root.animFrame = (root.animFrame + 1) % 3;
        }
    }

    readonly property int weatherBaseFolder: (currentDay < 10) ? 3 : 0

    // Weather service lifecycle management
    Component.onCompleted: {
        if (WeatherService && showWeather) {
            WeatherService.addRef();
        }
    }

    Component.onDestruction: {
        if (WeatherService && showWeather) {
            WeatherService.removeRef();
        }
    }

    onShowWeatherChanged: {
        if (!WeatherService) return;
        if (showWeather) WeatherService.addRef();
        else WeatherService.removeRef();
    }

    Item {
        id: container
        anchors.fill: parent
        opacity: root.widgetOpacity

        Item {
            id: canvas
            anchors.centerIn: parent
            width: root.nativeWidth
            height: root.nativeHeight
            scale: Math.min(parent.width / root.nativeWidth, parent.height / root.nativeHeight)
            transformOrigin: Item.Center

            // Layer 1: Background & Time of Day
            Image {
                anchors.fill: parent
                source: "assets/Day/" + root.effectiveVersion + "/" + root.currentDay + "Bottom.png"
                asynchronous: true
                smooth: true
            }

            Image {
                anchors.fill: parent
                source: "assets/Month/" + root.effectiveVersion + "/" + root.monthNumber + "Bottom.png"
                asynchronous: true
                smooth: true
            }

            Image {
                anchors.fill: parent
                source: "assets/Week/" + root.effectiveVersion + "/" + root.currentDayName + "Bottom.png"
                asynchronous: true
                smooth: true
            }

            Image {
                anchors.fill: parent
                source: "assets/ToD/" + root.effectiveVersion + "/" + root.timeOfDay + ".png"
                asynchronous: true
                smooth: true
            }

            // Layer 2: Weather animation frames (Pre-loaded to prevent texture swapping flash)
            Image {
                anchors.fill: parent
                visible: root.showWeather && root.weatherCode !== "" && (!root.animateWeather || root.animFrame === 0)
                source: (root.showWeather && root.weatherCode !== "")
                    ? "assets/Weather/icons" + (root.weatherBaseFolder + 0) + "/" + root.effectiveVersion + "/" + root.weatherCode + ".png"
                    : ""
                cache: true
                smooth: true
            }

            Image {
                anchors.fill: parent
                visible: root.showWeather && root.weatherCode !== "" && root.animateWeather && root.animFrame === 1
                source: (root.showWeather && root.weatherCode !== "")
                    ? "assets/Weather/icons" + (root.weatherBaseFolder + 1) + "/" + root.effectiveVersion + "/" + root.weatherCode + ".png"
                    : ""
                cache: true
                smooth: true
            }

            Image {
                anchors.fill: parent
                visible: root.showWeather && root.weatherCode !== "" && root.animateWeather && root.animFrame === 2
                source: (root.showWeather && root.weatherCode !== "")
                    ? "assets/Weather/icons" + (root.weatherBaseFolder + 2) + "/" + root.effectiveVersion + "/" + root.weatherCode + ".png"
                    : ""
                cache: true
                smooth: true
            }

            // Layer 3: Midground silhouettes
            Image {
                anchors.fill: parent
                source: "assets/Day/" + root.effectiveVersion + "/" + root.currentDay + ".png"
                asynchronous: true
                smooth: true
            }

            Image {
                anchors.fill: parent
                source: "assets/Month/" + root.effectiveVersion + "/" + root.monthNumber + ".png"
                asynchronous: true
                smooth: true
            }

            Image {
                anchors.fill: parent
                source: "assets/Week/" + root.effectiveVersion + "/" + root.currentDayName + ".png"
                asynchronous: true
                smooth: true
            }

            // Layer 4: Foreground numbers and highlights
            Image {
                anchors.fill: parent
                source: "assets/Day/" + root.effectiveVersion + "/" + root.currentDay + "Top.png"
                asynchronous: true
                smooth: true
            }

            Image {
                anchors.fill: parent
                source: "assets/Month/" + root.effectiveVersion + "/" + root.monthNumber + "Top.png"
                asynchronous: true
                smooth: true
            }

            Image {
                anchors.fill: parent
                source: "assets/Week/" + root.effectiveVersion + "/" + root.currentDayName + "Top.png"
                asynchronous: true
                smooth: true
            }
        }

        MouseArea {
            anchors.fill: parent
            cursorShape: root.clickAction !== "none" ? Qt.PointingHandCursor : Qt.ArrowCursor
            onClicked: {
                if (root.clickAction === "refresh") {
                    if (WeatherService) WeatherService.forceRefresh();
                    if (typeof ToastService !== "undefined" && ToastService) {
                        ToastService.showInfo(I18n.trFor("persona5Calendar", "Weather refreshed"));
                    }
                } else if (root.clickAction === "dateInfo") {
                    const dateStr = root.now ? root.now.toLocaleDateString(Qt.locale(), Locale.LongFormat) : "";
                    const tempStr = (WeatherService && WeatherService.currentTempText) ? WeatherService.currentTempText(false) : "";
                    if (typeof ToastService !== "undefined" && ToastService) {
                        ToastService.showInfo(dateStr + (tempStr ? " • " + tempStr : ""));
                    }
                }
            }
        }
    }
}
