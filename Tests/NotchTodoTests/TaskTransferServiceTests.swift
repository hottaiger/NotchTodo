import XCTest
import SwiftData
@testable import NotchTodo

final class TaskTransferServiceTests: XCTestCase {
    @MainActor func testExportThenImportPreservesTask() throws {
        let source = try ModelContainer(for: TodoTask.self, configurations: ModelConfiguration(isStoredInMemoryOnly: true)).mainContext
        source.insert(TodoTask(title: "备份", bucket: .later, priority: .high, note: "说明"))
        try source.save()
        let data = try TaskTransferService.exportData(from: source)
        let destination = try ModelContainer(for: TodoTask.self, configurations: ModelConfiguration(isStoredInMemoryOnly: true)).mainContext
        try TaskTransferService.importData(data, into: destination)
        let result = try destination.fetch(FetchDescriptor<TodoTask>())
        XCTAssertEqual(result.count, 1)
        XCTAssertEqual(result.first?.title, "备份")
        XCTAssertEqual(result.first?.priority, .high)
    }

    @MainActor func testRejectsUnsupportedVersion() throws {
        let data = "{\"version\":99,\"exportedAt\":\"2026-08-09T00:00:00Z\",\"tasks\":[]}".data(using: .utf8)!
        let context = try ModelContainer(for: TodoTask.self, configurations: ModelConfiguration(isStoredInMemoryOnly: true)).mainContext
        XCTAssertThrowsError(try TaskTransferService.importData(data, into: context))
    }
}
