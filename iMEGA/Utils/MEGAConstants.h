#import <Foundation/Foundation.h>

#pragma mark - global constants

extern NSString * const MEGAiOSAppUserAgent;
extern NSString * const MEGAiOSAppKey;
extern NSString * const MEGAPasswordService;
extern NSString * const MEGAPasswordName;
extern NSString * const MEGAFirstLoginDate;

extern NSString * const MEGAGroupIdentifier;

extern NSString * const MEGASortingPreference;
extern NSString * const MEGASortingPreferenceType;

extern NSString * const MEGAViewModePreference;

extern uint64_t const MEGAInvalidHandle;

extern NSString * const MEGAVoiceMessagesFolderName;

extern NSString * const MEGAAwaitingEmailConfirmationNotification;

#pragma mark - global notifications

extern NSString * const MEGALogoutNotification;
extern NSString * const MEGANodesCurrentNotification;
extern NSString * const MEGAStorageOverQuotaNotification;
extern NSString * const MEGATransferOverQuotaNotification;
extern NSString * const MEGABusinessAccountExpiredNotification;
extern NSString * const MEGABusinessAccountActivatedNotification;
extern NSString * const MEGAStorageEventDidChangeNotification;
extern NSString * const MEGAMediaInfoReadyNotification;
extern NSString * const MEGAPasscodeViewControllerWillCloseNotification;
extern NSString * const MEGAAudioPlayerInterruptionNotification;
extern NSString * const MEGASQLiteDiskFullNotification;
extern NSString * const MEGATransferFinishedNotification;
extern NSString * const MEGAShareCreatedNotification;
extern NSString * const MEGAEmailHasChangedNotification;

#pragma mark - global notification keys

extern NSString * const MEGAStorageEventStateUserInfoKey;
extern NSString * const MEGATransferUserInfoKey;

#pragma mark - camera upload notifications

extern NSString * const MEGACameraUploadStatsChangedNotification;
extern NSString * const MEGACameraUploadPhotoUploadLocalDiskFullNotification;
extern NSString * const MEGACameraUploadVideoUploadLocalDiskFullNotification;
extern NSString * const MEGACameraUploadPhotoConcurrentCountChangedNotification;
extern NSString * const MEGACameraUploadVideoConcurrentCountChangedNotification;
extern NSString * const MEGACameraUploadUploadingTasksCountChangedNotification;
extern NSString * const MEGACameraUploadQueueUpNextAssetNotification;
extern NSString * const MEGACameraUploadAllAssetsFinishedProcessingNotification;
extern NSString * const MEGACameraUploadTargetFolderChangedInRemoteNotification;
extern NSString * const MEGACameraUploadTargetFolderUpdatedInMemoryNotification;
extern NSString * const MEGACameraUploadNodeUploadCompleteNotification;
extern NSString * const MEGACameraUploadCompleteNotification;

#pragma mark - backups in fm notifications

extern NSString * const MEGABackupRootFolderUpdatedInMemoryNotification;
extern NSString * const MEGABackupRootFolderUpdatedInRemoteNotification;

#pragma mark - my chat files notifications

extern NSString * const MEGAMyChatFilesFolderUpdatedInMemoryNotification;
extern NSString * const MEGAMyChatFilesFolderUpdatedInRemoteNotification;

#pragma mark - audio player notification keys

extern NSString * const MEGAAudioPlayerShouldUpdateContainerNotification;

#pragma mark - Recents notification keys

extern NSString * const MEGAHomeChangedHeightNotification;
extern NSString * const MEGABannerChangedHomeHeightNotification;

#pragma mark - camera upload notification keys

extern NSString * const MEGAPhotoConcurrentCountUserInfoKey;
extern NSString * const MEGAVideoConcurrentCountUserInfoKey;
extern NSString * const MEGAHasUploadingTasksReachedMaximumCountUserInfoKey;
extern NSString * const MEGACurrentUploadingTasksCountUserInfoKey;
extern NSString * const MEGAAssetMediaTypeUserInfoKey;
extern NSString * const MEGANodeHandleKey;

#pragma mark - camera upload constants

extern NSString * const MEGACameraUploadsNodeName;
extern NSString * const MEGACameraUploadsFolderPath;
extern const NSUInteger MEGACameraUploadLowDiskStorageSizeInBytes;

#pragma mark - file extension constants

extern NSString * const MEGAJPGFileExtension;
extern NSString * const MEGAMP4FileExtension;
extern NSString * const MEGAQuickTimeFileExtension;

#pragma mark - media formats

extern NSString * const JPGFormat;
extern NSString * const HEICFormat;
extern NSString * const HEVCFormat;
extern NSString * const H264Format;

#pragma mark - MEGA URLS

extern NSString * const MEGADisputeURL;
extern NSString * const RequireTransferSession;

#pragma mark - Group Shared Directory

extern NSString * const MEGAShareExtensionStorageFolder;
extern NSString * const MEGAFileExtensionStorageFolder;
extern NSString * const MEGAExtensionLogsFolder;
extern NSString * const MEGAExtensionGroupSupportFolder;
extern NSString * const MEGAExtensionCacheFolder;
extern NSString * const MEGANotificationServiceExtensionCacheFolder;

#pragma mark - MEGA Activity Types

extern NSString * const MEGAUIActivityTypeGetLink;
extern NSString * const MEGAUIActivityTypeOpenIn;
extern NSString * const MEGAUIActivityTypeRemoveLink;
extern NSString * const MEGAUIActivityTypeRemoveSharing;
extern NSString * const MEGAUIActivityTypeShareFolder;
extern NSString * const MEGAUIActivityTypeSaveToCameraRoll;
extern NSString * const MEGAUIActivityTypeSendToChat;
extern NSString * const MEGAExplorerViewModePreference;
extern NSString * const MEGAUIActivityTypeImportToCloudDrive;

#pragma mark - Background Task completion.

extern NSString * const MEGAAllUsersNicknameLoaded;

#pragma mark - MEGA Contact Nickname change Notification

extern NSString * const MEGContactNicknameChangeNotification;

#pragma mark - Notification Service Extension

extern NSString * const MEGAInvalidateNSECache;

#pragma mark - DB name

// Droping the first 44 characters of the user session the last ones are used by sdk and karere to name their dbs
extern const NSUInteger MEGADropFirstCharactersFromSession;

#pragma mark - File size

extern const long long MEGAMaxFileLinkAutoOpenSize;

#pragma mark - Calls

/// In group calls the layout for the collection view changes when the peers are 7 or more
extern const NSUInteger MEGAGroupCallsPeersChangeLayout;

extern NSString * const MEGACallMuteUnmuteOperationFailedNotification;

#pragma mark - Add Your Phone Number

extern const NSUInteger MEGAOptOutOfAddYourPhoneNumberMinCount;

#pragma mark - MEGAApplicationIconBadgeNumber

/// Key used for shared user default to store the value of the aplication icon badge
extern NSString * const MEGAApplicationIconBadgeNumber;

#pragma mark - Delay events

/// Minimum delay in seconds to send an event (used for chat messages)
extern const NSTimeInterval MEGAMinDelayInSecondsToSendAnEvent;

#pragma mark - Chat Reaction

extern const NSInteger MEGAMaxReactionsPerMessagePerUser;
extern const NSInteger MEGAMaxReactionsPerMessage;

#pragma mark - Widget Extension

extern NSString * const MEGAShortcutsWidget;
extern NSString * const MEGAQuickAccessWidget;
extern NSString * const MEGAFavouritesQuickAccessWidget;
extern NSString * const MEGARecentsQuickAccessWidget;
extern NSString * const MEGAOfflineQuickAccessWidget;
extern const NSInteger MEGAQuickAccessWidgetMaxDisplayItems;

#pragma mark - Photo Browser

extern NSString * const MEGAUseMobileDataForPreviewingOriginalPhoto;

#pragma mark - Feature Flag

extern NSString * const MEGAFeatureFlagsUserDefaultsKey;
