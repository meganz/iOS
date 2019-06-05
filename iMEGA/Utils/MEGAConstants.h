
#import <Foundation/Foundation.h>

#pragma mark - global constants

extern NSString * const MEGAiOSAppUserAgent;
extern NSString * const MEGAiOSAppKey;

#pragma mark - global notifications

extern NSString * const MEGALogoutNotificationName;
extern NSString * const MEGANodesCurrentNotificationName;
extern NSString * const MEGAStorageOverQuotaNotificationName;
extern NSString * const MEGAStorageEventDidChangeNotificationName;
extern NSString * const MEGAMediaInfoReadyNotification;

#pragma mark - global notification keys

extern NSString * const MEGAStorageEventStateUserInfoKey;

#pragma mark - camera upload notifications

extern NSString * const MEGACameraUploadStatsChangedNotificationName;
extern NSString * const MEGACameraUploadPhotoUploadLocalDiskFullNotificationName;
extern NSString * const MEGACameraUploadVideoUploadLocalDiskFullNotificationName;
extern NSString * const MEGACameraUploadPhotoConcurrentCountChangedNotificationName;
extern NSString * const MEGACameraUploadVideoConcurrentCountChangedNotificationName;
extern NSString * const MEGACameraUploadUploadingTasksCountChangedNotificationName;
extern NSString * const MEGACameraUploadTaskExpiredNotificationName;
extern NSString * const MEGACameraUploadQueueUpNextAssetNotificationName;
extern NSString * const MEGACameraUploadAllAssetsFinishedProcessingNotificationName;

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
