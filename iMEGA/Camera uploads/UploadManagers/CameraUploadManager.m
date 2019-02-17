
#import "CameraUploadManager.h"
#import "CameraUploadRecordManager.h"
#import "CameraScanner.h"
#import "CameraUploadOperation.h"
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

static NSString * const CameraUploadIdentifierSeparator = @",";

static const NSInteger PhotoUploadInForegroundConcurrentCount = 10;
static const NSInteger PhotoUploadInBackgroundConcurrentCount = 5;
static const NSInteger PhotoUploadInMemoryWarningConcurrentCount = 2;

static const NSInteger VideoUploadConcurrentCount = 1;

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
            [self initializePhotoUploadQueue];
            if (CameraUploadManager.isVideoUploadEnabled) {
                [self initializeVideoUploadQueue];
            }
            
            [self registerNotificationsForUpload];
        }
    }
    return self;
}

- (void)registerGlobalNotifications {
    [NSNotificationCenter.defaultCenter addObserver:self selector:@selector(didReceiveLogoutNotification:) name:MEGALogoutNotificationName object:nil];
    [NSNotificationCenter.defaultCenter addObserver:self selector:@selector(didReceiveNodesFetchDoneNotification:) name:MEGANodesFetchDoneNotificationName object:nil];
}

- (void)setupCameraUploadWhenAppLaunches {
    [CameraUploadManager disableCameraUploadIfAccessProhibited];
    [CameraUploadManager enableBackgroundRefreshIfNeeded];
    [self startBackgroundUploadIfPossible];
    
    dispatch_async(dispatch_get_global_queue(QOS_CLASS_DEFAULT, 0), ^{
        [AttributeUploadManager.shared scanLocalAttributeFilesAndRetryUploadIfNeeded];
        [TransferSessionManager.shared restoreAllSessions];
        [self collateUploadRecords];
    });
}

#pragma mark - manage operation queues

- (void)initializePhotoUploadQueue {
    _photoUploadOperationQueue = [[NSOperationQueue alloc] init];
    if (UIApplication.sharedApplication.applicationState == UIApplicationStateBackground) {
        _photoUploadOperationQueue.maxConcurrentOperationCount = PhotoUploadInBackgroundConcurrentCount;
    } else {
        _photoUploadOperationQueue.maxConcurrentOperationCount = PhotoUploadInForegroundConcurrentCount;
    }
}

- (void)resetPhotoUploadQueue {
    [self.photoUploadOperationQueue cancelAllOperations];
    self.photoUploadOperationQueue = nil;
}

- (void)initializeVideoUploadQueue {
    _videoUploadOperationQueue = [[NSOperationQueue alloc] init];
    _videoUploadOperationQueue.maxConcurrentOperationCount = VideoUploadConcurrentCount;
}

- (void)resetVideoUploadQueue {
    [self.videoUploadOperationQueue cancelAllOperations];
    self.videoUploadOperationQueue = nil;
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
            [self startCameraUploadIfNeeded];
        }
    }
}

- (void)setPauseVideoUpload:(BOOL)pauseVideoUpload {
    if (_pauseVideoUpload != pauseVideoUpload) {
        _pauseVideoUpload = pauseVideoUpload;
        if (!pauseVideoUpload) {
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
    if (self.mediaInfoLoader.isMediaInfoLoaded) {
        [self loadCameraUploadNodeForUpload];
    } else {
        __weak __typeof__(self) weakSelf = self;
        [self.mediaInfoLoader loadMediaInfoWithTimeout:LoadMediaInfoTimeoutInSeconds completion:^(BOOL loaded) {
            if (loaded) {
                [weakSelf loadCameraUploadNodeForUpload];
            } else {
                [weakSelf startCameraUploadIfNeeded];
            }
        }];
    }
}

- (void)loadCameraUploadNodeForUpload {
    MEGALogDebug(@"[Camera Upload] start loading camera upload node");
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
        MEGALogDebug(@"[Camera Upload] photo upload is paused");
        return;
    }
    
    MEGALogDebug(@"[Camera Upload] camera upload node is loaded and start uploading camera with current operation count %lu", (unsigned long)self.photoUploadOperationQueue.operationCount);
    [self.diskSpaceDetector startDetectingPhotoUpload];
    
    if (self.photoUploadOperationQueue.operationCount < PhotoUploadInForegroundConcurrentCount) {
        [self uploadNextAssetsWithNumber:PhotoUploadInForegroundConcurrentCount mediaType:PHAssetMediaTypeImage];
    }
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
        MEGALogDebug(@"[Camera Upload] video upload is paused");
        return;
    }
    
    MEGALogDebug(@"[Camera Upload] start uploading videos with current video operation count %lu", (unsigned long)self.videoUploadOperationQueue.operationCount);
    
    [self.diskSpaceDetector startDetectingVideoUpload];
    
    if (self.videoUploadOperationQueue.operationCount < VideoUploadConcurrentCount) {
        [self uploadNextAssetsWithNumber:VideoUploadConcurrentCount mediaType:PHAssetMediaTypeVideo];
    }
}

#pragma mark - upload next assets

- (void)uploadNextAssetWithMediaType:(PHAssetMediaType)mediaType {
    if (!CameraUploadManager.isCameraUploadEnabled) {
        return;
    }
    
    switch (mediaType) {
        case PHAssetMediaTypeImage:
            if (self.isPhotoUploadPaused) {
                MEGALogDebug(@"[Camera Upload] photo upload is paused when to upload next asset");
                return;
            }
            break;
        case PHAssetMediaTypeVideo:
            if (!CameraUploadManager.isVideoUploadEnabled) {
                return;
            } else if (self.isVideoUploadPaused) {
                MEGALogDebug(@"[Camera Upload] video upload is paused when to upload next asset");
                return;
            }
            break;
        default:
            break;
    }
    
    [self uploadNextAssetsWithNumber:1 mediaType:mediaType];
}

- (void)uploadNextAssetsWithNumber:(NSInteger)number mediaType:(PHAssetMediaType)mediaType {
    NSArray<NSNumber *> *statuses = AssetUploadStatus.statusesReadyToQueueUp;
    if (MEGAReachabilityManager.isReachable) {
        statuses = AssetUploadStatus.allStatusesToQueueUp;
    }
    NSArray *records = [CameraUploadRecordManager.shared queueUpUploadRecordsByStatuses:statuses fetchLimit:number mediaType:mediaType error:nil];
    if (records.count == 0) {
        MEGALogDebug(@"[Camera Upload] no more local asset to upload for media type %li", (long)mediaType);
        return;
    }
    
    for (MOAssetUploadRecord *record in records) {
        PHAssetMediaSubtype savedMediaSubtype = PHAssetMediaSubtypeNone;
        CameraUploadOperation *operation = [UploadOperationFactory operationWithUploadRecord:record parentNode:self.cameraUploadNode identifierSeparator:CameraUploadIdentifierSeparator savedMediaSubtype:&savedMediaSubtype];
        PHAsset *asset = operation.uploadInfo.asset;
        if (operation) {
            if (asset.mediaType == PHAssetMediaTypeImage) {
                [self.photoUploadOperationQueue addOperation:operation];
            } else {
                [self.videoUploadOperationQueue addOperation:operation];
            }
            
            [self addUploadRecordIfNeededForAsset:asset savedMediaSubtype:savedMediaSubtype];
        } else {
            [CameraUploadRecordManager.shared deleteUploadRecord:record error:nil];
        }
    }
}

- (void)addUploadRecordIfNeededForAsset:(PHAsset *)asset savedMediaSubtype:(PHAssetMediaSubtype)savedMediaSubtype {
    if (@available(iOS 9.1, *)) {
        if (asset.mediaType == PHAssetMediaTypeImage && savedMediaSubtype == PHAssetMediaSubtypeNone && (asset.mediaSubtypes & PHAssetMediaSubtypePhotoLive)) {
            NSString *mediaSubtypedLocalIdentifier = [@[asset.localIdentifier, [@(PHAssetMediaSubtypePhotoLive) stringValue]] componentsJoinedByString:CameraUploadIdentifierSeparator];
            [CameraUploadRecordManager.shared saveAsset:asset mediaSubtypedLocalIdentifier:mediaSubtypedLocalIdentifier error:nil];
        }
    }
}

#pragma mark - enable, disable and stop upload

- (void)enableCameraUpload {
    CameraUploadManager.cameraUploadEnabled = YES;
    [self initializePhotoUploadQueue];
    [self registerNotificationsForUpload];
    [self startBackgroundUploadIfPossible];
    [CameraUploadManager enableBackgroundRefreshIfNeeded];
    [self startCameraUploadIfNeeded];
}

- (void)enableVideoUpload {
    CameraUploadManager.videoUploadEnabled = YES;
    [self initializeVideoUploadQueue];
    [self startVideoUploadIfNeeded];
}

- (void)disableCameraUpload {
    [self disableVideoUpload];
    CameraUploadManager.cameraUploadEnabled = NO;
    [self resetPhotoUploadQueue];
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
    [self resetVideoUploadQueue];
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

- (NSUInteger)uploadPendingItemsCount {
    NSArray<NSNumber *> *mediaTypes;
    if (CameraUploadManager.isVideoUploadEnabled) {
        mediaTypes = @[@(PHAssetMediaTypeVideo), @(PHAssetMediaTypeImage)];
    } else {
        mediaTypes = @[@(PHAssetMediaTypeImage)];
    }
    
    return [CameraUploadRecordManager.shared pendingUploadRecordsCountByMediaTypes:mediaTypes error:nil];
}

- (BOOL)isPhotoUploadDone {
    if (CameraUploadManager.isCameraUploadEnabled) {
        return self.photoUploadOperationQueue.operationCount == 0 && [CameraUploadRecordManager.shared pendingUploadRecordsCountByMediaTypes:@[@(PHAssetMediaTypeImage)] error:nil] == 0;
    } else {
        return NO;
    }
}

- (BOOL)isVideoUploadDone {
    if (CameraUploadManager.isCameraUploadEnabled && CameraUploadManager.isVideoUploadEnabled) {
        return self.videoUploadOperationQueue.operationCount == 0 && [CameraUploadRecordManager.shared pendingUploadRecordsCountByMediaTypes:@[@(PHAssetMediaTypeVideo)] error:nil] == 0;
    } else {
        return NO;
    }
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
    self.photoUploadOperationQueue.maxConcurrentOperationCount = PhotoUploadInBackgroundConcurrentCount;
}

- (void)applicationDidBecomeActive {
    self.photoUploadOperationQueue.maxConcurrentOperationCount = PhotoUploadInForegroundConcurrentCount;
}

- (void)applicationDidReceiveMemoryWarning {
    self.photoUploadOperationQueue.maxConcurrentOperationCount = PhotoUploadInMemoryWarningConcurrentCount;
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
        [UIApplication.sharedApplication setMinimumBackgroundFetchInterval:MinimumBackgroundRefreshInterval];
    }
}

+ (void)disableBackgroundRefresh {
    [UIApplication.sharedApplication setMinimumBackgroundFetchInterval:UIApplicationBackgroundFetchIntervalNever];
}

- (void)performBackgroundRefreshWithCompletion:(void (^)(UIBackgroundFetchResult))completion {
    if (CameraUploadManager.isCameraUploadEnabled) {
        [self scanPhotoLibraryWithCompletion:^{
            if (self.uploadPendingItemsCount == 0) {
                completion(UIBackgroundFetchResultNoData);
            } else {
                [self startCameraUploadIfNeeded];
                [NSTimer scheduledTimerWithTimeInterval:BackgroundRefreshDuration repeats:NO block:^(NSTimer * _Nonnull timer) {
                    completion(UIBackgroundFetchResultNewData);
                    if (self.uploadPendingItemsCount == 0) {
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
