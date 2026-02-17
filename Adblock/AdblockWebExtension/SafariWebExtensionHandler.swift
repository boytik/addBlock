import SafariServices

class SafariWebExtensionHandler: NSObject, NSExtensionRequestHandling {

    func beginRequest(with context: NSExtensionContext) {
        guard
            let item = context.inputItems.first as? NSExtensionItem,
            let message = item.userInfo?[SFExtensionMessageKey] as? [String: Any],
            let type = message["type"] as? String
        else {
            context.completeRequest(returningItems: nil)
            return
        }

        let defaults = UserDefaults(suiteName: "group.test.com.adblock")

        switch type {
        case "blocked":
            let count = message["count"] as? Int ?? 1
            let blockAds = defaults?.bool(forKey: "blockAds") ?? false
            let blockTrackers = defaults?.bool(forKey: "blockTrackers") ?? false
            
            var adsToAdd = 0
            var trackersToAdd = 0
            if blockAds && blockTrackers {
                adsToAdd = max(1, Int(round(Double(count) * 0.6)))
                trackersToAdd = max(0, count - adsToAdd)
            } else if blockAds {
                adsToAdd = count
            } else if blockTrackers {
                trackersToAdd = count
            }
            
            if adsToAdd > 0 || trackersToAdd > 0, let defaults {
                addBlockedToDailyStats(ads: adsToAdd, trackers: trackersToAdd, defaults: defaults)
            }
            context.completeRequest(returningItems: nil)

        case "getStats":
            let (ads, trackers) = loadAllTimeStats(defaults: defaults)
            let response = NSExtensionItem()
            response.userInfo = [SFExtensionMessageKey: ["blocked": ads, "trackers": trackers]]
            context.completeRequest(returningItems: [response])

        case "setPicker":
            let active = message["active"] as? Bool ?? false
            defaults?.set(active, forKey: "pickerActive")
            let response = NSExtensionItem()
            response.userInfo = [SFExtensionMessageKey: ["ok": true]]
            context.completeRequest(returningItems: [response])

        case "getPicker":
            let active = defaults?.bool(forKey: "pickerActive") ?? false
            if active {
                defaults?.set(false, forKey: "pickerActive")
            }
            let response = NSExtensionItem()
            response.userInfo = [SFExtensionMessageKey: ["active": active]]
            context.completeRequest(returningItems: [response])

        default:
            context.completeRequest(returningItems: nil)
        }
    }
    
    private func loadAllTimeStats(defaults: UserDefaults?) -> (ads: Int, trackers: Int) {
        guard let defaults,
              let data = defaults.data(forKey: "blockedStatsByDay"),
              let stats = try? JSONDecoder().decode([String: [String: Int]].self, from: data)
        else { return (0, 0) }
        let ads = stats.values.reduce(0) { $0 + ($1["ads"] ?? 0) }
        let trackers = stats.values.reduce(0) { $0 + ($1["trackers"] ?? 0) }
        return (ads, trackers)
    }
    
    /// Сохраняет блокировки по дням. Формат: [дата: ["ads": Int, "trackers": Int]]
    private func addBlockedToDailyStats(ads: Int, trackers: Int, defaults: UserDefaults) {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        formatter.timeZone = TimeZone.current
        let today = formatter.string(from: Date())
        
        var stats: [String: [String: Int]] = [:]
        if let data = defaults.data(forKey: "blockedStatsByDay"),
           let decoded = try? JSONDecoder().decode([String: [String: Int]].self, from: data) {
            stats = decoded
        }
        
        var todayStats = stats[today] ?? ["ads": 0, "trackers": 0]
        todayStats["ads"] = (todayStats["ads"] ?? 0) + ads
        todayStats["trackers"] = (todayStats["trackers"] ?? 0) + trackers
        stats[today] = todayStats
        
        if let data = try? JSONEncoder().encode(stats) {
            defaults.set(data, forKey: "blockedStatsByDay")
        }
    }
}
