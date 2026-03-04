//
//  File.swift
//  Adblock
//
//  Created by Telegram: @Boytik_E on 03.02.2026.
//
import Foundation

/// Хранит статистику блокировок по дням. Формат: [дата "yyyy-MM-dd": ["ads": Int, "trackers": Int]]
final class BlockedStatsStore {
    private let appGroupID = "group.test.com.adblock"
    private let storageKey = "blockedStatsByDay"
    private let migrationKey = "blockedStatsMigrated"
    
    private var defaults: UserDefaults? {
        UserDefaults(suiteName: appGroupID)
    }
    
    // MARK: - Date helpers
    
    private func dateString(from date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        formatter.timeZone = TimeZone.current
        return formatter.string(from: date)
    }
    
    private func last7DateStrings() -> [String] {
        (0..<7).compactMap { offset in
            Calendar.current.date(byAdding: .day, value: -offset, to: Date())
        }.map { dateString(from: $0) }
    }
    
    // MARK: - Load/Save raw data
    
    private func loadRawStats() -> [String: [String: Int]] {
        guard let defaults,
              let data = defaults.data(forKey: storageKey),
              let decoded = try? JSONDecoder().decode([String: [String: Int]].self, from: data)
        else { return [:] }
        return decoded
    }
    
    private func saveRawStats(_ stats: [String: [String: Int]]) {
        guard let defaults,
              let data = try? JSONEncoder().encode(stats)
        else { return }
        defaults.set(data, forKey: storageKey)
    }
    
    // MARK: - Migration from old format
    
    private func migrateIfNeeded() {
        guard let defaults, !defaults.bool(forKey: migrationKey) else { return }
        
        let oldAds = defaults.integer(forKey: "blockedAdsCount")
        let oldTrackers = defaults.integer(forKey: "blockedTrackersCount")
        
        if oldAds > 0 || oldTrackers > 0 {
            var stats = loadRawStats()
            let today = dateString(from: Date())
            var todayStats = stats[today] ?? ["ads": 0, "trackers": 0]
            todayStats["ads"] = (todayStats["ads"] ?? 0) + oldAds
            todayStats["trackers"] = (todayStats["trackers"] ?? 0) + oldTrackers
            stats[today] = todayStats
            saveRawStats(stats)
        }
        
        defaults.removeObject(forKey: "blockedAdsCount")
        defaults.removeObject(forKey: "blockedTrackersCount")
        defaults.set(true, forKey: migrationKey)
    }
    
    // MARK: - Public API (for GeneralViewModel)
    
    /// Загружает статистику с учётом выбранного диапазона
    func loadStats(range: TimeRange) -> (ads: Int, trackers: Int) {
        migrateIfNeeded()
        let stats = loadRawStats()
        
        switch range {
        case .today:
            let today = dateString(from: Date())
            let dayStats = stats[today] ?? [:]
            return (dayStats["ads"] ?? 0, dayStats["trackers"] ?? 0)
        case .week:
            let dates = last7DateStrings()
            let ads = dates.reduce(0) { $0 + (stats[$1]?["ads"] ?? 0) }
            let trackers = dates.reduce(0) { $0 + (stats[$1]?["trackers"] ?? 0) }
            return (ads, trackers)
        case .allTime:
            let ads = stats.values.reduce(0) { $0 + ($1["ads"] ?? 0) }
            let trackers = stats.values.reduce(0) { $0 + ($1["trackers"] ?? 0) }
            return (ads, trackers)
        }
    }
}
