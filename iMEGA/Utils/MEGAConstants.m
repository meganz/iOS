#import "MEGAConstants.h"

#pragma mark - global constants

NSString * const MEGAFirstLoginDate = @"FirstLoginDate";

NSString * const MEGAGroupIdentifier = @"group.mega.ios";

NSString * const MEGASortingPreference = @"MEGASortingPreference";
NSString * const MEGASortingPreferenceType = @"SortOrderType";

NSString * const MEGAViewModePreference = @"MEGAViewModePreference";
NSString * const MEGAExplorerViewModePreference = @"MEGAExplorerViewModePreference";

uint64_t const MEGAInvalidHandle = ~(uint64_t)0;

NSString * const MEGAVoiceMessagesFolderName = @"My voice messages";

NSString * const MEGAAwaitingEmailConfirmationNotification = @"processStarted";

#pragma mark - global notifications

NSString * const MEGALogoutNotification = @"nz.mega.logout";
NSString * const MEGANodesCurrentNotification = @"nz.mega.nodesCurrent";
NSString * const MEGAStorageOverQuotaNotification = @"nz.mega.storageOverQuota";
NSString * const MEGATransferOverQuotaNotification = @"nz.mega.transferOverQuota";
NSString * const MEGABusinessAccountExpiredNotification = @"nz.mega.businessAccountExpired";
NSString * const MEGABusinessAccountActivatedNotification = @"nz.mega.businessAccountActivated";
NSString * const MEGAStorageEventDidChangeNotification = @"nz.mega.event.storage";
NSString * const MEGAMediaInfoReadyNotification = @"nz.mega.mediaInfoReady";
NSString * const MEGAPasscodeViewControllerWillCloseNotification = @"nz.mega.passcodeViewControllerWillClose";
NSString * const MEGAAudioPlayerInterruptionNotification = @"nz.mega.audioPlayerInterruption";
NSString * const MEGASQLiteDiskFullNotification = @"nz.mega.sqliteDiskFull";
NSString * const MEGATransferFinishedNotification = @"nz.mega.transferFinished";
NSString * const MEGAShareCreatedNotification = @"nz.mega.ShareCreated";
NSString * const MEGAEmailHasChangedNotification = @"nz.mega.emailHasChanged";

#pragma mark - global notification keys

NSString * const MEGAStorageEventStateUserInfoKey = @"nz.mega.event.storage.stateKey";
NSString * const MEGATransferUserInfoKey = @"nz.mega.transferKey";

#pragma mark - camera upload notifications

NSString * const MEGACameraUploadStatsChangedNotification = @"nz.mega.cameraUpload.statsChanged";
NSString * const MEGACameraUploadPhotoUploadLocalDiskFullNotification = @"nz.mega.cameraUpload.photo.localDiskFull";
NSString * const MEGACameraUploadVideoUploadLocalDiskFullNotification = @"nz.mega.cameraUpload.video.localDiskFull";
NSString * const MEGACameraUploadPhotoConcurrentCountChangedNotification = @"nz.mega.cameraUpload.photo.concurrentCountChanged";
NSString * const MEGACameraUploadVideoConcurrentCountChangedNotification = @"nz.mega.cameraUpload.video.concurrentCountChanged";
NSString * const MEGACameraUploadUploadingTasksCountChangedNotification = @"nz.mega.cameraUpload.uploadingTaskCountChanged";
NSString * const MEGACameraUploadQueueUpNextAssetNotification = @"nz.mega.cameraUpload.queueUpNextAsset";
NSString * const MEGACameraUploadAllAssetsFinishedProcessingNotification = @"nz.mega.cameraUpload.allAssetsFinishedProcessing";
NSString * const MEGACameraUploadTargetFolderChangedInRemoteNotification = @"nz.mega.cameraUpload.targetFolderChangedInRemote";
NSString * const MEGACameraUploadTargetFolderUpdatedInMemoryNotification = @"nz.mega.cameraUpload.targetFolderUpdatedInMemory";
NSString * const MEGACameraUploadNodeUploadCompleteNotification = @"nz.mega.cameraUpload.nodeUploadCompleteNotification";
NSString * const MEGACameraUploadCompleteNotification = @"nz.mega.cameraUpload.completeNotification";

#pragma mark - camera upload notification keys

NSString * const MEGAPhotoConcurrentCountUserInfoKey = @"nz.mega.photoConcurrentCountKey";
NSString * const MEGAVideoConcurrentCountUserInfoKey = @"nz.mega.videoConcurrentCountKey";
NSString * const MEGACameraUploadsPhotosPausedReasonUserInfoKey = @"nz.mega.cameraUploads.photosPausedReason";
NSString * const MEGACameraUploadsVideosPausedReasonUserInfoKey = @"nz.mega.cameraUploads.videosPausedReason";
NSString * const MEGAHasUploadingTasksReachedMaximumCountUserInfoKey = @"nz.mega.uploadingTasksReachedMaximumCountKey";
NSString * const MEGACurrentUploadingTasksCountUserInfoKey = @"nz.mega.currentUploadingTasksCountKey";
NSString * const MEGAAssetMediaTypeUserInfoKey = @"nz.mega.assetMediaTypeKey";
NSString * const MEGANodeHandleKey = @"nz.mega.nodeHandleKey";

#pragma mark - backups in fm notifications

NSString * const MEGABackupRootFolderUpdatedInMemoryNotification = @"nz.mega.backup.rootFolderUpdatedInMemory";
NSString * const MEGABackupRootFolderUpdatedInRemoteNotification = @"nz.mega.backup.rootFolderUpdatedInRemote";

#pragma mark - my chat files notifications

NSString * const MEGAMyChatFilesFolderUpdatedInMemoryNotification = @"nz.mega.myChatFilesFolderUpdatedInMemory";
NSString * const MEGAMyChatFilesFolderUpdatedInRemoteNotification = @"nz.mega.myChatFilesFolderUpdatedInRemote";

#pragma mark - audio player notification keys

NSString * const MEGAAudioPlayerShouldUpdateContainerNotification = @"nz.mega.audioplayer.updateContainerView";

#pragma mark - Home notification keys

NSString * const MEGAHomeChangedHeightNotification = @"nz.mega.home.changedHeight";
NSString * const MEGABannerChangedHomeHeightNotification = @"nz.mega.home.bannerChangedHeight";

#pragma mark - camera upload constants

NSString * const MEGACameraUploadsNodeName = @"Camera Uploads";
NSString * const MEGACameraUploadsFolderPath = @"/CameraRoll";
const NSUInteger MEGACameraUploadLowDiskStorageSizeInBytes = 100 * 1024 * 1024;

#pragma mark - file extension constants

NSString * const MEGAJPGFileExtension = @"jpg";
NSString * const MEGAMP4FileExtension = @"mp4";
NSString * const MEGAQuickTimeFileExtension = @"mov";

#pragma mark - media formats

NSString * const JPGFormat = @"JPG";
NSString * const HEICFormat = @"HEIC";
NSString * const HEVCFormat = @"HEVC";
NSString * const H264Format = @"H.264";

#pragma mark - MEGA URLS

NSString * const RequireTransferSession = @"fm/";

#pragma mark - Group Shared Directory

NSString * const MEGAShareExtensionStorageFolder = @"Share Extension Storage";
NSString * const MEGAFileExtensionStorageFolder = @"File Provider Storage";
NSString * const MEGAExtensionLogsFolder = @"logs";
NSString * const MEGAExtensionGroupSupportFolder = @"GroupSupport";
NSString * const MEGAExtensionCacheFolder = @"Library/Caches";
NSString * const MEGANotificationServiceExtensionCacheFolder = @"Library/Caches/NSE";

#pragma mark - MEGA Activity Types

NSString * const MEGAUIActivityTypeGetLink = @"MEGAUIActivityTypeGetLink";
NSString * const MEGAUIActivityTypeOpenIn = @"MEGAUIActivityTypeOpenIn";
NSString * const MEGAUIActivityTypeRemoveLink = @"MEGAUIActivityTypeRemoveLink";
NSString * const MEGAUIActivityTypeRemoveSharing = @"MEGAUIActivityTypeRemoveSharing";
NSString * const MEGAUIActivityTypeShareFolder = @"MEGAUIActivityTypeShareFolder";
NSString * const MEGAUIActivityTypeSaveToCameraRoll = @"MEGAUIActivityTypeSaveToCameraRoll";
NSString * const MEGAUIActivityTypeSendToChat = @"MEGAUIActivityTypeSendToChat";
NSString * const MEGAUIActivityTypeImportToCloudDrive = @"MEGAUIActivityTypeImportToCloudDrive";

#pragma mark - Background Task completion.

NSString * const MEGAAllUsersNicknameLoaded = @"MEGAAllUsersNicknameLoaded";

#pragma mark - MEGA Contact Nickname change Notification

NSString * const MEGContactNicknameChangeNotification = @"MEGAContactNicknameChangeNotification";

#pragma mark - Notification Service Extension

NSString * const MEGAInvalidateNSECache = @"MEGAInvalidateNSECache";

#pragma mark - DB name

const NSUInteger MEGADropFirstCharactersFromSession = 44;

#pragma mark - File size

const long long MEGAMaxFileLinkAutoOpenSize = 10000000; //10Megabytes

#pragma mark - Calls

const NSUInteger MEGAGroupCallsPeersChangeLayout = 7;
NSString * const MEGACallMuteUnmuteOperationFailedNotification = @"nz.mega.calls.muteUnmuteOperationFailed";

#pragma mark - Add Your Phone Number

const NSUInteger MEGAOptOutOfAddYourPhoneNumberMinCount = 10;

#pragma mark - MEGAApplicationIconBadgeNumber

NSString * const MEGAApplicationIconBadgeNumber = @"MEGAApplicationIconBadgeNumber";

#pragma mark - Delay events

const NSTimeInterval MEGAMinDelayInSecondsToSendAnEvent = 20.0;

#pragma mark - Chat Reaction

const NSInteger MEGAMaxReactionsPerMessagePerUser = 24;
const NSInteger MEGAMaxReactionsPerMessage = 50;

#pragma mark - Widget Extension

NSString * const MEGAShortcutsWidget = @"MEGAShortcutsWidget";
NSString * const MEGAQuickAccessWidget = @"MEGAQuickAccessWidget";
NSString * const MEGAFavouritesQuickAccessWidget = @"MEGAFavouritesQuickAccessWidget";
NSString * const MEGARecentsQuickAccessWidget = @"MEGARecentsQuickAccessWidget";
NSString * const MEGAOfflineQuickAccessWidget = @"MEGAOfflineQuickAccessWidget";

const NSInteger MEGAQuickAccessWidgetMaxDisplayItems = 8;

#pragma mark - Photo Browser

NSString * const MEGAUseMobileDataForPreviewingOriginalPhoto = @"MEGAUseMobileDataForPreviewingOriginalPhoto";

#pragma mark - Feature Flags

NSString * const MEGAFeatureFlagsUserDefaultsKey = @"nz.co.mega.feature-flags";
