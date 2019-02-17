
#import "MEGAConstants.h"

NSString * const MEGALogoutNotificationName = @"nz.mega.logout";
NSString * const MEGANodesFetchDoneNotificationName = @"nz.mega.nodesFetchFinished";
NSString * const MEGAStorageOverQuotaNotificationName = @"nz.mega.storageOverQuota";
NSString * const MEGAStorageEventNotificationName = @"nz.mega.event.storage";

NSString * const MEGAStorageEventStateUserInfoKey = @"nz.mega.event.storage.stateKey";

NSString * const MEGACameraUploadAssetUploadDoneNotificationName = @"nz.mega.cameraUpload.assetUploadDone";
NSString * const MEGACameraUploadPhotoUploadLocalDiskFullNotificationName = @"nz.mega.cameraUpload.photo.localDiskFull";
NSString * const MEGACameraUploadVideoUploadLocalDiskFullNotificationName = @"nz.mega.cameraUpload.video.localDiskFull";

const NSUInteger MEGACameraUploadLowDiskStorageSizeInBytes = 100 * 1024 * 1024;

NSString * const MEGAJPGFileExtension = @"jpg";
NSString * const MEGAMP4FileExtension = @"mp4";
NSString * const MEGAQuickTimeFileExtension = @"mov";
