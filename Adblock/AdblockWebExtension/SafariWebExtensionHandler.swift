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

        if type == "blocked" {
            let count = message["count"] as? Int ?? 1
            let current = defaults?.integer(forKey: "blockedAdsCount") ?? 0
            defaults?.set(current + count, forKey: "blockedAdsCount")
            context.completeRequest(returningItems: nil)
            return
        }

        if type == "getStats" {
            let blocked = defaults?.integer(forKey: "blockedAdsCount") ?? 0
            let response = NSExtensionItem()
            response.userInfo = [SFExtensionMessageKey: ["blocked": blocked]]
            context.completeRequest(returningItems: [response])
            return
        }

        context.completeRequest(returningItems: nil)
    }
}
