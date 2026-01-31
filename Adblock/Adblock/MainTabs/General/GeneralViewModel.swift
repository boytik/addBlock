
import SwiftUI
import Combine


class GeneralViewModel: ObservableObject {
   
    //MARK: Properties
    
    @Published var selectedRange: TimeRange = .today
    @Published var isWorking: Bool = false 
}

enum TimeRange: CaseIterable {
    case today
    case week
    case allTime
    
    var titel: String {
        switch self {
        case .today: return "Today"
        case .week: return "Week"
        case .allTime: return "All Time"
        }
    }
}
