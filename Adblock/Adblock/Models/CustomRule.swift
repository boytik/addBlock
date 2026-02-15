import Foundation

struct CustomRule: Codable, Identifiable, Equatable {
    let id: UUID
    var domain: String
    var blockAds: Bool
    var blockTrackers: Bool
    var antiAdblock: Bool
    var hideElements: Bool
    var isEnabled: Bool

    init(id: UUID = UUID(),
         domain: String,
         blockAds: Bool = false,
         blockTrackers: Bool = false,
         antiAdblock: Bool = false,
         hideElements: Bool = false,
         isEnabled: Bool = true) {
        self.id = id
        self.domain = domain
        self.blockAds = blockAds
        self.blockTrackers = blockTrackers
        self.antiAdblock = antiAdblock
        self.hideElements = hideElements
        self.isEnabled = isEnabled
    }
}
