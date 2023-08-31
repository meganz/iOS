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

extension UserAttributeEntity {
    public func toMEGAUserAttribute() -> MEGAUserAttribute {
        switch self {
        case .avatar: return MEGAUserAttribute.avatar
        case .firstName: return MEGAUserAttribute.firstname
        case .lastName: return MEGAUserAttribute.lastname
        case .authRing: return MEGAUserAttribute.authRing
        case .lastInteraction: return MEGAUserAttribute.lastInteraction
        case .eD25519PublicKey: return MEGAUserAttribute.ed25519PublicKey
        case .cU25519PublicKey: return MEGAUserAttribute.cu25519PublicKey
        case .keyring: return MEGAUserAttribute.keyring
        case .sigRsaPublicKey: return MEGAUserAttribute.sigRsaPublicKey
        case .sigCU255PublicKey: return MEGAUserAttribute.sigCU255PublicKey
        case .language: return MEGAUserAttribute.language
        case .pwdReminder: return MEGAUserAttribute.pwdReminder
        case .disableVersions: return MEGAUserAttribute.disableVersions
        case .contactLinkVerification: return MEGAUserAttribute.contactLinkVerification
        case .richPreviews: return MEGAUserAttribute.richPreviews
        case .rubbishTime: return MEGAUserAttribute.rubbishTime
        case .lastPSA: return MEGAUserAttribute.lastPSA
        case .storageState: return MEGAUserAttribute.storageState
        case .geolocation: return MEGAUserAttribute.geolocation
        case .cameraUploadsFolder: return MEGAUserAttribute.cameraUploadsFolder
        case .myChatFilesFolder: return MEGAUserAttribute.myChatFilesFolder
        case .pushSettings: return MEGAUserAttribute.pushSettings
        case .alias: return MEGAUserAttribute.alias
        case .deviceNames: return MEGAUserAttribute.deviceNames
        case .backupsFolder: return MEGAUserAttribute.backupsFolder
        case .cookieSettings: return MEGAUserAttribute.cookieSettings
        case .jsonSyncConfigData: return MEGAUserAttribute.jsonSyncConfigData
        case .drivesName: return MEGAUserAttribute.drivesName
        case .noCallKit: return MEGAUserAttribute.noCallKit
        case .appsPreferences: return MEGAUserAttribute.appsPreferences
        case .contentConsumptionPreferences: return MEGAUserAttribute.contentConsumptionPreferences
        }
    }
}
