
//
//  File.swift
//  Adblock
//
//  Created by Telegram: @Boytik_E on 03.02.2026.
//
import Foundation

/// Тип блокировки
/// либо блокируем
/// либо игнорируем правила блокировки
enum BlockingActionType: String, Codable {
    case block
    case ignorePreviousRules = "ignore-previous-rules"
}

struct BlockingAction: Codable {
    let type: BlockingActionType
}
///Триггеры блокировки
struct BlockingTrigger: Codable {
    let urlFilter: String
    let ifDomain: [String]?
    let unlessDomain: [String]?
    let loadType: [String]?
    let resourceType: [String]?
    
    enum CodingKeys: String, CodingKey {
        case urlFilter = "url-filter"
        case ifDomain = "if-domain"
        case unlessDomain = "unless-domain"
        case loadType = "load-type"
        case resourceType = "resource-type"
    }
}
///Одно правило блокировки
struct BlockingRule: Codable {
    let trigger: BlockingTrigger
    let action: BlockingAction
    
   
    var dedupeKey: String {
        let domain = trigger.ifDomain?.joined(separator: ",") ?? ""
        let load = trigger.loadType?.joined(separator: ",") ?? ""
        let resource = trigger.resourceType?.joined(separator: ",") ?? ""

        return "\(trigger.urlFilter)|\(domain)|\(load)|\(resource)|\(action.type.rawValue)"
    }
}
