import SwiftUI

struct TaskColumnView: View {
    let bucket: TaskBucket
    let tasks: [TodoTask]
    @ObservedObject var store: TaskStore
    @Binding var editorTask: TodoTask?
    let activity: () -> Void
    @State private var isTargeted = false

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(bucket.title).font(.system(size: 11, weight: .bold)).foregroundStyle(.secondary)
            ForEach(tasks, id: \.id) { task in TaskCardView(task: task, store: store, editorTask: $editorTask, activity: activity).draggable(task.id.uuidString) }
            Spacer(minLength: 4)
        }
        .padding(7)
        .frame(maxWidth: .infinity, minHeight: 220, alignment: .top)
        .background(isTargeted ? Color.accentColor.opacity(0.13) : Color.primary.opacity(0.045), in: RoundedRectangle(cornerRadius: 12, style: .continuous))
        .dropDestination(for: String.self) { identifiers, _ in
            guard let identifier = identifiers.first, let id = UUID(uuidString: identifier), let task = store.tasks.first(where: { $0.id == id }) else { return false }
            store.move(task, to: bucket); activity(); return true
        } isTargeted: { isTargeted = $0 }
        .accessibilityLabel(L10n.t("column.accessibility", bucket.title))
    }
}
