import SwiftUI

@main
struct NotchTodoApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) private var appDelegate

    var body: some Scene {
        Settings { SettingsView(settings: appDelegate.settings, appDelegate: appDelegate) }
    }
}
