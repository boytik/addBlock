import Foundation

/// Хранит дату первого запуска приложения.
/// Используется для ограничения данных графика — не показываем «активность» до установки.
final class AppInstallDateStore {
    static let shared = AppInstallDateStore()

    private let key = "app_first_launch_date"
    private let appGroupID = "group.test.com.adblock"

    private(set) lazy var installDate: Date = {
        guard let defaults = UserDefaults(suiteName: appGroupID) else {
            return Date()
        }
        if let stored = defaults.object(forKey: key) as? Date {
            return stored
        }
        let now = Date()
        defaults.set(now, forKey: key)
        return now
    }()

    private init() {}
}
