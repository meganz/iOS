import Foundation

public struct UserEntity: Sendable, Equatable {
    public enum VisibilityEntity: Sendable {
        case unknown
        case hidden
        case visible
        case inactive
        case blocked
    }
    
    public struct ChangeTypeEntity: OptionSet, Sendable {
        public let rawValue: Int
        
        public init(rawValue: Int) {
            self.rawValue = rawValue
        }
        
        public static let authentication = ChangeTypeEntity(rawValue: 1 << 0)
        public static let lastInteractionTime = ChangeTypeEntity(rawValue: 1 << 1)
        public static let avatar = ChangeTypeEntity(rawValue: 1 << 2)
        public static let firstname = ChangeTypeEntity(rawValue: 1 << 3)
        public static let lastname = ChangeTypeEntity(rawValue: 1 << 4)
        public static let email = ChangeTypeEntity(rawValue: 1 << 5)
        public static let keyring = ChangeTypeEntity(rawValue: 1 << 6)
        public static let country = ChangeTypeEntity(rawValue: 1 << 7)
        public static let birthday = ChangeTypeEntity(rawValue: 1 << 8)
        public static let publicKeyForChat = ChangeTypeEntity(rawValue: 1 << 9)
        public static let publicKeyForSigning = ChangeTypeEntity(rawValue: 1 << 10)
        public static let signatureForRSAPublicKey = ChangeTypeEntity(rawValue: 1 << 11)
        public static let signatureForCu25519PublicKey = ChangeTypeEntity(rawValue: 1 << 12)
        public static let language = ChangeTypeEntity(rawValue: 1 << 13)
        public static let passwordReminder = ChangeTypeEntity(rawValue: 1 << 14)
        public static let disableVersions = ChangeTypeEntity(rawValue: 1 << 15)
        public static let contactLinkVerification = ChangeTypeEntity(rawValue: 1 << 16)
        public static let richPreviews = ChangeTypeEntity(rawValue: 1 << 17)
        public static let rubbishTimeForAutopurge = ChangeTypeEntity(rawValue: 1 << 18)
        public static let storageState = ChangeTypeEntity(rawValue: 1 << 19)
        public static let geolocation = ChangeTypeEntity(rawValue: 1 << 20)
        public static let cameraUploadsFolder = ChangeTypeEntity(rawValue: 1 << 21)
        public static let myChatFilesFolder = ChangeTypeEntity(rawValue: 1 << 22)
        public static let pushSettings = ChangeTypeEntity(rawValue: 1 << 23)
        public static let userAlias = ChangeTypeEntity(rawValue: 1 << 24)
        public static let unshareableKey = ChangeTypeEntity(rawValue: 1 << 25)
        public static let deviceNames = ChangeTypeEntity(rawValue: 1 << 26)
        public static let backupFolder = ChangeTypeEntity(rawValue: 1 << 27)
        public static let cookieSetting = ChangeTypeEntity(rawValue: 1 << 28)
        public static let NoCallKit = ChangeTypeEntity(rawValue: 1 << 29)
        public static let AppPrefs = ChangeTypeEntity(rawValue: 1 << 30)
        public static let CCPrefs = ChangeTypeEntity(rawValue: 1 << 31)
    }
    
    public enum ChangeSource: Sendable {
        case externalChange
        case explicitRequest
        case implicitRequest
    }
    
    public let email: String?
    public let handle: HandleEntity
    public let visibility: VisibilityEntity
    public let changes: ChangeTypeEntity
    public let changeSource: ChangeSource
    public let addedDate: Date?
    
    public init(email: String?, handle: HandleEntity, visibility: VisibilityEntity, changes: ChangeTypeEntity, changeSource: ChangeSource, addedDate: Date?) {
        self.email = email
        self.handle = handle
        self.visibility = visibility
        self.changes = changes
        self.changeSource = changeSource
        self.addedDate = addedDate
    }
}
