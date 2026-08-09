import Foundation
import SwiftData

@MainActor
enum ArchiveService {
    static func archiveCompletedTasks(in context: ModelContext, now: Date = .now) throws {
        let endOfPreviousDay = Calendar.current.startOfDay(for: now)
        let tasks = try context.fetch(FetchDescriptor<TodoTask>())
        for task in tasks where task.completedAt != nil && task.archivedAt == nil && task.completedAt! < endOfPreviousDay {
            task.archivedAt = now
        }
        try context.save()
    }

    static func purgeExpiredArchives(in context: ModelContext, now: Date = .now) throws {
        let deadline = Calendar.current.date(byAdding: .day, value: -30, to: now)!
        let tasks = try context.fetch(FetchDescriptor<TodoTask>())
        for task in tasks where task.archivedAt.map({ $0 < deadline }) == true {
            context.delete(task)
        }
        try context.save()
    }
}
