import MEGADomain
import MEGASdk

extension UserAttributeEntity {
    public init?(rawValue: Int) {
        guard let userAttribute = MEGAUserAttribute(rawValue: rawValue) else { return nil }
        
        switch userAttribute {
        case .avatar: self = .avatar
        case .firstname: self = .firstName
        case .lastname: self = .lastName
        case .authRing: self = .authRing
        case .lastInteraction: self = .lastInteraction
        case .ed25519PublicKey: self = .eD25519PublicKey
        case .cu25519PublicKey: self = .cU25519PublicKey
        case .keyring: self = .keyring
        case .sigRsaPublicKey: self = .sigRsaPublicKey
        case .sigCU255PublicKey: self = .sigCU255PublicKey
        case .language: self = .language
        case .pwdReminder: self = .pwdReminder
        case .disableVersions: self = .disableVersions
        case .contactLinkVerification: self = .contactLinkVerification
        case .richPreviews: self = .richPreviews
        case .rubbishTime: self = .rubbishTime
        case .lastPSA: self = .lastPSA
        case .storageState: self = .storageState
        case .geolocation: self = .geolocation
        case .cameraUploadsFolder: self = .cameraUploadsFolder
        case .myChatFilesFolder: self = .myChatFilesFolder
        case .pushSettings: self = .pushSettings
        case .alias: self = .alias
        case .deviceNames: self = .deviceNames
        case .backupsFolder: self = .backupsFolder
        case .cookieSettings: self = .cookieSettings
        case .jsonSyncConfigData: self = .jsonSyncConfigData
        case .drivesName: self = .drivesName
        case .noCallKit: self = .noCallKit
        case .appsPreferences: self = .appsPreferences
        case .contentConsumptionPreferences: self = .contentConsumptionPreferences
        default: return nil
        }
    }
}
