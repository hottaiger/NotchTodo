import SwiftUI

struct TaskEditorView: View {
    let task: TodoTask
    @ObservedObject var store: TaskStore
    @Environment(\.dismiss) private var dismiss
    @State private var title: String
    @State private var priority: TaskPriority
    @State private var dueDate: Date
    @State private var hasDueDate: Bool
    @State private var note: String

    init(task: TodoTask, store: TaskStore) {
        self.task = task; self.store = store
        _title = State(initialValue: task.title); _priority = State(initialValue: task.priority)
        _dueDate = State(initialValue: task.dueDate ?? .now); _hasDueDate = State(initialValue: task.dueDate != nil)
        _note = State(initialValue: task.note)
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            Text("编辑待办").font(.headline)
            TextField("标题", text: $title)
            Picker("优先级", selection: $priority) { ForEach(TaskPriority.allCases) { Text($0.title).tag($0) } }.pickerStyle(.segmented)
            Toggle("设置截止日期", isOn: $hasDueDate)
            if hasDueDate { DatePicker("截止日期", selection: $dueDate, displayedComponents: [.date, .hourAndMinute]) }
            TextField("备注", text: $note, axis: .vertical).lineLimit(3...6)
            HStack { Button("取消") { dismiss() }; Spacer(); Button("保存") { store.update(task, title: title, priority: priority, dueDate: hasDueDate ? dueDate : nil, note: note); dismiss() }.keyboardShortcut(.defaultAction) }
        }
        .padding().frame(width: 360)
    }
}
