
#import <Foundation/Foundation.h>

#pragma mark - global notifications

extern NSString * const MEGALogoutNotificationName;
extern NSString * const MEGANodesCurrentNotificationName;
extern NSString * const MEGAStorageOverQuotaNotificationName;
extern NSString * const MEGAStorageEventDidChangeNotificationName;

#pragma mark - global notification keys

extern NSString * const MEGAStorageEventStateUserInfoKey;

#pragma mark - camera upload notifications

extern NSString * const MEGACameraUploadAssetUploadDoneNotificationName;
extern NSString * const MEGACameraUploadPhotoUploadLocalDiskFullNotificationName;
extern NSString * const MEGACameraUploadVideoUploadLocalDiskFullNotificationName;
extern NSString * const MEGACameraUploadPhotoConcurrentCountChangedNotificationName;
extern NSString * const MEGACameraUploadVideoConcurrentCountChangedNotificationName;
extern NSString * const MEGACameraUploadUploadingTasksCountChangedNotificationName;

#pragma mark - camera upload notification keys

extern NSString * const MEGAPhotoConcurrentCountUserInfoKey;
extern NSString * const MEGAVideoConcurrentCountUserInfoKey;
extern NSString * const MEGAHasUploadingTasksReachedMaximumCountUserInfoKey;
extern NSString * const MEGACurrentUploadingTasksCountUserInfoKey;

#pragma mark - camera upload constants

extern const NSUInteger MEGACameraUploadLowDiskStorageSizeInBytes;

#pragma mark - file extension constants

extern NSString * const MEGAJPGFileExtension;
extern NSString * const MEGAMP4FileExtension;
extern NSString * const MEGAQuickTimeFileExtension;
