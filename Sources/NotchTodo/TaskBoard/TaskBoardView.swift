import SwiftUI

struct TaskBoardView: View {
    @ObservedObject var store: TaskStore
    @ObservedObject var controller: NotchPanelController
    @State private var isCompletedExpanded = false
    @State private var activeSheet: ActiveSheet?
    @FocusState private var quickAddFocused: Bool
    @AppStorage("onboardingCompleted") private var onboardingCompleted = false

    private enum ActiveSheet: Identifiable {
        case onboarding
        case editor(TodoTask)
        var id: String {
            switch self {
            case .onboarding: "onboarding"
            case .editor(let task): "editor-\(task.id.uuidString)"
            }
        }
    }

    private var totalToday: Int { store.activeTasks.filter { $0.bucket != .later }.count + store.completedTasks.count }
    private var completeCount: Int { store.completedTasks.count }

    var body: some View {
        VStack(spacing: 12) {
            HStack(alignment: .center) {
                VStack(alignment: .leading, spacing: 2) {
                    Text(Date.now.formatted(.dateTime.weekday(.wide).month().day())).font(.system(size: 13, weight: .semibold))
                    Text("专注于下一件重要的事").font(.system(size: 11)).foregroundStyle(.secondary)
                }
                Spacer()
                CompletionProgressView(completed: completeCount, total: totalToday).frame(width: 34, height: 34)
                Button { controller.collapse() } label: { Image(systemName: "xmark").font(.system(size: 11, weight: .bold)) }.buttonStyle(.plain).accessibilityLabel("收起看板")
            }
            QuickAddView(store: store, focused: $quickAddFocused, activity: controller.registerActivity)
            HStack(alignment: .top, spacing: 8) {
                ForEach([TaskBucket.now, .later]) { bucket in
                    TaskColumnView(bucket: bucket, tasks: store.tasks(in: bucket), store: store, editorTask: editorBinding, activity: controller.registerActivity)
                }
            }
            if !store.completedTasks.isEmpty {
                DisclosureGroup("已完成 \(store.completedTasks.count) 项", isExpanded: $isCompletedExpanded) {
                    ForEach(store.completedTasks, id: \.id) { task in
                        TaskCardView(task: task, store: store, editorTask: editorBinding, activity: controller.registerActivity)
                    }
                }
                .font(.system(size: 11))
            }
            if store.activeTasks.isEmpty {
                Text("今天还没有待办。输入一件想完成的事。")
                    .font(.system(size: 12)).foregroundStyle(.secondary).frame(maxWidth: .infinity, minHeight: 42)
            }
        }
        .padding(14)
        .frame(width: 420, height: 510, alignment: .top)
        .background(.regularMaterial)
        .clipShape(RoundedRectangle(cornerRadius: 20, style: .continuous))
        .overlay(RoundedRectangle(cornerRadius: 20, style: .continuous).stroke(.white.opacity(0.12)))
        .onAppear {
            DispatchQueue.main.async { quickAddFocused = true }
            if !onboardingCompleted { activeSheet = .onboarding }
        }
        .onKeyPress(.escape) { controller.collapse(); return .handled }
        .sheet(item: $activeSheet, onDismiss: { activeSheet = nil }) { sheet in
            switch sheet {
            case .onboarding: OnboardingView { onboardingCompleted = true; activeSheet = nil }
            case .editor(let task): TaskEditorView(task: task, store: store)
            }
        }
        .alert("出错了", isPresented: Binding(get: { store.saveError != nil }, set: { if !$0 { store.clearError() } })) {
            Button("好") { store.clearError() }
        } message: {
            Text(store.saveError ?? "")
        }
    }

    /// Maps the unified `activeSheet` state onto the `editorTask: Binding<TodoTask?>`
    /// expected by TaskColumnView / TaskCardView, so child views need no changes.
    private var editorBinding: Binding<TodoTask?> {
        Binding(
            get: {
                if case .editor(let task) = activeSheet { return task }
                return nil
            },
            set: { newValue in
                if let newValue {
                    activeSheet = .editor(newValue)
                } else if case .editor = activeSheet {
                    activeSheet = nil
                }
            }
        )
    }
}
