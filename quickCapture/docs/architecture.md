# System Architecture & Engine Reference

Dux Shell Quick Capture is designed as a **Composite Plugin** for Dux Shell. This document covers the system architecture, component lifecycles, canvas rendering pipeline, and Wayland window management.

---

## 1. Plugin Lifecycle & Composite Model

Dux Shell supports different plugin types (widget, daemon, launcher, desktop). Quick Capture is a **composite plugin**, bundling multiple execution entry points:

- `daemon`: `./QuickCaptureDaemon.qml` (runs continuously in the background).
- `widget`: `./QuickCaptureWidget.qml` (loaded by DankBar).
- `settings`: `./QuickCaptureSettings.qml` (rendered in the Dux Shell Settings Center).

### Component Map

| Component | Role & Lifecycle |
| :--- | :--- |
| **`QuickCaptureDaemon`** | Background service. Listens to IPC requests, triggers screenshot portal/Wayland capture, and manages recording backends. |
| **`QuickCaptureWidget`** | DankBar and Dock widget (`dankbar-widget`). Provides left/right/middle click triggers, active recording indicators, attached panel or popout menu, and drag-and-drop file ingestion across bars and docks. |
| **`QuickCaptureModal`** | Fullscreen annotator window. Manages canvas layers, keyboard shortcuts, tool state, and mouse event routing. |
| **`QuickCaptureSettings`** | Multi-tab settings panel for tool defaults, watermarks, radial presets, and keybindings. |
| **`CaptureConfig`** | Shared configuration model for tool definitions, palette presets, and translation wrappers. |

---

## 2. Canvas & Rendering Pipeline

Annotations are rendered dynamically using a QML `Canvas` component maintaining an array model of vector objects rather than drawing statically on a raster surface.

```
[User Action] ➔ [Update Shape Model] ➔ [requestPaint()] ➔ [onPaint() Redraw Loop] ➔ [Screen Output]
```

### Coordinate Systems
- **Absolute Coordinates:** Vector coordinates (stored in `strokes` array) are relative to the raw screenshot image (`bgImage.sourceSize`).
- **Annotation Mode:** The canvas view is translated by `-cropRect.x` and `-cropRect.y`.
- **Crop Mode:** The canvas renders the full screenshot background but dims areas outside `cropRect`.
- **Mapping Helper:** Mouse positions are mapped to absolute coordinates using `getAbsolutePoint(mx, my)`.

### Drawing Constraints (Shift Modifier)
When `Shift` is held down during mouse dragging, ending coordinates are mathematically snapped:
- **Pen:** Disables curved tracking, draws a single line segment.
- **Line / Arrow:** Snaps angle to nearest 45° multiple.
- **Rectangle / Blur / Callout:** Forces 1:1 aspect ratio (square).
- **Ellipse:** Forces equal radii (circle).

### Background Layout Wrapping
When background modes (Solid or Gradient) are enabled, the screenshot is wrapped within a padded canvas container with configurable padding, corner radius, drop shadow, and aspect ratio ("1:1", "16:9", "4:3", or "Auto").

---

## 3. Window & Coordinate Mapping (Wayland)

Under Wayland, absolute window positioning is restricted. Quickshell permits panel windows to specify anchors, layers, and coordinate mapping.

### Popout Clipping Fix (Modal-Level Elevation)
Pop-up menus (e.g. `MoreToolsMenu`, font pickers, brush presets) are instantiated at the root window level (`contentRoot`) instead of inside small toolbar buttons (`36x36px`). Coordinates are mapped dynamically on click:

```qml
onMoreToolsClicked: (buttonItem) => {
    var pt = buttonItem.mapToItem(contentRoot, 0, 0);
    if (toolbarCard.isVertical) {
        moreToolsMenu.x = pt.x + buttonItem.width + Theme.spacingS;
        moreToolsMenu.y = pt.y;
    } else {
        moreToolsMenu.x = pt.x;
        moreToolsMenu.y = pt.y + buttonItem.height + Theme.spacingS;
    }
    moreToolsMenu.open();
}
```

---

## 4. Key Constraints & Common Patterns

- **Stateless JS Libraries:** All `.js` files use `.pragma library` singletons without direct QML context. State must be passed explicitly via `window` or `config` references.
- **Array Reactivity:** The QML engine cannot detect in-place array mutations (`push`, `splice`). Always reassign arrays immutably (`window.strokes = [...window.strokes, newStroke]`).
- **Signal-Driven State:** Children emit action signals rather than mutating parent properties directly to prevent destroying QML reactive bindings.
