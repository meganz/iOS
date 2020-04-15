
#import <Foundation/Foundation.h>

#pragma mark - global constants

extern NSString * const MEGAiOSAppUserAgent;
extern NSString * const MEGAiOSAppKey;
extern NSString * const MEGAPasswordService;
extern NSString * const MEGAPasswordName;
extern NSString * const MEGAFirstRun;
extern NSString * const MEGAFirstRunValue;

extern NSString * const MEGAGroupIdentifier;

extern NSString * const MEGASortingPreference;
extern NSString * const MEGASortingPreferenceType;

extern NSString * const MEGAViewModePreference;

extern NSString * const MEGAPasscodeLogoutAfterTenFailedAttemps;

extern uint64_t const MEGAInvalidHandle;

#pragma mark - global notifications

extern NSString * const MEGALogoutNotification;
extern NSString * const MEGANodesCurrentNotification;
extern NSString * const MEGAStorageOverQuotaNotification;
extern NSString * const MEGAStorageEventDidChangeNotification;
extern NSString * const MEGAMediaInfoReadyNotification;

#pragma mark - global notification keys

extern NSString * const MEGAStorageEventStateUserInfoKey;

#pragma mark - camera upload notifications

extern NSString * const MEGACameraUploadStatsChangedNotification;
extern NSString * const MEGACameraUploadPhotoUploadLocalDiskFullNotification;
extern NSString * const MEGACameraUploadVideoUploadLocalDiskFullNotification;
extern NSString * const MEGACameraUploadPhotoConcurrentCountChangedNotification;
extern NSString * const MEGACameraUploadVideoConcurrentCountChangedNotification;
extern NSString * const MEGACameraUploadUploadingTasksCountChangedNotification;
extern NSString * const MEGACameraUploadTaskExpiredNotification;
extern NSString * const MEGACameraUploadQueueUpNextAssetNotification;
extern NSString * const MEGACameraUploadAllAssetsFinishedProcessingNotification;

#pragma mark - camera upload notification keys

extern NSString * const MEGAPhotoConcurrentCountUserInfoKey;
extern NSString * const MEGAVideoConcurrentCountUserInfoKey;
extern NSString * const MEGAHasUploadingTasksReachedMaximumCountUserInfoKey;
extern NSString * const MEGACurrentUploadingTasksCountUserInfoKey;
extern NSString * const MEGAAssetMediaTypeUserInfoKey;

#pragma mark - camera upload constants

extern NSString * const MEGACameraUploadsNodeName;
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

#pragma mark - Background Task completion.

extern NSString * const MEGAAllUsersNicknameLoaded;

#pragma mark - MEGA Affiliate program

extern NSString * const MEGALastPublicHandleAccessed;
extern NSString * const MEGALastPublicTypeAccessed;
extern NSString * const MEGALastPublicTimestampAccessed;

#pragma mark - MEGA Contact Nickname change Notification

extern NSString * const MEGContactNicknameChangeNotification;

#pragma mark - DB name

// Last 36 characters of the user session are used by sdk and karere to name their dbs
extern const NSUInteger MEGALastCharactersFromSession;
