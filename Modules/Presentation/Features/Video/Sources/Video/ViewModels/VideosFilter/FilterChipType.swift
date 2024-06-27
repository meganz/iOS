import MEGAL10n

enum FilterChipType {
    case location
    case duration
}

extension FilterChipType: CustomStringConvertible {
    var description: String {
        switch self {
        case .location:
            Strings.Localizable.Videos.Tab.All.Filter.Location.Title.location
        case .duration:
            Strings.Localizable.Videos.Tab.All.Filter.Duration.Title.duration
        }
    }
}
