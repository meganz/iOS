
#import "CameraUploadBackgroundRefreshPerformer.h"
#import "CameraUploadManager.h"
#import "CameraUploadManager+Settings.h"
#import "CameraScanner.h"
#import "CameraUploadRecordManager.h"

@interface CameraUploadBackgroundRefreshPerformer ()

@property (nonatomic, strong) BGAppRefreshTask *refreshTask;

@end

@implementation CameraUploadBackgroundRefreshPerformer

#pragma mark - background refresh

- (void)performBackgroundRefreshWithTask:(BGAppRefreshTask *)task {
    self.refreshTask = task;
    __weak typeof(self) weakself = self;
    
    [task setExpirationHandler:^{
        [weakself setTaskCompletedWithSuccess:NO];
    }];
    
    CameraScanner *cameraScanner = [[CameraScanner alloc] init];
    [cameraScanner scanMediaTypes:CameraUploadManager.enabledMediaTypes completion:^(NSError * _Nullable error) {
        if (error) {
            [weakself setTaskCompletedWithSuccess:NO];
            return;
        }
        
        NSError *fetchPendingCountError;
        NSUInteger pendingCount = [CameraUploadRecordManager.shared pendingRecordsCountByMediaTypes:CameraUploadManager.enabledMediaTypes error:&fetchPendingCountError];
        if (fetchPendingCountError) {
            [weakself setTaskCompletedWithSuccess:NO];
            return;
        }
        
        if (pendingCount == 0) {
            [weakself setTaskCompletedWithSuccess:YES];
            return;
        }
        
        [weakself startCameraUploadIfNeeded];
    }];
}

#pragma mark - background refresh for camera upload

- (void)startCameraUploadIfNeeded {
    MEGALogDebug(@"[Camera Upload] upload camera in background refresh");
    [NSNotificationCenter.defaultCenter removeObserver:self name:MEGACameraUploadAllAssetsFinishedProcessingNotification object:nil];
    [NSNotificationCenter.defaultCenter addObserver:self selector:@selector(didReceiveCameraUploadAllAssetsFinishedProcessingNotification) name:MEGACameraUploadAllAssetsFinishedProcessingNotification object:nil];
    
    [CameraUploadManager.shared startCameraUploadIfNeeded];    
}

#pragma mark - notifications

- (void)didReceiveCameraUploadAllAssetsFinishedProcessingNotification {
    [self setTaskCompletedWithSuccess:YES];
}

#pragma mark - private methods

- (void)setTaskCompletedWithSuccess:(BOOL)success {
    [self.refreshTask setTaskCompletedWithSuccess:success];
    self.refreshTask = nil;
}

@end
