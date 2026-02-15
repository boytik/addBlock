import SafariServices

class SafariWebExtensionHandler: NSObject, NSExtensionRequestHandling {

    func beginRequest(with context: NSExtensionContext) {
        print("[AdblockWebExtension] beginRequest called")

        guard
            let item = context.inputItems.first as? NSExtensionItem,
            let message = item.userInfo?[SFExtensionMessageKey] as? [String: Any],
            let type = message["type"] as? String
        else {
            print("[AdblockWebExtension] Failed to parse message - inputItems: \(context.inputItems.count)")
            context.completeRequest(returningItems: nil)
            return
        }

        print("[AdblockWebExtension] Received message type: \(type)")

        if type == "blocked" {
            let defaults = UserDefaults(suiteName: "group.test.com.adblock")
            let current = defaults?.integer(forKey: "blockedCount") ?? 0
            defaults?.set(current + 1, forKey: "blockedCount")
            print("[AdblockWebExtension] Blocked count updated: \(current) -> \(current + 1)")
        }

        context.completeRequest(returningItems: nil)
    }
}
