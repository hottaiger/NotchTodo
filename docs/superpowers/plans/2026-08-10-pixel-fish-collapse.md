# Pixel Fish Collapse Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Show a static compact pixel fish beside the notch capsule and play one short shake only as the board collapses.

**Architecture:** `NotchPanelController` publishes a panel transition phase and collapse event ID. `PixelFishView` draws the fish with `Canvas`, observes the event ID, and performs the one-shot shake. `NotchSurfaceView` composes the fish and capsule at a fixed screen position.

**Tech Stack:** Swift 5.9, macOS 14+, SwiftUI, AppKit, XCTest.

## Global Constraints

- Draw a 28 by 16 point blue-green pixel fish in SwiftUI `Canvas`; add no raster asset.
- Place it directly left of the collapsed notch capsule; it must not move while the board expands.
- It has no idle or expand animation.
- Collapse shake: -2 points, +2 points, -1 point, neutral, within 180 ms.
- If Reduce Motion is enabled, do not animate the fish.
- Do not change task data, board columns, settings, or placement rules.

---

### Task 1: Publish collapse intent

**Files:**
- Create: `Sources/NotchTodo/NotchWindow/PanelTransitionPhase.swift`
- Modify: `Sources/NotchTodo/NotchWindow/NotchPanelController.swift`
- Test: `Tests/NotchTodoTests/PanelTransitionPhaseTests.swift`

**Interfaces:**
- Produces: `enum PanelTransitionPhase: Equatable { case collapsed, expanding, expanded, collapsing }`.
- Produces: `@Published private(set) var transitionPhase` and `@Published private(set) var collapseAnimationID: UInt`.

- [ ] **Step 1: Write the failing phase test**

```swift
import XCTest
@testable import NotchTodo

final class PanelTransitionPhaseTests: XCTestCase {
    func testCollapsedAndCollapsingAreDistinct() {
        XCTAssertNotEqual(PanelTransitionPhase.collapsed, .collapsing)
    }
}
```

- [ ] **Step 2: Run the focused test**

Run: `swift test --filter PanelTransitionPhaseTests`

Expected: compilation failure because `PanelTransitionPhase` does not exist.

- [ ] **Step 3: Add the phase and controller state**

```swift
enum PanelTransitionPhase: Equatable {
    case collapsed, expanding, expanded, collapsing
}

@Published private(set) var transitionPhase: PanelTransitionPhase = .collapsed
@Published private(set) var collapseAnimationID: UInt = 0

func collapse() {
    guard isExpanded else { return }
    transitionPhase = .collapsing
    collapseAnimationID &+= 1
    isExpanded = false
    resize(to: collapsedFrame) { [weak self] in self?.transitionPhase = .collapsed }
}
```

Change `resize(to:)` to accept an optional completion; call it immediately for Reduce Motion. Set `.expanding` before expand resize and `.expanded` in that completion.

- [ ] **Step 4: Verify and commit**

Run: `swift test --filter PanelTransitionPhaseTests`

Expected: `1 test, 0 failures`.

```bash
git add Sources/NotchTodo/NotchWindow/PanelTransitionPhase.swift Sources/NotchTodo/NotchWindow/NotchPanelController.swift Tests/NotchTodoTests/PanelTransitionPhaseTests.swift
git commit -m "feat: publish notch panel transition phase"
```

### Task 2: Draw and shake the fish

**Files:**
- Create: `Sources/NotchTodo/TaskBoard/PixelFishView.swift`
- Modify: `Sources/NotchTodo/TaskBoard/NotchSurfaceView.swift`

**Interfaces:**
- Consumes: `NotchPanelController.collapseAnimationID` and `NSWorkspace.shared.accessibilityDisplayShouldReduceMotion`.
- Produces: `PixelFishView(collapseAnimationID: UInt, shouldReduceMotion: Bool)`.

- [ ] **Step 1: Draw the fixed pixel silhouette**

```swift
struct PixelFishView: View {
    let collapseAnimationID: UInt
    let shouldReduceMotion: Bool
    @State private var horizontalOffset: CGFloat = 0

    var body: some View {
        Canvas { context, _ in
            for (x, y, color) in PixelFishView.pixels {
                context.fill(Path(CGRect(x: x, y: y, width: 4, height: 4)), with: .color(color))
            }
        }
        .frame(width: 28, height: 16)
        .offset(x: horizontalOffset)
        .onChange(of: collapseAnimationID) { _, _ in shakeIfAllowed() }
    }
}
```

Define `pixels` with 4-point cells for dark tail, blue-green body, pale stripe, and dark eye. Use the approved 28 by 16 compact silhouette.

- [ ] **Step 2: Implement the one-shot collapse shake**

```swift
private func shakeIfAllowed() {
    guard !shouldReduceMotion else { return }
    withAnimation(.linear(duration: 0.045)) { horizontalOffset = -2 }
    DispatchQueue.main.asyncAfter(deadline: .now() + 0.045) { withAnimation(.linear(duration: 0.055)) { horizontalOffset = 2 } }
    DispatchQueue.main.asyncAfter(deadline: .now() + 0.10) { withAnimation(.linear(duration: 0.04)) { horizontalOffset = -1 } }
    DispatchQueue.main.asyncAfter(deadline: .now() + 0.14) { withAnimation(.linear(duration: 0.04)) { horizontalOffset = 0 } }
}
```

- [ ] **Step 3: Compose the fish at the capsule's leading edge**

```swift
PixelFishView(
    collapseAnimationID: controller.collapseAnimationID,
    shouldReduceMotion: NSWorkspace.shared.accessibilityDisplayShouldReduceMotion
)
```

Place this in the root `NotchSurfaceView` overlay, aligned with the leading edge of the collapsed capsule, rather than inside `TaskBoardView`. Keep it displayed across expanded and collapsed states. Do not add a fish hit target.

- [ ] **Step 4: Verify, build, and commit**

Run: `swift test && zsh scripts/build-app.sh`

Expected: all XCTest cases pass and `.build/release/NotchTodo.app` exists.

Run: `open .build/release/NotchTodo.app`

Expected: the fish is still while idle or opening; click-close, Escape, outside-click, and inactivity trigger exactly one shake; Reduce Motion triggers none.

```bash
git add Sources/NotchTodo/TaskBoard/PixelFishView.swift Sources/NotchTodo/TaskBoard/NotchSurfaceView.swift
git commit -m "feat: add pixel fish collapse shake"
```
