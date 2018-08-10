
#import "MEGATransfer+MNZCategory.h"

#import <Photos/Photos.h>

#import "CameraUploads.h"
#import "Helper.h"
#import "MEGANode+MNZCategory.h"
#import "MEGASdkManager.h"
#import "MEGAReachabilityManager.h"
#import "NSString+MNZCategory.h"

@implementation MEGATransfer (MNZCategory)

- (void)mnz_parseAppData {
    if (!self.appData) {
        return;
    }
    
    NSArray *appDataComponentsArray = [self.appData componentsSeparatedByString:@">"];
    if (appDataComponentsArray.count) {
        for (NSString *appDataComponent in appDataComponentsArray) {
            NSArray *appDataComponentComponentsArray = [appDataComponent componentsSeparatedByString:@"="];
            NSString *appDataType = appDataComponentComponentsArray.firstObject;
            
            if ([appDataType isEqualToString:@"SaveInPhotosApp"]) {
                [self mnz_saveInPhotosApp];
            }
            
            if ([appDataType isEqualToString:@"attachToChatID"]) {
                NSString *tempAppDataComponent = [appDataComponent stringByReplacingOccurrencesOfString:@"!" withString:@""];
                [self mnz_attachtToChatID:tempAppDataComponent];
            }
            
            if ([appDataType isEqualToString:@"setCoordinates"]) {
                [self mnz_setCoordinates:appDataComponent];
            }
        }
    }
}

- (void)mnz_cancelPendingCUTransfer {
    if ([self.appData containsString:@"CU"]) {
        if ([CameraUploads syncManager].isCameraUploadsEnabled) {
            if (![CameraUploads syncManager].isUseCellularConnectionEnabled && [MEGAReachabilityManager isReachableViaWWAN]) {
                [[MEGASdkManager sharedMEGASdk] cancelTransfer:self];
            }
        } else {
            [[MEGASdkManager sharedMEGASdk] cancelTransfer:self];
        }
    }
}

- (void)mnz_cancelPendingCUVideoTransfer {
    if ([self.appData containsString:@"CU"]) {
        if ([CameraUploads syncManager].isCameraUploadsEnabled) {
            if (self.fileName.mnz_isVideoPathExtension) {
                [[MEGASdkManager sharedMEGASdk] cancelTransfer:self];
            }
        }
    }
}

- (void)mnz_saveInPhotosApp {
    [self mnz_setNodeCoordinates];
    
    MEGANode *node = [[MEGASdkManager sharedMEGASdk] nodeForHandle:self.nodeHandle];
    if (!node) {
        node = [self publicNode];
    }
    
    [node mnz_copyToGalleryFromTemporaryPath:[NSHomeDirectory() stringByAppendingPathComponent:self.path]];
}

- (void)mnz_attachtToChatID:(NSString *)attachToChatID {
    NSArray *appDataComponentComponentsArray = [attachToChatID componentsSeparatedByString:@"="];
    NSString *chatID = [appDataComponentComponentsArray objectAtIndex:1];
    unsigned long long chatIdUll = strtoull(chatID.UTF8String, NULL, 0);
    [[MEGASdkManager sharedMEGAChatSdk] attachNodeToChat:chatIdUll node:self.nodeHandle];
}

- (void)mnz_setNodeCoordinates {
    if (self.fileName.mnz_isImagePathExtension || self.fileName.mnz_isVideoPathExtension) {
        MEGANode *node = [[MEGASdkManager sharedMEGASdk] nodeForHandle:self.nodeHandle];
        if (node.latitude && node.longitude) {
            return;
        }
        
        if (self.type == MEGATransferTypeDownload) {
            NSString *coordinates = [[NSString new] mnz_appDataToSaveCoordinates:self.path.mnz_coordinatesOfPhotoOrVideo];
            if (!coordinates.mnz_isEmpty) {
                [self mnz_setCoordinates:coordinates];
            }
        } else {
            [self mnz_parseAppData];
        }
    }
}

#pragma mark - Private

- (void)mnz_setCoordinates:(NSString *)coordinates {
    NSArray *appDataComponentComponentsArray = [coordinates componentsSeparatedByString:@"="];
    NSString *appDataSecondComponentComponentsString = [appDataComponentComponentsArray objectAtIndex:1];
    NSArray *setCoordinatesComponentsArray = [appDataSecondComponentComponentsString componentsSeparatedByString:@"&"];
    if (setCoordinatesComponentsArray.count == 2) {
        NSString *latitude = [setCoordinatesComponentsArray objectAtIndex:0];
        NSString *longitude = [setCoordinatesComponentsArray objectAtIndex:1];
        if (latitude && longitude) {
            MEGANode *node = [[MEGASdkManager sharedMEGASdk] nodeForHandle:self.nodeHandle];
            [[MEGASdkManager sharedMEGASdk] setNodeCoordinates:node latitude:latitude.doubleValue longitude:longitude.doubleValue];
        }
    }
}

@end
