
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

static const NSUInteger PhotoUploadInForegroundConcurrentCount = 10;
static const NSUInteger PhotoUploadInBackgroundConcurrentCount = 4;
static const NSUInteger PhotoUploadInMemoryWarningConcurrentCount = 2;

static const NSUInteger VideoUploadInForegroundConcurrentCount = 1;
static const NSUInteger VideoUploadInBackgroundConcurrentCount = 1;
static const NSUInteger VideoUploadInMemoryWarningConcurrentCount = 1;

static const NSTimeInterval MinimumBackgroundRefreshInterval = 3600;
static const NSTimeInterval BackgroundRefreshDuration = 25;
static const NSTimeInterval LoadMediaInfoTimeoutInSeconds = 120;

@interface CameraUploadManager ()

@property (nonatomic) BOOL isNodesFetchDone;
@property (nonatomic) StorageState storageState;
@property (strong, nonatomic) NSOperationQueue *photoUploadOperationQueue;
@property (strong, nonatomic) NSOperationQueue *videoUploadOperationQueue;
@property (strong, readwrite, nonatomic) MEGANode *cameraUploadNode;
@property (strong, nonatomic) CameraScanner *cameraScanner;
@property (strong, nonatomic) UploadRecordsCollator *dataCollator;
@property (strong, nonatomic) BackgroundUploadMonitor *backgroundUploadMonitor;
@property (strong, nonatomic) MediaInfoLoader *mediaInfoLoader;
@property (strong, nonatomic) DiskSpaceDetector *diskSpaceDetector;
@property (strong, nonatomic) CameraUploadNodeLoader *cameraUploadNodeLoader;
@property (readonly) NSArray<NSNumber *> *enabledMediaTypes;

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
    [NSNotificationCenter.defaultCenter addObserver:self selector:@selector(didReceiveNodesFetchDoneNotification:) name:MEGANodesFetchDoneNotificationName object:nil];
}

#pragma mark - application lifecycle

- (void)setupCameraUploadWhenApplicationLaunches:(UIApplication *)application {
    [CameraUploadManager disableCameraUploadIfAccessProhibited];
    [CameraUploadManager enableBackgroundRefreshIfNeeded];
    [self startBackgroundUploadIfPossible];
    
    dispatch_async(dispatch_get_global_queue(QOS_CLASS_UTILITY, 0), ^{
        [AttributeUploadManager.shared scanLocalAttributeFilesAndRetryUploadIfNeeded];
        [TransferSessionManager.shared restoreAllSessions];
        [self collateUploadRecords];
        
        MEGALogDebug(@"[Camera Upload] app launches to state %@", @(application.applicationState));
        if (application.applicationState == UIApplicationStateBackground) {
            MEGALogDebug(@"[Camera Upload] upload camera when app launches to background");
            [CameraUploadManager.shared startCameraUploadIfNeeded];
        }
    });
}

- (void)startCameraUploadWhenApplicationResumesFromBackgroundTransfer {
    [self startCameraUploadIfNeeded];
    [AttributeUploadManager.shared scanLocalAttributeFilesAndRetryUploadIfNeeded];
}

#pragma mark - manage operation queues

- (void)initializeCameraUploadQueues {
    _photoUploadOperationQueue = [[NSOperationQueue alloc] init];
    _photoUploadOperationQueue.qualityOfService = NSQualityOfServiceUtility;
    
    _videoUploadOperationQueue = [[NSOperationQueue alloc] init];
    _videoUploadOperationQueue.qualityOfService = NSQualityOfServiceBackground;
    
    if (UIApplication.sharedApplication.applicationState == UIApplicationStateBackground) {
        _photoUploadOperationQueue.maxConcurrentOperationCount = PhotoUploadInBackgroundConcurrentCount;
        _videoUploadOperationQueue.maxConcurrentOperationCount = VideoUploadInBackgroundConcurrentCount;
    } else {
        _photoUploadOperationQueue.maxConcurrentOperationCount = PhotoUploadInForegroundConcurrentCount;
        _videoUploadOperationQueue.maxConcurrentOperationCount = VideoUploadInForegroundConcurrentCount;
    }
}

- (void)resetCameraUploadQueues {
    [self.photoUploadOperationQueue cancelAllOperations];
    [self.videoUploadOperationQueue cancelAllOperations];
    self.photoUploadOperationQueue = nil;
    self.videoUploadOperationQueue = nil;
}

- (void)cancelVideoUploadOperations {
    for (NSOperation *operation in self.videoUploadOperationQueue.operations) {
        if ([operation isMemberOfClass:[VideoUploadOperation class]]) {
            [operation cancel];
        }
    }
}

#pragma mark - register and unregister notifications

- (void)registerNotificationsForUpload {
    [NSNotificationCenter.defaultCenter addObserver:self selector:@selector(applicationDidEnterBackground) name:UIApplicationDidEnterBackgroundNotification object:nil];
    [NSNotificationCenter.defaultCenter addObserver:self selector:@selector(applicationDidBecomeActive) name:UIApplicationDidBecomeActiveNotification object:nil];
    [NSNotificationCenter.defaultCenter addObserver:self selector:@selector(applicationDidReceiveMemoryWarning) name:UIApplicationDidReceiveMemoryWarningNotification object:nil];
    [NSNotificationCenter.defaultCenter addObserver:self selector:@selector(didReceiveReachabilityChangedNotification:) name:kReachabilityChangedNotification object:nil];
    [NSNotificationCenter.defaultCenter addObserver:self selector:@selector(didReceiveStorageOverQuotaNotification:) name:MEGAStorageOverQuotaNotificationName object:nil];
    [NSNotificationCenter.defaultCenter addObserver:self selector:@selector(didReceiveStorageEventNotification:) name:MEGAStorageEventNotificationName object:nil];
}

- (void)unregisterNotificationsForUpload {
    [NSNotificationCenter.defaultCenter removeObserver:self name:UIApplicationDidEnterBackgroundNotification object:nil];
    [NSNotificationCenter.defaultCenter removeObserver:self name:UIApplicationDidBecomeActiveNotification object:nil];
    [NSNotificationCenter.defaultCenter removeObserver:self name:UIApplicationDidReceiveMemoryWarningNotification object:nil];
    [NSNotificationCenter.defaultCenter removeObserver:self name:kReachabilityChangedNotification object:nil];
    [NSNotificationCenter.defaultCenter removeObserver:self name:MEGAStorageOverQuotaNotificationName object:nil];
    [NSNotificationCenter.defaultCenter removeObserver:self name:MEGAStorageEventNotificationName object:nil];
}

#pragma mark - properties

- (CameraUploadNodeLoader *)cameraUploadNodeLoader {
    if (_cameraUploadNodeLoader == nil) {
        _cameraUploadNodeLoader = [[CameraUploadNodeLoader alloc] init];
    }
    
    return _cameraUploadNodeLoader;
}

- (UploadRecordsCollator *)dataCollator {
    if (_dataCollator == nil) {
        _dataCollator = [[UploadRecordsCollator alloc] init];
    }
    
    return _dataCollator;
}

- (BackgroundUploadMonitor *)backgroundUploadMonitor {
    if (_backgroundUploadMonitor == nil) {
        _backgroundUploadMonitor = [[BackgroundUploadMonitor alloc] init];
    }
    
    return _backgroundUploadMonitor;
}

- (CameraScanner *)cameraScanner {
    if (_cameraScanner == nil) {
        _cameraScanner = [[CameraScanner alloc] init];
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

- (BOOL)isCameraUploadPausedByDiskFull {
    if (!CameraUploadManager.isCameraUploadEnabled) {
        return NO;
    }
    
    BOOL isFull = NO;
    if ([self isPhotoUploadDone]) {
        if (CameraUploadManager.isVideoUploadEnabled && ![self isVideoUploadDone]) {
            isFull = [self isVideoUploadPausedByDiskFull];
        }
    } else {
        isFull = [self isPhotoUploadPausedByDiskFull];
        
        if (CameraUploadManager.isVideoUploadEnabled && ![self isVideoUploadDone]) {
            isFull &= [self isVideoUploadPausedByDiskFull];
        }
    }

    return isFull;
}

- (BOOL)isPhotoUploadPausedByDiskFull {
    return self.isPhotoUploadPaused && self.diskSpaceDetector.isDiskFullForPhotos;
}

- (BOOL)isVideoUploadPausedByDiskFull {
    return self.isVideoUploadPaused && self.diskSpaceDetector.isDiskFullForVideos;
}

#pragma mark - start upload

- (void)startCameraUploadIfNeeded {
    MEGALogDebug(@"[Camera Upload] start camera upload if needed");
    if (!MEGASdkManager.sharedMEGASdk.isLoggedIn || !CameraUploadManager.isCameraUploadEnabled) {
        return;
    }

    [self.cameraScanner scanMediaTypes:@[@(PHAssetMediaTypeImage)] completion:^{
        [self.cameraScanner observePhotoLibraryChanges];
        [self requestMediaInfoForUpload];
    }];
}

- (void)requestMediaInfoForUpload {
    MEGALogDebug(@"[Camera Upload] request media info for upload");
    if (self.mediaInfoLoader.isMediaInfoLoaded) {
        [self loadCameraUploadNodeForUpload];
    } else {
        __weak __typeof__(self) weakSelf = self;
        [self.mediaInfoLoader loadMediaInfoWithTimeout:LoadMediaInfoTimeoutInSeconds completion:^(BOOL loaded) {
            if (loaded) {
                [weakSelf loadCameraUploadNodeForUpload];
            } else {
                MEGALogError(@"[Camera Upload] retry to start camera upload due to failed to load media into");
                [weakSelf startCameraUploadIfNeeded];
            }
        }];
    }
}

- (void)loadCameraUploadNodeForUpload {
    MEGALogDebug(@"[Camera Upload] load camera upload node");
    if (!self.isNodesFetchDone) {
        return;
    }
    
    [self.cameraUploadNodeLoader loadCameraUploadNodeWithCompletion:^(MEGANode * _Nullable cameraUploadNode) {
        if (cameraUploadNode != self.cameraUploadNode) {
            self.cameraUploadNode = cameraUploadNode;
        }
        
        if (cameraUploadNode) {
            [self uploadCamera];
        }
    }];
}

- (void)uploadCamera {
    [self startVideoUploadIfNeeded];
    
    if (self.isPhotoUploadPaused) {
        MEGALogInfo(@"[Camera Upload] photo upload is paused");
        return;
    }
    
    [self.diskSpaceDetector startDetectingPhotoUpload];
    
    MEGALogDebug(@"[Camera Upload] start uploading photos with current photo operation count %lu", (unsigned long)self.photoUploadOperationQueue.operationCount);
    [self uploadAssetsForMediaType:PHAssetMediaTypeImage concurrentCount:PhotoUploadInForegroundConcurrentCount];
}

- (void)startVideoUploadIfNeeded {
    MEGALogDebug(@"[Camera Upload] start video upload if needed");
    if (!(CameraUploadManager.isCameraUploadEnabled && CameraUploadManager.isVideoUploadEnabled)) {
        MEGALogDebug(@"[Camera Upload] video upload is not enabled");
        return;
    }
    
    [self.cameraScanner scanMediaTypes:@[@(PHAssetMediaTypeVideo)] completion:^{
        [self uploadVideos];
    }];
}

- (void)uploadVideos {
    if (!(self.mediaInfoLoader.isMediaInfoLoaded && self.isNodesFetchDone && self.cameraUploadNode != nil)) {
        MEGALogDebug(@"[Camera Upload] can not upload videos due to the dependency on media info and camera uplaod node issues");
        return;
    }
    
    if (self.isVideoUploadPaused) {
        MEGALogInfo(@"[Camera Upload] video upload is paused");
        return;
    }
    
    [self.diskSpaceDetector startDetectingVideoUpload];
    
    MEGALogDebug(@"[Camera Upload] start uploading videos with current video operation count %lu", (unsigned long)self.videoUploadOperationQueue.operationCount);
    [self uploadAssetsForMediaType:PHAssetMediaTypeVideo concurrentCount:VideoUploadInForegroundConcurrentCount];
}

#pragma mark - upload next assets

- (void)uploadNextAssetForMediaType:(PHAssetMediaType)mediaType {
    if (!CameraUploadManager.isCameraUploadEnabled) {
        return;
    }
    
    switch (mediaType) {
        case PHAssetMediaTypeImage:
            if (self.isPhotoUploadPaused) {
                MEGALogInfo(@"[Camera Upload] photo upload is paused when to upload next asset");
                return;
            }
            break;
        case PHAssetMediaTypeVideo:
            if (!CameraUploadManager.isVideoUploadEnabled) {
                return;
            } else if (self.isVideoUploadPaused) {
                MEGALogInfo(@"[Camera Upload] video upload is paused when to upload next asset");
                return;
            }
            break;
        default:
            break;
    }
    
    [self uploadAssetsForMediaType:mediaType concurrentCount:1];
}

- (void)uploadAssetsForMediaType:(PHAssetMediaType)mediaType concurrentCount:(NSUInteger)count {
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
        NSArray<CameraUploadOperation *> *operations = [UploadOperationFactory operationsForUploadRecord:record parentNode:self.cameraUploadNode];
        if (operations.count > 0) {
            for (CameraUploadOperation *operation in operations) {
                if ([operation isMemberOfClass:[PhotoUploadOperation class]]) {
                    [self.photoUploadOperationQueue addOperation:operation];
                } else if ([operation isMemberOfClass:[LivePhotoUploadOperation class]]) {
                    [self.videoUploadOperationQueue addOperation:operation];
                } else if ([operation isMemberOfClass:[VideoUploadOperation class]]) {
                    [self.videoUploadOperationQueue addOperation:operation];
                }
            }
            
            MEGALogDebug(@"[Camera Upload] photo queue count %lu, video queue count %lu", (unsigned long)self.photoUploadOperationQueue.operationCount, (unsigned long)self.videoUploadOperationQueue.operationCount);
        } else {
            MEGALogInfo(@"[Camera Upload] delete record as we don't have data to upload");
            [CameraUploadRecordManager.shared deleteUploadRecord:record error:nil];
        }
    }
}

#pragma mark - enable, disable and stop upload

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
    [self startVideoUploadIfNeeded];
}

- (void)disableCameraUpload {
    [self disableVideoUpload];
    CameraUploadManager.cameraUploadEnabled = NO;
    [self resetCameraUploadQueues];
    [self unregisterNotificationsForUpload];
    [self.diskSpaceDetector stopDetectingPhotoUpload];
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

#pragma mark - upload status

- (NSUInteger)totalAssetsCount {
    return [CameraUploadRecordManager.shared totalRecordsCountByMediaTypes:self.enabledMediaTypes error:nil];
}

- (NSUInteger)uploadDoneAssetsCount {
    return [CameraUploadRecordManager.shared uploadDoneRecordsCountByMediaTypes:self.enabledMediaTypes error:nil];
}

- (NSUInteger)uploadPendingAssetsCount {
    return [CameraUploadRecordManager.shared pendingUploadRecordsCountByMediaTypes:self.enabledMediaTypes error:nil];
}

- (BOOL)isPhotoUploadDone {
    return [CameraUploadRecordManager.shared pendingUploadRecordsCountByMediaTypes:@[@(PHAssetMediaTypeImage)] error:nil] == 0;
}

- (BOOL)isVideoUploadDone {
    return [CameraUploadRecordManager.shared pendingUploadRecordsCountByMediaTypes:@[@(PHAssetMediaTypeVideo)] error:nil] == 0;
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

#pragma mark - photo library scan

- (void)scanPhotoLibraryWithCompletion:(void (^)(void))completion {
    NSMutableArray<NSNumber *> *mediaTypes = [NSMutableArray array];
    
    if (CameraUploadManager.isCameraUploadEnabled) {
        [mediaTypes addObject:@(PHAssetMediaTypeImage)];
        if (CameraUploadManager.isVideoUploadEnabled) {
            [mediaTypes addObject:@(PHAssetMediaTypeVideo)];
        }
        
        [self.cameraScanner scanMediaTypes:mediaTypes completion:completion];
    } else {
        completion();
        return;
    }
}

#pragma mark - handle app lifecycle

- (void)applicationDidEnterBackground {
    MEGALogDebug(@"[Camera Upload] adjust concurrent count when app went background");
    self.photoUploadOperationQueue.maxConcurrentOperationCount = PhotoUploadInBackgroundConcurrentCount;
    self.videoUploadOperationQueue.maxConcurrentOperationCount = VideoUploadInBackgroundConcurrentCount;
}

- (void)applicationDidBecomeActive {
    MEGALogDebug(@"[Camera Upload] adjust concurrent count when app became active");
    self.photoUploadOperationQueue.maxConcurrentOperationCount = PhotoUploadInForegroundConcurrentCount;
    self.videoUploadOperationQueue.maxConcurrentOperationCount = VideoUploadInForegroundConcurrentCount;
}

- (void)applicationDidReceiveMemoryWarning {
    MEGALogDebug(@"[Camera Upload] adjust concurrent count app got memory warning");
    self.photoUploadOperationQueue.maxConcurrentOperationCount = PhotoUploadInMemoryWarningConcurrentCount;
    self.videoUploadOperationQueue.maxConcurrentOperationCount = VideoUploadInMemoryWarningConcurrentCount;
}

#pragma mark - notifications

- (void)didReceiveStorageOverQuotaNotification:(NSNotification *)notification {
    MEGALogDebug(@"[Camera Upload] did receive storage over quota notification %@", notification);
    [self pauseCameraUploadIfNeeded];
}

- (void)didReceiveStorageEventNotification:(NSNotification *)notification {
    MEGALogDebug(@"[Camera Upload] did receive storage event notification %@", notification);
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

- (void)didReceiveNodesFetchDoneNotification:(NSNotification *)notification {
    MEGALogDebug(@"[Camera Upload] did receive nodes fetch done notification %@", notification);
    self.isNodesFetchDone = YES;
    [self startCameraUploadIfNeeded];
    [AttributeUploadManager.shared scanLocalAttributeFilesAndRetryUploadIfNeeded];
}

- (void)didReceiveReachabilityChangedNotification:(NSNotification *)notification {
    MEGALogDebug(@"[Camera Upload] did receive reachability changed notification %@", notification);
    if (MEGAReachabilityManager.isReachable) {
        [self startCameraUploadIfNeeded];
        [AttributeUploadManager.shared scanLocalAttributeFilesAndRetryUploadIfNeeded];
    }
}

- (void)didReceiveLogoutNotification:(NSNotification *)notification {
    MEGALogDebug(@"[Camera Upload] did receive logout notification %@", notification);
    [self disableCameraUpload];
    [NSFileManager.defaultManager removeItemIfExistsAtURL:NSURL.mnz_cameraUploadURL];
    [CameraUploadRecordManager.shared resetDataContext];
    [CameraUploadManager clearLocalSettings];
    _isNodesFetchDone = NO;
    _cameraUploadNode = nil;
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

#pragma mark - data collator

- (void)collateUploadRecords {
    [self.dataCollator collateUploadRecords];
}

#pragma mark - background refresh

+ (void)enableBackgroundRefreshIfNeeded {
    if (CameraUploadManager.isCameraUploadEnabled) {
        MEGALogInfo(@"[Camera Upload] enable background refresh for background upload");
        [UIApplication.sharedApplication setMinimumBackgroundFetchInterval:MinimumBackgroundRefreshInterval];
    }
}

+ (void)disableBackgroundRefresh {
    MEGALogInfo(@"[Camera Upload] disable background refresh for background upload");
    [UIApplication.sharedApplication setMinimumBackgroundFetchInterval:UIApplicationBackgroundFetchIntervalNever];
}

- (void)performBackgroundRefreshWithCompletion:(void (^)(UIBackgroundFetchResult))completion {
    if (CameraUploadManager.isCameraUploadEnabled) {
        [self scanPhotoLibraryWithCompletion:^{
            if (self.uploadPendingAssetsCount == 0) {
                completion(UIBackgroundFetchResultNoData);
            } else {
                MEGALogDebug(@"[Camera Upload] upload camera in background refresh");
                [self startCameraUploadIfNeeded];
                [NSTimer scheduledTimerWithTimeInterval:BackgroundRefreshDuration repeats:NO block:^(NSTimer * _Nonnull timer) {
                    completion(UIBackgroundFetchResultNewData);
                    if (self.uploadPendingAssetsCount == 0) {
                        completion(UIBackgroundFetchResultNoData);
                    }
                }];
            }
        }];
    } else {
        completion(UIBackgroundFetchResultNoData);
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
