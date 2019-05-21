
#import <Foundation/Foundation.h>

#pragma mark - global constants

extern NSString * const MEGAiOSAppUserAgent;
extern NSString * const MEGAiOSAppKey;

#pragma mark - global notifications

extern NSNotificationName const MEGALogoutNotification;
extern NSNotificationName const MEGANodesCurrentNotification;
extern NSNotificationName const MEGAStorageOverQuotaNotification;
extern NSNotificationName const MEGAStorageEventDidChangeNotification;

#pragma mark - global notification keys

extern NSString * const MEGAStorageEventStateUserInfoKey;

#pragma mark - camera upload notifications

extern NSNotificationName const MEGACameraUploadStatsChangedNotification;
extern NSNotificationName const MEGACameraUploadPhotoUploadLocalDiskFullNotification;
extern NSNotificationName const MEGACameraUploadVideoUploadLocalDiskFullNotification;
extern NSNotificationName const MEGACameraUploadPhotoConcurrentCountChangedNotification;
extern NSNotificationName const MEGACameraUploadVideoConcurrentCountChangedNotification;
extern NSNotificationName const MEGACameraUploadUploadingTasksCountChangedNotification;
extern NSNotificationName const MEGACameraUploadTaskExpiredNotification;
extern NSNotificationName const MEGACameraUploadQueueUpNextAssetNotification;

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
