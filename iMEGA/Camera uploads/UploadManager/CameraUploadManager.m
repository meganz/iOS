
#import "CameraUploadManager.h"
#import "CameraUploadRecordManager.h"
#import "CameraScanner.h"
#import "CameraUploadOperation.h"
#import "Helper.h"
#import "MEGASdkManager.h"
#import "MEGACreateFolderRequestDelegate.h"
#import "UploadOperationFactory.h"

static NSString * const CameraUplodFolderName = @"Camera Uploads";
static const NSInteger ConcurrentPhotoUploadCount = 10;
static const NSInteger MaxConcurrentPhotoOperationCountInBackground = 5;
static const NSInteger MaxConcurrentPhotoOperationCountInMemoryWarning = 2;

static const NSInteger ConcurrentVideoUploadCount = 1;
static const NSInteger MaxConcurrentVideoOperationCount = 1;

@interface CameraUploadManager ()

@property (strong, nonatomic) NSOperationQueue *photoUploadOerationQueue;
@property (strong, nonatomic) NSOperationQueue *videoUploadOerationQueue;
@property (strong, nonatomic) CameraUploadRecordManager *assetUploadRecordManager;
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
        _assetUploadRecordManager = [[CameraUploadRecordManager alloc] init];
        _scanner = [[CameraScanner alloc] init];
        [self initializeUploadOperationQueues];
        [self registerNotifications];
        
        dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
            [[MEGASdkManager sharedMEGASdk] ensureMediaInfo];
        });
    }
    return self;
}

- (void)initializeUploadOperationQueues {
    _photoUploadOerationQueue = [[NSOperationQueue alloc] init];
    
    if (UIApplication.sharedApplication.applicationState == UIApplicationStateActive) {
        _photoUploadOerationQueue.maxConcurrentOperationCount = NSOperationQueueDefaultMaxConcurrentOperationCount;
    } else {
        _photoUploadOerationQueue.maxConcurrentOperationCount = MaxConcurrentPhotoOperationCountInBackground;
    }
    
    _videoUploadOerationQueue = [[NSOperationQueue alloc] init];
    _videoUploadOerationQueue.maxConcurrentOperationCount = MaxConcurrentVideoOperationCount;
}

- (void)registerNotifications {
    [NSNotificationCenter.defaultCenter addObserver:self selector:@selector(applicationDidEnterBackground) name:UIApplicationDidEnterBackgroundNotification object:nil];
    [NSNotificationCenter.defaultCenter addObserver:self selector:@selector(applicationDidBecomeActive) name:UIApplicationDidBecomeActiveNotification object:nil];
    [NSNotificationCenter.defaultCenter addObserver:self selector:@selector(applicationDidReceiveMemoryWarning) name:UIApplicationDidReceiveMemoryWarningNotification object:nil];
}

#pragma mark - scan and upload

- (void)startUploading {
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        if (self.cameraUploadNode) {
            [self uploadIfPossible];
        } else {
            [[MEGASdkManager sharedMEGASdk] createFolderWithName:CameraUplodFolderName parent:[[MEGASdkManager sharedMEGASdk] rootNode]
                                                        delegate:[[MEGACreateFolderRequestDelegate alloc] initWithCompletion:^(MEGARequest *request) {
                self->_cameraUploadNode = [[MEGASdkManager sharedMEGASdk] nodeForHandle:request.nodeHandle];
                [self saveCameraUploadHandle:request.nodeHandle];
                [self uploadIfPossible];
            }]];
        }
    });
}

- (void)uploadIfPossible {
    [PHPhotoLibrary requestAuthorization:^(PHAuthorizationStatus status) {
        if (status == PHAuthorizationStatusAuthorized) {
            [self.scanner startScanningWithCompletion:^{
                [self uploadNextAssetsWithNumber:ConcurrentPhotoUploadCount mediaType:PHAssetMediaTypeImage];
                [self uploadNextAssetsWithNumber:ConcurrentVideoUploadCount mediaType:PHAssetMediaTypeVideo];
            }];
        }
    }];
}

- (void)uploadNextForAsset:(PHAsset *)asset {
    [self uploadNextAssetsWithNumber:1 mediaType:asset.mediaType];
}

- (void)uploadNextAssetsWithNumber:(NSInteger)number mediaType:(PHAssetMediaType)mediaType {
    NSArray *records = [self.assetUploadRecordManager fetchNonUploadedRecordsWithLimit:number mediaType:mediaType error:nil];
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
