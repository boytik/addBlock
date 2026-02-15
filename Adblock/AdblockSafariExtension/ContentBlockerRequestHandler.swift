import Foundation

class ContentBlockerRequestHandler: NSObject, NSExtensionRequestHandling {

    func beginRequest(with context: NSExtensionContext) {

        guard
            let containerURL = FileManager.default
                .containerURL(forSecurityApplicationGroupIdentifier: "group.test.com.adblock"),
            let data = try? Data(contentsOf: containerURL.appendingPathComponent("blockerList.json"))
        else {
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
}
