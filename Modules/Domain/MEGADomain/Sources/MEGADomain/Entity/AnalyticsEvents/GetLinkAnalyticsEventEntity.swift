import Foundation

public enum GetLinkAnalyticsEventEntity: Sendable {
    case sendDecryptionKeySeparateForFolderEnabled
    case sendDecryptionKeySeparateForFileEnabled
    case sendDecryptionKeySeparateForFolderDisabled
    case sendDecryptionKeySeparateForFileDisabled
    case setExpiryDateForFolderEnabled
    case setExpiryDateForFileEnabled
    case setExpiryDateForFolderDisabled
    case setExpiryDateForFileDisabled
    case setPasswordForFolder
    case setPasswordForFile
    case confirmPaswordForFolder
    case confirmPasswordForFile
    case resetPasswordForFolder
    case resetPasswordForFile
    case removePasswordForFolder
    case removePasswordForFile
    case shareFolder
    case shareFile
    case shareMultipleNodes
    case getLinkForFolder
    case getLinkForFile
    case getLinkMultipleNodes
    case proFeaturesSeePlansFolder
    case proFeaturesNotNowFolder
    case proFeaturesSeePlansFile
    case proFeaturesNotNowFile
    case encryptFolder
    case encryptFile
    case viewUpgradeToProScreenFile
    case viewUpgradeToProScreenFolder
}
