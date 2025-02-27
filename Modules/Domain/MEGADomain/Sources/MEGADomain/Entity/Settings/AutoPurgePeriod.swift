import Foundation

public enum AutoPurgePeriod: Identifiable, Equatable, Sendable {
    case none
    case never
    case days(Int)
    case years(Int)
    
    public var id: Int {
        switch self {
        case .none: -2
        case .never: -1
        default: durationInDays ?? -1
        }
    }
    
    public var durationInDays: Int? {
        switch self {
        case .none:
            nil
        case .never:
            0
        case .days(let days):
            days
        case .years(let years):
            years * 365
        }
    }
    
    public static let sevenDays = AutoPurgePeriod.days(7)
    public static let fourteenDays = AutoPurgePeriod.days(14)
    public static let thirtyDays = AutoPurgePeriod.days(30)
    public static let sixtyDays = AutoPurgePeriod.days(60)
    public static let oneYear = AutoPurgePeriod.years(1)
    public static let fiveYears = AutoPurgePeriod.years(5)
    public static let tenYears = AutoPurgePeriod.years(10)
    
    public static func options(forPaidAccount isPaid: Bool) -> [AutoPurgePeriod] {
        if isPaid {
            return [.sevenDays, .fourteenDays, .thirtyDays, .sixtyDays, .oneYear, .fiveYears, .tenYears, .never]
        } else {
            return [.sevenDays, .fourteenDays, .thirtyDays]
        }
    }
}

public extension AutoPurgePeriod {
    /// Creates an `AutoPurgePeriod` from a given number of days.
    /// If the value doesn't match a defined option, returns `.none`.
    /// - Parameter days: The number of days to initialize the `AutoPurgePeriod`.
    init(fromDays days: Int) {
        switch days {
        case 0:
            self = .never
        case 7:
            self = .sevenDays
        case 14:
            self = .fourteenDays
        case 30:
            self = .thirtyDays
        case 60:
            self = .sixtyDays
        case 365:
            self = .oneYear
        case 1825:
            self = .fiveYears
        case 3650:
            self = .tenYears
        default:
            self = .none
        }
    }
}
