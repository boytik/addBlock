//
//  File.swift
//  Adblock
//
//  Created by Telegram: @Boytik_E on 03.02.2026.
//
import Foundation

/// Хранит дату первого включения защиты (кнопка на General).
/// Используется для ограничения данных графика — не показываем «активность» до включения адблокера.
final class AppInstallDateStore {
    static let shared = AppInstallDateStore()

    private let protectionKey = "protection_first_enabled_date"
    private let appGroupID = "group.test.com.adblock"

    /// Дата, с которой показываем данные графика (первое включение защиты или сегодня, если ещё не включали).
    var installDate: Date {
        guard let defaults = UserDefaults(suiteName: appGroupID) else {
            return Date()
        }
        if let stored = defaults.object(forKey: protectionKey) as? Date {
            return stored
        }
        return Date()
    }

    /// Вызвать при первом включении защиты (isWorking → true).
    func recordProtectionEnabled() {
        guard let defaults = UserDefaults(suiteName: appGroupID) else { return }
        if defaults.object(forKey: protectionKey) as? Date != nil { return }
        defaults.set(Date(), forKey: protectionKey)
    }

    private init() {}
}
