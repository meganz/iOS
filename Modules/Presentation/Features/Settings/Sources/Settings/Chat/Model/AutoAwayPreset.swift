import MEGAL10n

@MainActor
public enum AutoAwayPreset: Identifiable, Equatable {
    case none
    case never
    case minutes(Int)
    case hours(Int)
    
    public nonisolated var id: Int {
        switch self {
        case .none: -2
        case .never: -1
        case .minutes(let minutes): minutes
        case .hours(let hours): hours * 60
        }
    }
    
    public static let fiveMinutes = AutoAwayPreset.minutes(5)
    public static let thirtyMinutes = AutoAwayPreset.minutes(30)
    public static let fortyFiveMinutes = AutoAwayPreset.minutes(45)
    public static let oneHour = AutoAwayPreset.hours(1)
    public static let threeHours = AutoAwayPreset.hours(3)
    public static let sixHours = AutoAwayPreset.hours(6)
    
    public static func options() -> [AutoAwayPreset] {
        [fiveMinutes, thirtyMinutes, fortyFiveMinutes, oneHour, threeHours, sixHours, .never]
    }
    
    var displayName: String {
        switch self {
        case .none: ""
        case .never: Strings.Localizable.never
        case .minutes(let minutes): Strings.Localizable.Chat.AutoAway.minute(minutes)
        case .hours(let hours): Strings.Localizable.Chat.AutoAway.hour(hours)
        }
    }
}

public extension AutoAwayPreset {
    /// Creates an `AutoAwayPreset` from a given number of minutes.
    /// If the value doesn't match a defined option, returns `.none`.
    /// - Parameter minutes: The number of minutes to initialize the `AutoAwayPreset`.
    init(fromMinutes minutes: Int) {
        switch minutes {
        case 5:
            self = .fiveMinutes
        case 30:
            self = .thirtyMinutes
        case 45:
            self = .fortyFiveMinutes
        case 60:
            self = .oneHour
        case 180:
            self = .threeHours
        case 360:
            self = .sixHours
        default:
            self = .none
        }
    }
}
