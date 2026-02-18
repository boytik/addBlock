import Foundation

/// Хранит «активности» по доменам (ruleId).
/// Реальные данные из Safari недоступны, поэтому при первом открытии генерируются случайные значения.
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
    func getOrCreateActivities(for ruleId: UUID, createdAt: Date?) -> [DomainActivityPoint] {
        let calendar = Calendar.current
        let now = Date()
        let startDate = createdAt ?? calendar.date(byAdding: .day, value: -1, to: now) ?? now

        if let existing = activitiesByRule[ruleId] {
            let cutoff = createdAt ?? calendar.date(byAdding: .day, value: -7, to: now) ?? now
            return existing.filter { $0.date >= calendar.startOfDay(for: cutoff) }
        }
        let generated = generateRandomActivities(from: startDate, to: now)
        activitiesByRule[ruleId] = generated
        persist()
        return generated
    }

    func getActivities(for ruleId: UUID) -> [DomainActivityPoint] {
        activitiesByRule[ruleId] ?? []
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
