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
            
            if blockAds && blockTrackers {
                // Примерно 60% ads, 40% trackers
                let adsCount = max(1, Int(round(Double(count) * 0.6)))
                let trackersCount = max(0, count - adsCount)
                let currentAds = defaults?.integer(forKey: "blockedAdsCount") ?? 0
                let currentTrackers = defaults?.integer(forKey: "blockedTrackersCount") ?? 0
                defaults?.set(currentAds + adsCount, forKey: "blockedAdsCount")
                defaults?.set(currentTrackers + trackersCount, forKey: "blockedTrackersCount")
            } else if blockAds {
                let current = defaults?.integer(forKey: "blockedAdsCount") ?? 0
                defaults?.set(current + count, forKey: "blockedAdsCount")
            } else if blockTrackers {
                let current = defaults?.integer(forKey: "blockedTrackersCount") ?? 0
                defaults?.set(current + count, forKey: "blockedTrackersCount")
            }
            context.completeRequest(returningItems: nil)

        case "getStats":
            let ads = defaults?.integer(forKey: "blockedAdsCount") ?? 0
            let trackers = defaults?.integer(forKey: "blockedTrackersCount") ?? 0
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
}
