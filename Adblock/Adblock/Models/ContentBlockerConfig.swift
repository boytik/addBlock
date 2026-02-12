

import Foundation

struct ContentBlockerConfig {
    let isEnabled: Bool
    let blockAds: Bool
    let blockTrackers: Bool
    let antiAdblock: Bool
    let whiteListedDomains: [String]
}
