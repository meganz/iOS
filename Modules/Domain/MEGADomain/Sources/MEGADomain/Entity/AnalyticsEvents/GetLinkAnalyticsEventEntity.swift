import Foundation

public enum GetLinkAnalyticsEventEntity {
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
    case shareFolders
    case shareFile
    case shareFiles
    case shareFilesAndFolders
    case getLinkForFolder
    case getLinkForFolders
    case getLinkForFile
    case getLinkForFiles
    case getLinkForFilesAndFolders
    case proFeaturesSeePlansFolder
    case proFeaturesNotNowFolder
    case proFeaturesSeePlansFile
    case proFeaturesNotNowFile
}
