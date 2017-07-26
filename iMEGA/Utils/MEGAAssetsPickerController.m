#import "MEGAAssetsPickerController.h"

#import "SVProgressHUD.h"

#import "MEGAAssetOperation.h"

@interface MEGAAssetsPickerController () <CTAssetsPickerControllerDelegate>

@property (nonatomic) MEGANode *parentNode;

@property (nonatomic, getter=toUploadToCloudDrive) BOOL uploadToCloudDrive;

@end

@implementation MEGAAssetsPickerController

- (instancetype)initToUploadToCloudDriveWithParentNode:(MEGANode *)parentNode {
    self = [super init];
    
    if (self) {
        _uploadToCloudDrive = YES;
        _parentNode = parentNode;
        
        self.delegate = self;
    }
    
    return self;
}

#pragma mark - Lifecycle

- (void)viewDidLoad {
    [super viewDidLoad];
    
    if (![[NSFileManager defaultManager] fileExistsAtPath:NSTemporaryDirectory()]) {
        [[NSFileManager defaultManager] createDirectoryAtPath:NSTemporaryDirectory() withIntermediateDirectories:YES attributes:nil error:nil];
    }
}

#pragma mark - CTAssetsPickerControllerDelegate

- (void)assetsPickerController:(CTAssetsPickerController *)picker didFinishPickingAssets:(NSArray *)assets {
    if (assets.count == 0) {
        [self dismissViewControllerAnimated:YES completion:nil];
        return;
    }
    
    [self dismissViewControllerAnimated:YES completion:^{
        NSOperationQueue *operationQueue = [[NSOperationQueue alloc] init];
        operationQueue.qualityOfService = NSOperationQualityOfServiceUtility;
        operationQueue.maxConcurrentOperationCount = 1;
        if (self.toUploadToCloudDrive) {
            for (PHAsset *asset in assets) {
                MEGAAssetOperation *assetOperation = [[MEGAAssetOperation alloc] initWithPHAsset:asset parentNode:self.parentNode automatically:NO];
                [operationQueue addOperation:assetOperation];
            }
        }
    }];
}

@end
