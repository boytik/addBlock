//
//  ContentBlockerRequestHandler.swift
//  AdblockSafariExtension
//
//  Created by Евгений on 05.02.2026.
//

import Foundation

class ContentBlockerRequestHandler: NSObject, NSExtensionRequestHandling {
    func beginRequest(with context: NSExtensionContext) {
        //МИНИИМАЛЬНЫЙ НАБО ПРАВИЛ КОТОРЫЙ ПОТОМ НАДО ЗАМЕНИТЬ
        let rules = """
            [
              {
                 "trigger": {
                   "url-filter": ".*ads.*"
                  },
                  "action": {
                    "type": "block"
                  }
                }
            ]
            """
        
        guard let data = rules.data(using: .utf8) else {
            context.completeRequest(returningItems: [],
                                    completionHandler: nil
            )
            return
        }
        
        let item = NSExtensionItem()
        item.attachments = [
            NSItemProvider(
                item: data as NSSecureCoding,
                typeIdentifier: "public.json"
            )
        ]
        context.completeRequest(returningItems: [item],
                                completionHandler: nil)
    }
    
    
}
