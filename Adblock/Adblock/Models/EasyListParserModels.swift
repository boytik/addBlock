//
//  EasyListParser.swift
//  Adblock
//
//  Created by Евгений on 11.02.2026.
//

import Foundation

enum ABPRuleType {
    case block
    case exception
}

struct ABPRule {
    let pattern: String
    let type: ABPRuleType
    let resourceTypes: [String]
}
