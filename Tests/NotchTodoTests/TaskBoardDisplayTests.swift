import XCTest
@testable import NotchTodo

final class TaskBoardDisplayTests: XCTestCase {
    func testCapsuleShowsFirstTitleAndTruncatesAfterFiveCharacters() {
        XCTAssertEqual(CapsuleSummaryText.title(from: ["SFE-42281", "稍后处理"]), "SFE-4...")
        XCTAssertEqual(CapsuleSummaryText.title(from: ["买牛奶"]), "买牛奶")
        XCTAssertEqual(CapsuleSummaryText.title(from: []), "暂无待办")
    }
}
