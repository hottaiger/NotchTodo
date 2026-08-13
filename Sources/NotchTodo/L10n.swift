import Foundation

/// Localization helper. Strings are looked up in the module resource bundle so the
/// SwiftPM executable target can ship `.lproj` resources alongside the binary.
enum L10n {
    private static let bundle = Bundle.module
    static func t(_ key: String, comment: String = "") -> String {
        NSLocalizedString(key, bundle: bundle, comment: comment)
    }
}
