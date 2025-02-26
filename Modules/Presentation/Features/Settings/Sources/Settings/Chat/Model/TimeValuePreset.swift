import Foundation
import MEGAL10n

@MainActor
public enum TimeValuePreset: Identifiable, Equatable {
    case untilTomorrowMorning
    case none
    case never
    case minutes(Int64)
    case hours(Int64)
    
    public nonisolated var id: Int64 {
        switch self {
        case .untilTomorrowMorning: -3
        case .none: -2
        case .never: -1
        case .minutes(let minutes): minutes
        case .hours(let hours): hours * 60
        }
    }
    
    public static let fiveMinutes = TimeValuePreset.minutes(5)
    public static let thirtyMinutes = TimeValuePreset.minutes(30)
    public static let fortyFiveMinutes = TimeValuePreset.minutes(45)
    public static let oneHour = TimeValuePreset.hours(1)
    public static let threeHours = TimeValuePreset.hours(3)
    public static let sixHours = TimeValuePreset.hours(6)
        
    var displayName: String {
        switch self {
        case .untilTomorrowMorning: isMorningEightToday ?  Strings.Localizable.untilThisMorning : Strings.Localizable.untilTomorrowMorning
        case .none: ""
        case .never: Strings.Localizable.never
        case .minutes(let minutes): Strings.Localizable.Chat.AutoAway.minute(Int(minutes))
        case .hours(let hours): Strings.Localizable.Chat.AutoAway.hour(Int(hours))
        }
    }
    
    var timeInterval: TimeInterval {
        switch self {
        case .untilTomorrowMorning: timeLeftUntilEightAM
        case .minutes(let minutes): TimeInterval(minutes * 60)
        case .hours(let hours): TimeInterval(hours * 3600)
        default: 0
        }
    }
}

// - MARK: Auto away time presets
public extension TimeValuePreset {
    static func autoAwayOptions() -> [TimeValuePreset] {
        [fiveMinutes, thirtyMinutes, fortyFiveMinutes, oneHour, threeHours, sixHours, .never]
    }

    /// Creates an `TimeValuePreset` from a given number of minutes.
    /// If the value doesn't match a defined option, returns `.none`.
    /// - Parameter minutes: The number of minutes to initialize the `TimeValuePreset`.
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

// - MARK: Mute notifications time presets
extension TimeValuePreset {
    public static func muteNotificationOptions() -> [TimeValuePreset] {
        [thirtyMinutes, oneHour, sixHours, .untilTomorrowMorning, .never]
    }
}

// - MARK: Private
extension TimeValuePreset {
    private var isMorningEightToday: Bool {
        let calendar = Calendar.current
        let comp = calendar.dateComponents([.hour], from: Date())
        if let hour = comp.hour, hour < 8 {
            return true
        }

        return false
    }
    
    private var timeLeftUntilEightAM: TimeInterval {
        let calendar = Calendar.current
        let now = Date()
        
        if let today = now.startOfDay(on: calendar) {
            var dayComponent = DateComponents()
            dayComponent.day = !isMorningEightToday ? 1 : 0
            dayComponent.hour = 8
            
            if let date = calendar.date(byAdding: dayComponent, to: today) {
                return date.timeIntervalSince(now)
            }
        }
        
        return 0
    }
}
