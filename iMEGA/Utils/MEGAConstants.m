
#import "MEGAConstants.h"

#pragma mark - global constants

NSString * const MEGAiOSAppUserAgent = @"MEGAiOS";
NSString * const MEGAiOSAppKey = @"EVtjzb7R";

#pragma mark - global notifications

NSNotificationName const MEGALogoutNotification = @"nz.mega.logout";
NSNotificationName const MEGANodesCurrentNotification = @"nz.mega.nodesCurrent";
NSNotificationName const MEGAStorageOverQuotaNotification = @"nz.mega.storageOverQuota";
NSNotificationName const MEGAStorageEventDidChangeNotification = @"nz.mega.event.storage";

#pragma mark - global notification keys

NSString * const MEGAStorageEventStateUserInfoKey = @"nz.mega.event.storage.stateKey";

#pragma mark - camera upload notifications

NSNotificationName const MEGACameraUploadStatsChangedNotification = @"nz.mega.cameraUpload.statsChanged";
NSNotificationName const MEGACameraUploadPhotoUploadLocalDiskFullNotification = @"nz.mega.cameraUpload.photo.localDiskFull";
NSNotificationName const MEGACameraUploadVideoUploadLocalDiskFullNotification = @"nz.mega.cameraUpload.video.localDiskFull";
NSNotificationName const MEGACameraUploadPhotoConcurrentCountChangedNotification = @"nz.mega.cameraUpload.photo.concurrentCountChanged";
NSNotificationName const MEGACameraUploadVideoConcurrentCountChangedNotification = @"nz.mega.cameraUpload.video.concurrentCountChanged";
NSNotificationName const MEGACameraUploadUploadingTasksCountChangedNotification = @"nz.mega.cameraUpload.uploadingTaskCountChanged";
NSNotificationName const MEGACameraUploadTaskExpiredNotification = @"nz.mega.cameraUpload.uploadTaskExpired";
NSNotificationName const MEGACameraUploadQueueUpNextAssetNotification = @"nz.mega.cameraUpload.queueUpNextAsset";
NSNotificationName const MEGACameraUploadAllAssetsFinishedProcessingNotification = @"nz.mega.cameraUpload.allAssetsFinishedProcessing";

#pragma mark - camera upload notification keys

NSString * const MEGAPhotoConcurrentCountUserInfoKey = @"nz.mega.photoConcurrentCountKey";
NSString * const MEGAVideoConcurrentCountUserInfoKey = @"nz.mega.videoConcurrentCountKey";
NSString * const MEGAHasUploadingTasksReachedMaximumCountUserInfoKey = @"nz.mega.uploadingTasksReachedMaximumCountKey";
NSString * const MEGACurrentUploadingTasksCountUserInfoKey = @"nz.mega.currentUploadingTasksCountKey";
NSString * const MEGAAssetMediaTypeUserInfoKey = @"nz.mega.assetMediaTypeKey";

#pragma mark - camera upload constants

NSString * const MEGACameraUploadsNodeName = @"Camera Uploads";
const NSUInteger MEGACameraUploadLowDiskStorageSizeInBytes = 100 * 1024 * 1024;

#pragma mark - file extension constants

NSString * const MEGAJPGFileExtension = @"jpg";
NSString * const MEGAMP4FileExtension = @"mp4";
NSString * const MEGAQuickTimeFileExtension = @"mov";
