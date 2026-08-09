import SwiftUI

struct TaskCardView: View {
    let task: TodoTask
    @ObservedObject var store: TaskStore
    @Binding var editorTask: TodoTask?
    let activity: () -> Void

    var body: some View {
        HStack(alignment: .top, spacing: 6) {
            Button {
                task.isCompleted ? store.reopen(task) : store.complete(task)
                activity()
            } label: {
                Image(systemName: task.isCompleted ? "checkmark.circle.fill" : "circle")
                    .foregroundStyle(task.isCompleted ? .green : priorityColor)
            }.buttonStyle(.plain).accessibilityLabel(task.isCompleted ? "恢复 \(task.title)" : "完成 \(task.title)")
            VStack(alignment: .leading, spacing: 3) {
                Text(task.title).font(.system(size: 12, weight: .medium)).strikethrough(task.isCompleted).lineLimit(2)
                if let dueDate = task.dueDate {
                    Label(dueDate.formatted(.dateTime.month(.abbreviated).day()), systemImage: "calendar")
                        .font(.system(size: 9)).foregroundStyle(task.isDueSoon ? .orange : .secondary)
                }
            }
            Spacer(minLength: 0)
        }
        .padding(7)
        .background(.background.opacity(0.55), in: RoundedRectangle(cornerRadius: 9, style: .continuous))
        .contentShape(Rectangle())
        .onTapGesture { editorTask = task; activity() }
        .contextMenu {
            Menu("优先级") { ForEach(TaskPriority.allCases) { priority in Button(priority.title) { store.setPriority(task, priority: priority) } } }
            Button("延期到明天") { store.deferToTomorrow(task) }
            Button("删除", role: .destructive) { store.delete(task) }
        }
        .accessibilityElement(children: .combine)
    }

    private var priorityColor: Color { switch task.priority { case .high: .red; case .medium: .blue; case .low: .gray } }
}
