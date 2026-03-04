//
//  File.swift
//  Adblock
//
//  Created by Telegram: @Boytik_E on 03.02.2026.
//
import Foundation

struct ContentBlockerConfig {
    let isEnabled: Bool
    let blockAds: Bool
    let blockTrackers: Bool
    let antiAdblock: Bool
    let whiteListedDomains: [String]
}
