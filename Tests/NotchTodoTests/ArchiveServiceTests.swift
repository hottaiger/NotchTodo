import XCTest
import SwiftData
@testable import NotchTodo

final class ArchiveServiceTests: XCTestCase {
    @MainActor func testArchivesPreviousDayCompletionAndPurgesAfterThirtyDays() throws {
        let container = try ModelContainer(for: TodoTask.self, configurations: ModelConfiguration(isStoredInMemoryOnly: true))
        let context = container.mainContext
        let oldCompletion = Calendar.current.date(byAdding: .day, value: -1, to: .now)!
        let task = TodoTask(title: "已完成", completedAt: oldCompletion)
        context.insert(task)
        try ArchiveService.archiveCompletedTasks(in: context)
        XCTAssertNotNil(task.archivedAt)
        try ArchiveService.purgeExpiredArchives(in: context, now: Calendar.current.date(byAdding: .day, value: 31, to: .now)!)
        XCTAssertTrue(try context.fetch(FetchDescriptor<TodoTask>()).isEmpty)
    }
}
