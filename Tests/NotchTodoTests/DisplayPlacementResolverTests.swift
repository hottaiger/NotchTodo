import XCTest
@testable import NotchTodo

final class DisplayPlacementResolverTests: XCTestCase {
    func testCollapsedFrameUsesRequestedWidthAndHeight() {
        let screen = NSScreen.main!
        let frame = DisplayPlacementResolver.collapsedFrame(on: screen, width: 104, height: 34)
        if DisplayPlacementResolver.notchRightFrame(on: screen, width: 104) == nil {
            XCTAssertEqual(frame.size, CGSize(width: 104, height: 34))
        } else {
            XCTAssertEqual(frame, DisplayPlacementResolver.notchRightFrame(on: screen, width: 104)!)
        }
    }

    func testNotchFrameUsesRightSafeAuxiliaryArea() {
        let screen = NSScreen.main!
        let frame = DisplayPlacementResolver.collapsedFrame(on: screen)
        guard let right = screen.auxiliaryTopRightArea else {
            XCTAssertEqual(frame.maxY, screen.visibleFrame.maxY, accuracy: 0.5)
            return
        }
        XCTAssertEqual(frame.minY, right.minY, accuracy: 0.5)
        XCTAssertEqual(frame.minX, right.minX - 18, accuracy: 0.5)
        XCTAssertLessThanOrEqual(frame.maxX, right.maxX)
        XCTAssertEqual(frame.height, right.height, accuracy: 0.5)
    }

    func testNotchPanelCanBecomeKeyForQuickEntry() {
        XCTAssertTrue(NotchPanelWindow(contentRect: .zero).canBecomeKey)
    }

    func testNotchPanelFloatsAboveMenuBarToReceiveClicks() {
        XCTAssertGreaterThan(NotchPanelWindow(contentRect: .zero).level.rawValue, NSWindow.Level.mainMenu.rawValue)
    }
}
