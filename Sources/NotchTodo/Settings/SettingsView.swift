import SwiftUI

struct SettingsView: View {
    @ObservedObject var settings: AppSettings
    let appDelegate: AppDelegate
    @State private var launchError: String?

    var body: some View {
        Form {
            Section("行为") {
                Toggle("显示未完成数量", isOn: $settings.showsTaskCount)
                Picker("自动收起", selection: $settings.autoCollapseSeconds) { Text("关闭").tag(0.0); Text("5 秒").tag(5.0); Text("10 秒").tag(10.0); Text("30 秒").tag(30.0) }
                Picker("全局快捷键", selection: Binding(get: { settings.shortcutChoice }, set: { settings.shortcutChoice = $0; appDelegate.configureShortcut($0) })) { ForEach(ShortcutChoice.allCases) { Text($0.title).tag($0) } }
            }
            Section("显示器") { Picker("外接显示器位置", selection: Binding(get: { settings.externalDisplayPlacement }, set: { settings.externalDisplayPlacement = $0; appDelegate.refreshPanelPlacement() })) { ForEach(ExternalDisplayPlacement.allCases) { Text($0.title).tag($0) } } }
            Section("启动") {
                Toggle("登录时启动", isOn: $settings.launchAtLogin).onChange(of: settings.launchAtLogin) { _, enabled in do { try LaunchAtLoginService.setEnabled(enabled) } catch { launchError = error.localizedDescription; settings.launchAtLogin = LaunchAtLoginService.isEnabled } }
                if let launchError { Text(launchError).foregroundStyle(.red) }
            }
        }.padding().frame(width: 420)
    }
}
