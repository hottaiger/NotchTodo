import AppKit
import SwiftUI
import UniformTypeIdentifiers

@MainActor
struct MenuBarController: View {
    let appDelegate: AppDelegate
    @State private var errorMessage: String?

    var body: some View {
        Button("打开待办看板") { appDelegate.panelController.toggle() }
        Button("导出 JSON") { exportTasks() }
        Button("导入 JSON") { importTasks() }
        SettingsLink { Text("设置…") }
        if let recoveryMessage = appDelegate.recoveryMessage { Text(recoveryMessage).foregroundStyle(.orange) }
        if let errorMessage { Text(errorMessage).foregroundStyle(.red) }
        Divider()
        Button("退出 NotchTodo") { NSApplication.shared.terminate(nil) }
    }

    private func exportTasks() {
        do {
            let panel = NSSavePanel(); panel.allowedContentTypes = [.json]; panel.nameFieldStringValue = "NotchTodo-backup.json"
            guard panel.runModal() == .OK, let url = panel.url else { return }
            try TaskTransferService.exportData(from: appDelegate.store.context).write(to: url, options: .atomic)
        } catch { errorMessage = error.localizedDescription }
    }

    private func importTasks() {
        let panel = NSOpenPanel(); panel.allowedContentTypes = [.json]; panel.allowsMultipleSelection = false
        guard panel.runModal() == .OK, let url = panel.url else { return }
        do { try TaskTransferService.importData(Data(contentsOf: url), into: appDelegate.store.context); appDelegate.store.refresh() }
        catch { errorMessage = error.localizedDescription }
    }
}
