import Foundation

class ContentBlockerRequestHandler: NSObject, NSExtensionRequestHandling {

    private static let appGroupID = "group.test.com.adblock"
    private static let fallbackResourceName = "blockerList"

    func beginRequest(with context: NSExtensionContext) {
        let data: Data? = loadRulesFromContainer() ?? loadRulesFromBundle()
        guard let data else {
            context.completeRequest(returningItems: nil)
            return
        }
        let item = NSExtensionItem()
        item.attachments = [
            NSItemProvider(
                item: data as NSSecureCoding,
                typeIdentifier: "public.json"
            )
        ]
        context.completeRequest(returningItems: [item])
    }

    /// Правила из App Group (основное приложение пишет сюда).
    private func loadRulesFromContainer() -> Data? {
        guard let containerURL = FileManager.default.containerURL(forSecurityApplicationGroupIdentifier: Self.appGroupID) else { return nil }
        return try? Data(contentsOf: containerURL.appendingPathComponent("blockerList.json"))
    }

    /// Запасной вариант при недоступном контейнере (Container: null без VPN): из бандла расширения.
    private func loadRulesFromBundle() -> Data? {
        guard let url = Bundle.main.url(forResource: Self.fallbackResourceName, withExtension: "json") else { return nil }
        return try? Data(contentsOf: url)
    }
}
