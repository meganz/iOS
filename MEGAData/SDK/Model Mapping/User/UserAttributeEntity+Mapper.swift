import MEGADomain

extension UserAttributeEntity {
    func toMEGAUserAttribute() -> MEGAUserAttribute {
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
        }
    }
}
