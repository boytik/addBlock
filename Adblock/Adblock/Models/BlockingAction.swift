//
//  BlockingAction.swift
//  Adblock
//
//  Created by Евгений on 05.02.2026.
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
    let loadType: [String]?
    let resourceType: [String]?
    
    enum CodingKeys: String, CodingKey {
        case urlFilter = "url-filter"
        case ifDomain = "if-domain"
        case loadType = "load-type"
        case resourceType = "resource-type"
    }
}
///Одно правило блокировки
struct BlockingRule: Codable {
    let trigger: BlockingTrigger
    let action: BlockingAction
}
