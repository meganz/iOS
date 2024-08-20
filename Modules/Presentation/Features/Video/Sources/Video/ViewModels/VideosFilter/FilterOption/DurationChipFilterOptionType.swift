import MEGAL10n

enum DurationChipFilterOptionType: CaseIterable, Sendable {
    case allDurations
    case lessThan10Seconds
    case between10And60Seconds
    case between1And4Minutes
    case between4And20Minutes
    case moreThan20Minutes
    
    init?(rawValue: String) {
        switch rawValue {
        case Strings.Localizable.Videos.Tab.All.Filter.Duration.Option.allDurations:
            self = .allDurations
        case Strings.Localizable.Videos.Tab.All.Filter.Duration.Option.lessThan10Seconds:
            self = .lessThan10Seconds
        case Strings.Localizable.Videos.Tab.All.Filter.Duration.Option.between10And60Seconds:
            self = .between10And60Seconds
        case Strings.Localizable.Videos.Tab.All.Filter.Duration.Option.between1And4Minutes:
            self = .between1And4Minutes
        case Strings.Localizable.Videos.Tab.All.Filter.Duration.Option.between4And20Minutes:
            self = .between4And20Minutes
        case Strings.Localizable.Videos.Tab.All.Filter.Duration.Option.moreThan20Minutes:
            self = .moreThan20Minutes
        default:
            return nil
        }
    }
    
    var stringValue: String {
        switch self {
        case .allDurations:
            Strings.Localizable.Videos.Tab.All.Filter.Duration.Option.allDurations
        case .lessThan10Seconds:
            Strings.Localizable.Videos.Tab.All.Filter.Duration.Option.lessThan10Seconds
        case .between10And60Seconds:
            Strings.Localizable.Videos.Tab.All.Filter.Duration.Option.between10And60Seconds
        case .between1And4Minutes:
            Strings.Localizable.Videos.Tab.All.Filter.Duration.Option.between1And4Minutes
        case .between4And20Minutes:
            Strings.Localizable.Videos.Tab.All.Filter.Duration.Option.between4And20Minutes
        case .moreThan20Minutes:
            Strings.Localizable.Videos.Tab.All.Filter.Duration.Option.moreThan20Minutes
        }
    }
}
