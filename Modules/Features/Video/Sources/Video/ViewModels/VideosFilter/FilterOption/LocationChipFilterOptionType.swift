import MEGADomain
import MEGAL10n

public enum LocationChipFilterOptionType: CaseIterable, Sendable {
    case allLocation
    case cloudDrive
    case cameraUploads
    case sharedItems
    
    public init?(rawValue: String) {
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
    
    public var stringValue: String {
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

// MARK: - Domain Entity Conversion

public extension LocationChipFilterOptionType {
    init(from entity: VideoLocationFilterEntity) {
        switch entity {
        case .allLocation:
            self = .allLocation
        case .cloudDrive:
            self = .cloudDrive
        case .cameraUploads:
            self = .cameraUploads
        case .sharedItems:
            self = .sharedItems
        }
    }

    var toVideoLocationFilterEntity: VideoLocationFilterEntity {
        switch self {
        case .allLocation:
            .allLocation
        case .cloudDrive:
            .cloudDrive
        case .cameraUploads:
            .cameraUploads
        case .sharedItems:
            .sharedItems
        }
    }
}
