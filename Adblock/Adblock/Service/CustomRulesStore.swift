//
//  File.swift
//  Adblock
//
//  Created by Telegram: @Boytik_E on 03.02.2026.
//
import Foundation
import Combine

final class CustomRulesStore: ObservableObject {

    @Published var rules: [CustomRule] = []

    private let storageKey = "custom_rules"
    private let appGroupID = "group.test.com.adblock"

    init() {
        restore()
    }

    // MARK: - CRUD

    /// Добавляет правило. Возвращает false если домен уже есть.
    @discardableResult
    func add(rule: CustomRule) -> Bool {
        let domain = normalizeDomain(rule.domain)
        guard !domain.isEmpty else { return false }
        guard !rules.contains(where: { $0.domain == domain }) else { return false }

        let newRule = CustomRule(
            domain: domain,
            blockAds: rule.blockAds,
            blockTrackers: rule.blockTrackers,
            antiAdblock: rule.antiAdblock,
            hideElements: rule.hideElements,
            isEnabled: rule.isEnabled,
            createdAt: Date()
        )
        rules.append(newRule)
        persist()
        return true
    }

    /// Обновляет правило по существующему ID (сохраняет id)
    func update(withId id: UUID, rule: CustomRule) {
        guard let index = rules.firstIndex(where: { $0.id == id }) else { return }
        let domain = normalizeDomain(rule.domain)
        let existing = rules[index]
        rules[index] = CustomRule(
            id: id,
            domain: domain,
            blockAds: rule.blockAds,
            blockTrackers: rule.blockTrackers,
            antiAdblock: rule.antiAdblock,
            hideElements: rule.hideElements,
            isEnabled: rule.isEnabled,
            createdAt: existing.createdAt
        )
        persist()
    }

    /// Обновляет правило по его собственному ID
    func update(_ rule: CustomRule) {
        update(withId: rule.id, rule: rule)
    }

    func remove(id: UUID) {
        rules.removeAll { $0.id == id }
        persist()
    }

    func contains(domain: String, excludingId: UUID? = nil) -> Bool {
        let normalized = normalizeDomain(domain)
        return rules.contains { $0.domain == normalized && $0.id != excludingId }
    }

    // MARK: - Generate filter lines for RulesService

    func filterLines() -> [String] {
        var lines: [String] = []

        for rule in rules where rule.isEnabled {
            let d = rule.domain

            if rule.blockAds {
                lines.append("||\(d)^$popup")
                lines.append("\(d)##.ad")
                lines.append("\(d)##.ads")
                lines.append("\(d)##.adsbygoogle")
                lines.append("\(d)##[id*=\"ad-\"]")
                lines.append("\(d)##[class*=\"ad-\"]")
                lines.append("\(d)##[id*=\"banner\"]")
                lines.append("\(d)##[class*=\"banner\"]")
                lines.append("\(d)##iframe[src*=\"ad\"]")
                lines.append("\(d)##.sponsored")
                lines.append("\(d)##.advertisement")
            }

            if rule.blockTrackers {
                lines.append("\(d)##img[src*=\"track\"]")
                lines.append("\(d)##img[src*=\"pixel\"]")
                lines.append("\(d)##script[src*=\"analytics\"]")
                lines.append("\(d)##script[src*=\"tracker\"]")
                lines.append("\(d)##[id*=\"tracking\"]")
            }

            if rule.antiAdblock {
                lines.append("\(d)##.adblock-notice")
                lines.append("\(d)##.adblock-overlay")
                lines.append("\(d)##[class*=\"adblock\"]")
                lines.append("\(d)##[id*=\"adblock\"]")
                lines.append("\(d)##[class*=\"disable-ad\"]")
                lines.append("\(d)##.modal-overlay[class*=\"ad\"]")
            }

            if rule.hideElements {
                lines.append("\(d)##.social-widget")
                lines.append("\(d)##.social-share")
                lines.append("\(d)##[class*=\"social\"]")
                lines.append("\(d)##.comments-section")
                lines.append("\(d)##.comment-section")
                lines.append("\(d)##[id*=\"comments\"]")
                lines.append("\(d)##[id*=\"disqus\"]")
                lines.append("\(d)##footer")
                lines.append("\(d)##.footer")
                lines.append("\(d)##.site-footer")
                lines.append("\(d)##.cookie-banner")
                lines.append("\(d)##[class*=\"cookie\"]")
                lines.append("\(d)##[class*=\"consent\"]")
                lines.append("\(d)##.newsletter-popup")
                lines.append("\(d)##[class*=\"newsletter\"]")
                lines.append("\(d)##[class*=\"popup\"]")
            }
        }

        return lines
    }

    /// Хеш для RulesService
    func contentHash() -> String {
        let data = (try? JSONEncoder().encode(rules)) ?? Data()
        return String(data.hashValue)
    }

    // MARK: - Private

    private func normalizeDomain(_ input: String) -> String {
        var domain = input
            .lowercased()
            .trimmingCharacters(in: .whitespacesAndNewlines)

        if domain.hasPrefix("http://") { domain.removeFirst(7) }
        if domain.hasPrefix("https://") { domain.removeFirst(8) }
        if domain.hasPrefix("www.") { domain.removeFirst(4) }
        if let slash = domain.firstIndex(of: "/") {
            domain = String(domain[..<slash])
        }
        return domain
    }

    private func persist() {
        guard let data = try? JSONEncoder().encode(rules),
              let defaults = UserDefaults(suiteName: appGroupID)
        else { return }
        defaults.set(data, forKey: storageKey)
    }

    private func restore() {
        guard let defaults = UserDefaults(suiteName: appGroupID),
              let data = defaults.data(forKey: storageKey),
              let items = try? JSONDecoder().decode([CustomRule].self, from: data)
        else { return }
        self.rules = items
    }
}
