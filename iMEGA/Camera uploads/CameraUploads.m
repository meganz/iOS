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

#import <Photos/Photos.h>
#import <AssetsLibrary/AssetsLibrary.h>
#import "MEGAAssetOperation.h"

#import "CameraUploads.h"
#import "MEGASdkManager.h"
#import "MEGAReachabilityManager.h"
#import "Helper.h"
#import "SVProgressHUD.h"
#import "CameraUploadsTableViewController.h"

#define kCameraUploads @"Camera Uploads"

@interface CameraUploads () <UIAlertViewDelegate> {
    MEGANode *cameraUploadsNode;
    int64_t cameraUploadHandle;
}

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
    self.library = [[ALAssetsLibrary alloc] init];
    
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
    
    _isCameraUploadsEnabled = [[[NSUserDefaults standardUserDefaults] objectForKey:kIsCameraUploadsEnabled] boolValue];
    self.isUploadVideosEnabled = [[[NSUserDefaults standardUserDefaults] objectForKey:kIsUploadVideosEnabled] boolValue];
    self.isUseCellularConnectionEnabled = [[[NSUserDefaults standardUserDefaults] objectForKey:kIsUseCellularConnectionEnabled] boolValue];
    self.isOnlyWhenChargingEnabled = [[[NSUserDefaults standardUserDefaults] objectForKey:kIsOnlyWhenChargingEnabled] boolValue];
    
    [self resetOperationQueue];
}

- (void)resetOperationQueue {
    [self.assetsOperationQueue cancelAllOperations];
    
    self.assetsOperationQueue = [[NSOperationQueue alloc] init];
    if ([self.assetsOperationQueue respondsToSelector:@selector(qualityOfService)]) {
        self.assetsOperationQueue.qualityOfService = NSOperationQualityOfServiceUtility;
    }
    
    self.assetsOperationQueue.maxConcurrentOperationCount = 1;
    
    [self setBadgeValue];
    
    if (_isCameraUploadsEnabled) {
        if (_isUseCellularConnectionEnabled) {
            [self setIsCameraUploadsEnabled:YES];
        } else {
            if ([MEGAReachabilityManager isReachableViaWiFi]) {
                [self setIsCameraUploadsEnabled:YES];
            }
        }
    }
}

- (void)setIsCameraUploadsEnabled:(BOOL)isCameraUploadsEnabled {
    _isCameraUploadsEnabled = isCameraUploadsEnabled;
    
    if (isCameraUploadsEnabled) {
        MEGALogInfo(@"Camera Uploads enabled");
        self.lastUploadPhotoDate = [[NSUserDefaults standardUserDefaults] objectForKey:kLastUploadPhotoDate];
        self.lastUploadVideoDate = [[NSUserDefaults standardUserDefaults] objectForKey:kLastUploadVideoDate];
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
        MEGALogInfo(@"Camera Uploads disabled");
        [self resetOperationQueue];
        
        _isCameraUploadsEnabled = NO;
        self.isUploadVideosEnabled = NO;
        self.isUseCellularConnectionEnabled = NO;
        self.isOnlyWhenChargingEnabled = NO;
        
        [[NSUserDefaults standardUserDefaults] setObject:[NSNumber numberWithBool:_isCameraUploadsEnabled] forKey:kIsCameraUploadsEnabled];
        [[NSUserDefaults standardUserDefaults] setObject:[NSNumber numberWithBool:self.isUploadVideosEnabled] forKey:kIsUploadVideosEnabled];
        [[NSUserDefaults standardUserDefaults] setObject:[NSNumber numberWithBool:self.isUseCellularConnectionEnabled] forKey:kIsUseCellularConnectionEnabled];
        [[NSUserDefaults standardUserDefaults] setObject:[NSNumber numberWithBool:self.isOnlyWhenChargingEnabled] forKey:kIsOnlyWhenChargingEnabled];
        
        [[NSUserDefaults standardUserDefaults] synchronize];
        
        [[NSNotificationCenter defaultCenter] postNotificationName:@"kUserDeniedPhotoAccess" object:nil];
    }
}

- (void)getAssetsForUpload {
    if ([self.assetsOperationQueue operationCount] >= 1) {
        return;
    }
    
    if (![[NSFileManager defaultManager] fileExistsAtPath:NSTemporaryDirectory()]) {
        [[NSFileManager defaultManager] createDirectoryAtPath:NSTemporaryDirectory() withIntermediateDirectories:YES attributes:nil error:nil];
    }
    
    if ([[[UIDevice currentDevice] systemVersion] floatValue] >= 8.0) {
        PHFetchResult *assetsFetchResult = nil;
        
        PHFetchOptions *fetchOptions = [[PHFetchOptions alloc] init];
        fetchOptions.sortDescriptors = @[[NSSortDescriptor sortDescriptorWithKey:@"creationDate" ascending:YES]];
        
        if (self.isUploadVideosEnabled) {
            assetsFetchResult = [PHAsset fetchAssetsWithOptions:fetchOptions];
        } else {
            assetsFetchResult = [PHAsset fetchAssetsWithMediaType:PHAssetMediaTypeImage options:fetchOptions];
        }
        
        MEGALogInfo(@"Retrieved assets %ld", assetsFetchResult.count);
        
        [assetsFetchResult enumerateObjectsUsingBlock:^(PHAsset *asset, NSUInteger index, BOOL *stop) {
            if (asset.mediaType == PHAssetMediaTypeVideo && self.isUploadVideosEnabled && ([asset.creationDate timeIntervalSince1970] > [self.lastUploadVideoDate timeIntervalSince1970])) {
                MEGAAssetOperation *uploadAssetsOperation = [[MEGAAssetOperation alloc] initWithPHAsset:asset parentNode:cameraUploadsNode automatically:YES];
                [_assetsOperationQueue addOperation:uploadAssetsOperation];
            } else if (asset.mediaType == PHAssetMediaTypeImage && ([asset.creationDate timeIntervalSince1970] > [self.lastUploadPhotoDate timeIntervalSince1970])) {
                MEGAAssetOperation *uploadAssetsOperation = [[MEGAAssetOperation alloc] initWithPHAsset:asset parentNode:cameraUploadsNode automatically:YES];
                [_assetsOperationQueue addOperation:uploadAssetsOperation];
            }            
        }];
    } else {
        __block NSInteger totalAssets = 0;
        
        void (^assetEnumerator)( ALAsset *, NSUInteger, BOOL *) = ^(ALAsset *result, NSUInteger index, BOOL *stop) {
            if(result != nil) {
                NSURL *url = [[result defaultRepresentation]url];
                [self.library assetForURL:url
                              resultBlock:^(ALAsset *asset) {
                                  NSDate *assetCreationTime = [asset valueForProperty:ALAssetPropertyDate];
                                  
                                  if (asset != nil && [[asset valueForProperty:ALAssetPropertyType] isEqualToString:ALAssetTypeVideo] && self.isUploadVideosEnabled && ([assetCreationTime timeIntervalSince1970] > [self.lastUploadVideoDate timeIntervalSince1970])) {
                                      MEGAAssetOperation *uploadAssetsOperation = [[MEGAAssetOperation alloc] initWithALAsset:asset cameraUploadNode:cameraUploadsNode];
                                      [_assetsOperationQueue addOperation:uploadAssetsOperation];
                                  } else if (asset != nil  && [[asset valueForProperty:ALAssetPropertyType] isEqualToString:ALAssetTypePhoto] && ([assetCreationTime timeIntervalSince1970] > [self.lastUploadPhotoDate timeIntervalSince1970])) {
                                      MEGAAssetOperation *uploadAssetsOperation = [[MEGAAssetOperation alloc] initWithALAsset:asset cameraUploadNode:cameraUploadsNode];
                                      [_assetsOperationQueue addOperation:uploadAssetsOperation];
                                  }
                              }
                             failureBlock:^(NSError *error) {
                                 MEGALogError(@"Asset for url failed with error: %@", error);
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
                                      [self setIsCameraUploadsEnabled:NO];
                                      [[NSNotificationCenter defaultCenter] postNotificationName:@"kUserDeniedPhotoAccess" object:nil];
                                      MEGALogError(@"Enumerate groups with types failed with error: %@", error);
                                  }];
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
        badgeValue = [NSString stringWithFormat:@"%lu", (unsigned long)[self.assetsOperationQueue operationCount]];
    }
    
    dispatch_async(dispatch_get_main_queue(), ^{
        if ((cameraUploadsTabPosition >= 4) && ([[UIDevice currentDevice] userInterfaceIdiom] == UIUserInterfaceIdiomPhone)) {
            [[[self.tabBarController moreNavigationController] tabBarItem] setBadgeValue:badgeValue];
        }
        [[self.tabBarController.viewControllers objectAtIndex:cameraUploadsTabPosition] tabBarItem].badgeValue = badgeValue;
    });
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
            
        default:
            break;
    }
}

#pragma mark - MEGATransferDelegate

- (void)onTransferFinish:(MEGASdk *)api transfer:(MEGATransfer *)transfer error:(MEGAError *)error {
    if ([error type]) {
        if ([error type] == MEGAErrorTypeApiEArgs) {
            [self resetOperationQueue];
        }
        return;
    }
}

@end
