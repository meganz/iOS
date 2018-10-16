
#import "CameraUploadManager.h"
#import "AssetUploadRecordCoreDataManager.h"
#import "AssetManager.h"
#import "AssetUploadOperation.h"
@import Photos;

@interface CameraUploadManager ()

@property (strong, nonatomic) NSOperationQueue *operationQueue;
@property (strong, nonatomic) AssetUploadRecordCoreDataManager *assetUploadRecordManager;

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
    }
    return self;
}

- (void)startUploading {
    [PHPhotoLibrary requestAuthorization:^(PHAuthorizationStatus status) {
        if (status == PHAuthorizationStatusAuthorized) {
            [[AssetManager shared] startScanningWithCompletion:^{
                NSArray *records = [self.assetUploadRecordManager fetchNonUploadedRecordsWithLimit:1 error:nil];
                for (MOAssetUploadRecord *record in records) {
                    [self.operationQueue addOperation:[[AssetUploadOperation alloc] initWithLocalIdentifier:record.localIdentifier]];
                }
            }];
        }
    }];
}


@end
