# Pixel Fish Collapse Design

## Scope

Add a compact pixel fish immediately to the left of the notch-attached task capsule. The fish remains visible in both collapsed and expanded states. It is motionless in the normal state. When the task board closes, it performs one short, in-place two-beat shake; it does not swim or turn around.

## Chosen Approach

Three rendering options were considered: a bundled raster asset, SwiftUI drawing primitives, and `Canvas`. The implementation uses SwiftUI `Canvas`: it produces a crisp resolution-independent pixel silhouette, has no image-loading path, and can be mirrored in tests through its explicit motion state. A bundled image would introduce scaling and asset maintenance; a large collection of individual `Rectangle` views would make the silhouette harder to maintain.

## Components and Data Flow

`NotchPanelController` owns a published transition phase: `collapsed`, `expanding`, `expanded`, and `collapsing`. `expand()` assigns `expanding`, changes the panel frame, then settles on `expanded`. `collapse()` assigns `collapsing`, begins the existing frame resize, and returns to `collapsed` after the matching animation duration.

`NotchSurfaceView` always places `PixelFishView` at the leading edge of the collapsed capsule. The fish is independent of the board content so its screen position does not change as the panel expands. `PixelFishView` observes the phase and runs its shake only when the phase becomes `collapsing`.

The fish uses a 28 by 16 point blue-green pixel grid with a darker tail, pale body stripe, and eye. It has no idle animation.

## Motion and Accessibility

The collapse shake lasts 180 ms: left 2 points, right 2 points, left 1 point, then neutral. It starts with the close transition and never repeats after collapse completes. Expand has no fish animation. When Reduce Motion is enabled, the fish remains static and the panel uses the existing zero-duration resize.

## Testing

Unit tests cover legal transition-phase changes and verify that a collapse request enters `collapsing` before settling at `collapsed`. Existing placement tests remain unchanged. Manual verification checks: static fish while idle and expanded, one shake on click/Escape/outside-click/inactivity collapse, and no shake with Reduce Motion.

## Non-goals

No swimming, turning, idle bobbing, new preferences, raster assets, notifications, or changes to task storage and board layout.
