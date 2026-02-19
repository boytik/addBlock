
import Foundation
import SwiftUI

extension String {
    /// Returns localized string for the current language
    var localized: String {
        NSLocalizedString(self, comment: "")
    }
    
    /// Returns localized string with arguments
    func localized(_ arguments: CVarArg...) -> String {
        String(format: self.localized, arguments: arguments)
    }
}

// MARK: - Text View Extension
extension Text {
    /// Creates a Text view with localized string
    init(localized key: String) {
        self.init(key.localized)
    }
}
