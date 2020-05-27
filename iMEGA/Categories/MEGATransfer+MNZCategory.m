
#import "MEGATransfer+MNZCategory.h"
#import <Photos/Photos.h>
#import "Helper.h"
#import "MEGANode+MNZCategory.h"
#import "MEGASdkManager.h"
#import "MEGAReachabilityManager.h"
#import "NSFileManager+MNZCategory.h"
#import "NSString+MNZCategory.h"

@implementation MEGATransfer (MNZCategory)

#pragma mark - Thumbnails and previews

- (void)mnz_createThumbnailAndPreview {
    NSString *transferAbsolutePath = [NSHomeDirectory() stringByAppendingPathComponent:self.path];
    NSString *imageFilePath;
    if (self.fileName.mnz_isImagePathExtension) {
        imageFilePath = transferAbsolutePath;
    } else if (self.fileName.mnz_isVideoPathExtension) {
        AVURLAsset *asset = [[AVURLAsset alloc] initWithURL:[NSURL fileURLWithPath:transferAbsolutePath] options:nil];
        AVAssetImageGenerator *generator = [[AVAssetImageGenerator alloc] initWithAsset:asset];
        generator.appliesPreferredTrackTransform = YES;
        CMTime requestedTime = CMTimeMake(1, 60);
        CGImageRef imgRef = [generator copyCGImageAtTime:requestedTime actualTime:NULL error:NULL];
        UIImage *image = [[UIImage alloc] initWithCGImage:imgRef];
        
        imageFilePath = [transferAbsolutePath.stringByDeletingPathExtension stringByAppendingPathExtension:@"jpg"];
        
        [UIImageJPEGRepresentation(image, 1) writeToFile:imageFilePath atomically:YES];
        
        CGImageRelease(imgRef);
    } else {
        return;
    }
    
    NSString *thumbnailFilePath = [transferAbsolutePath.stringByDeletingPathExtension stringByAppendingString:@"_thumbnail"];
    NSString *previewFilePath = [transferAbsolutePath.stringByDeletingPathExtension stringByAppendingString:@"_preview"];
    
    [[MEGASdkManager sharedMEGASdk] createThumbnail:imageFilePath destinatioPath:thumbnailFilePath];
    [[MEGASdkManager sharedMEGASdk] createPreview:imageFilePath destinatioPath:previewFilePath];
    
    if (self.fileName.mnz_isVideoPathExtension) {
        [NSFileManager.defaultManager mnz_removeItemAtPath:imageFilePath];
    }
}

- (void)mnz_renameOrRemoveThumbnailAndPreview {
    if (self.fileName.mnz_isImagePathExtension || self.fileName.mnz_isVideoPathExtension) {
        NSString *transferAbsolutePath = [NSHomeDirectory() stringByAppendingPathComponent:self.path];
        NSString *thumbnailPath = [transferAbsolutePath.stringByDeletingPathExtension stringByAppendingString:@"_thumbnail"];
        NSString *previewPath = [transferAbsolutePath.stringByDeletingPathExtension stringByAppendingString:@"_preview"];
        
        switch (self.state) {
            case MEGATransferStateComplete: {
                MEGANode *node = [[MEGASdkManager sharedMEGASdk] nodeForHandle:self.nodeHandle];
                NSString *thumbsDirectory = [Helper pathForSharedSandboxCacheDirectory:@"thumbnailsV3"];
                NSString *previewsDirectory = [NSSearchPathForDirectoriesInDomains(NSCachesDirectory, NSUserDomainMask, YES).firstObject stringByAppendingPathComponent:@"previewsV3"];
                
                [[NSFileManager defaultManager] moveItemAtPath:thumbnailPath toPath:[thumbsDirectory stringByAppendingPathComponent:node.base64Handle] error:nil];
                [[NSFileManager defaultManager] moveItemAtPath:previewPath toPath:[previewsDirectory stringByAppendingPathComponent:node.base64Handle] error:nil];
                break;
            }
                
            case MEGATransferStateCancelled:
            case MEGATransferStateFailed: {
                [NSFileManager.defaultManager mnz_removeItemAtPath:thumbnailPath];
                [NSFileManager.defaultManager mnz_removeItemAtPath:previewPath];
                break;
            }
                
            default:
                break;
        }
    }
}

#pragma mark - App data

- (MEGAChatMessageType)transferChatMessageType {
    if ([self.appData containsString:@"attachToChatID"]) {
        return MEGAChatMessageTypeAttachment;
    }
    
    if ([self.appData containsString:@"attachVoiceClipToChatID"]) {
         return MEGAChatMessageTypeVoiceClip;
    }
    
    return MEGAChatMessageTypeUnknown;
}

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
                [self mnz_attachtToChatID:tempAppDataComponent asVoiceClip:NO];
            }
            
            if ([appDataType isEqualToString:@"attachVoiceClipToChatID"]) {
                NSString *tempAppDataComponent = [appDataComponent stringByReplacingOccurrencesOfString:@"!" withString:@""];
                MEGANode *node = [MEGASdkManager.sharedMEGASdk nodeForHandle:self.nodeHandle];
                if (node) {
                    NSString *nodeFilePath = [node mnz_temporaryPathForDownloadCreatingDirectories:YES];
                    [NSFileManager.defaultManager mnz_moveItemAtPath:self.path toPath:nodeFilePath];
                }
                [self mnz_attachtToChatID:tempAppDataComponent asVoiceClip:YES];
            }
            
            if ([appDataType isEqualToString:@"setCoordinates"]) {
                [self mnz_setCoordinates:appDataComponent];
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

- (void)mnz_attachtToChatID:(NSString *)attachToChatID asVoiceClip:(BOOL)asVoiceClip {
    NSArray *appDataComponentComponentsArray = [attachToChatID componentsSeparatedByString:@"="];
    NSString *chatID = [appDataComponentComponentsArray objectAtIndex:1];
    unsigned long long chatIdUll = strtoull(chatID.UTF8String, NULL, 0);
    if (asVoiceClip) {
        [[MEGASdkManager sharedMEGAChatSdk] attachVoiceMessageToChat:chatIdUll node:self.nodeHandle];
    } else {
        [[MEGASdkManager sharedMEGAChatSdk] attachNodeToChat:chatIdUll node:self.nodeHandle];
    }
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

- (NSUInteger)mnz_orderByState {
    NSUInteger orderByState;
    
    switch (self.state) {
        case MEGATransferStateCompleting:
            orderByState = 0;
            break;
            
        case MEGATransferStateActive:
            orderByState = 1;
            break;
            
        case MEGATransferStateQueued:
            orderByState = 2;
            break;
            
        default:
            orderByState = 3;
            break;
    }
    
    return orderByState;
}

#pragma mark - Private

- (void)mnz_setCoordinates:(NSString *)coordinates {
    NSArray *appDataComponentComponentsArray = [coordinates componentsSeparatedByString:@"="];
    NSString *appDataSecondComponentComponentsString = [appDataComponentComponentsArray objectAtIndex:1];
    NSArray *setCoordinatesComponentsArray = [appDataSecondComponentComponentsString componentsSeparatedByString:@"&"];
    if (setCoordinatesComponentsArray.count == 2) {
        NSString *latitude = setCoordinatesComponentsArray.firstObject;
        NSString *longitude = [setCoordinatesComponentsArray objectAtIndex:1];
        if (latitude && longitude) {
            MEGANode *node = [[MEGASdkManager sharedMEGASdk] nodeForHandle:self.nodeHandle];
            [[MEGASdkManager sharedMEGASdk] setNodeCoordinates:node latitude:@(latitude.doubleValue) longitude:@(longitude.doubleValue)];
        }
    }
}

@end
