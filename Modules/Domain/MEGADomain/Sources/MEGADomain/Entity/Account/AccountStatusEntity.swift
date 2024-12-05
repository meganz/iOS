import Foundation

public enum AccountStatusEntity: Equatable {
    case active
    case gracePeriod
    case overdue
    case none
}
