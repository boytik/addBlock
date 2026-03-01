import Foundation

enum DomainActivityRange {
    case last24h
    case lastWeek
    case lastMonth
}

/// Хранит «активности» по доменам (ruleId).
/// Реальные данные из Safari недоступны, поэтому при первом открытии генерируются случайные значения.
/// Для режима создания правила используется «маркетинговая» модель — правдоподобные данные.
final class DomainActivityStore {
    private let storageKey = "domain_activities"
    private let appGroupID = "group.test.com.adblock"

    /// ruleId -> массив точек (дата, количество)
    private var activitiesByRule: [UUID: [DomainActivityPoint]] = [:]

    init() {
        restore()
    }

    /// Возвращает активности для правила. Если их нет — генерирует случайные и сохраняет.
    /// Генерация только с `createdAt` до текущего момента (для старых правил без createdAt — последний день).
    /// Учитывается дата установки приложения — не показываем данные до установки.
    func getOrCreateActivities(for ruleId: UUID, createdAt: Date?) -> [DomainActivityPoint] {
        let calendar = Calendar.current
        let now = Date()
        let installDate = AppInstallDateStore.shared.installDate
        let baseStart = createdAt ?? calendar.date(byAdding: .day, value: -1, to: now) ?? now
        let startDate = max(baseStart, installDate)

        if let existing = activitiesByRule[ruleId] {
            let cutoff = createdAt ?? calendar.date(byAdding: .day, value: -7, to: now) ?? now
            let effectiveCutoff = max(cutoff, installDate)
            return existing.filter { $0.date >= calendar.startOfDay(for: effectiveCutoff) }
        }
        let generated = generateRandomActivities(from: startDate, to: now)
        activitiesByRule[ruleId] = generated
        persist()
        return generated
    }

    func getActivities(for ruleId: UUID) -> [DomainActivityPoint] {
        activitiesByRule[ruleId] ?? []
    }

    /// Маркетинговая модель: генерирует правдоподобные данные для нового правила.
    /// Средний сайт: 15–40 рекламных запросов; blockTrackers +20%; antiAdblock (heavy news) — больше.
    /// Учитывается дата установки — для периодов до установки возвращаем 0.
    func generateMarketingActivities(
        blockTrackers: Bool,
        antiAdblock: Bool,
        hideElements: Bool,
        range: DomainActivityRange
    ) -> [DomainActivityPoint] {
        let calendar = Calendar.current
        let now = Date()
        let installDate = calendar.startOfDay(for: AppInstallDateStore.shared.installDate)
        var multiplier: Double = 1.0
        if blockTrackers { multiplier += 0.2 }
        if antiAdblock { multiplier += 0.15 }
        if hideElements { multiplier += 0.05 }
        let baseMin = 15
        let baseMax = 40
        let baseRange = baseMin...baseMax

        // Всегда 7 столбцов; для периодов до установки — count = 0
        let bucketCount = 7

        switch range {
        case .last24h:
            var result: [DomainActivityPoint] = []
            for i in 0..<bucketCount {
                let hourOffset = -24 + (i * 24 / bucketCount)
                guard let date = calendar.date(byAdding: .hour, value: hourOffset, to: now),
                      let hourStart = calendar.date(bySetting: .minute, value: 0, of: date) else { continue }
                let value = hourStart >= installDate
                    ? max(0, Int(Double(Int.random(in: baseRange)) * multiplier) + Int.random(in: -5...8))
                    : 0
                result.append(DomainActivityPoint(date: hourStart, count: value))
            }
            return result.sorted { $0.date < $1.date }
        case .lastWeek:
            var result: [DomainActivityPoint] = []
            for dayOffset in (0..<7).reversed() {
                guard let date = calendar.date(byAdding: .day, value: -dayOffset, to: now) else { continue }
                let start = calendar.startOfDay(for: date)
                let value = start >= installDate
                    ? max(0, Int(Double(Int.random(in: baseRange)) * multiplier) + Int.random(in: -8...12))
                    : 0
                result.append(DomainActivityPoint(date: start, count: value))
            }
            return result
        case .lastMonth:
            var result: [DomainActivityPoint] = []
            for i in 0..<bucketCount {
                let dayOffset = -30 + (i * 30 / bucketCount)
                guard let date = calendar.date(byAdding: .day, value: dayOffset, to: now) else { continue }
                let start = calendar.startOfDay(for: date)
                let value = start >= installDate
                    ? max(0, Int(Double(Int.random(in: baseRange)) * multiplier) + Int.random(in: -10...15))
                    : 0
                result.append(DomainActivityPoint(date: start, count: value))
            }
            return result.sorted { $0.date < $1.date }
        }
    }

    // MARK: - Private

    private func generateRandomActivities(from startDate: Date, to endDate: Date) -> [DomainActivityPoint] {
        var result: [DomainActivityPoint] = []
        let calendar = Calendar.current
        let start = calendar.startOfDay(for: startDate)
        let end = calendar.startOfDay(for: endDate)

        var current = start
        while current <= end {
            let count = Int.random(in: 5...150)
            result.append(DomainActivityPoint(date: current, count: count))
            guard let next = calendar.date(byAdding: .day, value: 1, to: current) else { break }
            current = next
        }

        return result
    }

    private func persist() {
        var payload: [String: [DomainActivityPoint]] = [:]
        for (id, points) in activitiesByRule {
            payload[id.uuidString] = points
        }
        guard let data = try? JSONEncoder().encode(payload),
              let defaults = UserDefaults(suiteName: appGroupID)
        else { return }
        defaults.set(data, forKey: storageKey)
    }

    private func restore() {
        guard let defaults = UserDefaults(suiteName: appGroupID),
              let data = defaults.data(forKey: storageKey),
              let payload = try? JSONDecoder().decode([String: [DomainActivityPoint]].self, from: data)
        else { return }
        activitiesByRule = [:]
        for (key, points) in payload {
            if let id = UUID(uuidString: key) {
                activitiesByRule[id] = points
            }
        }
    }
}
