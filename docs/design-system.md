# Dux Shell Plugins Design System & Tokens

This document defines the visual design standards and token system for Dux Shell plugins.
Always use `Theme` tokens (`import qs.Common`). Never hardcode hex strings, pixel sizes, arbitrary colors, or magic numbers.

---

## 1. Strict Theme Rules

- **No Hex Colors:** Never use hex strings (e.g. `#FF1744`, `#1A1A1A`) or color names (e.g. `"white"`, `"blue"`). Always use semantic `Theme` properties.
- **No Hardcoded Dimensions:** Do not hardcode font sizes, padding/margins, corner radii, or icon sizes.
- **Light/Dark Mode Support:** Dynamic colors adjust automatically. Using hardcoded values breaks layouts on theme changes.
- **Alpha Blending:** Use `Theme.withAlpha(color, alpha)` instead of hardcoded transparent hex values:
  ```qml
  color: Theme.withAlpha(Theme.primary, 0.22)
  ```

---

## 2. Color Tokens

### Semantic & Accent Colors
| Token | Role & Usage |
| :--- | :--- |
| `Theme.primary` | Main accent color (respects user selection). |
| `Theme.secondary` | Secondary accent color for subtle actions. |
| `Theme.error` | Destructive actions, errors, and critical alerts. |
| `Theme.warning` | Warnings, pending states, and caution flags. |
| `Theme.success` | Positive states, successful completions, and confirmations. |

### Surface & Text Roles
| Token | Role & Usage |
| :--- | :--- |
| `Theme.surface` | Base surface / background. |
| `Theme.surfaceContainer` | Standard container background (cards, panels, modals). |
| `Theme.surfaceContainerHigh` | Elevated / highlighted container (hovered items, prominent rows). |
| `Theme.surfaceText` (or `Theme.onSurface`) | Primary readable text. |
| `Theme.surfaceVariantText` (or `Theme.onSurfaceVariant`) | Secondary / muted text, captions, and descriptions. |
| `Theme.outline` / `Theme.outlineVariant` | Standard boundaries, borders, and dividers. |

---

## 3. Button & Control Sizing (`Theme.buttonHeight*`)

| Token | Pixels | Role & Usage | Recommended Components | Icon Size |
| :--- | :--- | :--- | :--- | :--- |
| `Theme.buttonHeightXXS` | `28px` | Micro actions, inline list chips | `DActionButton`, `TagChip` | `Theme.iconSizeSmall` (16px) |
| `Theme.buttonHeightXS` | `32px` | Compact chip buttons, filter chips | `DFilterChips`, `DButton` (size: "s") | `Theme.iconSizeSmall` (16px) |
| `Theme.buttonHeightS` | `40px` | **Default standard** for toolbars, headers, compact inputs | `DActionButton`, `DDropdown` (compactMode) | `Theme.iconSizeMedium` (20px) |
| `Theme.buttonHeightM` | `56px` | Prominent control bars, primary modal actions | `DButton` (size: "m"), bottom bar container | `Theme.iconSize` (24px) / `Theme.iconSizeLarge` (32px) |

---

## 4. Icon Sizing (`Theme.iconSize*`)

| Token | Pixels | Usage Context |
| :--- | :--- | :--- |
| `Theme.iconSizeSmall` | `16px` | Inside `XXS`/`XS` buttons, inline text badges, keyboard hints. |
| `Theme.iconSizeMedium` | `20px` | Inside `S` (40px) action buttons, standard list item icons. |
| `Theme.iconSize` | `24px` | Standard standalone icons, prominent actions (e.g. Play/Pause toggle). |
| `Theme.iconSizeLarge` | `32px` | Hero icons, modal headers, large feature indicators. |

---

## 5. Spacing Scale (`Theme.spacing*`)

| Token | Pixels | Standard Usage |
| :--- | :--- | :--- |
| `Theme.spacingXXS` | `2px` | Micro-gaps between keycaps, badge padding, thin dividers. |
| `Theme.spacingXS` | `4px` | Compact button padding, tight element gaps. |
| `Theme.spacingS` | `8px` | Space between related controls, inside cards. |
| `Theme.spacingM` | `12px` | Standard modal/panel padding, row layouts, container margins. |
| `Theme.spacingL` | `16px` | Section margins, card boundaries, outer content gutters. |
| `Theme.spacingXL` | `24px` | Major section separators, prominent dialog margins. |

---

## 6. Corner Radius Scale (`Theme.cornerRadius*`)

| Token | Value | Typical Application |
| :--- | :--- | :--- |
| `Theme.cornerRadiusXS` | `4px` | Small badges, sub-chips, tooltip indicators. |
| `Theme.cornerRadiusSmall` (`cornerRadiusS`) | `8px` | Action buttons, list/grid delegate hover shapes. |
| `Theme.cornerRadius` (`cornerRadiusM`) | `12px` | Standard cards, dropdown menus, popovers. |
| `Theme.cornerRadiusLarge` (`cornerRadiusL`) | `16px` | Modals, floating popout containers, preview dialogs. |

---

## 7. Typography Scale (`Theme.fontSize*`)

| Token | Typical Size | Usage |
| :--- | :--- | :--- |
| `Theme.fontSizeSmall` | ~`11px-12px` | Captions, secondary labels, badges, inline chips. |
| `Theme.fontSizeMedium` | ~`13px-14px` | Body text, standard button labels, inputs. |
| `Theme.fontSizeLarge` | ~`16px-18px` | Card headers, section titles, modal titles. |
| `Theme.fontSizeXLarge` | ~`20px-24px` | Prominent headings, hero metrics, clock displays. |

---

## 8. Material 3 Expressive (`M3E` Shared Singleton)

Import `./shared` (or `../shared`, `../../shared`) to access `M3E` (`shared/M3E.qml`), which standardizes M3E spatial motion, connected button/list radii, and hover/press morphing across plugins:

| Token / Helper | Purpose |
| :--- | :--- |
| `M3E.spatialFastMs`, `M3E.spatialDefaultMs`, `M3E.spatialSlowMs` | Expressive spatial spring durations (with fallback to `Theme.*Duration`). |
| `M3E.effectsFastMs`, `M3E.effectsMs`, `M3E.effectsSlowMs` | Color/opacity transition durations. |
| `M3E.curveFastSpatial`, `M3E.curveDefaultSpatial`, `M3E.curveEffects` | Bezier spline arrays (`Easing.BezierSpline`). |
| `M3E.outerR`, `M3E.innerR`, `M3E.groupGap` | Connected list/button group outer radius (`16`), inner seam radius (`6`), and gap (`2`). |
| `M3E.pressRadiusXXS`, `M3E.pressRadiusXS`, `M3E.pressRadiusS` | Squircle corner radii when pressed (`4`, `6`, `8`). |
| `M3E.tilePressScale`, `M3E.rowPressScale`, `M3E.iconBtnPressScale` | Press scale factors (`0.96`, `0.97`, `0.93`) without hover scale overshoot. |
| `M3E.tileIconPillWidth`, `M3E.tileIconPillActiveWidth`, `M3E.tileIconPillHeight` | Morphing icon pill dimensions for grid tiles (`34` → `42`, height `28`). |
| `M3E.rowIconPillWidth`, `M3E.rowIconPillActiveWidth`, `M3E.rowIconPillHeight` | Morphing icon pill dimensions for list rows (`28` → `34`, height `26`). |
| `M3E.activeBlendFactor`, `M3E.switcherActiveRatio` | Highlight hover blend (`0.18`) and 2-segment switcher active ratio (`0.68`). |
| `M3E.tileRadius(pressed, hovered, highlighted)` | Computes M3E morphing radius for grid tiles. |
| `M3E.iconPillRadius(pressed, hovered, height)` | Computes M3E morphing radius for inner icon pills. |
