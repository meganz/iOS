
#import "CameraUploadManager.h"
#import "CameraUploadRecordManager.h"
#import "CameraScanner.h"
#import "Helper.h"
#import "MEGASdkManager.h"
#import "UploadOperationFactory.h"
#import "AttributeUploadManager.h"
#import "MEGAConstants.h"
#import "CameraUploadManager+Settings.h"
#import "UploadRecordsCollator.h"
#import "BackgroundUploadMonitor.h"
#import "TransferSessionManager.h"
#import "NSFileManager+MNZCategory.h"
#import "NSURL+CameraUpload.h"
#import "MediaInfoLoader.h"
#import "DiskSpaceDetector.h"
#import "MEGAReachabilityManager.h"
#import "CameraUploadNodeLoader.h"
#import "VideoUploadOperation.h"
#import "LivePhotoUploadOperation.h"
#import "PhotoUploadOperation.h"
#import "CameraUploadConcurrentCountCalculator.h"
#import "BackgroundUploadingTaskMonitor.h"
#import "NSError+CameraUpload.h"
#import "CameraUploadStore.h"

static const NSTimeInterval MinimumBackgroundRefreshInterval = 1.5 * 3600;
static const NSTimeInterval BackgroundRefreshDuration = 25;
static const NSTimeInterval LoadMediaInfoTimeoutInSeconds = 120;

static const NSUInteger PhotoUploadBatchCount = 5;
static const NSUInteger VideoUploadBatchCount = 1;

static const NSUInteger MaximumPhotoUploadBatchCountMultiplier = 2;

@interface CameraUploadManager () <CameraScannerDelegate>

@property (copy, nonatomic) void (^backgroundRefreshCompletion)(UIBackgroundFetchResult);
@property (readonly) NSArray<NSNumber *> *enabledMediaTypes;
@property (nonatomic) BOOL isNodeTreeCurrent;
@property (nonatomic) StorageState storageState;

@property (strong, nonatomic) NSOperationQueue *photoUploadOperationQueue;
@property (strong, nonatomic) NSOperationQueue *videoUploadOperationQueue;

@property (readonly) BOOL isPhotoUploadQueueSuspended;
@property (readonly) BOOL isVideoUploadQueueSuspended;
    
@property (strong, readwrite, nonatomic) MEGANode *cameraUploadNode;

@property (strong, nonatomic) CameraScanner *cameraScanner;
@property (strong, nonatomic) UploadRecordsCollator *uploadRecordsCollator;
@property (strong, nonatomic) BackgroundUploadMonitor *backgroundUploadMonitor;
@property (strong, nonatomic) MediaInfoLoader *mediaInfoLoader;
@property (strong, nonatomic) DiskSpaceDetector *diskSpaceDetector;
@property (strong, nonatomic) CameraUploadNodeLoader *cameraUploadNodeLoader;
@property (strong, nonatomic) CameraUploadConcurrentCountCalculator *concurrentCountCalculator;\
@property (strong, nonatomic) BackgroundUploadingTaskMonitor *backgroundUploadingTaskMonitor;

@end

@implementation CameraUploadManager

#pragma mark - initilization

+ (instancetype)shared {
    static id sharedInstance = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        sharedInstance = [[self alloc] init];
    });
    
    return sharedInstance;
}

- (instancetype)init {
    self = [super init];
    if (self) {
        [self registerGlobalNotifications];
        
        if (CameraUploadManager.isCameraUploadEnabled) {
            [self initializeCameraUploadQueues];
            [self registerNotificationsForUpload];
        }
    }
    return self;
}

- (void)registerGlobalNotifications {
    [NSNotificationCenter.defaultCenter addObserver:self selector:@selector(didReceiveLogoutNotification:) name:MEGALogoutNotificationName object:nil];
    [NSNotificationCenter.defaultCenter addObserver:self selector:@selector(didReceiveNodesCurrentNotification:) name:MEGANodesCurrentNotificationName object:nil];
}

#pragma mark - setup when app launches

- (void)setupCameraUploadWhenApplicationLaunches:(UIApplication *)application {
    [AttributeUploadManager.shared collateLocalAttributes];
    [TransferSessionManager.shared restoreAllSessionsWithCompletion:^(NSArray<NSURLSessionUploadTask *> * _Nonnull uploadTasks) {
        [self.uploadRecordsCollator collateUploadingRecordsByPendingTasks:uploadTasks];
    }];
    
    [CameraUploadManager disableCameraUploadIfAccessProhibited];
    
    dispatch_async(dispatch_get_global_queue(QOS_CLASS_UTILITY, 0), ^{
        [CameraUploadManager enableBackgroundRefreshIfNeeded];
        [self startBackgroundUploadIfPossible];
        [self.uploadRecordsCollator collateNonUploadingRecords];
        [AttributeUploadManager.shared scanLocalAttributeFilesAndRetryUploadIfNeeded];
    });
}

#pragma mark - manage operation queues

- (void)initializeCameraUploadQueues {
    _photoUploadOperationQueue = [[NSOperationQueue alloc] init];
    _photoUploadOperationQueue.name = @"photoUploadOperationQueue";
    _photoUploadOperationQueue.qualityOfService = NSQualityOfServiceUtility;
    _photoUploadOperationQueue.maxConcurrentOperationCount = [self.concurrentCountCalculator calculatePhotoUploadConcurrentCount];
    
    _videoUploadOperationQueue = [[NSOperationQueue alloc] init];
    _videoUploadOperationQueue.name = @"videoUploadOperationQueue";
    _videoUploadOperationQueue.qualityOfService = NSQualityOfServiceBackground;
    _videoUploadOperationQueue.maxConcurrentOperationCount = [self.concurrentCountCalculator calculateVideoUploadConcurrentCount];
}

- (void)resetCameraUploadQueues {
    [self cancelAllPendingOperations];
    self.photoUploadOperationQueue = nil;
    self.videoUploadOperationQueue = nil;
}

- (void)cancelVideoUploadOperations {
    for (NSOperation *operation in self.videoUploadOperationQueue.operations) {
        if ([operation isKindOfClass:[VideoUploadOperation class]]) {
            [operation cancel];
        }
    }
}

- (void)cancelAllPendingOperations {
    [self.photoUploadOperationQueue cancelAllOperations];
    [self.videoUploadOperationQueue cancelAllOperations];
}

#pragma mark - register and unregister notifications

- (void)registerNotificationsForUpload {
    [NSNotificationCenter.defaultCenter addObserver:self selector:@selector(didReceiveMemoryWarningNotification) name:UIApplicationDidReceiveMemoryWarningNotification object:nil];
    [NSNotificationCenter.defaultCenter addObserver:self selector:@selector(didReceiveApplicationWillTerminateNotification) name:UIApplicationWillTerminateNotification object:nil];
    
    [NSNotificationCenter.defaultCenter addObserver:self selector:@selector(didReceivePhotoConcurrentCountChangedNotification:) name:MEGACameraUploadPhotoConcurrentCountChangedNotificationName object:nil];
    [NSNotificationCenter.defaultCenter addObserver:self selector:@selector(didReceiveVideoConcurrentCountChangedNotification:) name:MEGACameraUploadVideoConcurrentCountChangedNotificationName object:nil];
    [NSNotificationCenter.defaultCenter addObserver:self selector:@selector(didReceiveReachabilityChangedNotification:) name:kReachabilityChangedNotification object:nil];
    [NSNotificationCenter.defaultCenter addObserver:self selector:@selector(didReceiveStorageOverQuotaNotification:) name:MEGAStorageOverQuotaNotificationName object:nil];
    [NSNotificationCenter.defaultCenter addObserver:self selector:@selector(didReceiveStorageEventChangedNotification:) name:MEGAStorageEventDidChangeNotificationName object:nil];
    [NSNotificationCenter.defaultCenter addObserver:self selector:@selector(didReceiveUploadingTaskCountChangedNotification:) name:MEGACameraUploadUploadingTasksCountChangedNotificationName object:nil];
    [NSNotificationCenter.defaultCenter addObserver:self selector:@selector(didReceiveBackgroundTaskExpiredNotification:) name:MEGACameraUploadTaskExpiredNotificationName object:nil];
    [NSNotificationCenter.defaultCenter addObserver:self selector:@selector(didReceiveQueueUpNextAssetNotification:) name:MEGACameraUploadQueueUpNextAssetNotificationName object:nil];
}

- (void)unregisterNotificationsForUpload {
    [NSNotificationCenter.defaultCenter removeObserver:self name:UIApplicationDidReceiveMemoryWarningNotification object:nil];
    [NSNotificationCenter.defaultCenter removeObserver:self name:UIApplicationWillTerminateNotification object:nil];
    
    [NSNotificationCenter.defaultCenter removeObserver:self name:MEGACameraUploadPhotoConcurrentCountChangedNotificationName object:nil];
    [NSNotificationCenter.defaultCenter removeObserver:self name:MEGACameraUploadVideoConcurrentCountChangedNotificationName object:nil];
    [NSNotificationCenter.defaultCenter removeObserver:self name:kReachabilityChangedNotification object:nil];
    [NSNotificationCenter.defaultCenter removeObserver:self name:MEGAStorageOverQuotaNotificationName object:nil];
    [NSNotificationCenter.defaultCenter removeObserver:self name:MEGAStorageEventDidChangeNotificationName object:nil];
    [NSNotificationCenter.defaultCenter removeObserver:self name:MEGACameraUploadUploadingTasksCountChangedNotificationName object:nil];
    [NSNotificationCenter.defaultCenter removeObserver:self name:MEGACameraUploadTaskExpiredNotificationName object:nil];
    [NSNotificationCenter.defaultCenter removeObserver:self name:MEGACameraUploadQueueUpNextAssetNotificationName object:nil];
}

#pragma mark - properties

- (CameraUploadNodeLoader *)cameraUploadNodeLoader {
    if (_cameraUploadNodeLoader == nil) {
        _cameraUploadNodeLoader = [[CameraUploadNodeLoader alloc] init];
    }
    
    return _cameraUploadNodeLoader;
}

- (UploadRecordsCollator *)uploadRecordsCollator {
    if (_uploadRecordsCollator == nil) {
        _uploadRecordsCollator = [[UploadRecordsCollator alloc] init];
    }
    
    return _uploadRecordsCollator;
}

- (BackgroundUploadMonitor *)backgroundUploadMonitor {
    if (_backgroundUploadMonitor == nil) {
        _backgroundUploadMonitor = [[BackgroundUploadMonitor alloc] init];
    }
    
    return _backgroundUploadMonitor;
}

- (CameraScanner *)cameraScanner {
    if (_cameraScanner == nil) {
        _cameraScanner = [[CameraScanner alloc] initWithDelegate:self];
    }
    
    return _cameraScanner;
}

- (MediaInfoLoader *)mediaInfoLoader {
    if (_mediaInfoLoader == nil) {
        _mediaInfoLoader = [[MediaInfoLoader alloc] init];
    }
    
    return _mediaInfoLoader;
}

- (DiskSpaceDetector *)diskSpaceDetector {
    if (_diskSpaceDetector == nil) {
        _diskSpaceDetector = [[DiskSpaceDetector alloc] init];
    }
    
    return _diskSpaceDetector;
}

- (CameraUploadConcurrentCountCalculator *)concurrentCountCalculator {
    if (_concurrentCountCalculator == nil) {
        _concurrentCountCalculator = [[CameraUploadConcurrentCountCalculator alloc] init];
    }
    
    return _concurrentCountCalculator;
}

- (BackgroundUploadingTaskMonitor *)backgroundUploadingTaskMonitor {
    if (_backgroundUploadingTaskMonitor == nil) {
        _backgroundUploadingTaskMonitor = [[BackgroundUploadingTaskMonitor alloc] init];
    }
    
    return _backgroundUploadingTaskMonitor;
}

- (void)setPausePhotoUpload:(BOOL)pausePhotoUpload {
    if (_pausePhotoUpload != pausePhotoUpload) {
        _pausePhotoUpload = pausePhotoUpload;
        if (!pausePhotoUpload) {
            MEGALogDebug(@"[Camera Upload] resume camera upload");
            [self startCameraUploadIfNeeded];
        }
    }
}

- (void)setPauseVideoUpload:(BOOL)pauseVideoUpload {
    if (_pauseVideoUpload != pauseVideoUpload) {
        _pauseVideoUpload = pauseVideoUpload;
        if (!pauseVideoUpload) {
            MEGALogDebug(@"[Camera Upload] resume video upload");
            [self startVideoUploadIfNeeded];
        }
    }
}

#pragma mark - camera scanner delegate

- (void)cameraScanner:(CameraScanner *)scanner didObserveNewAssets:(NSArray<PHAsset *> *)assets {
    MEGALogDebug(@"[Camera Upload] did scan new assets count %lu", (unsigned long)assets.count);
    [self startCameraUploadWithRequestingMediaInfo];
}

#pragma mark - start upload

- (void)startCameraUploadIfNeeded {
    MEGALogDebug(@"[Camera Upload] start camera upload if needed");
    
    if (!MEGASdkManager.sharedMEGASdk.isLoggedIn || !CameraUploadManager.isCameraUploadEnabled) {
        return;
    }
    
    [self.cameraScanner scanMediaTypes:self.enabledMediaTypes completion:^(NSError * _Nullable error) {
        if (error) {
            MEGALogError(@"[Camera Upload] error when to scan image %@", error);
            dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(1 * NSEC_PER_SEC)), dispatch_get_global_queue(QOS_CLASS_USER_INITIATED, 0), ^{
                [self startCameraUploadIfNeeded];
            });
        } else {
            [self.cameraScanner observePhotoLibraryChanges];
            [self startCameraUploadWithRequestingMediaInfo];
        }
    }];
    
    [MEGASdkManager.sharedMEGASdk retryPendingConnections];
    
    [AttributeUploadManager.shared scanLocalAttributeFilesAndRetryUploadIfNeeded];
}

- (void)startCameraUploadWithRequestingMediaInfo {
    MEGALogDebug(@"[Camera Upload] request media info for upload");
    
    if (!MEGASdkManager.sharedMEGASdk.isLoggedIn || !CameraUploadManager.isCameraUploadEnabled) {
        return;
    }
    
    if (self.mediaInfoLoader.isMediaInfoLoaded) {
        [self loadCameraUploadNodeForUpload];
    } else {
        [self.mediaInfoLoader loadMediaInfoWithTimeout:LoadMediaInfoTimeoutInSeconds completion:^(BOOL loaded) {
            if (loaded) {
                [self loadCameraUploadNodeForUpload];
            } else {
                MEGALogError(@"[Camera Upload] retry to start camera upload due to failed to load media into");
                dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(.7 * NSEC_PER_SEC)), dispatch_get_global_queue(QOS_CLASS_USER_INITIATED, 0), ^{
                    [self startCameraUploadWithRequestingMediaInfo];
                });
            }
        }];
    }
}

- (void)loadCameraUploadNodeForUpload {
    MEGALogDebug(@"[Camera Upload] load camera upload node");
    if (!self.isNodeTreeCurrent) {
        return;
    }
    
    [self.cameraUploadNodeLoader loadCameraUploadNodeWithCompletion:^(MEGANode * _Nullable cameraUploadNode) {
        if (cameraUploadNode != self.cameraUploadNode) {
            self.cameraUploadNode = cameraUploadNode;
        }
        
        if (cameraUploadNode) {
            [self uploadCameraWhenCameraUploadNodeIsLoaded];
        } else {
            MEGALogError(@"[Camera Upload] camera upload node can not be loaded");
            dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(.5 * NSEC_PER_SEC)), dispatch_get_global_queue(QOS_CLASS_USER_INITIATED, 0), ^{
                [self startCameraUploadIfNeeded];
            });
        }
    }];
}

- (void)uploadCameraWhenCameraUploadNodeIsLoaded {
    if (!CameraUploadManager.canCameraUploadBeStarted) {
        return;
    }
    
    [self startVideoUploadIfNeeded];
    
    if (self.isPhotoUploadPaused) {
        MEGALogInfo(@"[Camera Upload] photo upload is paused");
        return;
    }
    
    if (self.isPhotoUploadQueueSuspended) {
        MEGALogInfo(@"[Camera Upload] photo upload queue is suspended");
        return;
    }
    
    [self.diskSpaceDetector startDetectingPhotoUpload];
    [self.concurrentCountCalculator startCalculatingConcurrentCount];
    [self.backgroundUploadingTaskMonitor startMonitoringBackgroundUploadingTasks];
    
    MEGALogDebug(@"[Camera Upload] start uploading photos with current photo operation count %lu", (unsigned long)self.photoUploadOperationQueue.operationCount);
    if (self.photoUploadOperationQueue.operationCount < PhotoUploadBatchCount * MaximumPhotoUploadBatchCountMultiplier) {
        [self uploadAssetsForMediaType:PHAssetMediaTypeImage concurrentCount:PhotoUploadBatchCount];
    }
}

- (void)startVideoUploadIfNeeded {
    MEGALogDebug(@"[Camera Upload] start video upload if needed");
    if (!(CameraUploadManager.isCameraUploadEnabled && CameraUploadManager.isVideoUploadEnabled)) {
        MEGALogDebug(@"[Camera Upload] video upload is not enabled");
        return;
    }
    
    if (!CameraUploadManager.canCameraUploadBeStarted) {
        return;
    }
    
    if (!(self.mediaInfoLoader.isMediaInfoLoaded && self.isNodeTreeCurrent && self.cameraUploadNode != nil)) {
        MEGALogDebug(@"[Camera Upload] can not upload videos due to the dependency on media info and camera uplaod node issues");
        return;
    }
    
    if (self.isVideoUploadPaused) {
        MEGALogInfo(@"[Camera Upload] video upload is paused");
        return;
    }
    
    if (self.isVideoUploadQueueSuspended) {
        MEGALogInfo(@"[Camera Upload] video upload queue is suspended");
        return;
    }
    
    [self.diskSpaceDetector startDetectingVideoUpload];
    
    MEGALogDebug(@"[Camera Upload] start uploading videos with current video operation count %lu", (unsigned long)self.videoUploadOperationQueue.operationCount);
    [self uploadAssetsForMediaType:PHAssetMediaTypeVideo concurrentCount:VideoUploadBatchCount];
}

- (void)scanAndStartVideoUpload {
    MEGALogDebug(@"[Camera Upload] scan and start video upload if needed");
    
    if (!(CameraUploadManager.isCameraUploadEnabled && CameraUploadManager.isVideoUploadEnabled)) {
        return;
    }
    
    [self.cameraScanner scanMediaTypes:@[@(PHAssetMediaTypeVideo)] completion:^(NSError * _Nullable error) {
        if (error) {
            MEGALogError(@"[Camera Upload] error when to scan video %@", error);
            dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(1 * NSEC_PER_SEC)), dispatch_get_global_queue(QOS_CLASS_USER_INITIATED, 0), ^{
                [self scanAndStartVideoUpload];
            });
        } else {
            [self startVideoUploadIfNeeded];
            dispatch_async(dispatch_get_main_queue(), ^{
                [NSNotificationCenter.defaultCenter postNotificationName:MEGACameraUploadStatsChangedNotificationName object:nil];
            });
        }
    }];
}

#pragma mark - upload next assets

- (void)uploadNextAssetForMediaType:(PHAssetMediaType)mediaType {
    if (!CameraUploadManager.isCameraUploadEnabled) {
        return;
    }
    
    switch (mediaType) {
        case PHAssetMediaTypeImage:
            if (self.isPhotoUploadPaused || self.isPhotoUploadQueueSuspended) {
                MEGALogInfo(@"[Camera Upload] photo upload is paused or queue is suspended");
                return;
            }
            break;
        case PHAssetMediaTypeVideo:
            if (!CameraUploadManager.isVideoUploadEnabled) {
                return;
            } else if (self.isVideoUploadPaused || self.isVideoUploadQueueSuspended) {
                MEGALogInfo(@"[Camera Upload] video upload is paused or queue is suspended");
                return;
            }
            break;
        default:
            break;
    }
    
    [self uploadAssetsForMediaType:mediaType concurrentCount:1];
}

- (void)uploadAssetsForMediaType:(PHAssetMediaType)mediaType concurrentCount:(NSUInteger)count {
    MEGALogDebug(@"[Camera Upload] photo count %lu concurrent %ld, video count %lu concurrent %ld", (unsigned long)self.photoUploadOperationQueue.operationCount, (long)self.photoUploadOperationQueue.maxConcurrentOperationCount, (unsigned long)self.videoUploadOperationQueue.operationCount, (long)self.videoUploadOperationQueue.maxConcurrentOperationCount);
    
    NSArray<NSNumber *> *statuses = AssetUploadStatus.statusesReadyToQueueUp;
    if (MEGAReachabilityManager.isReachable) {
        statuses = AssetUploadStatus.allStatusesToQueueUp;
    }
    NSArray *records = [CameraUploadRecordManager.shared queueUpUploadRecordsByStatuses:statuses fetchLimit:count mediaType:mediaType error:nil];
    if (records.count == 0) {
        MEGALogInfo(@"[Camera Upload] no more local asset to upload for media type %li", (long)mediaType);
        return;
    }
    
    for (MOAssetUploadRecord *record in records) {
        NSError *error;
        CameraUploadOperation *operation = [UploadOperationFactory operationForUploadRecord:record parentNode:self.cameraUploadNode error:&error];
        if (operation) {
            [self queueUpOperation:operation];
        } else {
            MEGALogError(@"[Camera Upload] error when to build camera upload operation %@", error);
            if (!MEGASdkManager.sharedMEGASdk.isLoggedIn) {
                return;
            }
            
            if ([error.domain isEqualToString:CameraUploadErrorDomain]) {
                if (error.code == CameraUploadErrorEmptyLocalIdentifier || error.code == CameraUploadErrorNoMediaAssetFetched) {
                    [CameraUploadRecordManager.shared deleteUploadRecord:record error:nil];
                } else {
                    [CameraUploadRecordManager.shared updateUploadRecord:record withStatus:CameraAssetUploadStatusFailed error:nil];
                }
            }
            
            [self uploadNextAssetForMediaType:mediaType];
        }
    }
}

- (void)queueUpOperation:(CameraUploadOperation *)operation {
    if ([operation isKindOfClass:[PhotoUploadOperation class]]) {
        [self queueUpIfNeededForOperation:operation inOperationQueue:self.photoUploadOperationQueue];
    } else if ([operation isKindOfClass:[LivePhotoUploadOperation class]]) {
        [self queueUpIfNeededForOperation:operation inOperationQueue:self.videoUploadOperationQueue];
        [self uploadNextAssetForMediaType:PHAssetMediaTypeImage];
    } else if ([operation isKindOfClass:[VideoUploadOperation class]]) {
        [self queueUpIfNeededForOperation:operation inOperationQueue:self.videoUploadOperationQueue];
    }
}

- (void)queueUpIfNeededForOperation:(CameraUploadOperation *)uploadOperation inOperationQueue:(NSOperationQueue *)queue {
    BOOL hasPendingOperation = NO;
    for (NSOperation *operation in queue.operations) {
        if ([operation isKindOfClass:[CameraUploadOperation class]]) {
            if (!operation.isFinished && [[(CameraUploadOperation *)operation uploadInfo].savedLocalIdentifier isEqualToString:uploadOperation.uploadInfo.savedLocalIdentifier]) {
                hasPendingOperation = YES;
                MEGALogError(@"[Camera Upload] has pending operation %@", operation);
                break;
            }
        }
    }
    
    if (!hasPendingOperation) {
        [queue addOperation:uploadOperation];
    }
}

#pragma mark - enable camera upload

- (void)enableCameraUpload {
    CameraUploadManager.cameraUploadEnabled = YES;
    [self initializeCameraUploadQueues];
    [self registerNotificationsForUpload];
    [self startCameraUploadIfNeeded];
    [self startBackgroundUploadIfPossible];
    [CameraUploadManager enableBackgroundRefreshIfNeeded];
}

- (void)enableVideoUpload {
    CameraUploadManager.videoUploadEnabled = YES;
    [self scanAndStartVideoUpload];
}

#pragma mark - disable camera upload

- (void)disableCameraUpload {
    CameraUploadManager.cameraUploadEnabled = NO;
    [self disableVideoUpload];
    [self resetCameraUploadQueues];
    [self unregisterNotificationsForUpload];
    [self.diskSpaceDetector stopDetectingPhotoUpload];
    [self.concurrentCountCalculator stopCalculatingConcurrentCount];
    [self.backgroundUploadingTaskMonitor stopMonitoringBackgroundUploadingTasks];
    _pausePhotoUpload = NO;
    _storageState = StorageStateGreen;
    [TransferSessionManager.shared invalidateAndCancelPhotoSessions];
    [self.cameraScanner unobservePhotoLibraryChanges];
    [CameraUploadManager disableBackgroundRefresh];
    [self stopBackgroundUpload];
}

- (void)disableVideoUpload {
    CameraUploadManager.videoUploadEnabled = NO;
    [self cancelVideoUploadOperations];
    [self.diskSpaceDetector stopDetectingVideoUpload];
    _pauseVideoUpload = NO;
    [TransferSessionManager.shared invalidateAndCancelVideoSessions];
}

#pragma mark - pause and resume upload

- (void)pauseCameraUploadIfNeeded {
    if (CameraUploadManager.isCameraUploadEnabled) {
        self.pausePhotoUpload = YES;
        self.pauseVideoUpload = YES;
    }
}

- (void)resumeCameraUpload {
    self.pausePhotoUpload = NO;
    self.pauseVideoUpload = NO;
}

#pragma mark - suspend and unsuspend camera upload

- (void)suspendCameraUploadQueues {
    if (!self.isPhotoUploadQueueSuspended) {
        self.photoUploadOperationQueue.suspended = YES;
    }
    
    if (!self.isPhotoUploadQueueSuspended) {
        self.videoUploadOperationQueue.suspended = YES;
    }
}

- (void)unsuspendCameraUploadQueues {
    if (self.isPhotoUploadQueueSuspended) {
        self.photoUploadOperationQueue.suspended = NO;
    }
    
    if (self.isVideoUploadQueueSuspended) {
        self.videoUploadOperationQueue.suspended = NO;
    }
}

- (BOOL)isPhotoUploadQueueSuspended {
    return self.photoUploadOperationQueue.isSuspended;
}

- (BOOL)isVideoUploadQueueSuspended {
    return self.videoUploadOperationQueue.isSuspended;
}

#pragma mark - upload status

- (NSUInteger)uploadPendingAssetsCount {
    return [CameraUploadRecordManager.shared pendingRecordsCountByMediaTypes:self.enabledMediaTypes error:nil];
}

- (BOOL)isPhotoUploadDone {
    return [CameraUploadRecordManager.shared pendingRecordsCountByMediaTypes:@[@(PHAssetMediaTypeImage)] error:nil] == 0;
}

- (BOOL)isVideoUploadDone {
    return [CameraUploadRecordManager.shared pendingRecordsCountByMediaTypes:@[@(PHAssetMediaTypeVideo)] error:nil] == 0;
}

- (NSArray<NSNumber *> *)enabledMediaTypes {
    NSMutableArray<NSNumber *> *mediaTypes = [NSMutableArray array];
    if (CameraUploadManager.isCameraUploadEnabled) {
        [mediaTypes addObject:@(PHAssetMediaTypeImage)];
        
        if (CameraUploadManager.isVideoUploadEnabled) {
            [mediaTypes addObject:@(PHAssetMediaTypeVideo)];
        }
    }
    
    return [mediaTypes copy];
}

#pragma mark - get upload stats

- (void)loadCurrentUploadStatsWithCompletion:(void (^)(UploadStats * _Nullable, NSError * _Nullable))completion {
    return [self loadUploadStatsForMediaTypes:self.enabledMediaTypes completion:completion];
}

- (void)loadUploadStatsForMediaTypes:(NSArray<NSNumber *> *)mediaTypes completion:(void (^)(UploadStats * _Nullable, NSError * _Nullable))completion {
    dispatch_async(dispatch_get_global_queue(QOS_CLASS_USER_INITIATED, 0), ^{
        NSError *error;
        NSUInteger totalCount = [CameraUploadRecordManager.shared totalRecordsCountByMediaTypes:mediaTypes includeUploadErrorRecords:NO error:&error];
        if (error) {
            completion(nil, error);
            return;
        }
        
        if (totalCount == 0) {
            [self scanAndLoadUploadStatsForMediaTypes:mediaTypes completion:completion];
        } else {
            NSUInteger finishedCount = [CameraUploadRecordManager.shared finishedRecordsCountByMediaTypes:mediaTypes error:&error];
            if (error) {
                completion(nil, error);
            } else {
                completion([[UploadStats alloc] initWithFinishedCount:finishedCount totalCount:totalCount], nil);
            }
        }
    });
}

- (void)scanAndLoadUploadStatsForMediaTypes:(NSArray<NSNumber *> *)mediaTypes completion:(void (^)(UploadStats * _Nullable, NSError * _Nullable))completion {
    [self.cameraScanner scanMediaTypes:mediaTypes completion:^(NSError * _Nullable error) {
        if (error) {
            completion(nil, error);
            return;
        }
        
        NSUInteger totalCount = [CameraUploadRecordManager.shared totalRecordsCountByMediaTypes:mediaTypes includeUploadErrorRecords:NO error:&error];
        NSUInteger finishedCount = 0;
        if (error == nil) {
            finishedCount = [CameraUploadRecordManager.shared finishedRecordsCountByMediaTypes:mediaTypes error:&error];
        }
        
        if (error) {
            completion(nil, error);
        } else {
            completion([[UploadStats alloc] initWithFinishedCount:finishedCount totalCount:totalCount], nil);
        }
    }];
}

#pragma mark - check disk storage

- (BOOL)isDiskStorageFull {
    if (!CameraUploadManager.isCameraUploadEnabled) {
        return NO;
    }
    
    BOOL isFull = self.diskSpaceDetector.isDiskFullForPhotos;
    if (CameraUploadManager.isVideoUploadEnabled) {
        isFull &= self.diskSpaceDetector.isDiskFullForVideos;
    }
    
    return isFull;
}

#pragma mark - notifications

- (void)didReceiveQueueUpNextAssetNotification:(NSNotification *)notification {
    PHAssetMediaType mediaType = [notification.userInfo[MEGAAssetMediaTypeUserInfoKey] integerValue];
    MEGALogDebug(@"[Camera Upload] did receive queue up next asset %ld", (long)mediaType);
    [self uploadNextAssetForMediaType:mediaType];
}

- (void)didReceivePhotoConcurrentCountChangedNotification:(NSNotification *)notification {
    MEGALogDebug(@"[Camera Upload] photo concurrent count changed %@", notification.userInfo);
    NSInteger photoConcurrentCount = [notification.userInfo[MEGAPhotoConcurrentCountUserInfoKey] integerValue];
    self.photoUploadOperationQueue.maxConcurrentOperationCount = photoConcurrentCount;
    if (self.photoUploadOperationQueue.operationCount < photoConcurrentCount) {
        [self startCameraUploadWithRequestingMediaInfo];
    }
}

- (void)didReceiveVideoConcurrentCountChangedNotification:(NSNotification *)notification {
    MEGALogDebug(@"[Camera Upload] video concurrent count changed %@", notification.userInfo);
    NSInteger videoConcurrentCount = [notification.userInfo[MEGAVideoConcurrentCountUserInfoKey] integerValue];
    self.videoUploadOperationQueue.maxConcurrentOperationCount = videoConcurrentCount;
    if (self.videoUploadOperationQueue.operationCount < videoConcurrentCount) {
        [self startVideoUploadIfNeeded];
    }
}

- (void)didReceiveMemoryWarningNotification {
    MEGALogDebug(@"[Camera Upload] memory warning");
    NSInteger photoConcurrentCount = MIN([self.concurrentCountCalculator calculatePhotoUploadConcurrentCount], PhotoUploadConcurrentCountInMemoryWarning);
    self.photoUploadOperationQueue.maxConcurrentOperationCount = photoConcurrentCount;
    
    NSInteger index = 0;
    for (NSOperation *operation in self.photoUploadOperationQueue.operations) {
        if (operation.isExecuting) {
            index++;
            
            if (index > photoConcurrentCount) {
                MEGALogDebug(@"[Camera Upload] release memory in cancelling %@", operation);
                [operation cancel];
            }
        }
    }
}

- (void)didReceiveApplicationWillTerminateNotification {
    MEGALogDebug(@"[Camera Upload] app will terminate");
    [self resetCameraUploadQueues];
}

- (void)didReceiveStorageOverQuotaNotification:(NSNotification *)notification {
    MEGALogDebug(@"[Camera Upload] storage over quota notification %@", notification.userInfo);
    [self pauseCameraUploadIfNeeded];
}

- (void)didReceiveStorageEventChangedNotification:(NSNotification *)notification {
    MEGALogDebug(@"[Camera Upload] storage event notification %@", notification.userInfo);
    NSUInteger state = [notification.userInfo[MEGAStorageEventStateUserInfoKey] unsignedIntegerValue];
    if (self.storageState == state) {
        return;
    }
    
    self.storageState = state;
    switch (state) {
        case StorageStateGreen:
        case StorageStateOrange:
            [self resumeCameraUpload];
            break;
        case StorageStateRed:
            [self pauseCameraUploadIfNeeded];
            break;
        default:
            break;
    }
}

- (void)didReceiveNodesCurrentNotification:(NSNotification *)notification {
    MEGALogDebug(@"[Camera Upload] nodes current notification %@", notification);
    self.isNodeTreeCurrent = YES;
    [self startCameraUploadIfNeeded];
}

- (void)didReceiveReachabilityChangedNotification:(NSNotification *)notification {
    MEGALogDebug(@"[Camera Upload] reachability changed notification %@", notification.userInfo);
    if (MEGAReachabilityManager.isReachable) {
        [self startCameraUploadIfNeeded];
    }
}

- (void)didReceiveUploadingTaskCountChangedNotification:(NSNotification *)notification {
    MEGALogDebug(@"[Camera Upload] uploading task count changed notification %@", notification.userInfo);
    BOOL hasReachedMaximumCount = [notification.userInfo[MEGAHasUploadingTasksReachedMaximumCountUserInfoKey] boolValue];
    NSUInteger currentUploadingCount = [notification.userInfo[MEGACurrentUploadingTasksCountUserInfoKey] unsignedIntegerValue];
    if (hasReachedMaximumCount) {
        MEGALogDebug(@"[Camera Upload] suspend upload queues with current uplaoding tasks count %lu", (unsigned long)currentUploadingCount);
        [self suspendCameraUploadQueues];
    } else {
        MEGALogDebug(@"[Camera Upload] unsuspend upload queues with current uplaoding tasks count %lu", (unsigned long)currentUploadingCount);
        [self unsuspendCameraUploadQueues];
    }
}

- (void)didReceiveBackgroundTaskExpiredNotification:(NSNotification *)notification {
    MEGALogDebug(@"[Camera Upload] did receive background task expired notification");
    [self cancelAllPendingOperations];
}

- (void)didReceiveLogoutNotification:(NSNotification *)notification {
    MEGALogDebug(@"[Camera Upload] logout notification %@", notification);
    [self disableCameraUpload];
    [CameraUploadManager clearLocalSettings];
    _isNodeTreeCurrent = NO;
    _cameraUploadNode = nil;
    [AttributeUploadManager.shared cancelAllAttributesUpload];
    [CameraUploadRecordManager.shared resetDataContext];
    NSError *error;
    [CameraUploadStore.shared.storeStack deleteStoreWithError:&error];
    if (error) {
        MEGALogError(@"[Camera Upload] error when to delete camera upload store after logout %@", error);
    }
    [NSFileManager.defaultManager removeItemIfExistsAtURL:NSURL.mnz_cameraUploadURL];
}

#pragma mark - photos access permission check

+ (void)disableCameraUploadIfAccessProhibited {
    switch (PHPhotoLibrary.authorizationStatus) {
        case PHAuthorizationStatusDenied:
        case PHAuthorizationStatusRestricted:
            if (CameraUploadManager.isCameraUploadEnabled) {
                [CameraUploadManager.shared disableCameraUpload];
            }
            break;
        default:
            break;
    }
}

#pragma mark - background refresh

+ (void)enableBackgroundRefreshIfNeeded {
    if (CameraUploadManager.isCameraUploadEnabled) {
        MEGALogInfo(@"[Camera Upload] enable background refresh for background upload");
        [NSOperationQueue.mainQueue addOperationWithBlock:^{
            [UIApplication.sharedApplication setMinimumBackgroundFetchInterval:MinimumBackgroundRefreshInterval];
        }];
    }
}

+ (void)disableBackgroundRefresh {
    MEGALogInfo(@"[Camera Upload] disable background refresh for background upload");
    [NSOperationQueue.mainQueue addOperationWithBlock:^{
        [UIApplication.sharedApplication setMinimumBackgroundFetchInterval:UIApplicationBackgroundFetchIntervalNever];
    }];
}

- (void)performBackgroundRefreshWithCompletion:(void (^)(UIBackgroundFetchResult))completion {
    if (CameraUploadManager.isCameraUploadEnabled) {
        [self.cameraScanner scanMediaTypes:self.enabledMediaTypes completion:^(NSError * _Nullable error) {
            if (self.uploadPendingAssetsCount == 0) {
                completion(UIBackgroundFetchResultNoData);
            } else {
                MEGALogDebug(@"[Camera Upload] upload camera in background refresh");
                [self startCameraUploadIfNeeded];
                self.backgroundRefreshCompletion = completion;
                [NSTimer scheduledTimerWithTimeInterval:BackgroundRefreshDuration target:self selector:@selector(backgroudRefreshTimerExpired:) userInfo:nil repeats:NO];
            }
        }];
    } else {
        completion(UIBackgroundFetchResultNoData);
    }
}

- (void)backgroudRefreshTimerExpired:(NSTimer *)timer {
    if (self.backgroundRefreshCompletion) {
        self.backgroundRefreshCompletion(UIBackgroundFetchResultNewData);
        if (self.uploadPendingAssetsCount == 0) {
            self.backgroundRefreshCompletion(UIBackgroundFetchResultNoData);
        }
    }
}

#pragma mark - background upload

- (void)startBackgroundUploadIfPossible {
    [self.backgroundUploadMonitor startBackgroundUploadIfPossible];
}

- (void)stopBackgroundUpload {
    [self.backgroundUploadMonitor stopBackgroundUpload];
}

@end
