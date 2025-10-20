import Foundation

enum TransferBadgeState: Sendable {
    case none
    case completed
    case paused
    case overquota
    case error
    
    /// Priority order for badge display when multiple states could be active
    var priority: Int {
        switch self {
        case .error: 4      // Highest priority
        case .overquota: 3
        case .paused: 2
        case .completed: 1
        case .none: 0       // Lowest priority
        }
    }
}

extension TransferBadgeState: Comparable {
    static func < (lhs: TransferBadgeState, rhs: TransferBadgeState) -> Bool {
        lhs.priority < rhs.priority
    }
}
