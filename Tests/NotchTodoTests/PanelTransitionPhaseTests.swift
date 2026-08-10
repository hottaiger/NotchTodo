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

    func testFishShakeStartsAfterEightHundredMilliseconds() {
        XCTAssertEqual(PixelFishView.collapseShakeDelay, 0.8, accuracy: 0.001)
    }
}
