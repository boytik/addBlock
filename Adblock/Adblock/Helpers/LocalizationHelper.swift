import Foundation
import SwiftUI

extension String {
    /// Локализация отключена — возвращает строку как есть
    var localized: String { self }
    func localized(_ arguments: CVarArg...) -> String {
        String(format: self, arguments: arguments)
    }
}
