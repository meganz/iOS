
#import "CameraUploadManager.h"
#import "AssetUploadRecordCoreDataManager.h"
#import "AssetScanner.h"
#import "AssetUploadOperation.h"
#import "Helper.h"
#import "MEGASdkManager.h"
#import "MEGACreateFolderRequestDelegate.h"
@import Photos;

static NSString * const cameraUplodFolderName = @"Camera Uploads";
static const NSInteger concurrentPhotoUploadCount = 100;

@interface CameraUploadManager ()

@property (strong, nonatomic) NSOperationQueue *operationQueue;
@property (strong, nonatomic) AssetUploadRecordCoreDataManager *assetUploadRecordManager;
@property (strong, nonatomic) MEGANode *cameraUploadNode;
@property (strong, nonatomic) AssetScanner *scanner;

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
        _operationQueue = [[NSOperationQueue alloc] init];
        _assetUploadRecordManager = [[AssetUploadRecordCoreDataManager alloc] init];
        _scanner = [[AssetScanner alloc] init];
        [[MEGASdkManager sharedMEGASdk] ensureMediaInfo];
    }
    return self;
}

#pragma mark - scan and upload

- (void)startUploading {
    if (self.cameraUploadNode) {
        [self uploadIfPossible];
    } else {
        [[MEGASdkManager sharedMEGASdk] createFolderWithName:cameraUplodFolderName parent:[[MEGASdkManager sharedMEGASdk] rootNode]
                                                    delegate:[[MEGACreateFolderRequestDelegate alloc] initWithCompletion:^(MEGARequest *request) {
            self->_cameraUploadNode = [[MEGASdkManager sharedMEGASdk] nodeForHandle:request.nodeHandle];
            [self saveCameraUploadHandle:request.nodeHandle];
            [self uploadIfPossible];
        }]];
    }
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
    [self uploadNextPhotosWithNumber:concurrentPhotoUploadCount];
}

- (void)uploadNextVideoBatch {
}

- (void)uploadNextPhoto {
    [self uploadNextPhotosWithNumber:1];
}

- (void)uploadNextAvailableVideo {
    
}

- (void)uploadNextPhotosWithNumber:(NSInteger)number {
    NSArray *records = [self.assetUploadRecordManager fetchNonUploadedRecordsWithLimit:number error:nil];
    for (MOAssetUploadRecord *record in records) {
        [AssetUploadRecordCoreDataManager.shared updateStatus:uploadStatusQueuedUp forRecord:record error:nil];
        [self.operationQueue addOperation:[[AssetUploadOperation alloc] initWithLocalIdentifier:record.localIdentifier cameraUploadNode:self.cameraUploadNode]];
    }
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
        if ([cameraUplodFolderName isEqualToString:node.name] && node.isFolder) {
            return node;
        }
    }
    
    return nil;
}

@end
