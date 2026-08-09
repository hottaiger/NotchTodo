import AppKit
import SwiftData
import SwiftUI
import UniformTypeIdentifiers

@MainActor
final class AppDelegate: NSObject, NSApplicationDelegate {
    private(set) var settings = AppSettings()
    private(set) var store: TaskStore!
    private(set) var panelController: NotchPanelController!
    private var shortcut: GlobalShortcutManager?
    private var scheduler: TaskScheduler?
    private var statusItem: NSStatusItem?
    private var settingsWindow: NSWindow?
    private(set) var recoveryMessage: String?

    func applicationDidFinishLaunching(_ notification: Notification) {
        NSApp.setActivationPolicy(.accessory)
        installStatusItem()
        let factory = ModelContainerFactory.make()
        recoveryMessage = factory.recoveryMessage
        store = TaskStore(context: factory.container.mainContext)
        try? ArchiveService.archiveCompletedTasks(in: store.context)
        try? ArchiveService.purgeExpiredArchives(in: store.context)
        scheduler = TaskScheduler(context: store.context)
        scheduler?.start()
        panelController = NotchPanelController(store: store, settings: settings)
        shortcut = GlobalShortcutManager { [weak self] in self?.panelController.toggle() }
        configureShortcut(settings.shortcutChoice)
    }

    func configureShortcut(_ choice: ShortcutChoice) { shortcut?.register(choice) }
    func refreshPanelPlacement() { panelController.collapse() }

    private func installStatusItem() {
        let item = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)
        item.button?.title = "✓"
        item.button?.toolTip = "NotchTodo"
        item.button?.setAccessibilityLabel("NotchTodo")
        let menu = NSMenu()
        menu.addItem(withTitle: "打开待办看板", action: #selector(togglePanel), keyEquivalent: "")
        menu.addItem(withTitle: "导出 JSON…", action: #selector(exportTasks), keyEquivalent: "")
        menu.addItem(withTitle: "导入 JSON…", action: #selector(importTasks), keyEquivalent: "")
        menu.addItem(withTitle: "设置…", action: #selector(showSettings), keyEquivalent: ",")
        menu.addItem(.separator())
        menu.addItem(withTitle: "退出 NotchTodo", action: #selector(quit), keyEquivalent: "q")
        menu.items.forEach { $0.target = self }
        item.menu = menu
        statusItem = item
    }

    @objc private func togglePanel() { panelController.toggle() }
    @objc private func quit() { NSApp.terminate(nil) }

    @objc private func showSettings() {
        if settingsWindow == nil {
            let window = NSWindow(contentRect: NSRect(x: 0, y: 0, width: 440, height: 320), styleMask: [.titled, .closable], backing: .buffered, defer: false)
            window.title = "NotchTodo 设置"
            window.isReleasedWhenClosed = false
            window.contentView = NSHostingView(rootView: SettingsView(settings: settings, appDelegate: self))
            window.center()
            settingsWindow = window
        }
        NSApp.activate(ignoringOtherApps: true)
        settingsWindow?.makeKeyAndOrderFront(nil)
    }

    @objc private func exportTasks() {
        do {
            let panel = NSSavePanel()
            panel.allowedContentTypes = [.json]
            panel.nameFieldStringValue = "NotchTodo-backup.json"
            guard panel.runModal() == .OK, let url = panel.url else { return }
            try TaskTransferService.exportData(from: store.context).write(to: url, options: .atomic)
        } catch { present(error) }
    }

    @objc private func importTasks() {
        let panel = NSOpenPanel()
        panel.allowedContentTypes = [.json]
        panel.allowsMultipleSelection = false
        guard panel.runModal() == .OK, let url = panel.url else { return }
        do {
            try TaskTransferService.importData(Data(contentsOf: url), into: store.context)
            store.refresh()
        } catch { present(error) }
    }

    private func present(_ error: Error) {
        let alert = NSAlert(error: error)
        alert.runModal()
    }
}
