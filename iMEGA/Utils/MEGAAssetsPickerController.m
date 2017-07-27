#import "MEGAAssetsPickerController.h"

#import "SVProgressHUD.h"

#import "MEGAAssetOperation.h"
#import "MEGACreateFolderRequestDelegate.h"

@interface MEGAAssetsPickerController () <CTAssetsPickerControllerDelegate>

@property (nonatomic) MEGANode *parentNode;

@property (nonatomic, getter=toUploadToCloudDrive) BOOL uploadToCloudDrive;
@property (nonatomic, getter=toUploadToChat) BOOL uploadToChat;

@property (nonatomic, copy) void (^filePathCompletion)(NSString *filePath);
@property (nonatomic) NSString *filePath;

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

- (instancetype)initToUploadToChatWithFilePathCompletion:(void (^)(NSString *filePath))filePathCompletion {
    self = [super init];
    
    if (self) {
        _uploadToChat = YES;
        _filePathCompletion = filePathCompletion;
        
        self.delegate = self;
    }
    
    return self;
}

#pragma mark - Lifecycle

- (void)viewDidLoad {
    [super viewDidLoad];
    
    if (self.toUploadToChat) {
        [self createMyChatFilesFolderWithCompletion:nil];
    }
    
    if (![[NSFileManager defaultManager] fileExistsAtPath:NSTemporaryDirectory()]) {
        [[NSFileManager defaultManager] createDirectoryAtPath:NSTemporaryDirectory() withIntermediateDirectories:YES attributes:nil error:nil];
    }
}

#pragma mark - Private

- (void)prepareUploadDestination {
    MEGANode *parentNode = [[MEGASdkManager sharedMEGASdk] nodeForPath:@"/My chat files"];
    if (parentNode) {
        [self triggerPathCompletion];
    } else {
        [self createMyChatFilesFolderWithCompletion:^{
            [self triggerPathCompletion];
        }];
    }
}

- (void)triggerPathCompletion {
    if (self.filePathCompletion) {
        self.filePathCompletion(self.filePath);
    }
}

- (void)createMyChatFilesFolderWithCompletion:(void (^)(void))completion {
    MEGANode *parentNode = [[MEGASdkManager sharedMEGASdk] nodeForPath:@"/My chat files"];
    if (!parentNode) {
        MEGACreateFolderRequestDelegate *createFolderRequestDelegate = [[MEGACreateFolderRequestDelegate alloc] initWithCompletion:completion];
        [[MEGASdkManager sharedMEGASdk] createFolderWithName:@"My chat files" parent:[[MEGASdkManager sharedMEGASdk] rootNode] delegate:createFolderRequestDelegate];
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
        } else if (self.toUploadToChat) {
            [self createMyChatFilesFolderWithCompletion:nil];
            
            for (PHAsset *phAsset in assets) {
                MEGAAssetOperation *assetOperation = [[MEGAAssetOperation alloc] initToUploadToChatWithPHAsset:phAsset completion:^(NSString *filePath) {
                    self.filePath = [filePath stringByReplacingOccurrencesOfString:[NSHomeDirectory() stringByAppendingString:@"/"] withString:@""];
                    [self prepareUploadDestination];
                }];
                [operationQueue addOperation:assetOperation];
            }
        }
    }];
}

@end
