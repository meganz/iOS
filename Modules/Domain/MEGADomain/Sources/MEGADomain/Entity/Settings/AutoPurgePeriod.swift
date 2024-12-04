import Foundation

@MainActor
public enum AutoPurgePeriod: Identifiable, Equatable {
    case days(Int)
    case years(Int)
    case never
    
    public nonisolated var id: Int {
        switch self {
        case .never:
            return -1 // Use `-1` to represent `never`
        default:
            return durationInDays ?? -1 // Fallback to `-1` if nil (unlikely for other cases)
        }
    }
    
    public nonisolated var durationInDays: Int? {
        switch self {
        case .days(let days):
            return days
        case .years(let years):
            return years * 365
        case .never:
            return nil
        }
    }
    
    public var displayName: String {
        switch self {
        case .days(let days):
            return "\(days) days"
        case .years(let years):
            return years == 1 ? "1 year" : "\(years) years"
        case .never:
            return "Never"
        }
    }
    
    public static let sevenDays = AutoPurgePeriod.days(7)
    public static let fourteenDays = AutoPurgePeriod.days(14)
    public static let thirtyDays = AutoPurgePeriod.days(30)
    public static let sixtyDays = AutoPurgePeriod.days(60)
    public static let oneYear = AutoPurgePeriod.years(1)
    public static let fiveYears = AutoPurgePeriod.years(5)
    public static let tenYears = AutoPurgePeriod.years(10)
    
    public static func options(forProUser isPro: Bool) -> [AutoPurgePeriod] {
        if isPro {
            return [.sevenDays, .fourteenDays, .thirtyDays, .sixtyDays, .oneYear, .fiveYears, .tenYears, .never]
        } else {
            return [.sevenDays, .fourteenDays, .thirtyDays]
        }
    }
}
