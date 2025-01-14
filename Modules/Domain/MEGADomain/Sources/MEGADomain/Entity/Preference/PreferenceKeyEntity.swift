import Foundation

public enum PreferenceKeyEntity: String {
    case dontShowAgainAddPhoneNumber
    case backupHeartbeatRegistrationId
    case lastPSARequestTimestamp
    case launchTab
    case lastDateTurnOnNotificationsShowed
    case timesTurnOnNotificationsShowed
    case launchTabSelected
    case launchTabSuggested
    case offlineLogOutWarningDismissed
    case showRecents
    case lastRequestedVersionForRating
    case firstRun = "FirstRun"
    case hasUpdatedBackupToFixExistingBackupNameStorageIssue
    case sortingPreference = "MEGASortingPreference"
    case sortingPreferenceType = "SortOrderType"
    case favouritesIndexed
    case savePhotoToGallery = "IsSavePhotoToGalleryEnabled"
    case saveVideoToGallery = "IsSaveVideoToGalleryEnabled"
    case callsSoundNotification
    case logging
    case apiEnvironment = "MEGAAPIEnv"
    case secureFingerprintVerification
    case lastMoveActionTargetPath
    case lastMoveActionTargetDate
    case lastCopyActionTargetPath
    case lastCopyActionTargetDate
    case agreedCopywriteWarning
    case waitingRoomWarningBannerDismissed
    case isCallUIVisible
    case isWaitingRoomListVisible
    case shouldDisplayMediaDiscoveryWhenMediaOnly
    case mediaDiscoveryShouldIncludeSubfolderMedia
    case autoMediaDiscoveryBannerDismissed
    case isCameraUploadsEnabled = "IsCameraUploadsEnabled"
    case cameraUploadsCellularDataUsageAllowed = "IsUseCellularConnectionEnabled"
    case lastEncourageUpgradeDate = "lastEncourageUpgradeDate"
    case isSaveMediaCapturedToGalleryEnabled
    case presentPasscodeLater = "presentPasscodeLater"
    case lastStorageBannerDismissedDate = "lastStorageBannerDismissedDate"
    case lastCloseAdsButtonTappedDate
    case queuedTransfersPaused
    case transfersPaused
}
