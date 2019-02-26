
#import "MEGAConstants.h"

#pragma mark - global notifications

NSString * const MEGALogoutNotificationName = @"nz.mega.logout";
NSString * const MEGANodesFetchDoneNotificationName = @"nz.mega.nodesFetchFinished";
NSString * const MEGAStorageOverQuotaNotificationName = @"nz.mega.storageOverQuota";
NSString * const MEGAStorageEventDidChangeNotificationName = @"nz.mega.event.storage";

#pragma mark - global notification keys

NSString * const MEGAStorageEventStateUserInfoKey = @"nz.mega.event.storage.stateKey";

#pragma mark - camera upload notifications

NSString * const MEGACameraUploadAssetUploadDoneNotificationName = @"nz.mega.cameraUpload.assetUploadDone";
NSString * const MEGACameraUploadPhotoUploadLocalDiskFullNotificationName = @"nz.mega.cameraUpload.photo.localDiskFull";
NSString * const MEGACameraUploadVideoUploadLocalDiskFullNotificationName = @"nz.mega.cameraUpload.video.localDiskFull";
NSString * const MEGACameraUploadPhotoConcurrentCountChangedNotificationName = @"nz.mega.cameraUpload.photo.concurrentCountChanged";
NSString * const MEGACameraUploadVideoConcurrentCountChangedNotificationName = @"nz.mega.cameraUpload.video.concurrentCountChanged";
NSString * const MEGACameraUploadUploadingTasksCountChangedNotificationName = @"nz.mega.cameraUpload.uploadingTaskCountChanged";

#pragma mark - camera upload notification keys

NSString * const MEGAPhotoConcurrentCountUserInfoKey = @"nz.mega.photoConcurrentCountKey";
NSString * const MEGAVideoConcurrentCountUserInfoKey = @"nz.mega.videoConcurrentCountKey";
NSString * const MEGAHasUploadingTasksReachedMaximumCountUserInfoKey = @"nz.mega.uploadingTasksReachedMaximumCountKey";
NSString * const MEGACurrentUploadingTasksCountUserInfoKey = @"nz.mega.currentUploadingTasksCountKey";

#pragma mark - camera upload constants

const NSUInteger MEGACameraUploadLowDiskStorageSizeInBytes = 100 * 1024 * 1024;
NSString * const MEGACameraUploadIdentifierSeparator = @",";

#pragma mark - file extension constants

NSString * const MEGAJPGFileExtension = @"jpg";
NSString * const MEGAMP4FileExtension = @"mp4";
NSString * const MEGAQuickTimeFileExtension = @"mov";
