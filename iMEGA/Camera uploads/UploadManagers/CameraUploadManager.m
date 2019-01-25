
#import "CameraUploadManager.h"
#import "CameraUploadRecordManager.h"
#import "CameraScanner.h"
#import "CameraUploadOperation.h"
#import "Helper.h"
#import "MEGASdkManager.h"
#import "MEGACreateFolderRequestDelegate.h"
#import "UploadOperationFactory.h"
#import "AttributeUploadManager.h"
#import "MEGAConstants.h"
#import "CameraUploadManager+Settings.h"
#import "UploadRecordsCollator.h"
#import "BackgroundUploadMonitor.h"
#import "TransferSessionManager.h"
#import "NSFileManager+MNZCategory.h"
#import "NSURL+CameraUpload.h"
@import Photos;

static NSString * const CameraUploadsNodeHandle = @"CameraUploadsNodeHandle";
static NSString * const CameraUplodFolderName = @"Camera Uploads";
static const NSInteger ConcurrentPhotoUploadCount = 10;
static const NSInteger MaxConcurrentPhotoOperationCountInBackground = 5;
static const NSInteger MaxConcurrentPhotoOperationCountInMemoryWarning = 2;

static const NSInteger ConcurrentVideoUploadCount = 1;
static const NSInteger MaxConcurrentVideoOperationCount = 1;

static const NSTimeInterval MinimumBackgroundRefreshInterval = 3600 * 2;
static const NSTimeInterval BackgroundRefreshDuration = 25;

@interface CameraUploadManager ()

@property (strong, nonatomic) NSOperationQueue *photoUploadOerationQueue;
@property (strong, nonatomic) NSOperationQueue *videoUploadOerationQueue;
@property (strong, nonatomic) MEGANode *cameraUploadNode;
@property (strong, nonatomic) CameraScanner *scanner;
@property (strong, nonatomic) UploadRecordsCollator *dataCollator;
@property (strong, nonatomic) BackgroundUploadMonitor *backgroundUploadMonitor;

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
        [self initializeUploadOperationQueues];
        [self registerNotifications];
        
        dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
            [MEGASdkManager.sharedMEGASdk ensureMediaInfo];
        });
        
        [NSNotificationCenter.defaultCenter addObserver:self selector:@selector(resetCameraUpload) name:MEGALogoutNotificationName object:nil];
    }
    return self;
}

- (void)initializeUploadOperationQueues {
    _photoUploadOerationQueue = [[NSOperationQueue alloc] init];
    _photoUploadOerationQueue.qualityOfService = NSQualityOfServiceUtility;
    if (UIApplication.sharedApplication.applicationState == UIApplicationStateBackground) {
        _photoUploadOerationQueue.maxConcurrentOperationCount = MaxConcurrentPhotoOperationCountInBackground;
    }
    
    _videoUploadOerationQueue = [[NSOperationQueue alloc] init];
    _videoUploadOerationQueue.qualityOfService = NSQualityOfServiceUtility;
    _videoUploadOerationQueue.maxConcurrentOperationCount = MaxConcurrentVideoOperationCount;
}

- (void)registerNotifications {
    [NSNotificationCenter.defaultCenter addObserver:self selector:@selector(applicationDidEnterBackground) name:UIApplicationDidEnterBackgroundNotification object:nil];
    [NSNotificationCenter.defaultCenter addObserver:self selector:@selector(applicationDidBecomeActive) name:UIApplicationDidBecomeActiveNotification object:nil];
    [NSNotificationCenter.defaultCenter addObserver:self selector:@selector(applicationDidReceiveMemoryWarning) name:UIApplicationDidReceiveMemoryWarningNotification object:nil];
}

- (void)configCameraUploadWhenAppLaunches {
    [CameraUploadManager disableCameraUploadIfAccessProhibited];
    [CameraUploadManager enableBackgroundRefreshIfNeeded];
    [self startBackgroundUploadIfPossible];
    
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        [AttributeUploadManager.shared scanLocalAttributeFilesAndRetryUploadIfNeeded];
        [TransferSessionManager.shared restoreAllSessions];
        [self collateUploadRecords];
    });
}

#pragma mark - properties

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

- (CameraScanner *)scanner {
    if (_scanner == nil) {
        _scanner = [[CameraScanner alloc] init];
    }
    
    return _scanner;
}

#pragma mark - camera upload management

- (void)startCameraUploadIfNeeded {
    if (!MEGASdkManager.sharedMEGASdk.isLoggedIn) {
        return;
    }
    
    if (!CameraUploadManager.isCameraUploadEnabled || self.photoUploadOerationQueue.operationCount > 0) {
        return;
    }
    
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_HIGH, 0), ^{
        if (self.cameraUploadNode) {
            [self uploadCamera];
        } else {
            [[MEGASdkManager sharedMEGASdk] createFolderWithName:CameraUplodFolderName parent:[[MEGASdkManager sharedMEGASdk] rootNode]
                                                        delegate:[[MEGACreateFolderRequestDelegate alloc] initWithCompletion:^(MEGARequest *request) {
                self->_cameraUploadNode = [[MEGASdkManager sharedMEGASdk] nodeForHandle:request.nodeHandle];
                [self saveCameraUploadHandle:request.nodeHandle];
                [self uploadCamera];
            }]];
        }
    });
}

- (void)uploadCamera {
    [self.scanner scanMediaTypes:@[@(PHAssetMediaTypeImage)] completion:^{
        [self.scanner observePhotoLibraryChanges];
        [self uploadNextAssetsWithNumber:ConcurrentPhotoUploadCount mediaType:PHAssetMediaTypeImage];
    }];
    
    [self startVideoUploadIfNeeded];
}

- (void)startVideoUploadIfNeeded {
    if (!(CameraUploadManager.isCameraUploadEnabled && CameraUploadManager.isVideoUploadEnabled)) {
        return;
    }
    
    [self.scanner scanMediaTypes:@[@(PHAssetMediaTypeVideo)] completion:^{
        if (self.videoUploadOerationQueue.operationCount > 0) {
            return;
        }
        
        [self uploadNextAssetsWithNumber:ConcurrentVideoUploadCount mediaType:PHAssetMediaTypeVideo];
    }];
}

- (void)uploadNextForAsset:(PHAsset *)asset {
    if (!CameraUploadManager.isCameraUploadEnabled) {
        return;
    }
    
    if (asset.mediaType == PHAssetMediaTypeVideo && !CameraUploadManager.isVideoUploadEnabled) {
        return;
    }
    
    [self uploadNextAssetsWithNumber:1 mediaType:asset.mediaType];
}

- (void)uploadNextAssetsWithNumber:(NSInteger)number mediaType:(PHAssetMediaType)mediaType {
    NSArray *records = [CameraUploadRecordManager.shared fetchToBeUploadedRecordsWithLimit:number mediaType:mediaType error:nil];
    if (records.count == 0) {
        MEGALogDebug(@"[Camera Upload] no more local asset to upload for media type %li", (long)mediaType);
        return;
    }
    
    for (MOAssetUploadRecord *record in records) {
        [CameraUploadRecordManager.shared updateRecord:record withStatus:CameraAssetUploadStatusQueuedUp error:nil];
        CameraUploadOperation *operation = [UploadOperationFactory operationWithUploadRecord:record parentNode:self.cameraUploadNode];
        if (operation) {
            if (mediaType == PHAssetMediaTypeImage) {
                [self.photoUploadOerationQueue addOperation:operation];
            } else {
                [self.videoUploadOerationQueue addOperation:operation];
            }
        } else {
            [CameraUploadRecordManager.shared deleteRecordsByLocalIdentifiers:@[record.localIdentifier] error:nil];
        }
    }
}

#pragma mark - stop upload

- (void)resetCameraUpload {
    [CameraUploadManager clearLocalSettings];
    CameraUploadManager.cameraUploadEnabled = NO;
    [NSFileManager.defaultManager removeItemIfExistsAtURL:NSURL.mnz_cameraUploadURL];
}

- (void)stopCameraUpload {
    [self stopVideoUpload];
    [self.photoUploadOerationQueue cancelAllOperations];
    [self.scanner unobservePhotoLibraryChanges];
    [CameraUploadManager disableBackgroundRefresh];
    [self stopBackgroundUpload];
}

- (void)stopVideoUpload {
    [self.videoUploadOerationQueue cancelAllOperations];
}

#pragma mark - upload status

- (NSUInteger)uploadPendingItemsCount {
    NSUInteger pendingCount = 0;
    
    if (CameraUploadManager.isCameraUploadEnabled) {
        NSArray<NSNumber *> *mediaTypes;
        if (CameraUploadManager.isVideoUploadEnabled) {
            mediaTypes = @[@(PHAssetMediaTypeVideo), @(PHAssetMediaTypeImage)];
        } else {
            mediaTypes = @[@(PHAssetMediaTypeImage)];
        }
        
        pendingCount = [CameraUploadRecordManager.shared pendingRecordsCountByMediaTypes:mediaTypes error:nil];
    }
    
    return pendingCount;
}

#pragma mark - photo library scan

- (void)scanPhotoLibraryWithCompletion:(void (^)(void))completion {
    NSMutableArray<NSNumber *> *mediaTypes = [NSMutableArray array];
    
    if (CameraUploadManager.isCameraUploadEnabled) {
        [mediaTypes addObject:@(PHAssetMediaTypeImage)];
        if (CameraUploadManager.isVideoUploadEnabled) {
            [mediaTypes addObject:@(PHAssetMediaTypeVideo)];
        }
        
        [self.scanner scanMediaTypes:mediaTypes completion:completion];
    } else {
        completion();
        return;
    }
}

#pragma mark - handle app lifecycle

- (void)applicationDidEnterBackground {
    self.photoUploadOerationQueue.maxConcurrentOperationCount = MaxConcurrentPhotoOperationCountInBackground;
}

- (void)applicationDidBecomeActive {
    self.photoUploadOerationQueue.maxConcurrentOperationCount = NSOperationQueueDefaultMaxConcurrentOperationCount;
}

- (void)applicationDidReceiveMemoryWarning {
    self.photoUploadOerationQueue.maxConcurrentOperationCount = MaxConcurrentPhotoOperationCountInMemoryWarning;
}

#pragma mark - photos access permission check

+ (void)disableCameraUploadIfAccessProhibited {
    switch (PHPhotoLibrary.authorizationStatus) {
        case PHAuthorizationStatusDenied:
        case PHAuthorizationStatusRestricted:
            if (CameraUploadManager.isCameraUploadEnabled) {
                CameraUploadManager.cameraUploadEnabled = NO;
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

#pragma mark - handle camera upload node

- (MEGANode *)cameraUploadNode {
    if (_cameraUploadNode == nil) {
        _cameraUploadNode = [self restoreCameraUploadNode];
    }
    
    return _cameraUploadNode;
}

- (MEGANode *)restoreCameraUploadNode {
    MEGANode *node = [self savedCameraUploadNode];
    if (node == nil) {
        node = [self findCameraUploadNodeInRoot];
        [self saveCameraUploadHandle:node.handle];
    }
    
    return node;
}

- (MEGANode *)savedCameraUploadNode {
    unsigned long long cameraUploadHandle = [[[NSUserDefaults standardUserDefaults] objectForKey:CameraUploadsNodeHandle] unsignedLongLongValue];
    if (cameraUploadHandle > 0) {
        MEGANode *node = [[MEGASdkManager sharedMEGASdk] nodeForHandle:cameraUploadHandle];
        if (node.parentHandle == [[MEGASdkManager sharedMEGASdk] rootNode].handle) {
            return node;
        }
    }
    
    return nil;
}

- (void)saveCameraUploadHandle:(uint64_t)handle {
    if (handle > 0) {
        [[NSUserDefaults standardUserDefaults] setObject:[NSNumber numberWithUnsignedLongLong:handle] forKey:CameraUploadsNodeHandle];
    }
}

- (MEGANode *)findCameraUploadNodeInRoot {
    MEGANodeList *nodeList = [[MEGASdkManager sharedMEGASdk] childrenForParent:[[MEGASdkManager sharedMEGASdk] rootNode]];
    NSInteger nodeListSize = [[nodeList size] integerValue];
    
    for (NSInteger i = 0; i < nodeListSize; i++) {
        MEGANode *node = [nodeList nodeAtIndex:i];
        if ([CameraUplodFolderName isEqualToString:node.name] && node.isFolder) {
            return node;
        }
    }
    
    return nil;
}

@end
