import XCTest
@testable import NotchTodo

final class PanelTransitionPhaseTests: XCTestCase {
    func testCollapsedAndCollapsingAreDistinct() {
        XCTAssertNotEqual(PanelTransitionPhase.collapsed, .collapsing)
    }

    func testFishRemainsVisibleWhenBoardIsExpanded() {
        XCTAssertTrue(NotchSurfaceView.shouldShowFish(isExpanded: false))
        XCTAssertTrue(NotchSurfaceView.shouldShowFish(isExpanded: true))
    }

    func testFishUsesBlackBackgroundInBothStates() {
        XCTAssertTrue(NotchSurfaceView.shouldUseFishBackground(isExpanded: false))
        XCTAssertTrue(NotchSurfaceView.shouldUseFishBackground(isExpanded: true))
    }
}
