//
//  File.swift
//  Adblock
//
//  Created by Telegram: @Boytik_E on 03.02.2026.
//
import Foundation

struct DomainActivityPoint: Codable, Identifiable {
    let id: UUID
    let date: Date
    let count: Int

    init(id: UUID = UUID(), date: Date, count: Int) {
        self.id = id
        self.date = date
        self.count = count
    }
}
