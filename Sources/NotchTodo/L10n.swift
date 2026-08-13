import Foundation

/// Localization helper. Strings are looked up in the module resource bundle so the
/// SwiftPM executable target can ship `.lproj` resources alongside the binary.
enum L10n {
    private static let bundle = Bundle.module

    static func t(_ key: String, comment: String = "") -> String {
        NSLocalizedString(key, bundle: bundle, comment: comment)
    }

    /// Localized string with positional arguments (e.g. `"已完成 %lld 项"`).
    static func t(_ key: String, _ args: CVarArg...) -> String {
        String(format: NSLocalizedString(key, bundle: bundle, comment: ""), arguments: args)
    }
}
