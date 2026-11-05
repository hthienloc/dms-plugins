# Pixel Skin Authoring Guide

Pixel skins use the original 32x25 sprite in `pixel/` as their shared pose and
anatomy template. The `@4x` files are nearest-neighbor enlargements of the
corresponding 32x25 PNGs, not separate drawings.

## Coordinate Map

Coordinates start at `(0, 0)` in the top-left corner of the 32x25 image. Ranges
are approximate bounds; inspect the source PNG before changing individual
pixels.

| Region | Approximate coordinates | Notes |
| --- | --- | --- |
| Left ear | `x=7..10, y=1..5` | Top-left ear |
| Right ear | `x=23..27, y=2..6` | Top-right ear |
| Face details | Exact pixels below | Dark marks are facial features, not outline |
| Left paw pads | `x=1..4, y=13..16` | Visible in `idle`, `right`, and `blink` |
| Right paw pads | `x=22..25, y=14..17` | Visible in `idle`, `left`, and `blink` |
| Left lowered paw | `x=2..8, y=19..23` | Present in `left` and `both` |
| Right lowered paw | `x=18..27, y=19..24` | Present in `right` and `both` |
| Desk | Mostly `y=18` | Blue/dark region beneath the body |

These are image-space coordinates and apply to the base-size sprite. In an
`@4x` image, multiply each coordinate by four.

The face marks are consistent across all six source poses:

- Left eye: `(10,14)`, `(10,15)`
- Nose: `(12,14)`
- Right eye: `(14,14)`, `(14,15)`
- Mouth: `(11,15)`, `(13,15)`

Paw-pad pixels move or disappear with the pose. In `idle` and `blink`, the left
pad uses `(2,13)`, `(4,13)`, `(1,15)`, `(3,15)`, `(4,15)`, `(3,16)`, `(4,16)`;
the right pad uses `(23,14)`, `(25,14)`, `(22,16)`, `(24,16)`, `(25,16)`,
`(24,17)`, `(25,17)`. `left` shows only the right pad, `right` shows only the
left pad, and `both`/`sleep` show neither.

## Source Palette

The original `pixel/` sprites use these opaque colors:

| Color | Role |
| --- | --- |
| `(22, 23, 26)` | Outer contour **and face details** |
| `(255, 255, 255)` | Main fur |
| `(186, 216, 247)` | Fur shadow |
| `(119, 154, 202)` | Desk and lower shadow |
| `(246, 138, 152)` | Paw pads |

Do not recolor every dark pixel as if it were only an outline: the eyes and
facial marks use the same dark color. For colorway skins, recolor by source
color while preserving alpha and pose. Do not add or place details over the
eyes, nose, or mouth; preserve those features as a clear, unobstructed face.
For other added details, first identify the target pixels in the relevant
source frame; avoid guessed coordinates and do not overwrite the silhouette.

## Theme Accent Coordinates

The Cyberpunk and Zombie skins add small details only on confirmed opaque fur
pixels shared by every pose. Coordinates below are in the 32x25 source frame:

- Cyberpunk ear lights: `(8,3)`, `(9,4)`, `(24,4)`, `(25,5)`.
- Cyberpunk back circuit: `(18,8)`, `(19,8)`, `(19,9)`, `(20,9)`.
- Zombie stitched patch: the `x=17..19, y=8..9` fur area.

These accents stay on the ears and upper back. Keep all seven face-detail
pixels listed above free of added decorations, and preserve the original alpha
mask so accents do not change the silhouette.

## Pose Checklist

Each skin contains `idle`, `left`, `right`, `both`, `blink`, and `sleep`. Paw
positions and visible pads differ by pose, so review every state before
exporting. Keep all frames at 32x25 with transparent backgrounds, then create
each `@4x` PNG with nearest-neighbor scaling to 128x100.
