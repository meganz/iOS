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
        case .noCallKit: self = .noCallKit
        case .appsPreferences: self = .appsPreferences
        case .contentConsumptionPreferences: self = .contentConsumptionPreferences
        case .lastReadNotification: self = .lastReadNotification
        default: return nil
        }
    }
}

extension UserAttributeEntity {
    public func toMEGAUserAttribute() -> MEGAUserAttribute {
        switch self {
        case .avatar: .avatar
        case .firstName: .firstname
        case .lastName: .lastname
        case .authRing: .authRing
        case .lastInteraction: .lastInteraction
        case .eD25519PublicKey: .ed25519PublicKey
        case .cU25519PublicKey: .cu25519PublicKey
        case .keyring: .keyring
        case .sigRsaPublicKey: .sigRsaPublicKey
        case .sigCU255PublicKey: .sigCU255PublicKey
        case .language: .language
        case .pwdReminder: .pwdReminder
        case .disableVersions: .disableVersions
        case .contactLinkVerification: .contactLinkVerification
        case .richPreviews: .richPreviews
        case .rubbishTime: .rubbishTime
        case .lastPSA: .lastPSA
        case .storageState: .storageState
        case .geolocation: .geolocation
        case .cameraUploadsFolder: .cameraUploadsFolder
        case .myChatFilesFolder: .myChatFilesFolder
        case .pushSettings: .pushSettings
        case .alias: .alias
        case .deviceNames: .deviceNames
        case .backupsFolder: .backupsFolder
        case .cookieSettings: .cookieSettings
        case .jsonSyncConfigData: .jsonSyncConfigData
        case .noCallKit: .noCallKit
        case .appsPreferences: .appsPreferences
        case .contentConsumptionPreferences: .contentConsumptionPreferences
        case .lastReadNotification: .lastReadNotification
        }
    }
}

extension MEGAUserAttribute {
    public func toAttributeEntity() -> UserAttributeEntity? {
        switch self {
        case .avatar: .avatar
        case .firstname: .firstName
        case .lastname: .lastName
        case .authRing: .authRing
        case .lastInteraction: .lastInteraction
        case .ed25519PublicKey: .eD25519PublicKey
        case .cu25519PublicKey: .cU25519PublicKey
        case .keyring: .keyring
        case .sigRsaPublicKey: .sigRsaPublicKey
        case .sigCU255PublicKey: .sigCU255PublicKey
        case .language: .language
        case .pwdReminder: .pwdReminder
        case .disableVersions: .disableVersions
        case .contactLinkVerification: .contactLinkVerification
        case .richPreviews: .richPreviews
        case .rubbishTime: .rubbishTime
        case .lastPSA: .lastPSA
        case .storageState: .storageState
        case .geolocation: .geolocation
        case .cameraUploadsFolder: .cameraUploadsFolder
        case .myChatFilesFolder: .myChatFilesFolder
        case .pushSettings: .pushSettings
        case .alias: .alias
        case .deviceNames: .deviceNames
        case .backupsFolder: .backupsFolder
        case .cookieSettings: .cookieSettings
        case .jsonSyncConfigData: .jsonSyncConfigData
        case .noCallKit: .noCallKit
        case .appsPreferences: .appsPreferences
        case .contentConsumptionPreferences: .contentConsumptionPreferences
        case .lastReadNotification: .lastReadNotification
        @unknown default: nil
        }
    }
}
