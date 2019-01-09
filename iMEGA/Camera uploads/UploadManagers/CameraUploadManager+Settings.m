
#import "CameraUploadManager+Settings.h"

static NSString * const IsCameraUploadsEnabledKey = @"IsCameraUploadsEnabled";
static NSString * const IsVideoUploadsEnabledKey = @"IsUploadVideosEnabled";
static NSString * const IsCellularAllowedKey = @"IsUseCellularConnectionEnabled";
static NSString * const ShouldConvertHEIFPhotoKey = @"ShouldConvertHEIFPhoto";
static NSString * const ShouldConvertHEVCVideoKey = @"ShouldConvertHEVCVideo";
static NSString * const HEVCToH264CompressionQualityKey = @"HEVCToH264CompressionQuality";
static NSString * const IsLocationBasedBackgroundUploadEnabledKey = @"IsLocationBasedBackgroundUploadEnabled";

@implementation CameraUploadManager (Settings)

+ (void)clearLocalSettings {
    [NSUserDefaults.standardUserDefaults removeObjectForKey:IsCameraUploadsEnabledKey];
    [NSUserDefaults.standardUserDefaults removeObjectForKey:IsVideoUploadsEnabledKey];
    [NSUserDefaults.standardUserDefaults removeObjectForKey:IsCellularAllowedKey];
    [NSUserDefaults.standardUserDefaults removeObjectForKey:ShouldConvertHEIFPhotoKey];
    [NSUserDefaults.standardUserDefaults removeObjectForKey:ShouldConvertHEVCVideoKey];
    [NSUserDefaults.standardUserDefaults removeObjectForKey:HEVCToH264CompressionQualityKey];
    [NSUserDefaults.standardUserDefaults removeObjectForKey:IsLocationBasedBackgroundUploadEnabledKey];
}

+ (BOOL)isCameraUploadEnabled {
    return [NSUserDefaults.standardUserDefaults boolForKey:IsCameraUploadsEnabledKey];
}

+ (void)setCameraUploadEnabled:(BOOL)cameraUploadEnabled {
    [NSUserDefaults.standardUserDefaults setBool:cameraUploadEnabled forKey:IsCameraUploadsEnabledKey];
    [self setConvertHEIFPhoto:YES];
}

+ (BOOL)isVideoUploadEnabled {
    return [NSUserDefaults.standardUserDefaults boolForKey:IsVideoUploadsEnabledKey];
}

+ (void)setVideoUploadEnabled:(BOOL)videoUploadEnabled {
    return [NSUserDefaults.standardUserDefaults setBool:videoUploadEnabled forKey:IsVideoUploadsEnabledKey];
}

+ (BOOL)isCellularUploadAllowed {
    return [NSUserDefaults.standardUserDefaults boolForKey:IsCellularAllowedKey];
}

+ (void)setCellularUploadAllowed:(BOOL)cellularUploadAllowed {
    [NSUserDefaults.standardUserDefaults setBool:cellularUploadAllowed forKey:IsCellularAllowedKey];
}

+ (BOOL)shouldConvertHEVCVideo {
    return [NSUserDefaults.standardUserDefaults boolForKey:ShouldConvertHEVCVideoKey];
}

+ (void)setConvertHEVCVideo:(BOOL)convertHEVCVideo {
    [NSUserDefaults.standardUserDefaults setBool:convertHEVCVideo forKey:ShouldConvertHEVCVideoKey];
}

+ (BOOL)shouldConvertHEIFPhoto {
    return [NSUserDefaults.standardUserDefaults boolForKey:ShouldConvertHEIFPhotoKey];
}

+ (void)setConvertHEIFPhoto:(BOOL)convertHEIFPhoto {
    [NSUserDefaults.standardUserDefaults setBool:convertHEIFPhoto forKey:ShouldConvertHEIFPhotoKey];
}

+ (CameraUploadVideoQuality)HEVCToH264CompressionQuality {
    return [NSUserDefaults.standardUserDefaults integerForKey:HEVCToH264CompressionQualityKey];
}

+ (void)setHEVCToH264CompressionQuality:(CameraUploadVideoQuality)HEVCToH264CompressionQuality {
    [NSUserDefaults.standardUserDefaults setInteger:HEVCToH264CompressionQuality forKey:HEVCToH264CompressionQualityKey];
}

+ (BOOL)isBackgroundUploadEnabled {
    return [NSUserDefaults.standardUserDefaults boolForKey:IsLocationBasedBackgroundUploadEnabledKey];
}

+ (void)setBackgroundUploadEnabled:(BOOL)backgroundUploadEnabled {
    [NSUserDefaults.standardUserDefaults setBool:backgroundUploadEnabled forKey:IsLocationBasedBackgroundUploadEnabledKey];
}

@end
