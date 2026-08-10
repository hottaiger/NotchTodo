import XCTest
@testable import NotchTodo

final class PanelTransitionPhaseTests: XCTestCase {
    func testCollapsedAndCollapsingAreDistinct() {
        XCTAssertNotEqual(PanelTransitionPhase.collapsed, .collapsing)
    }

    func testFishIsHiddenWhenBoardIsExpanded() {
        XCTAssertTrue(NotchSurfaceView.shouldShowFish(isExpanded: false))
        XCTAssertFalse(NotchSurfaceView.shouldShowFish(isExpanded: true))
    }

    func testFishBackgroundIsHiddenWhenBoardIsExpanded() {
        XCTAssertTrue(NotchSurfaceView.shouldUseFishBackground(isExpanded: false))
        XCTAssertFalse(NotchSurfaceView.shouldUseFishBackground(isExpanded: true))
    }

    func testFishShakeStartsAfterFiveHundredMilliseconds() {
        XCTAssertEqual(PixelFishView.collapseShakeDelay, 0.5, accuracy: 0.001)
    }

    func testAttachedCapsuleUsesHalfItsHeightForTheLowerTrailingCorner() {
        XCTAssertEqual(NotchAttachedCapsuleShape.bottomTrailingRadius(isNotchAttached: true, height: 38), 19, accuracy: 0.001)
        XCTAssertEqual(NotchAttachedCapsuleShape.bottomTrailingRadius(isNotchAttached: false, height: 38), 10, accuracy: 0.001)
    }
}
