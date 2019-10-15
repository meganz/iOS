
#import "BackgroundRefreshPerformer.h"
#import "CameraUploadManager.h"
#import "CameraUploadManager+Settings.h"
#import "CameraScanner.h"
#import "CameraUploadRecordManager.h"

static const NSTimeInterval BackgroundRefreshMaximumDuration = 25;
static const NSTimeInterval BackgroundRefreshDurationTolerance = 2;

@interface BackgroundRefreshPerformer ()

@property (strong, nonatomic) dispatch_source_t monitorTimer;
@property (strong, nonatomic) dispatch_queue_t notificationProcessingSerialQueue;

@end

@implementation BackgroundRefreshPerformer

- (instancetype)init {
    self = [super init];
    if (self) {
        _notificationProcessingSerialQueue = dispatch_queue_create("nz.mega.backgroundRefresh.notificationProcessingSerialQueue", DISPATCH_QUEUE_SERIAL);
    }
    
    return self;
}

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
    
    [self setupMonitorTimerWithBackgroundRefreshCompletionHandler:completion];
}

#pragma mark - background refresh monitor timer

- (void)setupMonitorTimerWithBackgroundRefreshCompletionHandler:(void (^)(UIBackgroundFetchResult))completion {
    self.monitorTimer = dispatch_source_create(DISPATCH_SOURCE_TYPE_TIMER, 0, 0, dispatch_get_global_queue(QOS_CLASS_UTILITY, 0));
    dispatch_source_set_timer(self.monitorTimer, dispatch_time(DISPATCH_TIME_NOW, (uint64_t)(BackgroundRefreshMaximumDuration * NSEC_PER_SEC)), (uint64_t)(BackgroundRefreshMaximumDuration * NSEC_PER_SEC), (uint64_t)(BackgroundRefreshDurationTolerance * NSEC_PER_SEC));
    dispatch_source_set_event_handler(self.monitorTimer, ^{
        [self cancelMonitorTimerIfNeeded];
    });
    
    dispatch_source_set_cancel_handler(self.monitorTimer, ^{
        [NSNotificationCenter.defaultCenter removeObserver:self name:MEGACameraUploadAllAssetsFinishedProcessingNotification object:nil];
        completion(UIBackgroundFetchResultNewData);
    });
    
    dispatch_resume(self.monitorTimer);
}

- (void)cancelMonitorTimerIfNeeded {
    if (self.monitorTimer && dispatch_testcancel(self.monitorTimer) == 0) {
        dispatch_source_cancel(self.monitorTimer);
    }
}

#pragma mark - notifications

- (void)didReceiveCameraUploadAllAssetsFinishedProcessingNotification {
    dispatch_async(self.notificationProcessingSerialQueue, ^{
        [self cancelMonitorTimerIfNeeded];
    });
}

@end
