import Foundation
import SwiftData

@MainActor
enum ModelContainerFactory {
    static func make() -> (container: ModelContainer, recoveryMessage: String?) {
        let storeURL = applicationSupportDirectory().appendingPathComponent("NotchTodo.store")
        let schema = Schema([TodoTask.self])
        do {
            let configuration = ModelConfiguration("NotchTodo", schema: schema, url: storeURL, cloudKitDatabase: .none)
            return (try ModelContainer(for: TodoTask.self, configurations: configuration), nil)
        } catch {
            let recoveryDirectory = applicationSupportDirectory().appendingPathComponent("Recovery", isDirectory: true)
            try? FileManager.default.createDirectory(at: recoveryDirectory, withIntermediateDirectories: true)
            let stamp = ISO8601DateFormatter().string(from: .now).replacingOccurrences(of: ":", with: "-")
            for suffix in ["", "-wal", "-shm"] {
                let source = URL(fileURLWithPath: storeURL.path + suffix)
                let destination = recoveryDirectory.appendingPathComponent("NotchTodo-\(stamp).store\(suffix)")
                if FileManager.default.fileExists(atPath: source.path) { try? FileManager.default.moveItem(at: source, to: destination) }
            }
            do {
                let configuration = ModelConfiguration("NotchTodo", schema: schema, url: storeURL, cloudKitDatabase: .none)
                return (try ModelContainer(for: TodoTask.self, configurations: configuration), "本地数据无法读取，原始数据已移至恢复目录。请从菜单栏导入备份。")
            } catch {
                let fallback = ModelConfiguration("NotchTodo-Recovery", schema: schema, isStoredInMemoryOnly: true)
                return (try! ModelContainer(for: TodoTask.self, configurations: fallback), "本地数据无法读取，已启动空白恢复库。请从菜单栏导入备份。")
            }
        }
    }

    private static func applicationSupportDirectory() -> URL {
        let base = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask)[0].appendingPathComponent("NotchTodo", isDirectory: true)
        try? FileManager.default.createDirectory(at: base, withIntermediateDirectories: true)
        return base
    }
}
