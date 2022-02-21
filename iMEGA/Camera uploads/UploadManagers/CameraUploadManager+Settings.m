
#import "CameraUploadManager+Settings.h"

#import <Photos/PhotosTypes.h>
#import <CoreLocation/CoreLocation.h>

#import "NSFileManager+MNZCategory.h"
#import "MEGAReachabilityManager.h"

static NSString * const HasMigratedToCameraUploadsV2Key = @"HasMigratedToCameraUploadsV2";
static NSString * const BoardingScreenLastShowedDateKey = @"CameraUploadBoardingScreenLastShowedDate";

static NSString * const IsCameraUploadsEnabledKey = @"IsCameraUploadsEnabled";
static NSString * const IsVideoUploadsEnabledKey = @"IsUploadVideosEnabled";
static NSString * const IsCellularAllowedKey = @"IsUseCellularConnectionEnabled";
static NSString * const IsCellularForVideosAllowedKey = @"IsUseCellularConnectionForVideosEnabled";
static NSString * const ShouldConvertHEICPhotoKey = @"ShouldConvertHEICPhoto";
static NSString * const ShouldConvertHEVCVideoKey = @"ShouldConvertHEVCVideo";
static NSString * const HEVCToH264CompressionQualityKey = @"HEVCToH264CompressionQuality";
static NSString * const IncludeGPSTags = @"IncludeGPSTags";
static NSString * const UploadHiddenAlbumKey = @"UploadHiddenAlbum";
static NSString * const UploadAllBurstAssetsKey = @"UploadAllBurstAssets";
static NSString * const UploadVideosForLivePhotosKey = @"UploadVideosForLivePhotos";
static NSString * const UploadSharedAlbumsKey = @"UploadSharedAlbums";
static NSString * const UploadSyncedAlbumsKey = @"UploadSyncedAlbums";

static const NSTimeInterval BoardingScreenShowUpMinimumInterval = 30 * 24 * 3600;

@implementation CameraUploadManager (Settings)

#pragma mark - camera settings

+ (BOOL)isCameraUploadEnabled {
    return [NSUserDefaults.standardUserDefaults boolForKey:IsCameraUploadsEnabledKey];
}

+ (void)setCameraUploadEnabled:(BOOL)cameraUploadEnabled {
    [self setMigratedToCameraUploadsV2:YES];
    [NSUserDefaults.standardUserDefaults setBool:cameraUploadEnabled forKey:IsCameraUploadsEnabledKey];
    [self configDefaultSettingsIfNeededForCameraUpload];
    [self configDefaultSharedAlbumsAndSyncedAlbumsSettingsIfNeeded];
}

+ (void)configDefaultSettingsIfNeededForCameraUpload {
    if (![self isCameraUploadEnabled]) {
        return;
    }
    
    if ([NSUserDefaults.standardUserDefaults objectForKey:ShouldConvertHEICPhotoKey] == nil) {
        [self setConvertHEICPhoto:YES];
    }
    
    if ([NSUserDefaults.standardUserDefaults objectForKey:UploadVideosForLivePhotosKey] == nil) {
        [self setUploadVideosForLivePhotos:YES];
    }

    if ([NSUserDefaults.standardUserDefaults objectForKey:UploadAllBurstAssetsKey] == nil) {
        [self setUploadAllBurstPhotos:YES];
    }
}

+ (void)configDefaultSharedAlbumsAndSyncedAlbumsSettingsIfNeeded {
    if (![self isCameraUploadEnabled]) {
        return;
    }
    
    if ([NSUserDefaults.standardUserDefaults objectForKey:UploadSharedAlbumsKey] == nil) {
        [self setUploadSharedAlbums:NO];
    }
    
    if ([NSUserDefaults.standardUserDefaults objectForKey:UploadSyncedAlbumsKey] == nil) {
        [self setUploadSyncedAlbums:NO];
    }
}

+ (BOOL)shouldIncludeGPSTags {
    return [NSUserDefaults.standardUserDefaults boolForKey:IncludeGPSTags];
}

+ (void)setIncludeGPSTags:(BOOL)includeGPSTags {
    [NSUserDefaults.standardUserDefaults setBool:includeGPSTags forKey:IncludeGPSTags];
}

+ (NSDate *)boardingScreenLastShowedDate {
    return [NSUserDefaults.standardUserDefaults objectForKey:BoardingScreenLastShowedDateKey];
}

+ (void)setBoardingScreenLastShowedDate:(NSDate *)boardingScreenLastShowedDate {
    [NSUserDefaults.standardUserDefaults setObject:boardingScreenLastShowedDate forKey:BoardingScreenLastShowedDateKey];
}

#pragma mark - photo settings

+ (BOOL)isCellularUploadAllowed {
    return [NSUserDefaults.standardUserDefaults boolForKey:IsCellularAllowedKey];
}

+ (void)setCellularUploadAllowed:(BOOL)cellularUploadAllowed {
    [NSUserDefaults.standardUserDefaults setBool:cellularUploadAllowed forKey:IsCellularAllowedKey];
}

+ (BOOL)shouldConvertHEICPhoto {
    return [NSUserDefaults.standardUserDefaults boolForKey:ShouldConvertHEICPhotoKey];
}

+ (void)setConvertHEICPhoto:(BOOL)convertHEICPhoto {
    [NSUserDefaults.standardUserDefaults setBool:convertHEICPhoto forKey:ShouldConvertHEICPhotoKey];
}

#pragma mark - video settings

+ (BOOL)isVideoUploadEnabled {
    return [NSUserDefaults.standardUserDefaults boolForKey:IsVideoUploadsEnabledKey];
}

+ (void)setVideoUploadEnabled:(BOOL)videoUploadEnabled {
    [NSUserDefaults.standardUserDefaults setBool:videoUploadEnabled forKey:IsVideoUploadsEnabledKey];
    [self configDefaultSettingsIfNeededForVideoUpload];
}

+ (void)configDefaultSettingsIfNeededForVideoUpload {
    if (![self isVideoUploadEnabled]) {
        return;
    }
    
    if ([NSUserDefaults.standardUserDefaults objectForKey:ShouldConvertHEVCVideoKey] == nil) {
        [self setConvertHEVCVideo:YES];
    }
}

+ (BOOL)isCellularUploadForVideosAllowed {
    return [NSUserDefaults.standardUserDefaults boolForKey:IsCellularForVideosAllowedKey];
}

+ (void)setCellularUploadForVideosAllowed:(BOOL)cellularUploadForVideosAllowed {
    [NSUserDefaults.standardUserDefaults setBool:cellularUploadForVideosAllowed forKey:IsCellularForVideosAllowedKey];
}

+ (BOOL)shouldConvertHEVCVideo {
    return [NSUserDefaults.standardUserDefaults boolForKey:ShouldConvertHEVCVideoKey];
}

+ (void)setConvertHEVCVideo:(BOOL)convertHEVCVideo {
    [NSUserDefaults.standardUserDefaults setBool:convertHEVCVideo forKey:ShouldConvertHEVCVideoKey];
    
    if (convertHEVCVideo && [NSUserDefaults.standardUserDefaults objectForKey:HEVCToH264CompressionQualityKey] == nil) {
        [self setHEVCToH264CompressionQuality:CameraUploadVideoQualityMedium];
    }
}

+ (CameraUploadVideoQuality)HEVCToH264CompressionQuality {
    return [NSUserDefaults.standardUserDefaults integerForKey:HEVCToH264CompressionQualityKey];
}

+ (void)setHEVCToH264CompressionQuality:(CameraUploadVideoQuality)HEVCToH264CompressionQuality {
    [NSUserDefaults.standardUserDefaults setInteger:HEVCToH264CompressionQuality forKey:HEVCToH264CompressionQualityKey];
}

#pragma mark - advanced settings

+ (BOOL)shouldUploadVideosForLivePhotos {
    return [NSUserDefaults.standardUserDefaults boolForKey:UploadVideosForLivePhotosKey];
}

+ (void)setUploadVideosForLivePhotos:(BOOL)uploadVideosForLivePhotos {
    [NSUserDefaults.standardUserDefaults setBool:uploadVideosForLivePhotos forKey:UploadVideosForLivePhotosKey];
}

+ (BOOL)shouldUploadAllBurstPhotos {
    return [NSUserDefaults.standardUserDefaults boolForKey:UploadAllBurstAssetsKey];
}

+ (void)setUploadAllBurstPhotos:(BOOL)uploadAllBurstPhotos {
    [NSUserDefaults.standardUserDefaults setBool:uploadAllBurstPhotos forKey:UploadAllBurstAssetsKey];
}

+ (BOOL)shouldUploadHiddenAlbum {
    return [NSUserDefaults.standardUserDefaults boolForKey:UploadHiddenAlbumKey];
}

+ (void)setUploadHiddenAlbum:(BOOL)uploadHiddenAlbum {
    [NSUserDefaults.standardUserDefaults setBool:uploadHiddenAlbum forKey:UploadHiddenAlbumKey];
}

+ (BOOL)shouldUploadSharedAlbums {
    return [NSUserDefaults.standardUserDefaults boolForKey:UploadSharedAlbumsKey];
}

+ (void)setUploadSharedAlbums:(BOOL)uploadSharedAlbums {
    [NSUserDefaults.standardUserDefaults setBool:uploadSharedAlbums forKey:UploadSharedAlbumsKey];
}

+ (BOOL)shouldUploadSyncedAlbums {
    return [NSUserDefaults.standardUserDefaults boolForKey:UploadSyncedAlbumsKey];
}

+ (void)setUploadSyncedAlbums:(BOOL)uploadSyncedAlbums {
    [NSUserDefaults.standardUserDefaults setBool:uploadSyncedAlbums forKey:UploadSyncedAlbumsKey];
}

#pragma mark - readonly properties

+ (BOOL)shouldScanLivePhotosForVideos {
    return [self shouldUploadVideosForLivePhotos];
}

+ (BOOL)shouldShowCameraUploadBoardingScreen {
    BOOL show = NO;
    if (!CameraUploadManager.isCameraUploadEnabled) {
        NSDate *lastShowedDate = CameraUploadManager.boardingScreenLastShowedDate;
        if (lastShowedDate == nil) {
            show = YES;
        } else {
            show = [NSDate.date timeIntervalSinceDate:lastShowedDate] > BoardingScreenShowUpMinimumInterval;
        }
    }
    
    return show;
}

+ (BOOL)canCameraUploadBeStarted {
    return [self isCameraUploadEnabled] && [self hasMigratedToCameraUploadsV2];
}

+ (NSArray<NSNumber *> *)enabledMediaTypes {
    NSMutableArray<NSNumber *> *mediaTypes = [NSMutableArray array];
    if (CameraUploadManager.isCameraUploadEnabled) {
        [mediaTypes addObject:@(PHAssetMediaTypeImage)];
        
        if (CameraUploadManager.isVideoUploadEnabled) {
            [mediaTypes addObject:@(PHAssetMediaTypeVideo)];
        }
    }
    
    return [mediaTypes copy];
}

+ (BOOL)isCameraUploadPausedBecauseOfNoWiFiConnection {
    return ![self isCellularUploadAllowed] && !MEGAReachabilityManager.isReachableViaWiFi;
}

+ (void)enableAdvancedSettingsForUpgradingUserIfNeeded {
    if (![self isCameraUploadEnabled]) {
        return;
    }
    
    if ([NSUserDefaults.standardUserDefaults objectForKey:UploadSharedAlbumsKey] == nil) {
        [self setUploadSharedAlbums:YES];
    }
    
    if ([NSUserDefaults.standardUserDefaults objectForKey:UploadSyncedAlbumsKey] == nil) {
        [self setUploadSyncedAlbums:YES];
    }
}

#pragma mark - camera upload v2 migration

+ (BOOL)hasMigratedToCameraUploadsV2 {
    return [NSUserDefaults.standardUserDefaults boolForKey:HasMigratedToCameraUploadsV2Key];
}

+ (void)setMigratedToCameraUploadsV2:(BOOL)migratedToCameraUploadsV2 {
    [NSUserDefaults.standardUserDefaults setBool:migratedToCameraUploadsV2 forKey:HasMigratedToCameraUploadsV2Key];
}

+ (BOOL)shouldShowCameraUploadV2MigrationScreen {
    return [self isCameraUploadEnabled] && ![self hasMigratedToCameraUploadsV2];
}

+ (void)configDefaultSettingsForCameraUploadV2 {
    [self configDefaultSettingsIfNeededForCameraUpload];
    [self configDefaultSettingsIfNeededForVideoUpload];
}

@end
