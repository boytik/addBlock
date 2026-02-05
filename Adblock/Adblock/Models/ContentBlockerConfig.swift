

import Foundation

struct ContentBlockerConfig {
    let isEnabled: Bool
    let blockAds: Bool
    let blockTrackers: Bool
    let whiteListedDomains: [String]
}
