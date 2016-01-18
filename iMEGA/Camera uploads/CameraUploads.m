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
#import "Helper.h"
#import "SVProgressHUD.h"
#import "CameraUploadsTableViewController.h"

#define kCameraUploads @"Camera Uploads"

@interface CameraUploads () <UIAlertViewDelegate> {
    NSInteger totalAssets;
    
    MEGANode *cameraUploadsNode;
    uint64_t cameraUploadHandle;
    
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
    NSLocale *locale = [[NSLocale alloc] initWithLocaleIdentifier:@"en_US_POSIX"];
    [self.formatter setLocale:locale];
    
    self.fileManager = [NSFileManager defaultManager];
    [self.fileManager setDelegate:self];
    
    self.library = [[ALAssetsLibrary alloc] init];
    
    [[MEGASdkManager sharedMEGASdk] addMEGAGlobalDelegate:self];
    
    self.lastUploadPhotoDate = [[NSUserDefaults standardUserDefaults] objectForKey:kLastUploadPhotoDate];
    if (!self.lastUploadPhotoDate) {
        self.lastUploadPhotoDate = [NSDate dateWithTimeIntervalSince1970:0];
        [[NSUserDefaults standardUserDefaults] setObject:self.lastUploadPhotoDate forKey:kLastUploadPhotoDate];
    }
    
    self.lastUploadVideoDate = [[NSUserDefaults standardUserDefaults] objectForKey:kLastUploadVideoDate];
    if (!self.lastUploadVideoDate) {
        self.lastUploadVideoDate = [NSDate dateWithTimeIntervalSince1970:0];
        [[NSUserDefaults standardUserDefaults] setObject:self.lastUploadVideoDate forKey:kLastUploadVideoDate];
    }
    
    cameraUploadHandle = -1;
    totalAssets = 0;
    isCreatingFolder = NO;
    
    self.isCameraUploadsEnabled = [[[NSUserDefaults standardUserDefaults] objectForKey:kIsCameraUploadsEnabled] boolValue];
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
            NSURL *url = [[result defaultRepresentation]url];
            [self.library assetForURL:url
                          resultBlock:^(ALAsset *asset) {
                              NSDate *assetModificationTime = [asset valueForProperty:ALAssetPropertyDate];
                              
                              if (asset != nil && [[asset valueForProperty:ALAssetPropertyType] isEqualToString:ALAssetTypeVideo] && [CameraUploads syncManager].isUploadVideosEnabled && ([assetModificationTime timeIntervalSince1970] > [self.lastUploadVideoDate timeIntervalSince1970])) {
                                  [self.assetUploadArray addObject:asset];
                              } else {
                                  if (asset != nil  && [[asset valueForProperty:ALAssetPropertyType] isEqualToString:ALAssetTypePhoto] && ([assetModificationTime timeIntervalSince1970] > [self.lastUploadPhotoDate timeIntervalSince1970])) {
                                      [self.assetUploadArray addObject:asset];
                                  }
                              }
                              
                              if (index==totalAssets-1) {
                                  dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
                                      [self uploadAsset];
                                  });
                              }
                          }
                         failureBlock:^(NSError *error) {
                             [MEGASdk logWithLevel:MEGALogLevelError message:@"enumerateGroupsWithTypes failureBlock"];
                         } ];
            
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
    
    [self.library enumerateGroupsWithTypes:ALAssetsGroupAll
                                usingBlock:assetGroupEnumerator
                              failureBlock:^(NSError *error) {
                                  [[CameraUploads syncManager] setIsCameraUploadsEnabled:NO];
                                  [[NSNotificationCenter defaultCenter] postNotificationName:@"kUserDeniedPhotoAccess" object:nil];
                                  [MEGASdk logWithLevel:MEGALogLevelError message:@"enumerateGroupsWithTypes failureBlock"];
                              }];
}

- (void)uploadAsset {
    if ([self shouldRun] != 0) {
        return;
        //retryLayer;
    }
    
    ALAsset *asset = nil;
    
    [self setBadgeValue];
    
    if (self.assetUploadArray.count > 0) {
        asset = [self.assetUploadArray firstObject];
    }
    
    if (!asset) {
        return;
    }
    
    NSDate *modificationTime = [asset valueForProperty:ALAssetPropertyDate];
    NSString *extension = [[[[[asset defaultRepresentation] url] absoluteString] stringBetweenString:@"&ext=" andString:@"\n"] lowercaseString];
    NSString *name = [[self.formatter stringFromDate:modificationTime] stringByAppendingPathExtension:extension];
    NSString *localFilePath = [NSTemporaryDirectory() stringByAppendingPathComponent:name];
    
    ALAssetRepresentation *assetRepresentation = [asset defaultRepresentation];
    
    long long asize = assetRepresentation.size;
    long long freeSpace = (long long)[Helper freeDiskSpace];
    
    if (asize > freeSpace) {
        dispatch_async(dispatch_get_main_queue(), ^{
            UIAlertView *alertView = [[UIAlertView alloc] initWithTitle:AMLocalizedString(@"nodeTooBig", @"Title shown inside an alert if you don't have enough space on your device to download something")
                                                                message:AMLocalizedString(@"cameraUploadsDisabled_alertView_message", @"Camera Uploads will be disabled, because you don't have enought space on your device")
                                                               delegate:self
                                                      cancelButtonTitle:AMLocalizedString(@"ok", nil)
                                                      otherButtonTitles:nil];
            [alertView show];
        });
        
        [self turnOffCameraUploads];
        return;
    }
    
    if (!assetRepresentation) {
        return;
    }
    
    [[NSFileManager defaultManager] createFileAtPath:localFilePath contents:nil attributes:nil];
    NSFileHandle *handle = [NSFileHandle fileHandleForWritingAtPath:localFilePath];
    
    static const NSUInteger kBufferSize = 10 * 1024;
    uint8_t *buffer = calloc(kBufferSize, sizeof(*buffer));
    NSUInteger offset = 0, bytesRead = 0;
    
    do {
        bytesRead = [assetRepresentation getBytes:buffer fromOffset:offset length:kBufferSize error:nil];
        [handle writeData:[NSData dataWithBytesNoCopy:buffer length:bytesRead freeWhenDone:NO]];
        
        offset += bytesRead;
        
    } while (bytesRead > 0);
    
    free(buffer);
    [handle closeFile];
    
//    Byte *buffer = (Byte *)malloc(assetRepresentation.size);
//    NSUInteger buffered = [assetRepresentation getBytes:buffer fromOffset:0 length:assetRepresentation.size error:nil];
//    
//    NSData *data = [NSData dataWithBytesNoCopy:buffer length:buffered freeWhenDone:YES];
//    [data writeToFile:localFilePath atomically:YES];
    
    NSError *error = nil;
    NSDictionary *attributesDictionary = [NSDictionary dictionaryWithObject:modificationTime forKey:NSFileModificationDate];
    [[NSFileManager defaultManager] setAttributes:attributesDictionary ofItemAtPath:localFilePath error:&error];
    if (error) {
        [MEGASdk logWithLevel:MEGALogLevelError message:[NSString stringWithFormat:@"Error change modification date for file %@", error]];
    }
    
    NSString *localCRC = [[MEGASdkManager sharedMEGASdk] CRCForFilePath:localFilePath];
    MEGANode *nodeExists = nil;
    nodeExists = [[MEGASdkManager sharedMEGASdk] nodeByCRC:localCRC parent:cameraUploadsNode];
    
    if(nodeExists == nil) {
        NSString *localFingerPrint = [[MEGASdkManager sharedMEGASdk] fingerprintForFilePath:localFilePath];
        nodeExists = [[MEGASdkManager sharedMEGASdk] nodeForFingerprint:localFingerPrint parent:cameraUploadsNode];
    }
    
    if (nodeExists == nil) {
        NSString *newName = [self newNameForName:name];
        
        if (![name isEqualToString:newName]) {
            NSString *newLocalFilePath = [NSTemporaryDirectory() stringByAppendingPathComponent:newName];
            
            NSError *error = nil;
            [[NSFileManager defaultManager] moveItemAtPath:localFilePath toPath:newLocalFilePath error:&error];
            if (error) {
                [MEGASdk logWithLevel:MEGALogLevelError message:[NSString stringWithFormat:@"Move file error %@", error]];
            }
            [[MEGASdkManager sharedMEGASdk] startUploadWithLocalPath:newLocalFilePath parent:cameraUploadsNode delegate:self];
        } else {
            [[MEGASdkManager sharedMEGASdk] startUploadWithLocalPath:localFilePath parent:cameraUploadsNode delegate:self];
        }
    } else {
        NSError *error = nil;
        BOOL success = [[NSFileManager defaultManager] removeItemAtPath:localFilePath error:&error];
        if (!success || error) {
            [MEGASdk logWithLevel:MEGALogLevelError message:[NSString stringWithFormat:@"Remove file error %@", error]];
        }
        
        if ([[[MEGASdkManager sharedMEGASdk] parentNodeForNode:nodeExists] handle] != cameraUploadHandle) {
            NSString *newName = [self newNameForName:name];
            
            if (![name isEqualToString:newName]) {
                [[MEGASdkManager sharedMEGASdk] copyNode:nodeExists newParent:cameraUploadsNode newName:newName delegate:self];
            } else {
                [[MEGASdkManager sharedMEGASdk] copyNode:nodeExists newParent:cameraUploadsNode newName:name delegate:self];
            }
            
        } else {
            if (![nodeExists.name isEqualToString:name] && [[nodeExists.name stringByDeletingPathExtension] rangeOfString:[name stringByDeletingPathExtension]].location == NSNotFound) {
                NSString *newName = [self newNameForName:name];
                
                if (![name isEqualToString:newName]) {
                    [[MEGASdkManager sharedMEGASdk] renameNode:nodeExists newName:newName delegate:self];
                } else {
                    [[MEGASdkManager sharedMEGASdk] renameNode:nodeExists newName:name delegate:self];
                }
                
            } else {
                if ([self.assetUploadArray count] != 0) {
                    [self updateLastUploadDate];
                }
                
                dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
                    [self uploadAsset];
                });
            }
        }
    }
}

#pragma mark - Utils

- (void)setBadgeValue {
    NSInteger i;
    for (i = 0 ; i < self.tabBarController.viewControllers.count ; i++) {
        if ([[[self.tabBarController.viewControllers objectAtIndex:i] tabBarItem] tag] == 1) {
            break;
        }
    }
    
    if ([self.assetUploadArray count] > 0) {
        [[self.tabBarController.viewControllers objectAtIndex:i] tabBarItem].badgeValue = [NSString stringWithFormat:@"%lu", (unsigned long) [self.assetUploadArray count]];
    } else {
        [[self.tabBarController.viewControllers objectAtIndex:i] tabBarItem].badgeValue = nil;
    }
}

- (NSString *)newNameForName:(NSString *)name {
    NSString *nameWithoutExtension = [name stringByDeletingPathExtension];
    NSString *extension = [name pathExtension];
    int index = 0;
    int listSize = 0;
    
    do {
        if (index != 0) {
            nameWithoutExtension = [[name stringByDeletingPathExtension] stringByAppendingString:[NSString stringWithFormat:@"_%d", index]];
        }

        MEGANodeList *nameNodeList = [[MEGASdkManager sharedMEGASdk] nodeListSearchForNode:cameraUploadsNode searchString:[nameWithoutExtension stringByAppendingPathExtension:extension]];
        listSize = [nameNodeList.size intValue];
        index++;
    } while (listSize != 0);
    
    return [nameWithoutExtension stringByAppendingPathExtension:extension];
}

- (void)updateLastUploadDate {
    if (self.assetUploadArray > 0) {
        ALAsset *asset = [self.assetUploadArray objectAtIndex:0];
        
        if ([[asset valueForProperty:ALAssetPropertyType] isEqualToString:ALAssetTypePhoto]) {
            self.lastUploadPhotoDate = [asset valueForProperty:ALAssetPropertyDate];
            [[NSUserDefaults standardUserDefaults] setObject:self.lastUploadPhotoDate forKey:kLastUploadPhotoDate];
        }
        
        if ([[asset valueForProperty:ALAssetPropertyType] isEqualToString:ALAssetTypeVideo]) {
            self.lastUploadVideoDate = [asset valueForProperty:ALAssetPropertyDate];
            [[NSUserDefaults standardUserDefaults] setObject:self.lastUploadVideoDate forKey:kLastUploadVideoDate];
        }
        [self.assetUploadArray removeObjectAtIndex:0];
    }

}

- (void)turnOffCameraUploads {
    [self setBadgeValue];
    
    //TODO: Cancel only Camera Uploads upload transfers
    [[MEGASdkManager sharedMEGASdk] cancelTransfersForDirection:1 delegate:self];
    
    [[CameraUploads syncManager].assetUploadArray removeAllObjects];
    
    [CameraUploads syncManager].isCameraUploadsEnabled = NO;
    [CameraUploads syncManager].isUploadVideosEnabled = NO;
    [CameraUploads syncManager].isUseCellularConnectionEnabled = NO;
    [CameraUploads syncManager].isOnlyWhenChargingEnabled = NO;
    
    [[NSUserDefaults standardUserDefaults] setObject:[NSNumber numberWithBool:[CameraUploads syncManager].isCameraUploadsEnabled] forKey:kIsCameraUploadsEnabled];
    [[NSUserDefaults standardUserDefaults] setObject:[NSNumber numberWithBool:[CameraUploads syncManager].isUploadVideosEnabled] forKey:kIsUploadVideosEnabled];
    [[NSUserDefaults standardUserDefaults] setObject:[NSNumber numberWithBool:[CameraUploads syncManager].isUseCellularConnectionEnabled] forKey:kIsUseCellularConnectionEnabled];
    [[NSUserDefaults standardUserDefaults] setObject:[NSNumber numberWithBool:[CameraUploads syncManager].isOnlyWhenChargingEnabled] forKey:kIsOnlyWhenChargingEnabled];
    
    [[NSNotificationCenter defaultCenter] postNotificationName:@"kUserDeniedPhotoAccess" object:nil];
    
    NSError *error = nil;
    BOOL success = [[NSFileManager defaultManager] removeItemAtPath:NSTemporaryDirectory() error:&error];
    if (!success || error) {
        [MEGASdk logWithLevel:MEGALogLevelError message:[NSString stringWithFormat:@"Remove file error %@", error]];
    }
}

#pragma mark - UIAlertViewDelegate

- (void)alertView:(UIAlertView *)alertView clickedButtonAtIndex:(NSInteger)buttonIndex {
    //If settings is on "more" tab bar item
    if (self.tabBarController.selectedIndex >= 4) {
        if ([[self.tabBarController.moreNavigationController visibleViewController] isKindOfClass:[CameraUploadsTableViewController class]]) {
            dispatch_async(dispatch_get_main_queue(), ^{
                [[self.tabBarController.moreNavigationController visibleViewController] viewWillAppear:YES];
            });
        }
    } else {
        if ([[(UINavigationController *)[(UITabBarController *)[[[[UIApplication sharedApplication] delegate] window] rootViewController] selectedViewController] visibleViewController] isKindOfClass:[CameraUploadsTableViewController class]]) {
            dispatch_async(dispatch_get_main_queue(), ^{
                [[(UINavigationController *)[(UITabBarController *)[[[[UIApplication sharedApplication] delegate] window] rootViewController] selectedViewController] visibleViewController] viewWillAppear:YES];
            });
        }
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
                [self uploadAsset];
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
            [self updateLastUploadDate];
            
            dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
                [self uploadAsset];
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
    if ([transfer type] == MEGATransferTypeUpload) {
        [self setBadgeValue];
    }
}

- (void)onTransferUpdate:(MEGASdk *)api transfer:(MEGATransfer *)transfer {
}

- (void)onTransferFinish:(MEGASdk *)api transfer:(MEGATransfer *)transfer error:(MEGAError *)error {
    if ([error type]) {
        if ([[MEGASdkManager sharedMEGASdk] isLoggedIn]) {
            dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
                [self uploadAsset];
            });
        }
        return;
    }
    
    if ([transfer type] == MEGATransferTypeUpload) {
        [self updateLastUploadDate];
        
        [self setBadgeValue];
        
        dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
            [self uploadAsset];
        });
    }
}

-(void)onTransferTemporaryError:(MEGASdk *)api transfer:(MEGATransfer *)transfer error:(MEGAError *)error {
}

@end
