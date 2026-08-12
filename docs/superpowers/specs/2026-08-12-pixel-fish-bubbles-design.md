# Pixel Fish Bubble Design

## Scope

Add a brief bubble sequence beside the capsule fish. A sequence emits two small pixel bubbles that rise from the fish mouth, then the fish remains still for 15 seconds before it may emit again.

## Chosen Approach

Keep the effect encapsulated in `PixelFishView`. SwiftUI state controls a fixed-size `Canvas` bubble overlay and a cancellable work-item sequence. This preserves the controller state machine and panel geometry.

## Behavior

- Start one bubble sequence when the fish appears in the collapsed capsule.
- Emit two bubbles, staggered in time, that rise and fade within the fish's existing 28 by 16 point local canvas.
- After the sequence completes, wait 15 seconds before the next sequence.
- Cancel pending bubble work and clear visual state when the fish disappears, which occurs while expanded.
- Disable bubbles when macOS Reduce Motion is enabled.
- Preserve the existing collapse shake independently of bubble timing.

## Geometry and State Boundaries

`NotchSurfaceView` continues to render the fish and its black backing only while `controller.isExpanded` is false. It retains its existing 38-point backing frame, leading inset, and collapsed window sizing. `NotchPanelController`, `DisplayPlacementResolver`, and `PanelTransitionPhase` remain unchanged.

## Testing

Expose timing constants and a pure visibility predicate from `PixelFishView` for XCTest. Tests assert a 15-second cooldown, that bubble motion is enabled only without Reduce Motion, and that existing expanded/collapsed fish visibility remains unchanged. Run the full Swift test suite and app build.

## Non-goals

No changes to capsule dimensions, fish pixels, placement, board expansion, user settings, persisted data, or new assets.
