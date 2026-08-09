import SwiftUI

struct QuickAddView: View {
    @ObservedObject var store: TaskStore
    @FocusState.Binding var focused: Bool
    let activity: () -> Void
    @State private var title = ""

    var body: some View {
        TextField("添加待办，按回车创建", text: $title)
            .textFieldStyle(.plain)
            .padding(.horizontal, 10).padding(.vertical, 8)
            .background(.thinMaterial, in: RoundedRectangle(cornerRadius: 10, style: .continuous))
            .focused($focused)
            .onSubmit { if store.add(title: title) != nil { title = "" }; activity() }
            .onChange(of: title) { _, _ in activity() }
            .accessibilityLabel("快速新增待办")
    }
}
