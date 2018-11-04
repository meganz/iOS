
#import "CameraUploadManager.h"
#import "CameraUploadRecordManager.h"
#import "CameraScanner.h"
#import "CameraUploadOperation.h"
#import "Helper.h"
#import "MEGASdkManager.h"
#import "MEGACreateFolderRequestDelegate.h"
@import Photos;

static NSString * const CameraUplodFolderName = @"Camera Uploads";
static const NSInteger ConcurrentPhotoUploadCount = 10;
static const NSInteger MaxConcurrentOperationCountInBackground = 5;
static const NSInteger MaxConcurrentOperationCountInMemoryWarning = 2;

@interface CameraUploadManager ()

@property (strong, nonatomic) NSOperationQueue *operationQueue;
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
        [self initializeOperationQueue];
        [_operationQueue addOperationWithBlock:^{
            [[MEGASdkManager sharedMEGASdk] ensureMediaInfo];
        }];
        
        [self registerNotifications];
    }
    return self;
}

- (void)initializeOperationQueue {
    _operationQueue = [[NSOperationQueue alloc] init];

    if (UIApplication.sharedApplication.applicationState == UIApplicationStateActive) {
        _operationQueue.maxConcurrentOperationCount = NSOperationQueueDefaultMaxConcurrentOperationCount;
    } else {
        _operationQueue.maxConcurrentOperationCount = MaxConcurrentOperationCountInBackground;
    }
}

- (void)registerNotifications {
    [NSNotificationCenter.defaultCenter addObserver:self selector:@selector(applicationDidEnterBackground) name:UIApplicationDidEnterBackgroundNotification object:nil];
    [NSNotificationCenter.defaultCenter addObserver:self selector:@selector(applicationDidBecomeActive) name:UIApplicationDidBecomeActiveNotification object:nil];
    [NSNotificationCenter.defaultCenter addObserver:self selector:@selector(applicationDidReceiveMemoryWarning) name:UIApplicationDidReceiveMemoryWarningNotification object:nil];
}

#pragma mark - scan and upload

- (void)startUploading {
    [self.operationQueue addOperationWithBlock:^{
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
    }];
}

- (void)uploadIfPossible {
    [PHPhotoLibrary requestAuthorization:^(PHAuthorizationStatus status) {
        if (status == PHAuthorizationStatusAuthorized) {
            [self.scanner startScanningWithCompletion:^{
                [self uploadNextPhotoBatch];
            }];
        }
    }];
}

- (void)uploadNextPhotoBatch {
    [self uploadNextPhotosWithNumber:ConcurrentPhotoUploadCount];
}

- (void)uploadNextVideoBatch {
}

- (void)uploadNextPhoto {
    [self uploadNextPhotosWithNumber:1];
}

- (void)uploadNextAvailableVideo {
    
}

- (void)uploadNextPhotosWithNumber:(NSInteger)number {
    NSArray *records = [self.assetUploadRecordManager fetchNonUploadedRecordsWithLimit:number mediaType:PHAssetMediaTypeImage error:nil];
    for (MOAssetUploadRecord *record in records) {
        [CameraUploadRecordManager.shared updateStatus:UploadStatusQueuedUp forRecord:record error:nil];
        [self.operationQueue addOperation:[[CameraUploadOperation alloc] initWithLocalIdentifier:record.localIdentifier cameraUploadNode:self.cameraUploadNode]];
    }
}

#pragma mark - handle app lifecycle

- (void)applicationDidEnterBackground {
    self.operationQueue.maxConcurrentOperationCount = MaxConcurrentOperationCountInBackground;
}

- (void)applicationDidBecomeActive {
    self.operationQueue.maxConcurrentOperationCount = NSOperationQueueDefaultMaxConcurrentOperationCount;
}

- (void)applicationDidReceiveMemoryWarning {
    self.operationQueue.maxConcurrentOperationCount = MaxConcurrentOperationCountInMemoryWarning;
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
