
#import "BackgroundRefreshPerformer.h"
#import "CameraUploadManager.h"
#import "CameraUploadManager+Settings.h"
#import "CameraScanner.h"
#import "CameraUploadRecordManager.h"

static const NSTimeInterval BackgroundRefreshDuration = 25;

@interface BackgroundRefreshPerformer ()

@property (strong, nonatomic) dispatch_block_t monitorWorkItem;

@end

@implementation BackgroundRefreshPerformer

#pragma mark - background refresh

- (void)performBackgroundRefreshWithCompletionHandler:(void (^)(UIBackgroundFetchResult))completion {
    if (!CameraUploadManager.isCameraUploadEnabled) {
        [CameraUploadManager disableBackgroundRefresh];
        completion(UIBackgroundFetchResultNoData);
        return;
    }
    
    CameraScanner *cameraScanner = [[CameraScanner alloc] init];
    [cameraScanner scanMediaTypes:CameraUploadManager.enabledMediaTypes completion:^(NSError * _Nullable error) {
        if (error) {
            completion(UIBackgroundFetchResultFailed);
            return;
        }
        
        NSError *fetchPendingCountError;
        NSUInteger pendingCount = [CameraUploadRecordManager.shared pendingRecordsCountByMediaTypes:CameraUploadManager.enabledMediaTypes error:&fetchPendingCountError];
        if (fetchPendingCountError) {
            completion(UIBackgroundFetchResultFailed);
            return;
        }
        
        if (pendingCount == 0) {
            completion(UIBackgroundFetchResultNoData);
            return;
        }
        
        [self startCameraUploadWithBackgroundRefreshCompletionHandler:completion];
    }];
}

#pragma mark - background refresh for camera upload

- (void)startCameraUploadWithBackgroundRefreshCompletionHandler:(void (^)(UIBackgroundFetchResult))completion {
    MEGALogDebug(@"[Camera Upload] upload camera in background refresh");
    [NSNotificationCenter.defaultCenter removeObserver:self name:MEGACameraUploadAllAssetsFinishedProcessingNotification object:nil];
    [NSNotificationCenter.defaultCenter addObserver:self selector:@selector(didReceiveCameraUploadAllAssetsFinishedProcessingNotification) name:MEGACameraUploadAllAssetsFinishedProcessingNotification object:nil];
    
    [CameraUploadManager.shared startCameraUploadIfNeeded];
    
    [self monitorBackgroundRefreshWithCompletionHandler:completion];
}

#pragma mark - timer management

- (void)monitorBackgroundRefreshWithCompletionHandler:(void (^)(UIBackgroundFetchResult))completion {
    __weak typeof(self) weakSelf = self;
    self.monitorWorkItem = dispatch_block_create(DISPATCH_BLOCK_INHERIT_QOS_CLASS, ^{
        if (weakSelf) {
            [NSNotificationCenter.defaultCenter removeObserver:weakSelf name:MEGACameraUploadAllAssetsFinishedProcessingNotification object:nil];
        }
        
        completion(UIBackgroundFetchResultNewData);
    });
    
    if (self.monitorWorkItem) {
        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(BackgroundRefreshDuration * NSEC_PER_SEC)),
                       dispatch_get_global_queue(QOS_CLASS_UTILITY, 0),
                       self.monitorWorkItem);
    }
}

#pragma mark - notifications

- (void)didReceiveCameraUploadAllAssetsFinishedProcessingNotification {
    if (self.monitorWorkItem) {
        dispatch_block_cancel(self.monitorWorkItem);
    }
}

@end
