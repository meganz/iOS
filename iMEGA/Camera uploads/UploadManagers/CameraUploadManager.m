
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
@import Photos;

static NSString * const CameraUploadsNodeHandle = @"CameraUploadsNodeHandle";
static NSString * const CameraUplodFolderName = @"Camera Uploads";
static const NSInteger ConcurrentPhotoUploadCount = 10;
static const NSInteger MaxConcurrentPhotoOperationCountInBackground = 5;
static const NSInteger MaxConcurrentPhotoOperationCountInMemoryWarning = 2;

static const NSInteger ConcurrentVideoUploadCount = 1;
static const NSInteger MaxConcurrentVideoOperationCount = 1;

@interface CameraUploadManager ()

@property (strong, nonatomic) NSOperationQueue *photoUploadOerationQueue;
@property (strong, nonatomic) NSOperationQueue *videoUploadOerationQueue;
@property (strong, nonatomic) MEGANode *cameraUploadNode;
@property (strong, nonatomic) CameraScanner *scanner;
@property (strong, nonatomic) UploadRecordsCollator *dataCollator;

@end

@implementation CameraUploadManager

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
        _scanner = [[CameraScanner alloc] init];
        [self initializeUploadOperationQueues];
        [self registerNotifications];
        
        dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
            [[MEGASdkManager sharedMEGASdk] ensureMediaInfo];
        });
        
        [NSNotificationCenter.defaultCenter addObserver:self selector:@selector(clearCameraUploadSettings) name:MEGALogoutNotificationName object:nil];
    }
    return self;
}

- (void)initializeUploadOperationQueues {
    _photoUploadOerationQueue = [[NSOperationQueue alloc] init];
    _photoUploadOerationQueue.qualityOfService = NSQualityOfServiceUtility;
    
    if (UIApplication.sharedApplication.applicationState == UIApplicationStateActive) {
        _photoUploadOerationQueue.maxConcurrentOperationCount = NSOperationQueueDefaultMaxConcurrentOperationCount;
    } else {
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

- (UploadRecordsCollator *)dataCollator {
    if (_dataCollator == nil) {
        _dataCollator = [[UploadRecordsCollator alloc] init];
    }

    return _dataCollator;
}

#pragma mark - scan and upload

- (void)enableCameraUpload {
    [self.class setCameraUploadEnabled:YES];
    [self startCameraUploadIfNeeded];
}

- (void)startCameraUploadIfNeeded {
    if (!self.class.isCameraUploadEnabled || self.photoUploadOerationQueue.operationCount > 0) {
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
    [self.scanner scanMediaType:PHAssetMediaTypeImage completion:^{
        [self.scanner observePhotoLibraryChanges];
        [self uploadNextAssetsWithNumber:ConcurrentPhotoUploadCount mediaType:PHAssetMediaTypeImage];
    }];
    
    [self startVideoUploadIfNeeded];
}

- (void)startVideoUploadIfNeeded {
    if (!([self.class isCameraUploadEnabled] && [self.class isVideoUploadEnabled])) {
        return;
    }
    
    [self.scanner scanMediaType:PHAssetMediaTypeVideo completion:^{
        if (self.videoUploadOerationQueue.operationCount > 0) {
            return;
        }
        
        [self uploadNextAssetsWithNumber:ConcurrentVideoUploadCount mediaType:PHAssetMediaTypeVideo];
    }];
}

- (void)uploadNextForAsset:(PHAsset *)asset {
    if (![self.class isCameraUploadEnabled]) {
        return;
    }
    
    if (asset.mediaType == PHAssetMediaTypeVideo && ![self.class isVideoUploadEnabled]) {
        return;
    }
    
    [self uploadNextAssetsWithNumber:1 mediaType:asset.mediaType];
}

- (void)uploadNextAssetsWithNumber:(NSInteger)number mediaType:(PHAssetMediaType)mediaType {
    NSArray *records = [CameraUploadRecordManager.shared fetchNonUploadedRecordsWithLimit:number mediaType:mediaType error:nil];
    if (records.count == 0) {
        MEGALogDebug(@"[Camera Upload] no more local asset to upload for media type %li", (long)mediaType);
        return;
    }
    
    for (MOAssetUploadRecord *record in records) {
        [CameraUploadRecordManager.shared updateRecord:record withStatus:CameraAssetUploadStatusQueuedUp error:nil];
        CameraUploadOperation *operation = [UploadOperationFactory operationWithLocalIdentifier:record.localIdentifier parentNode:self.cameraUploadNode];
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

- (void)disableCameraUpload {
    [self.class setCameraUploadEnabled:NO];
    [self.photoUploadOerationQueue cancelAllOperations];
    [self disableVideoUpload];
    [self.scanner unobservePhotoLibraryChanges];
}

- (void)disableVideoUpload {
    [self.class setVideoUploadEnabled:NO];
    [self.videoUploadOerationQueue cancelAllOperations];
}

#pragma mark - logout

- (void)clearCameraUploadSettings {
    [self disableCameraUpload];
    [self.class clearLocalSettings];
}

#pragma mark - upload status

- (NSUInteger)uploadPendingItemsCount {
    NSUInteger pendingCount = 0;
    
    if (self.class.isCameraUploadEnabled) {
        NSArray<NSNumber *> *mediaTypes;
        if (self.class.isVideoUploadEnabled) {
            mediaTypes = @[@(PHAssetMediaTypeVideo), @(PHAssetMediaTypeImage)];
        } else {
            mediaTypes = @[@(PHAssetMediaTypeImage)];
        }
        
        pendingCount = [CameraUploadRecordManager.shared fetchPendingRecordsByMediaTypes:mediaTypes error:nil].count;
    }
    
    return pendingCount;
}

- (NSUInteger)uploadRunningItemsCount {
    return self.photoUploadOerationQueue.operationCount + self.videoUploadOerationQueue.operationCount;
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

#pragma mark - data collator

- (void)collateUploadRecords {
    [self.dataCollator collateUploadRecords];
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
