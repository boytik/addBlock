//
//  File.swift
//  Adblock
//
//  Created by Telegram: @Boytik_E on 03.02.2026.
//
import Foundation
struct WhiteListItem: Identifiable, Codable, Equatable {
    let id: UUID
    let name: String?
    let url: String
    
    init(name: String?, url: String) {
        self.id = UUID()
        self.name = name
        self.url = url
    }
}
