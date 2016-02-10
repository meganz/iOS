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
    MEGANode *cameraUploadsNode;
    int64_t cameraUploadHandle;
}


@property (nonatomic, strong) NSDateFormatter *formatter;
@property (nonatomic, strong) NSFileManager *fileManager;
@property (nonatomic, strong) ALAssetsLibrary *library;
@property (nonatomic, strong) NSMutableDictionary *pendingOperationsMutableDictionary;
@property (nonatomic, strong) NSMutableDictionary *completedOperationsMutableDictionary;
@property (nonatomic, strong) NSString *completedPath;

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
    
    if ([[NSUserDefaults standardUserDefaults] objectForKey:kLastUploadPhotoDate]) {
        [[NSUserDefaults standardUserDefaults] removeObjectForKey:kLastUploadPhotoDate];
    }
    if ([[NSUserDefaults standardUserDefaults] objectForKey:kLastUploadVideoDate]) {
        [[NSUserDefaults standardUserDefaults] removeObjectForKey:kLastUploadPhotoDate];
    }
    
    cameraUploadHandle = -1;
    
    _isCameraUploadsEnabled = [[[NSUserDefaults standardUserDefaults] objectForKey:kIsCameraUploadsEnabled] boolValue];
    self.isUploadVideosEnabled = [[[NSUserDefaults standardUserDefaults] objectForKey:kIsUploadVideosEnabled] boolValue];
    self.isUseCellularConnectionEnabled = [[[NSUserDefaults standardUserDefaults] objectForKey:kIsUseCellularConnectionEnabled] boolValue];
    self.isOnlyWhenChargingEnabled = [[[NSUserDefaults standardUserDefaults] objectForKey:kIsOnlyWhenChargingEnabled] boolValue];
    
    [self resetOperationQueue];
    
    _pendingOperationsMutableDictionary = [[NSMutableDictionary alloc] init];
    _completedOperationsMutableDictionary = [[NSMutableDictionary alloc] init];
}

- (int)shouldRun {
    if (!self.isCameraUploadsEnabled) {
        return 1;
    }
    
    if (self.isOnlyWhenChargingEnabled) {
        if ([[UIDevice currentDevice] batteryState] == UIDeviceBatteryStateUnplugged) {
            [self resetOperationQueue];
            return 1;
        }
    }
    
    if (!self.isUseCellularConnectionEnabled) {
        if ([MEGAReachabilityManager isReachableViaWWAN]) {
            [self resetOperationQueue];
            return 1;
        }
    }
    
    if ([[MEGASdkManager sharedMEGASdk] isLoggedIn] == 0) {
        return 1;
    }
    
    return 0;
}

- (void)resetOperationQueue {
    [self.assetsOperationQueue cancelAllOperations];
    
    self.assetsOperationQueue = [[NSOperationQueue alloc] init];
    if ([self.assetsOperationQueue respondsToSelector:@selector(qualityOfService)]) {
        self.assetsOperationQueue.qualityOfService = NSOperationQualityOfServiceUtility;
    }
    
    self.assetsOperationQueue.maxConcurrentOperationCount = 1;
}

- (void)setIsCameraUploadsEnabled:(BOOL)isCameraUploadsEnabled {
    _isCameraUploadsEnabled = isCameraUploadsEnabled;
    
    if (isCameraUploadsEnabled) {
        _completedPath = [NSSearchPathForDirectoriesInDomains(NSApplicationSupportDirectory, NSUserDomainMask, YES).firstObject stringByAppendingPathComponent:@"CameraUploads/completed.plist"];
        if (![[NSFileManager defaultManager] fileExistsAtPath:_completedPath]) {
            [[NSFileManager defaultManager] createDirectoryAtPath:[_completedPath stringByDeletingLastPathComponent] withIntermediateDirectories:YES attributes:nil error:nil];
            _completedOperationsMutableDictionary = [[NSMutableDictionary alloc] init];
        } else {
            _completedOperationsMutableDictionary = [NSMutableDictionary dictionaryWithContentsOfFile:_completedPath];
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
            
            if (cameraUploadHandle == -1){
                [[MEGASdkManager sharedMEGASdk] createFolderWithName:kCameraUploads parent:[[MEGASdkManager sharedMEGASdk] rootNode] delegate:self];
            } else {
                if (cameraUploadsNode == nil) {
                    cameraUploadsNode = [[MEGASdkManager sharedMEGASdk] nodeForHandle:cameraUploadHandle];
                }
                [self getAssetsForUpload];
            }
        } else {
            if (cameraUploadsNode == nil) {
                cameraUploadsNode = [[MEGASdkManager sharedMEGASdk] nodeForHandle:cameraUploadHandle];
            }
            [self getAssetsForUpload];
        }
    } else {
        
        //TODO: Cancel only Camera Uploads upload transfers
        [[MEGASdkManager sharedMEGASdk] cancelTransfersForDirection:1 delegate:self];
        
        [self resetOperationQueue];
        
        _isCameraUploadsEnabled = NO;
        [CameraUploads syncManager].isUploadVideosEnabled = NO;
        [CameraUploads syncManager].isUseCellularConnectionEnabled = NO;
        [CameraUploads syncManager].isOnlyWhenChargingEnabled = NO;
        
        [[NSUserDefaults standardUserDefaults] setObject:[NSNumber numberWithBool:_isCameraUploadsEnabled] forKey:kIsCameraUploadsEnabled];
        [[NSUserDefaults standardUserDefaults] setObject:[NSNumber numberWithBool:[CameraUploads syncManager].isUploadVideosEnabled] forKey:kIsUploadVideosEnabled];
        [[NSUserDefaults standardUserDefaults] setObject:[NSNumber numberWithBool:[CameraUploads syncManager].isUseCellularConnectionEnabled] forKey:kIsUseCellularConnectionEnabled];
        [[NSUserDefaults standardUserDefaults] setObject:[NSNumber numberWithBool:[CameraUploads syncManager].isOnlyWhenChargingEnabled] forKey:kIsOnlyWhenChargingEnabled];
        
        [[NSUserDefaults standardUserDefaults] synchronize];
        
        [[NSNotificationCenter defaultCenter] postNotificationName:@"kUserDeniedPhotoAccess" object:nil];
        
        NSError *error = nil;
        BOOL success = [[NSFileManager defaultManager] removeItemAtPath:NSTemporaryDirectory() error:&error];
        if (!success || error) {
            [MEGASdk logWithLevel:MEGALogLevelError message:[NSString stringWithFormat:@"Remove file error %@", error]];
        }
        
        [self setBadgeValue];
    }
}

- (void)getAssetsForUpload {
    if ([self.assetsOperationQueue operationCount] >= 1) {
        return;
    }
    
    __block NSInteger totalAssets = 0;
    
    NSMutableArray *photosOperationArray = [[NSMutableArray alloc] init];
    
    void (^assetEnumerator)( ALAsset *, NSUInteger, BOOL *) = ^(ALAsset *result, NSUInteger index, BOOL *stop) {
        if(result != nil) {
            NSURL *url = [[result defaultRepresentation]url];
            [self.library assetForURL:url
                          resultBlock:^(ALAsset *asset) {
                              NSString *assetID = [[[asset defaultRepresentation] url] absoluteString];
                              NSArray *allKeysForValue = [_completedOperationsMutableDictionary allKeysForObject:assetID];
                              
                              if ([allKeysForValue count] == 0) {
                                  if (asset != nil && [[asset valueForProperty:ALAssetPropertyType] isEqualToString:ALAssetTypeVideo] && [CameraUploads syncManager].isUploadVideosEnabled) {
                                      NSOperation *uploadAssetsOperation = [NSBlockOperation blockOperationWithBlock:^{
                                          [self uploadAsset:asset];
                                      }];
                                      [photosOperationArray addObject:uploadAssetsOperation];
                                  } else if (asset != nil && [[asset valueForProperty:ALAssetPropertyType] isEqualToString:ALAssetTypePhoto]) {
                                      NSOperation *uploadAssetsOperation = [NSBlockOperation blockOperationWithBlock:^{
                                          [self uploadAsset:asset];
                                      }];
                                      [photosOperationArray addObject:uploadAssetsOperation];
                                  }
                              }
                              
                              if (index==totalAssets-1) {
                                  [self.assetsOperationQueue addOperations:photosOperationArray waitUntilFinished:NO];
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

- (void)uploadAsset:(ALAsset *)asset {
    if ([self shouldRun] != 0) {
        return;
    }
    
    if (!asset) {
        return;
    }
    
    NSDate *modificationTime = [asset valueForProperty:ALAssetPropertyDate];
    NSString *extension = [[[[[asset defaultRepresentation] url] absoluteString] stringBetweenString:@"&ext=" andString:@"\n"] lowercaseString];
    NSString *name = [[self.formatter stringFromDate:modificationTime] stringByAppendingPathExtension:extension];
    NSString *localFilePath = [NSTemporaryDirectory() stringByAppendingPathComponent:name];
    
    ALAssetRepresentation *assetRepresentation = [asset defaultRepresentation];
    
    NSString *localFingerPrint = [[MEGASdkManager sharedMEGASdk] fingerprintForAssetRepresentation:assetRepresentation modificationTime:modificationTime];

    MEGANode *nodeExists = nil;
    nodeExists = [[MEGASdkManager sharedMEGASdk] nodeForFingerprint:localFingerPrint parent:cameraUploadsNode];
    
    if(nodeExists == nil) {
        NSString *localCRC = [[MEGASdkManager sharedMEGASdk] CRCForFingerprint:localFingerPrint];
        nodeExists = [[MEGASdkManager sharedMEGASdk] nodeByCRC:localCRC parent:cameraUploadsNode];

    }
    
    [self addValueToPendingOperations:asset fingerprint:localFingerPrint];
    
    [self.assetsOperationQueue setSuspended:YES];
    
    if (nodeExists == nil) {
        
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
            
            [self setIsCameraUploadsEnabled:NO];
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
        
        NSError *error = nil;
        NSDictionary *attributesDictionary = [NSDictionary dictionaryWithObject:modificationTime forKey:NSFileModificationDate];
        [[NSFileManager defaultManager] setAttributes:attributesDictionary ofItemAtPath:localFilePath error:&error];
        if (error) {
            [MEGASdk logWithLevel:MEGALogLevelError message:[NSString stringWithFormat:@"Error change modification date for file %@", error]];
        }
        
        NSString *newName = [self newNameForName:name];
        
        [self setBadgeValue];
        
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
                [self updateOperationsWithNode:nodeExists];
                if ([self.assetsOperationQueue operationCount] == 1) {
                    [self resetOperationQueue];
                    if (_isCameraUploadsEnabled) {
                        [self setIsCameraUploadsEnabled:YES];
                    }
                }
            }
        }
    }
}

- (void)addValueToPendingOperations:(ALAsset *)asset fingerprint:(NSString *)fingerprint {
    if ([_pendingOperationsMutableDictionary objectForKey:fingerprint] == nil) {
        NSString *assetID = [[[asset defaultRepresentation] url] absoluteString];
        if (fingerprint) {
            [_pendingOperationsMutableDictionary setValue:assetID forKey:fingerprint];
        }
    }
}

- (void)addToCompletedOperations:(NSString *)assetID fingerprint:(NSString *)fingerprint {
    if ([_completedOperationsMutableDictionary objectForKey:fingerprint] == nil) {
        if (fingerprint) {
            [_completedOperationsMutableDictionary setValue:assetID forKey:fingerprint];
        }
        [_completedOperationsMutableDictionary writeToFile:_completedPath atomically:YES];
    }
}

#pragma mark - Utils

- (void)setBadgeValue {
    NSInteger cameraUploadsTabPosition;
    for (cameraUploadsTabPosition = 0 ; cameraUploadsTabPosition < self.tabBarController.viewControllers.count ; cameraUploadsTabPosition++) {
        if ([[[self.tabBarController.viewControllers objectAtIndex:cameraUploadsTabPosition] tabBarItem] tag] == 1) {
            break;
        }
    }
    
    NSString *badgeValue = nil;
    if ([self.assetsOperationQueue operationCount] > 0) {
        badgeValue = [NSString stringWithFormat:@"%lu", [self.assetsOperationQueue operationCount]];
    }
    
    dispatch_async(dispatch_get_main_queue(), ^{
        if ((cameraUploadsTabPosition >= 4) && ([[UIDevice currentDevice] userInterfaceIdiom] == UIUserInterfaceIdiomPhone)) {
            [[[self.tabBarController moreNavigationController] tabBarItem] setBadgeValue:badgeValue];
        }
        [[self.tabBarController.viewControllers objectAtIndex:cameraUploadsTabPosition] tabBarItem].badgeValue = badgeValue;
    });
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

- (void)updateOperationsWithNode:(MEGANode *)node {
    NSString *fingerprint = [[MEGASdkManager sharedMEGASdk] fingerprintForNode:node];
    NSString *assetID = [_pendingOperationsMutableDictionary objectForKey:fingerprint];
    [self addToCompletedOperations:assetID fingerprint:fingerprint];
    [_pendingOperationsMutableDictionary removeObjectForKey:fingerprint];
    [self.assetsOperationQueue setSuspended:NO];
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

- (void)onRequestFinish:(MEGASdk *)api request:(MEGARequest *)request error:(MEGAError *)error {
    if ([error type]) {
        return;
    }
    
    switch ([request type]) {
        case MEGARequestTypeCreateFolder:
            cameraUploadHandle = request.nodeHandle;
            [[NSUserDefaults standardUserDefaults] setObject:[NSNumber numberWithLongLong:cameraUploadHandle] forKey:kCameraUploadsNodeHandle];
            [[NSUserDefaults standardUserDefaults] synchronize];
            cameraUploadsNode = [[MEGASdkManager sharedMEGASdk] nodeForHandle:cameraUploadHandle];
            [self getAssetsForUpload];
            break;
            
        case MEGARequestTypeCopy:
        case MEGARequestTypeRename: {
            MEGANode *node = [[MEGASdkManager sharedMEGASdk] nodeForHandle:request.nodeHandle];
            [self setBadgeValue];
            [self updateOperationsWithNode:node];
            break;
        }
            
        default:
            break;
    }
    
    if (![_assetsOperationQueue operationCount] && [self isCameraUploadsEnabled]) {
        [self resetOperationQueue];
        [self setIsCameraUploadsEnabled:YES];
    }
}

#pragma mark - MEGATransferDelegate

- (void)onTransferFinish:(MEGASdk *)api transfer:(MEGATransfer *)transfer error:(MEGAError *)error {
    if ([error type]) {
        if ([error type] == MEGAErrorTypeApiEArgs) {
            [self resetOperationQueue];
            if (_isCameraUploadsEnabled) {
                [self setIsCameraUploadsEnabled:YES];
            }
        }
        return;
    }
    
    if ([transfer type] == MEGATransferTypeUpload) {
        MEGANode *node = [[MEGASdkManager sharedMEGASdk] nodeForHandle:transfer.nodeHandle];
        [self setBadgeValue];
        [self updateOperationsWithNode:node];
        
        NSError *error = nil;
        BOOL success = [[NSFileManager defaultManager] removeItemAtPath:transfer.path error:&error];
        if (!success || error) {
            [MEGASdk logWithLevel:MEGALogLevelError message:[NSString stringWithFormat:@"Remove file error %@", error]];
        }
    }
    
    if (![_assetsOperationQueue operationCount] && [self isCameraUploadsEnabled]) {
        [self resetOperationQueue];
        [self setIsCameraUploadsEnabled:YES];
    }
}

@end
