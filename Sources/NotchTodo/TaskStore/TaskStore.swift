import Foundation
import SwiftData
import Combine

@MainActor
final class TaskStore: ObservableObject {
    @Published private(set) var tasks: [TodoTask] = []
    @Published private(set) var activeTasks: [TodoTask] = []
    @Published private(set) var completedTasks: [TodoTask] = []
    @Published private(set) var saveError: String?
    let context: ModelContext

    init(context: ModelContext) {
        self.context = context
        refresh()
    }

    func tasks(in bucket: TaskBucket) -> [TodoTask] {
        activeTasks
            .filter { bucket == .now ? ($0.bucket == .now || $0.bucket == .today) : $0.bucket == bucket }
            .sorted { $0.sortOrder < $1.sortOrder }
    }

    @discardableResult
    func add(title: String, bucket: TaskBucket = .now) -> TodoTask? {
        let cleanTitle = title.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !cleanTitle.isEmpty else { return nil }
        let task = TodoTask(title: cleanTitle, bucket: bucket, sortOrder: nextOrder(in: bucket))
        context.insert(task)
        saveAndRefresh()
        return task
    }

    func update(_ task: TodoTask, title: String, priority: TaskPriority, dueDate: Date?, note: String) {
        let cleanTitle = title.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !cleanTitle.isEmpty else { return }
        task.title = cleanTitle
        task.priority = priority
        task.dueDate = dueDate
        task.note = note
        saveAndRefresh()
    }

    func move(_ task: TodoTask, to bucket: TaskBucket) {
        task.bucket = bucket
        task.sortOrder = nextOrder(in: bucket)
        saveAndRefresh()
    }

    func complete(_ task: TodoTask) {
        task.completedAt = .now
        saveAndRefresh()
    }

    func reopen(_ task: TodoTask) {
        task.completedAt = nil
        task.archivedAt = nil
        task.sortOrder = nextOrder(in: task.bucket)
        saveAndRefresh()
    }

    func delete(_ task: TodoTask) {
        context.delete(task)
        saveAndRefresh()
    }

    func deferToTomorrow(_ task: TodoTask) {
        task.dueDate = Calendar.current.date(byAdding: .day, value: 1, to: Calendar.current.startOfDay(for: .now))
        task.bucket = .today
        task.sortOrder = nextOrder(in: .today)
        saveAndRefresh()
    }

    func setPriority(_ task: TodoTask, priority: TaskPriority) {
        task.priority = priority
        saveAndRefresh()
    }

    func refresh() {
        let descriptor = FetchDescriptor<TodoTask>(sortBy: [SortDescriptor(\.createdAt)])
        do {
            tasks = try context.fetch(descriptor)
        } catch {
            tasks = []
            saveError = error.localizedDescription
        }
        recomputeDerivedLists()
    }

    func clearError() {
        saveError = nil
    }

    private func recomputeDerivedLists() {
        activeTasks = tasks.filter { !$0.isCompleted && !$0.isArchived }
        completedTasks = tasks.filter { $0.isCompleted && !$0.isArchived }.sorted { ($0.completedAt ?? .distantPast) > ($1.completedAt ?? .distantPast) }
    }

    private func nextOrder(in bucket: TaskBucket) -> Double {
        (tasks(in: bucket).map(\.sortOrder).max() ?? -1) + 1
    }

    private func saveAndRefresh() {
        do {
            try context.save()
        } catch {
            saveError = error.localizedDescription
        }
        refresh()
    }
}
