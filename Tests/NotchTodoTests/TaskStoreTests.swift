import XCTest
import SwiftData
@testable import NotchTodo

final class TaskStoreTests: XCTestCase {
    @MainActor
    private func makeStore() throws -> TaskStore {
        let configuration = ModelConfiguration(isStoredInMemoryOnly: true)
        let container = try ModelContainer(for: TodoTask.self, configurations: configuration)
        return TaskStore(context: container.mainContext)
    }

    @MainActor func testNewTaskUsesTodayAndIgnoresBlankTitle() throws {
        let store = try makeStore()
        XCTAssertNil(store.add(title: "  \n"))
        let task = try XCTUnwrap(store.add(title: "买牛奶"))
        XCTAssertEqual(task.bucket, .now)
        XCTAssertEqual(store.activeTasks.count, 1)
    }

    @MainActor func testMoveAppendsTaskToTargetBucket() throws {
        let store = try makeStore()
        let first = try XCTUnwrap(store.add(title: "先做" , bucket: .now))
        let second = try XCTUnwrap(store.add(title: "再做", bucket: .today))
        store.move(second, to: .now)
        XCTAssertEqual(store.tasks(in: .now).map(\.id), [first.id, second.id])
    }

    @MainActor func testCompleteAndReopenTask() throws {
        let store = try makeStore()
        let task = try XCTUnwrap(store.add(title: "完成它"))
        store.complete(task)
        XCTAssertTrue(task.isCompleted)
        XCTAssertEqual(store.completedTasks.count, 1)
        store.reopen(task)
        XCTAssertFalse(task.isCompleted)
        XCTAssertEqual(store.activeTasks.count, 1)
    }

    @MainActor func testNowColumnIncludesLegacyTodayTasks() throws {
        let store = try makeStore()
        let task = try XCTUnwrap(store.add(title: "遗留今天", bucket: .today))
        XCTAssertEqual(store.tasks(in: .now).map(\.id), [task.id])
    }
}
