
#import "CameraUploadManager+Settings.h"
#import "CameraUploadManager.h"
#import "MEGAConstants.h"

static NSString * const IsCameraUploadsEnabledKey = @"IsCameraUploadsEnabled";
static NSString * const IsVideoUploadsEnabledKey = @"IsUploadVideosEnabled";
static NSString * const IsCellularAllowedKey = @"IsUseCellularConnectionEnabled";
static NSString * const IsCellularForVideosAllowedKey = @"IsUseCellularConnectionForVideosEnabled";
static NSString * const ShouldConvertHEICPhotoKey = @"ShouldConvertHEICPhoto";
static NSString * const ShouldConvertHEVCVideoKey = @"ShouldConvertHEVCVideo";
static NSString * const HEVCToH264CompressionQualityKey = @"HEVCToH264CompressionQuality";
static NSString * const IsLocationBasedBackgroundUploadAllowedKey = @"IsLocationBasedBackgroundUploadAllowed";

@implementation CameraUploadManager (Settings)

#pragma mark - setting clean ups

+ (void)clearLocalSettings {
    [NSUserDefaults.standardUserDefaults removeObjectForKey:IsCameraUploadsEnabledKey];
    [self clearCameraSettings];
}

+ (void)clearCameraSettings {
    [NSUserDefaults.standardUserDefaults removeObjectForKey:IsCellularAllowedKey];
    [NSUserDefaults.standardUserDefaults removeObjectForKey:ShouldConvertHEICPhotoKey];
    [NSUserDefaults.standardUserDefaults removeObjectForKey:IsLocationBasedBackgroundUploadAllowedKey];
    [NSUserDefaults.standardUserDefaults removeObjectForKey:IsVideoUploadsEnabledKey];
    [self clearVideoSettings];
}

+ (void)clearVideoSettings {
    [NSUserDefaults.standardUserDefaults removeObjectForKey:ShouldConvertHEVCVideoKey];
    [NSUserDefaults.standardUserDefaults removeObjectForKey:HEVCToH264CompressionQualityKey];
    [NSUserDefaults.standardUserDefaults removeObjectForKey:IsCellularForVideosAllowedKey];
}

#pragma mark - properties

+ (BOOL)shouldShowCameraUploadBoardingScreen {
    return [NSUserDefaults.standardUserDefaults objectForKey:IsCameraUploadsEnabledKey] == nil;
}

+ (BOOL)isCameraUploadEnabled {
    return [NSUserDefaults.standardUserDefaults boolForKey:IsCameraUploadsEnabledKey];
}

+ (void)setCameraUploadEnabled:(BOOL)cameraUploadEnabled {
    BOOL previousValue = [self isCameraUploadEnabled];
    [NSUserDefaults.standardUserDefaults setBool:cameraUploadEnabled forKey:IsCameraUploadsEnabledKey];
    if (cameraUploadEnabled) {
        if (!previousValue) {
            [self setConvertHEICPhoto:YES];
        }
        [CameraUploadManager.shared startCameraUploadIfNeeded];
        [self enableBackgroundRefreshIfNeeded];
    } else {
        [self clearCameraSettings];
        [CameraUploadManager.shared stopCameraUpload];
    }
}

+ (BOOL)isVideoUploadEnabled {
    return [NSUserDefaults.standardUserDefaults boolForKey:IsVideoUploadsEnabledKey];
}

+ (void)setVideoUploadEnabled:(BOOL)videoUploadEnabled {
    BOOL previousValue = [self isVideoUploadEnabled];
    [NSUserDefaults.standardUserDefaults setBool:videoUploadEnabled forKey:IsVideoUploadsEnabledKey];
    if (videoUploadEnabled) {
        if (!previousValue) {
            [self setConvertHEVCVideo:YES];
        }
        [CameraUploadManager.shared startVideoUploadIfNeeded];
    } else {
        [self clearVideoSettings];
        [CameraUploadManager.shared stopVideoUpload];
    }
}

+ (BOOL)isCellularUploadAllowed {
    return [NSUserDefaults.standardUserDefaults boolForKey:IsCellularAllowedKey];
}

+ (void)setCellularUploadAllowed:(BOOL)cellularUploadAllowed {
    [NSUserDefaults.standardUserDefaults setBool:cellularUploadAllowed forKey:IsCellularAllowedKey];
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
    BOOL previousValue = [self shouldConvertHEVCVideo];
    [NSUserDefaults.standardUserDefaults setBool:convertHEVCVideo forKey:ShouldConvertHEVCVideoKey];
    if (convertHEVCVideo) {
        if (!previousValue) {
            [self setHEVCToH264CompressionQuality:CameraUploadVideoQualityMedium];
        }
    } else {
        [NSUserDefaults.standardUserDefaults removeObjectForKey:HEVCToH264CompressionQualityKey];
    }
}

+ (BOOL)shouldConvertHEICPhoto {
    return [NSUserDefaults.standardUserDefaults boolForKey:ShouldConvertHEICPhotoKey];
}

+ (void)setConvertHEICPhoto:(BOOL)convertHEICPhoto {
    [NSUserDefaults.standardUserDefaults setBool:convertHEICPhoto forKey:ShouldConvertHEICPhotoKey];
    [NSNotificationCenter.defaultCenter postNotificationName:MEGACameraUploadSwitchPhotoFormatNotificationName object:nil];
}

+ (CameraUploadVideoQuality)HEVCToH264CompressionQuality {
    return [NSUserDefaults.standardUserDefaults integerForKey:HEVCToH264CompressionQualityKey];
}

+ (void)setHEVCToH264CompressionQuality:(CameraUploadVideoQuality)HEVCToH264CompressionQuality {
    [NSUserDefaults.standardUserDefaults setInteger:HEVCToH264CompressionQuality forKey:HEVCToH264CompressionQualityKey];
}

+ (BOOL)isBackgroundUploadAllowed {
    return [NSUserDefaults.standardUserDefaults boolForKey:IsLocationBasedBackgroundUploadAllowedKey];
}

+ (void)setBackgroundUploadAllowed:(BOOL)backgroundUploadAllowed {
    [NSUserDefaults.standardUserDefaults setBool:backgroundUploadAllowed forKey:IsLocationBasedBackgroundUploadAllowedKey];
    if (backgroundUploadAllowed) {
        [CameraUploadManager.shared startBackgroundUploadIfPossible];
    } else {
        [CameraUploadManager.shared stopBackgroundUpload];
    }
}

+ (BOOL)shouldShowPhotoAndVideoFormat {
    if (@available(iOS 11.0, *)) {
        return YES;
    } else {
        return NO;
    }
}

@end
