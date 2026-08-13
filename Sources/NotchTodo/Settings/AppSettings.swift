import Foundation
import SwiftUI

enum ExternalDisplayPlacement: String, CaseIterable, Identifiable {
    case center, leading, trailing
    var id: String { rawValue }
    var title: String {
        switch self {
        case .center: L10n.t("placement.center")
        case .leading: L10n.t("placement.leading")
        case .trailing: L10n.t("placement.trailing")
        }
    }
}

enum ShortcutChoice: String, CaseIterable, Identifiable {
    case optionSpace, optionReturn
    static let defaultChoice: ShortcutChoice = .optionReturn
    var id: String { rawValue }
    var title: String { self == .optionSpace ? "Option + Space" : "Option + Enter" }
    var keyCode: UInt32 { self == .optionSpace ? 49 : 36 }
}

enum DecorationKind: String, CaseIterable, Codable, Identifiable {
    case fish, apple
    var id: String { rawValue }
    var title: String {
        switch self {
        case .fish: L10n.t("decoration.fish")
        case .apple: L10n.t("decoration.apple")
        }
    }
}

@MainActor
final class AppSettings: ObservableObject {
    static let defaultAutoCollapseSeconds = 10.0

    private let defaults = UserDefaults.standard

    @Published var autoCollapseSeconds: Double {
        didSet { defaults.set(autoCollapseSeconds, forKey: Keys.autoCollapseSeconds) }
    }
    @Published var showsTaskCount: Bool {
        didSet { defaults.set(showsTaskCount, forKey: Keys.showsTaskCount) }
    }
    @Published var externalDisplayPlacementRaw: String {
        didSet { defaults.set(externalDisplayPlacementRaw, forKey: Keys.externalDisplayPlacement) }
    }
    @Published var launchAtLogin: Bool {
        didSet { defaults.set(launchAtLogin, forKey: Keys.launchAtLogin) }
    }
    @Published var decoration: DecorationKind {
        didSet { defaults.set(decoration.rawValue, forKey: Keys.decoration) }
    }
    @Published var shortcutChoiceRaw: String {
        didSet { defaults.set(shortcutChoiceRaw, forKey: Keys.shortcutChoice) }
    }

    private enum Keys {
        static let autoCollapseSeconds = "autoCollapseSeconds"
        static let showsTaskCount = "showsTaskCount"
        static let externalDisplayPlacement = "externalDisplayPlacement"
        static let launchAtLogin = "launchAtLogin"
        static let decoration = "decoration"
        static let shortcutChoice = "shortcutChoice"
    }

    init() {
        let d = UserDefaults.standard
        autoCollapseSeconds = d.object(forKey: Keys.autoCollapseSeconds) as? Double ?? AppSettings.defaultAutoCollapseSeconds
        showsTaskCount = d.object(forKey: Keys.showsTaskCount) as? Bool ?? true
        externalDisplayPlacementRaw = d.string(forKey: Keys.externalDisplayPlacement) ?? ExternalDisplayPlacement.center.rawValue
        launchAtLogin = (d.object(forKey: Keys.launchAtLogin) as? Bool) ?? true
        shortcutChoiceRaw = d.string(forKey: Keys.shortcutChoice) ?? ShortcutChoice.defaultChoice.rawValue
        decoration = DecorationKind(rawValue: d.string(forKey: Keys.decoration) ?? "") ?? .fish
    }

    var externalDisplayPlacement: ExternalDisplayPlacement {
        get { ExternalDisplayPlacement(rawValue: externalDisplayPlacementRaw) ?? .center }
        set { externalDisplayPlacementRaw = newValue.rawValue }
    }
    var shortcutChoice: ShortcutChoice {
        get { ShortcutChoice(rawValue: shortcutChoiceRaw) ?? .defaultChoice }
        set { shortcutChoiceRaw = newValue.rawValue }
    }
}
