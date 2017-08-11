#import "CameraUploads.h"

#import <Photos/Photos.h>
#import "MEGAAssetOperation.h"

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
    
    self.assetsOperationQueue = [[NSOperationQueue alloc] init];
    self.assetsOperationQueue.qualityOfService = NSOperationQualityOfServiceUtility;
    self.assetsOperationQueue.maxConcurrentOperationCount = 1;
}

- (void)resetOperationQueue {
    [self.assetsOperationQueue cancelAllOperations];
    
    self.assetsOperationQueue = [[NSOperationQueue alloc] init];
    self.assetsOperationQueue.qualityOfService = NSOperationQualityOfServiceUtility;
    self.assetsOperationQueue.maxConcurrentOperationCount = 1;
    
    [self setBadgeValue:nil];
    
    if (_isCameraUploadsEnabled) {
        if (_isUseCellularConnectionEnabled || [MEGAReachabilityManager isReachableViaWiFi]) {
            MEGALogInfo(@"Enable Camera Uploads");
            [self setIsCameraUploadsEnabled:YES];
        }
    }
}

- (void)setIsCameraUploadsEnabled:(BOOL)isCameraUploadsEnabled {
    _isCameraUploadsEnabled = isCameraUploadsEnabled;
    
    if (isCameraUploadsEnabled) {
        if (self.shouldCameraUploadsBeDelayed) {
            return;
        }
        
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
        [self resetOperationQueue];
        
        _isCameraUploadsEnabled = NO;
        self.isUploadVideosEnabled = NO;
        self.isUseCellularConnectionEnabled = NO;
        self.isOnlyWhenChargingEnabled = NO;
        self.shouldCameraUploadsBeDelayed = NO;
        
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
    
    MEGALogInfo(@"Assets in the operation queue %ld", _assetsOperationQueue.operationCount);
    
    [self setBadgeValue:[NSString stringWithFormat:@"%ld", [self.assetsOperationQueue operationCount]]];
}

#pragma mark - Utils

- (void)setBadgeValue:(NSString *)value {
    if (![value boolValue]) {
        value = nil;
    }
    
    dispatch_async(dispatch_get_main_queue(), ^{
        NSInteger cameraUploadsTabPosition = 1;
        UIViewController *cameraUploadsVC = [self.tabBarController.viewControllers objectAtIndex:cameraUploadsTabPosition];
        cameraUploadsVC.tabBarItem.badgeValue = [NSString stringWithFormat:@"%ld", self.assetsOperationQueue.operationCount];
    });
}


#pragma mark - UIAlertViewDelegate

- (void)alertView:(UIAlertView *)alertView clickedButtonAtIndex:(NSInteger)buttonIndex {
    if ([[(UINavigationController *)[(UITabBarController *)[[[[UIApplication sharedApplication] delegate] window] rootViewController] selectedViewController] visibleViewController] isKindOfClass:[CameraUploadsTableViewController class]]) {
        dispatch_async(dispatch_get_main_queue(), ^{
            [[(UINavigationController *)[(UITabBarController *)[[[[UIApplication sharedApplication] delegate] window] rootViewController] selectedViewController] visibleViewController] viewWillAppear:YES];
        });
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
