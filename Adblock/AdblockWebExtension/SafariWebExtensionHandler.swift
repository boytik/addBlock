import SafariServices
import os.log

class SafariWebExtensionHandler: NSObject, NSExtensionRequestHandling {

    func beginRequest(with context: NSExtensionContext) {

        guard let item = context.inputItems.first as? NSExtensionItem,
              let message = item.userInfo?[SFExtensionMessageKey] else {
            return
        }

        print("🔥 NATIVE RECEIVED:")
        print(message)

        let response = NSExtensionItem()
        response.userInfo = [
            SFExtensionMessageKey: ["status": "received"]
        ]

        context.completeRequest(returningItems: [response], completionHandler: nil)
    }
}
