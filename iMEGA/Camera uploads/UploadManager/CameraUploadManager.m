
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
@import Photos;

#define kIsCameraUploadsEnabled @"IsCameraUploadsEnabled"
#define kIsUploadVideosEnabled @"IsUploadVideosEnabled"
#define kIsUseCellularConnectionEnabled @"IsUseCellularConnectionEnabled"
#define kCameraUploadsNodeHandle @"CameraUploadsNodeHandle"

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

#pragma mark - scan and upload

- (void)startCameraUploadIfNeeded {
    if (!self.class.isCameraUploadEnabled || self.photoUploadOerationQueue.operationCount > 0) {
        return;
    }
    
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        
        // TODO: may need to move attributes scan to app launch
        [AttributeUploadManager.shared scanLocalAttributesAndRetryUploadIfNeeded];
   
        if (self.cameraUploadNode) {
            [self startCameraUpload];
        } else {
            [[MEGASdkManager sharedMEGASdk] createFolderWithName:CameraUplodFolderName parent:[[MEGASdkManager sharedMEGASdk] rootNode]
                                                        delegate:[[MEGACreateFolderRequestDelegate alloc] initWithCompletion:^(MEGARequest *request) {
                self->_cameraUploadNode = [[MEGASdkManager sharedMEGASdk] nodeForHandle:request.nodeHandle];
                [self saveCameraUploadHandle:request.nodeHandle];
                [self startCameraUpload];
            }]];
        }
    });
}

- (void)startCameraUpload {
    [self uploadNextAssetsWithNumber:ConcurrentPhotoUploadCount mediaType:PHAssetMediaTypeImage];
    [self startVideoUploadIfNeeded];
}

- (void)startVideoUploadIfNeeded {
    if (!([self.class isCameraUploadEnabled] && [self.class isVideoUploadEnabled])) {
        return;
    }
    
    if (self.videoUploadOerationQueue.operationCount > 0) {
        return;
    }
    
    [self uploadNextAssetsWithNumber:ConcurrentVideoUploadCount mediaType:PHAssetMediaTypeVideo];
}

- (void)uploadNextForAsset:(PHAsset *)asset {
    [self uploadNextAssetsWithNumber:1 mediaType:asset.mediaType];
}

- (void)uploadNextAssetsWithNumber:(NSInteger)number mediaType:(PHAssetMediaType)mediaType {
    NSArray *records = [CameraUploadRecordManager.shared fetchNonUploadedRecordsWithLimit:number mediaType:mediaType error:nil];
    if (records.count == 0) {
        MEGALogDebug(@"[Camera Upload] no more local asset to upload for media type %ld", mediaType);
        return;
    }
    
    for (MOAssetUploadRecord *record in records) {
        [CameraUploadRecordManager.shared updateStatus:UploadStatusQueuedUp forRecord:record error:nil];
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

- (void)stopCameraUpload {
    [self.class setCameraUploadEnabled:NO];
    [self.photoUploadOerationQueue cancelAllOperations];
    [self stopVideoUpload];
}

- (void)stopVideoUpload {
    [self.class setVideoUploadEnabled:NO];
    [self.videoUploadOerationQueue cancelAllOperations];
}

#pragma mark - logout

- (void)clearCameraUploadSettings {
    [self.class setCameraUploadEnabled:NO];
    [self stopCameraUpload];
    [NSUserDefaults.standardUserDefaults removeObjectForKey:kCameraUploadsNodeHandle];
}

#pragma mark - enable check

+ (BOOL)isCameraUploadEnabled {
    return [NSUserDefaults.standardUserDefaults boolForKey:kIsCameraUploadsEnabled];
}

+ (void)setCameraUploadEnabled:(BOOL)cameraUploadEnabled {
    [NSUserDefaults.standardUserDefaults setBool:cameraUploadEnabled forKey:kIsCameraUploadsEnabled];
}

+ (BOOL)isVideoUploadEnabled {
    return [NSUserDefaults.standardUserDefaults boolForKey:kIsUploadVideosEnabled];
}

+ (void)setVideoUploadEnabled:(BOOL)videoUploadEnabled {
    return [NSUserDefaults.standardUserDefaults setBool:videoUploadEnabled forKey:kIsUploadVideosEnabled];
}

+ (BOOL)isCellularUploadEnabled {
    return [NSUserDefaults.standardUserDefaults boolForKey:kIsUseCellularConnectionEnabled];
}

+ (void)setCellularUploadEnabled:(BOOL)cellularUploadEnabled {
    [NSUserDefaults.standardUserDefaults setBool:cellularUploadEnabled forKey:kIsUseCellularConnectionEnabled];
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
        
        pendingCount = [CameraUploadRecordManager.shared fetchAllPendingUploadRecordsInMediaTypes:mediaTypes error:nil].count;
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
    unsigned long long cameraUploadHandle = [[[NSUserDefaults standardUserDefaults] objectForKey:kCameraUploadsNodeHandle] unsignedLongLongValue];
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
        [[NSUserDefaults standardUserDefaults] setObject:[NSNumber numberWithUnsignedLongLong:handle] forKey:kCameraUploadsNodeHandle];
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
