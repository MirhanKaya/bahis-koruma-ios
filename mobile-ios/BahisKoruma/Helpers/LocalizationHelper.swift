import Foundation
import SwiftUI

// MARK: - Shorthand wrapper

/// Shorthand for NSLocalizedString.
/// Usage: L("main.title")
func L(_ key: String) -> String {
    NSLocalizedString(key, comment: "")
}

// MARK: - SwiftUI Text convenience

extension Text {
    /// Creates a localized Text view using the L() key system.
    /// Usage: Text(localized: "main.title")
    init(localized key: String) {
        self.init(L(key))
    }
}

// MARK: - Language detection

enum AppLanguage: String, CaseIterable {
    case turkish = "tr"
    case english = "en"

    var displayName: String {
        switch self {
        case .turkish: return "Türkçe"
        case .english: return "English"
        }
    }

    static var current: AppLanguage {
        let preferred = Locale.preferredLanguages.first ?? "en"
        return preferred.hasPrefix("tr") ? .turkish : .english
    }
}
