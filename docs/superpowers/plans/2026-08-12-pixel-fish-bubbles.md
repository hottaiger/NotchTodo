# Pixel Fish Bubbles Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Make the collapsed capsule fish emit two short-lived pixel bubbles, then remain still for 15 seconds before repeating.

**Architecture:** Keep bubble state, scheduling, and rendering inside `PixelFishView`. `NotchSurfaceView` continues to decide whether the fish exists from `controller.isExpanded`; no panel controller or placement logic changes. The bubble overlay stays inside the fish's existing 28 by 16 point local frame.

**Tech Stack:** Swift 5.9, macOS 14+, SwiftUI Canvas, XCTest.

## Global Constraints

- Do not change `NotchPanelController`, `DisplayPlacementResolver`, panel frames, capsule dimensions, or expanded/collapsed logic.
- Render bubbles only while the fish is present in the collapsed state; clear scheduled work and bubble state when it disappears.
- Emit two staggered pixel bubbles, then wait exactly 15 seconds before the next sequence.
- Respect `NSWorkspace.shared.accessibilityDisplayShouldReduceMotion` by disabling bubble animation.
- Preserve the existing collapse shake behavior and 28 by 16 point fish rendering.

---

### Task 1: Define and test bubble timing policy

**Files:**
- Modify: `Sources/NotchTodo/TaskBoard/PixelFishView.swift`
- Modify: `Tests/NotchTodoTests/PanelTransitionPhaseTests.swift`

**Interfaces:**
- Produces: `PixelFishView.bubbleCooldown: TimeInterval` equal to `15`.
- Produces: `PixelFishView.shouldAnimateBubbles(shouldReduceMotion: Bool) -> Bool`.

- [ ] **Step 1: Write the failing tests**

```swift
func testFishWaitsFifteenSecondsBetweenBubbleSequences() {
    XCTAssertEqual(PixelFishView.bubbleCooldown, 15, accuracy: 0.001)
}

func testFishBubblesRespectReduceMotion() {
    XCTAssertTrue(PixelFishView.shouldAnimateBubbles(shouldReduceMotion: false))
    XCTAssertFalse(PixelFishView.shouldAnimateBubbles(shouldReduceMotion: true))
}
```

- [ ] **Step 2: Run the focused test and verify RED**

Run: `swift test --filter PanelTransitionPhaseTests`

Expected: compilation failure because `bubbleCooldown` and `shouldAnimateBubbles(shouldReduceMotion:)` do not exist.

- [ ] **Step 3: Add the minimal timing policy**

```swift
static let bubbleCooldown: TimeInterval = 15

static func shouldAnimateBubbles(shouldReduceMotion: Bool) -> Bool {
    !shouldReduceMotion
}
```

- [ ] **Step 4: Run the focused test and verify GREEN**

Run: `swift test --filter PanelTransitionPhaseTests`

Expected: all `PanelTransitionPhaseTests` pass.

- [ ] **Step 5: Commit**

Run: `git add Sources/NotchTodo/TaskBoard/PixelFishView.swift Tests/NotchTodoTests/PanelTransitionPhaseTests.swift && git commit -m "test: define pixel fish bubble timing"`

### Task 2: Render and schedule the bubble sequence

**Files:**
- Modify: `Sources/NotchTodo/TaskBoard/PixelFishView.swift`
- Test: `Tests/NotchTodoTests/PanelTransitionPhaseTests.swift`

**Interfaces:**
- Consumes: `bubbleCooldown`, `shouldReduceMotion`, and the existing SwiftUI view lifecycle.
- Produces: `PixelFishView` that runs an initial two-bubble sequence, schedules the next sequence after 15 seconds, and cancels all work on disappearance.

- [ ] **Step 1: Add the lifecycle contract test**

```swift
func testFishBubblePolicyKeepsExistingCollapseShakeDelay() {
    XCTAssertEqual(PixelFishView.collapseShakeDelay, 0.5, accuracy: 0.001)
    XCTAssertEqual(PixelFishView.bubbleCooldown, 15, accuracy: 0.001)
}
```

- [ ] **Step 2: Run the focused test and verify RED**

Run: `swift test --filter PanelTransitionPhaseTests.testFishBubblePolicyKeepsExistingCollapseShakeDelay`

Expected: failure until Task 1's timing constant exists; after Task 1 it passes, documenting that bubble work must not alter shake timing.

- [ ] **Step 3: Implement the local bubble state and scheduling**

```swift
@State private var bubbleProgress: CGFloat = 0
@State private var bubbleWorkItems: [DispatchWorkItem] = []

private func startBubblesIfAllowed() {
    cancelBubbles()
    guard Self.shouldAnimateBubbles(shouldReduceMotion: shouldReduceMotion) else { return }
    emitBubbleSequence()
}

private func emitBubbleSequence() {
    withAnimation(.easeOut(duration: 0.45)) { bubbleProgress = 1 }
    scheduleBubbleSequence(after: Self.bubbleCooldown)
}
```

Draw the two bubble pixel groups in the existing `Canvas` only when `bubbleProgress > 0`, using offsets that rise from the fish mouth and opacity `1 - bubbleProgress`. Call `startBubblesIfAllowed()` from `onAppear`; call `cancelBubbles()` from `onDisappear`. Keep `cancelShake()` separate and invoke both cleanups in `onDisappear`.

- [ ] **Step 4: Run the complete test suite and build**

Run: `swift test && zsh scripts/build-app.sh`

Expected: all tests pass and `.build/release/NotchTodo.app` exists.

- [ ] **Step 5: Manually verify the animation**

Run: `open .build/release/NotchTodo.app`

Expected: in the collapsed capsule, two bubbles rise and fade, the fish remains still for 15 seconds, then the sequence repeats. Expanding hides the fish immediately; collapsing restores it without changing capsule height. With Reduce Motion enabled, bubbles and shake do not run.

- [ ] **Step 6: Commit**

Run: `git add Sources/NotchTodo/TaskBoard/PixelFishView.swift Tests/NotchTodoTests/PanelTransitionPhaseTests.swift && git commit -m "feat: animate pixel fish bubbles"`
