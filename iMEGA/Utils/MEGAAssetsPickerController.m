#import "MEGAAssetsPickerController.h"

#import "MEGACreateFolderRequestDelegate.h"

#import "Helper.h"
#import "MEGAStore.h"
#import "MEGASdkManager.h"
#import "MEGASdk+MNZCategory.h"

@interface MEGAAssetsPickerController () <CTAssetsPickerControllerDelegate>

@property (nonatomic) MEGANode *parentNode;

@property (nonatomic, getter=toUploadToCloudDrive) BOOL uploadToCloudDrive;
@property (nonatomic, getter=toUploadToChat) BOOL uploadToChat;

@property (nonatomic, copy) void (^assetsCompletion)(NSArray *assets);
@property (nonatomic, copy) NSArray *assets;

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

- (instancetype)initToUploadToChatWithAssetsCompletion:(void (^)(NSArray<PHAsset *> *))assetsCompletion {
    self = [super init];
    
    if (self) {
        _uploadToChat = YES;
        _assetsCompletion = assetsCompletion;
        
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

#pragma mark - Private

- (void)triggerAssetsCompletion {
    if (self.assetsCompletion) {
        self.assetsCompletion(self.assets);
    }
}

#pragma mark - CTAssetsPickerControllerDelegate

- (void)assetsPickerController:(CTAssetsPickerController *)picker didFinishPickingAssets:(NSArray *)assets {
    if (assets.count == 0) {
        [self dismissViewControllerAnimated:YES completion:nil];
        return;
    }
    
    [self dismissViewControllerAnimated:YES completion:^{
        if (self.toUploadToCloudDrive) {
            for (PHAsset *asset in assets) {
                [[MEGAStore shareInstance] insertUploadTransferWithLocalIdentifier:asset.localIdentifier parentNodeHandle:self.parentNode.handle];
            }
            [Helper startPendingUploadTransferIfNeeded];
        } else if (self.toUploadToChat) {
            self.assets = assets;
            [self triggerAssetsCompletion];
        }
    }];
}

@end
