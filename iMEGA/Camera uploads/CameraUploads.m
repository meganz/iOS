/**
 * @file CameraUploads.m
 * @brief Uploads assets from device to your mega account
 *
 * (c) 2013-2015 by Mega Limited, Auckland, New Zealand
 *
 * This file is part of the MEGA SDK - Client Access Engine.
 *
 * Applications using the MEGA API must present a valid application key
 * and comply with the the rules set forth in the Terms of Service.
 *
 * The MEGA SDK is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.
 *
 * @copyright Simplified (2-clause) BSD License.
 *
 * You should have received a copy of the license along with this
 * program.
 */

#import <UIKit/UIKit.h>
#import <AssetsLibrary/AssetsLibrary.h>

#import "CameraUploads.h"
#import "MEGASdkManager.h"
#import "NSString+MNZCategory.h"
#import "MEGAReachabilityManager.h"

#define kCameraUploads @"Camera Uploads"
#define kLastUploadPhotoDate @"LastUploadPhotoDate"
#define kCameraUploadsNodeHandle @"CameraUploadsNodeHandle"

@interface CameraUploads () {
    NSInteger totalAssets;
    
    MEGANode *cameraUploadsNode;
    uint64_t cameraUploadHandle;
    
    NSDate *lastUploadPhotoDate;
    
    BOOL isCreatingFolder;
}


@property (nonatomic, strong) NSDateFormatter *formatter;
@property (nonatomic, strong) NSFileManager *fileManager;
@property (nonatomic, strong) ALAssetsLibrary *library;

@end

@implementation CameraUploads

static CameraUploads *instance = nil;

+ (CameraUploads *)syncManager {
    static dispatch_once_t once;
    dispatch_once(&once, ^ {
        instance = [[super alloc] init];
        if (instance) {
            [instance prepare];
        }
    });
    return instance;
}

- (void)prepare {
    self.formatter = [[NSDateFormatter alloc] init];
    [self.formatter setDateFormat:@"yyyy'-'MM'-'dd' 'HH'.'mm'.'ss"];
    
    self.fileManager = [NSFileManager defaultManager];
    [self.fileManager setDelegate:self];
    
    self.library = [[ALAssetsLibrary alloc] init];
    
    [[MEGASdkManager sharedMEGASdk] addMEGAGlobalDelegate:self];
    
    lastUploadPhotoDate = [[NSUserDefaults standardUserDefaults] objectForKey:kLastUploadPhotoDate];
    if (!lastUploadPhotoDate) {
        lastUploadPhotoDate = [NSDate dateWithTimeIntervalSince1970:0];
        [[NSUserDefaults standardUserDefaults] setObject:lastUploadPhotoDate forKey:kLastUploadPhotoDate];
    }
    
    cameraUploadHandle = -1;
    totalAssets = 0;
    isCreatingFolder = NO;
    
    self.isCameraUploadsEnabled = [[[NSUserDefaults standardUserDefaults] objectForKey:kIsCameraUploadsEnable] boolValue];
    self.isUploadVideosEnabled = [[[NSUserDefaults standardUserDefaults] objectForKey:kIsUploadVideosEnabled] boolValue];
    self.isUseCellularConnectionEnabled = [[[NSUserDefaults standardUserDefaults] objectForKey:kIsUseCellularConnectionEnabled] boolValue];
    self.isOnlyWhenChargingEnabled = [[[NSUserDefaults standardUserDefaults] objectForKey:kIsOnlyWhenChargingEnabled] boolValue];
    
//    NSTimer *timer = [NSTimer scheduledTimerWithTimeInterval: 360.0 target: self
//                                                      selector: @selector(getAllAssetsForUpload) userInfo: nil repeats: YES];
//    [timer fire];
}

- (int)shouldRun {
    if (!self.isCameraUploadsEnabled) {
        return 1;
    }
    
    if (self.isOnlyWhenChargingEnabled) {
        if ([[UIDevice currentDevice] batteryState] == UIDeviceBatteryStateUnplugged) {
            [self.assetUploadArray removeAllObjects];
            return 1;
        }
    }
    
    if (!self.isUseCellularConnectionEnabled) {
        if ([MEGAReachabilityManager isReachableViaWWAN]) {
            [self.assetUploadArray removeAllObjects];
            return 1;
        }
    }
    
    if ([[MEGASdkManager sharedMEGASdk] isLoggedIn] == 0) {
        return 1;
    }
    
    if (![[NSUserDefaults standardUserDefaults] objectForKey:kCameraUploadsNodeHandle]){
        cameraUploadHandle = -1;
    } else {
        cameraUploadHandle = [[[NSUserDefaults standardUserDefaults] objectForKey:kCameraUploadsNodeHandle] longLongValue];
        
        if (![[MEGASdkManager sharedMEGASdk] nodeForHandle:cameraUploadHandle]){
            cameraUploadHandle = -1;
        } else {
            cameraUploadsNode = [[MEGASdkManager sharedMEGASdk] nodeForHandle:cameraUploadHandle];
            if ([[[MEGASdkManager sharedMEGASdk] parentNodeForNode:cameraUploadsNode] handle] != [[[MEGASdkManager sharedMEGASdk] rootNode] handle]){
                cameraUploadHandle = -1;
            }
        }
    }
    
    if (cameraUploadHandle == -1){
        MEGANodeList *nodeList = [[MEGASdkManager sharedMEGASdk] childrenForParent:[[MEGASdkManager sharedMEGASdk] rootNode]];
        NSInteger nodeListSize = [[nodeList size] integerValue];
        
        for (NSInteger i = 0; i < nodeListSize; i++) {
            if ([kCameraUploads isEqualToString:[[nodeList nodeAtIndex:i] name]] && [[nodeList nodeAtIndex:i] isFolder]) {
                cameraUploadHandle = [[nodeList nodeAtIndex:i] handle];
                NSNumber *cuh = [NSNumber numberWithLongLong:cameraUploadHandle];
                [[NSUserDefaults standardUserDefaults] setObject:cuh forKey:kCameraUploadsNodeHandle];
            }
        }
        
        if (cameraUploadHandle == -1 && !isCreatingFolder){
            [[MEGASdkManager sharedMEGASdk] createFolderWithName:kCameraUploads parent:[[MEGASdkManager sharedMEGASdk] rootNode] delegate:self];
        }
    }
    
    return 0;
}

- (void)getAllAssetsForUpload {
    if (self.assetUploadArray.count != 0) {
        return;
    }
    
    self.assetUploadArray =[NSMutableArray new];
    
    void (^assetEnumerator)( ALAsset *, NSUInteger, BOOL *) = ^(ALAsset *result, NSUInteger index, BOOL *stop) {
        if(result != nil) {
            if([[result valueForProperty:ALAssetPropertyType] isEqualToString:ALAssetTypePhoto]) {
                NSURL *url = [[result defaultRepresentation]url];
                
                [self.library assetForURL:url
                              resultBlock:^(ALAsset *asset) {
                                  NSDate *assetModificationTime = [asset valueForProperty:ALAssetPropertyDate];
                                  
                                  if (asset != nil  && ([assetModificationTime timeIntervalSince1970] > [lastUploadPhotoDate timeIntervalSince1970])) {
                                      [self.assetUploadArray addObject:asset];
                                  }
                                  
                                  if (index==totalAssets-1) {
                                      dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
                                          [self uploadNextImage];
                                      });
                                  }
                              }
                             failureBlock:^(NSError *error){ NSLog(@"operation was not successfull!"); } ];
                
            }
        }
    };
    
    NSMutableArray *assetGroups = [[NSMutableArray alloc] init];
    
    void (^ assetGroupEnumerator) ( ALAssetsGroup *, BOOL *)= ^(ALAssetsGroup *group, BOOL *stop) {
        if(group != nil) {
            if ([[group valueForProperty:@"ALAssetsGroupPropertyType"] intValue] == ALAssetsGroupSavedPhotos) {
                [group enumerateAssetsUsingBlock:assetEnumerator];
                [assetGroups addObject:group];
                totalAssets = [group numberOfAssets];
            }
        }
    };
    
    assetGroups = [[NSMutableArray alloc] init];
    
    [self.library enumerateGroupsWithTypes:ALAssetsGroupAll
                                usingBlock:assetGroupEnumerator
                              failureBlock:^(NSError *error) {NSLog(@"There is an error");}];
}

- (void)uploadNextImage {
    if ([self shouldRun] != 0) {
        return;
        //retryLayer;
    }
    
    ALAsset *asset = [self.assetUploadArray firstObject];
    if (!asset) {
        [self setBadgeValue];
        return;
    }
    
    NSDate *modificationTime = [asset valueForProperty:ALAssetPropertyDate];
    NSString *extension = [[[[[asset defaultRepresentation] url] absoluteString] stringBetweenString:@"&ext=" andString:@"\n"] lowercaseString];
    NSString *name = [[self.formatter stringFromDate:modificationTime] stringByAppendingPathExtension:extension];
    NSString *localFilePath = [NSTemporaryDirectory() stringByAppendingPathComponent:name];
    
    if ([[asset valueForProperty:ALAssetPropertyType] isEqualToString:ALAssetTypePhoto]) {
        ALAssetRepresentation *assetRepresentation = [asset defaultRepresentation];
        
        if (!assetRepresentation) {
            return;
        }
        
        Byte *buffer = (Byte *)malloc(assetRepresentation.size);
        NSUInteger buffered = [assetRepresentation getBytes:buffer fromOffset:0 length:assetRepresentation.size error:nil];
        
        NSData *data = [NSData dataWithBytesNoCopy:buffer length:buffered freeWhenDone:YES];
        [data writeToFile:localFilePath atomically:YES];
        
        NSError *error = nil;
        NSDictionary *attributesDictionary = [NSDictionary dictionaryWithObject:modificationTime forKey:NSFileModificationDate];
        [[NSFileManager defaultManager] setAttributes:attributesDictionary ofItemAtPath:localFilePath error:&error];
        if (error) {
            NSLog(@"Error change modification date of file %@", error);
        }
    }
    
    [self setBadgeValue];
    
    NSString *localFingerPrint = [[MEGASdkManager sharedMEGASdk] fingerprintForFilePath:localFilePath];
    
    MEGANode *nodeExists = nil;
    nodeExists = [[MEGASdkManager sharedMEGASdk] nodeForFingerprint:localFingerPrint parent:cameraUploadsNode];
    
    if(nodeExists == nil) {
        MEGANodeList *nameNodeList = [[MEGASdkManager sharedMEGASdk] nodeListSearchForNode:cameraUploadsNode searchString:name];
        
        if ([[nameNodeList size] intValue] != 0) {
            
            NSString *newName = [[NSString stringWithFormat:@"%@_%d", [self.formatter stringFromDate:modificationTime], [[nameNodeList size] intValue]] stringByAppendingPathExtension:extension];
            NSString *newLocalFilePath = [NSTemporaryDirectory() stringByAppendingPathComponent:newName];

            NSError *error = nil;
            [[NSFileManager defaultManager] moveItemAtPath:localFilePath toPath:newLocalFilePath error:&error];
            if (error) {
                NSLog(@"There is an Error: %@", error);
            }
            
            [[MEGASdkManager sharedMEGASdk] startUploadWithLocalPath:newLocalFilePath parent:cameraUploadsNode delegate:self];
            
        } else {
            [[MEGASdkManager sharedMEGASdk] startUploadWithLocalPath:localFilePath parent:cameraUploadsNode delegate:self];
        }
        
    } else {
        NSError *error = nil;
        BOOL success = [[NSFileManager defaultManager] removeItemAtPath:localFilePath error:&error];
        if (!success || error) {
            NSLog(@"remove file error %@", error);
        }
        
        if ([[[MEGASdkManager sharedMEGASdk] parentNodeForNode:nodeExists] handle] != cameraUploadHandle) {
            [[MEGASdkManager sharedMEGASdk] copyNode:nodeExists newParent:cameraUploadsNode newName:name delegate:self];
            
        } else {
            if (![nodeExists.name isEqualToString:name]) {
                [[MEGASdkManager sharedMEGASdk] renameNode:nodeExists newName:name delegate:self];
            } else {
                if ([self.assetUploadArray count] != 0) {
                    ALAsset *assetUploaded = [self.assetUploadArray objectAtIndex:0];
                    lastUploadPhotoDate = [assetUploaded valueForProperty:ALAssetPropertyDate];
                    [[NSUserDefaults standardUserDefaults] setObject:lastUploadPhotoDate forKey:kLastUploadPhotoDate];
                    [self.assetUploadArray removeObjectAtIndex:0];
                }
                
                [[UIApplication sharedApplication] setApplicationIconBadgeNumber:[CameraUploads syncManager].assetUploadArray.count];
                
                dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
                    [self uploadNextImage];
                });
            }
        }
        
    }
}

#pragma mark - Utils

- (void)setBadgeValue {
    if ([self.assetUploadArray count] > 0) {
        [[self.tabBarController.viewControllers objectAtIndex:1] tabBarItem].badgeValue = [NSString stringWithFormat:@"%lu", (unsigned long) [self.assetUploadArray count]];
    } else {
        [[self.tabBarController.viewControllers objectAtIndex:1] tabBarItem].badgeValue = nil;
    }
}

#pragma mark - MEGARequestDelegate

- (void)onRequestStart:(MEGASdk *)api request:(MEGARequest *)request {
    switch ([request type]) {
        case MEGARequestTypeCreateFolder:
            isCreatingFolder = YES;
            break;
            
        default:
            break;
    }
}

- (void)onRequestFinish:(MEGASdk *)api request:(MEGARequest *)request error:(MEGAError *)error {
    if ([error type]) {
        if ([request type] == MEGARequestTypeCopy) {
            dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
                [self uploadNextImage];
            });
        }
        return;
    }
    
    switch ([request type]) {
        case MEGARequestTypeCreateFolder:
            isCreatingFolder = NO;
            break;
            
        case MEGARequestTypeCopy:
        case MEGARequestTypeRename: {
            ALAsset *assetUploaded = [self.assetUploadArray objectAtIndex:0];
            lastUploadPhotoDate = [assetUploaded valueForProperty:ALAssetPropertyDate];
            [[NSUserDefaults standardUserDefaults] setObject:lastUploadPhotoDate forKey:kLastUploadPhotoDate];
            [self.assetUploadArray removeObjectAtIndex:0];
            
            [[UIApplication sharedApplication] setApplicationIconBadgeNumber:[CameraUploads syncManager].assetUploadArray.count];
            
            dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
                [self uploadNextImage];
            });
            break;
        }
            
        default:
            break;
    }
}

- (void)onRequestTemporaryError:(MEGASdk *)api request:(MEGARequest *)request error:(MEGAError *)error {
}

#pragma mark - MEGATransferDelegate

- (void)onTransferStart:(MEGASdk *)api transfer:(MEGATransfer *)transfer {
}

- (void)onTransferUpdate:(MEGASdk *)api transfer:(MEGATransfer *)transfer {
}

- (void)onTransferFinish:(MEGASdk *)api transfer:(MEGATransfer *)transfer error:(MEGAError *)error {
    if ([error type]) {
        if ([[MEGASdkManager sharedMEGASdk] isLoggedIn]) {
            dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
                [self uploadNextImage];
            });
        }
        return;
    }
    
    if ([transfer type] == MEGATransferTypeUpload) {
        ALAsset *assetUploaded = [self.assetUploadArray objectAtIndex:0];
        lastUploadPhotoDate = [assetUploaded valueForProperty:ALAssetPropertyDate];
        [[NSUserDefaults standardUserDefaults] setObject:lastUploadPhotoDate forKey:kLastUploadPhotoDate];
        
        [self.assetUploadArray removeObjectAtIndex:0];
        
        [self setBadgeValue];
        
        NSError *error = nil;
        NSString *localFilePath = [NSTemporaryDirectory() stringByAppendingPathComponent:[transfer fileName]];
        BOOL success = [[NSFileManager defaultManager] removeItemAtPath:localFilePath error:&error];
        if (!success || error) {
            NSLog(@"remove file error %@", error);
        }
        
       [[UIApplication sharedApplication] setApplicationIconBadgeNumber:[CameraUploads syncManager].assetUploadArray.count];
        
        dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
            [self uploadNextImage];
        });
    }
}

-(void)onTransferTemporaryError:(MEGASdk *)api transfer:(MEGATransfer *)transfer error:(MEGAError *)error {
}

@end
