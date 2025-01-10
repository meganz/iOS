import Foundation

public enum GetLinkAnalyticsEventEntity: Sendable {
    case sendDecriptionKeySeparateForFolder
    case sendDecriptionKeySeparateForFile
    case setExpiryDateForFolder
    case setExpiryDateForFile
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
}
