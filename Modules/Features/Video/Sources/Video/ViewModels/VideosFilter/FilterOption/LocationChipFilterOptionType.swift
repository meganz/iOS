import MEGAL10n

enum LocationChipFilterOptionType: CaseIterable, Sendable {
    case allLocation
    case cloudDrive
    case cameraUploads
    case sharedItems
    
    init?(rawValue: String) {
        switch rawValue {
        case Strings.Localizable.Videos.Tab.All.Filter.Location.Option.allLocations:
            self = .allLocation
        case Strings.Localizable.Videos.Tab.All.Filter.Location.Option.cloudDrive:
            self = .cloudDrive
        case Strings.Localizable.Videos.Tab.All.Filter.Location.Option.cameraUploads:
            self = .cameraUploads
        case Strings.Localizable.Videos.Tab.All.Filter.Location.Option.sharedItems:
            self = .sharedItems
        default:
            return nil
        }
    }
    
    var stringValue: String {
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
