
#import "CameraUploadManager.h"

NS_ASSUME_NONNULL_BEGIN

typedef NS_ENUM(NSUInteger, CameraUploadVideoQuality) {
    CameraUploadVideoQualityLow = 0, // 480p
    CameraUploadVideoQualityMedium = 1, // 720p
    CameraUploadVideoQualityHigh = 2, // 1080p
    CameraUploadVideoQualityOriginal = 3 // original
};

@interface CameraUploadManager (Settings)

#pragma mark - camera settings

@property (class, getter=isCameraUploadEnabled) BOOL cameraUploadEnabled;
@property (class, getter=shouldIncludeGPSTags) BOOL includeGPSTags;

@property (class, nullable) NSDate *boardingScreenLastShowedDate;

#pragma mark - photo settings

@property (class, getter=isCellularUploadAllowed) BOOL cellularUploadAllowed;
@property (class, getter=shouldConvertHEICPhoto) BOOL convertHEICPhoto;

#pragma mark - video settings

@property (class, getter=isVideoUploadEnabled) BOOL videoUploadEnabled;
@property (class, getter=shouldConvertHEVCVideo) BOOL convertHEVCVideo;
@property (class, getter=isCellularUploadForVideosAllowed) BOOL cellularUploadForVideosAllowed;
@property (class) CameraUploadVideoQuality HEVCToH264CompressionQuality;

#pragma mark - advanced settings

@property (class, getter=shouldUploadVideosForLivePhotos) BOOL uploadVideosForLivePhotos;
@property (class, getter=shouldUploadAllBurstPhotos) BOOL uploadAllBurstPhotos;
@property (class, getter=shouldUploadHiddenAlbum) BOOL uploadHiddenAlbum;
@property (class, getter=shouldUploadSharedAlbums) BOOL uploadSharedAlbums;
@property (class, getter=shouldUploadSyncedAlbums) BOOL uploadSyncedAlbums;


#pragma mark - readonly properties

@property (class, readonly, getter=shouldShowCameraUploadBoardingScreen) BOOL showCameraUploadBoardingScreen;
@property (class, readonly, getter=shouldScanLivePhotosForVideos) BOOL scanLivePhotosForVideos;
@property (class, readonly) BOOL canCameraUploadBeStarted;
@property (class, readonly, getter=isCameraUploadPausedBecauseOfNoWiFiConnection) BOOL cameraUploadPausedBecauseOfNoWifiConnection;
@property (class, readonly) NSArray<NSNumber *> * enabledMediaTypes;

#pragma mark - camera upload v2 migration

@property (class, getter=hasMigratedToCameraUploadsV2) BOOL migratedToCameraUploadsV2;
@property (class, readonly) BOOL shouldShowCameraUploadV2MigrationScreen;

+ (void)configDefaultSettingsForCameraUploadV2;

#pragma mark - clear local settings

+ (void)enableAdvancedSettingsForUpgradingUserIfNeeded;

@end

NS_ASSUME_NONNULL_END
