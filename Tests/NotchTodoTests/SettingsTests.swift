import XCTest
@testable import NotchTodo

final class SettingsTests: XCTestCase {
    func testDefaultShortcutIsOptionEnter() {
        XCTAssertEqual(ShortcutChoice.defaultChoice, .optionReturn)
        XCTAssertEqual(ShortcutChoice.optionReturn.title, "Option + Enter")
    }
}
