import XCTest
import AppKit
import SwiftData
@testable import NotchTodo

final class TaskStoreTests: XCTestCase {
    func testCopyTitleWritesToGeneralPasteboard() throws {
        TaskTitleClipboard.copy("SFE-42281")
        XCTAssertEqual(NSPasteboard.general.string(forType: .string), "SFE-42281")
    }

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

    @MainActor func testUpdateChangesFields() throws {
        let store = try makeStore()
        let task = try XCTUnwrap(store.add(title: "原标题"))
        let due = Calendar.current.date(byAdding: .day, value: 2, to: .now)!
        store.update(task, title: "新标题", priority: .high, dueDate: due, note: "备注")
        XCTAssertEqual(task.title, "新标题")
        XCTAssertEqual(task.priority, .high)
        XCTAssertEqual(task.note, "备注")
    }

    @MainActor func testUpdateIgnoresBlankTitleAndSkipsAllFields() throws {
        let store = try makeStore()
        let task = try XCTUnwrap(store.add(title: "原标题"))
        store.update(task, title: "   ", priority: .high, dueDate: .now, note: "x")
        XCTAssertEqual(task.title, "原标题")
        XCTAssertEqual(task.priority, .medium)
        XCTAssertNil(task.dueDate)
    }

    @MainActor func testDeleteRemovesFromActive() throws {
        let store = try makeStore()
        let task = try XCTUnwrap(store.add(title: "删除我"))
        XCTAssertEqual(store.activeTasks.count, 1)
        store.delete(task)
        XCTAssertTrue(store.activeTasks.isEmpty)
    }

    @MainActor func testDeferToTomorrowSetsDateAndBucket() throws {
        let store = try makeStore()
        let task = try XCTUnwrap(store.add(title: "推迟", bucket: .later))
        store.deferToTomorrow(task)
        let tomorrow = Calendar.current.date(byAdding: .day, value: 1, to: Calendar.current.startOfDay(for: .now))!
        XCTAssertEqual(task.bucket, .today)
        XCTAssertEqual(try XCTUnwrap(task.dueDate).timeIntervalSince1970, tomorrow.timeIntervalSince1970, accuracy: 1.0)
        XCTAssertTrue(store.tasks(in: .now).contains(where: { $0.id == task.id }))
    }

    @MainActor func testSetPriorityUpdatesPriority() throws {
        let store = try makeStore()
        let task = try XCTUnwrap(store.add(title: "优先"))
        store.setPriority(task, priority: .high)
        XCTAssertEqual(task.priority, .high)
    }

    @MainActor func testReopenClearsArchivedAt() throws {
        let store = try makeStore()
        let task = try XCTUnwrap(store.add(title: "归档测试"))
        task.archivedAt = .now
        store.reopen(task)
        XCTAssertNil(task.archivedAt)
        XCTAssertFalse(task.isArchived)
    }

    @MainActor func testCompletedTasksSortedDescByCompletedAt() throws {
        let store = try makeStore()
        let older = try XCTUnwrap(store.add(title: "旧"))
        let newer = try XCTUnwrap(store.add(title: "新"))
        older.completedAt = Calendar.current.date(byAdding: .hour, value: -2, to: .now)
        newer.completedAt = Calendar.current.date(byAdding: .hour, value: -1, to: .now)
        store.refresh()
        XCTAssertEqual(store.completedTasks.map(\.id), [newer.id, older.id])
    }

    @MainActor func testLaterBucketFilter() throws {
        let store = try makeStore()
        let nowTask = try XCTUnwrap(store.add(title: "现在", bucket: .now))
        let laterTask = try XCTUnwrap(store.add(title: "稍后", bucket: .later))
        XCTAssertEqual(store.tasks(in: .later).map(\.id), [laterTask.id])
        XCTAssertEqual(store.tasks(in: .now).map(\.id), [nowTask.id])
    }

    @MainActor func testNextOrderIsDeterministic() throws {
        let store = try makeStore()
        let t1 = try XCTUnwrap(store.add(title: "一", bucket: .later))
        let t2 = try XCTUnwrap(store.add(title: "二", bucket: .later))
        let t3 = try XCTUnwrap(store.add(title: "三", bucket: .later))
        XCTAssertEqual([t1.sortOrder, t2.sortOrder, t3.sortOrder], [0.0, 1.0, 2.0])
        XCTAssertEqual(store.tasks(in: .later).map(\.id), [t1.id, t2.id, t3.id])
    }

    @MainActor func testMoveBeforeNeighborInsertsInOrder() throws {
        let store = try makeStore()
        let a = try XCTUnwrap(store.add(title: "A", bucket: .later))
        let b = try XCTUnwrap(store.add(title: "B", bucket: .later))
        let c = try XCTUnwrap(store.add(title: "C", bucket: .later))
        store.move(c, to: .later, before: a)
        XCTAssertEqual(store.tasks(in: .later).map(\.id), [c.id, a.id, b.id])
    }

    @MainActor func testMoveBeforeFirstGoesToTop() throws {
        let store = try makeStore()
        let a = try XCTUnwrap(store.add(title: "A", bucket: .later))
        let b = try XCTUnwrap(store.add(title: "B", bucket: .later))
        store.move(b, to: .later, before: a)
        XCTAssertEqual(store.tasks(in: .later).map(\.id), [b.id, a.id])
    }

    @MainActor func testArchivedTasksExcludedFromActiveAndCompleted() throws {
        let store = try makeStore()
        let task = try XCTUnwrap(store.add(title: "完成并归档"))
        store.complete(task)
        task.archivedAt = .now
        store.refresh()
        XCTAssertTrue(store.activeTasks.isEmpty)
        XCTAssertTrue(store.completedTasks.isEmpty)
        XCTAssertEqual(store.archivedTasks.count, 1)
    }

    @MainActor func testUnarchiveReturnsToCompleted() throws {
        let store = try makeStore()
        let task = try XCTUnwrap(store.add(title: "归档"))
        store.complete(task)
        task.archivedAt = .now
        store.refresh()
        store.unarchive(task)
        XCTAssertNil(task.archivedAt)
        XCTAssertTrue(task.isCompleted)
        XCTAssertTrue(store.archivedTasks.isEmpty)
        XCTAssertEqual(store.completedTasks.count, 1)
    }
}
