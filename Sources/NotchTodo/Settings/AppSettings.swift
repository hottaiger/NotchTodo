import Foundation
import SwiftUI

enum ExternalDisplayPlacement: String, CaseIterable, Identifiable {
    case center, leading, trailing
    var id: String { rawValue }
    var title: String { ["center": "顶部居中", "leading": "顶部左侧", "trailing": "顶部右侧"][rawValue]! }
}

enum ShortcutChoice: String, CaseIterable, Identifiable {
    case optionSpace, optionReturn
    static let defaultChoice: ShortcutChoice = .optionReturn
    var id: String { rawValue }
    var title: String { self == .optionSpace ? "Option + Space" : "Option + Enter" }
    var keyCode: UInt32 { self == .optionSpace ? 49 : 36 }
}

@MainActor
final class AppSettings: ObservableObject {
    static let defaultAutoCollapseSeconds = 10.0
    @AppStorage("autoCollapseSeconds") var autoCollapseSeconds = AppSettings.defaultAutoCollapseSeconds
    @AppStorage("showsTaskCount") var showsTaskCount = true
    @AppStorage("externalDisplayPlacement") var externalDisplayPlacementRaw = ExternalDisplayPlacement.center.rawValue
    @AppStorage("launchAtLogin") var launchAtLogin = false
    @AppStorage("shortcutChoice") var shortcutChoiceRaw = ShortcutChoice.defaultChoice.rawValue

    var externalDisplayPlacement: ExternalDisplayPlacement {
        get { ExternalDisplayPlacement(rawValue: externalDisplayPlacementRaw) ?? .center }
        set { externalDisplayPlacementRaw = newValue.rawValue }
    }

    var shortcutChoice: ShortcutChoice {
        get { ShortcutChoice(rawValue: shortcutChoiceRaw) ?? .defaultChoice }
        set { shortcutChoiceRaw = newValue.rawValue }
    }
}
