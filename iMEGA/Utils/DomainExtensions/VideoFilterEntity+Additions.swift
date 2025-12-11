import MEGADomain
import MEGAL10n

extension VideoLocationFilterEntity {
    var localizedTitle: String {
        switch self {
        case .allLocation:
            Strings.Localizable.Videos.Tab.All.Filter.Location.Option.allLocations
        case .cloudDrive:
            Strings.Localizable.Videos.Tab.All.Filter.Location.Option.cloudDrive
        case .cameraUploads:
            Strings.Localizable.Videos.Tab.All.Filter.Location.Option.cameraUploads
        case .sharedItems:
            Strings.Localizable.Videos.Tab.All.Filter.Location.Option.sharedItems
        }
    }
}

extension VideoDurationFilterEntity {
    var localizedTitle: String {
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
