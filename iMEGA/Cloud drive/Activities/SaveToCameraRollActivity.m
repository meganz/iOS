
#import "SaveToCameraRollActivity.h"
#import "MEGASdkManager.h"
#import "MEGAReachabilityManager.h"
#import "SVProgressHUD.h"

#import <Photos/Photos.h>

@interface SaveToCameraRollActivity () <MEGATransferDelegate>

@property (nonatomic, strong) MEGANode *node;

@end

@implementation SaveToCameraRollActivity


- (instancetype)initWithNode:(MEGANode *)node {
    _node = node;
    
    return self;
}

- (NSString *)activityType {
    return @"SaveToCameraRollActivity";
}

- (NSString *)activityTitle {
    return AMLocalizedString(@"saveImage", nil);
}

- (UIImage *)activityImage {
    return [UIImage imageNamed:@"activity_saveImage"];
}

- (BOOL)canPerformWithActivityItems:(NSArray *)activityItems {
    return YES;
}

- (void)prepareWithActivityItems:(NSArray *)activityItems {
    
}

- (void)performActivity {
    if ([MEGAReachabilityManager isReachableHUDIfNot]) {
        [[MEGASdkManager sharedMEGASdk] startDownloadNode:self.node localPath:NSTemporaryDirectory() delegate:self];
    }
}

+ (UIActivityCategory)activityCategory {
    return UIActivityCategoryAction;
}

#pragma mark - MEGATransferDelegate

- (void)onTransferStart:(MEGASdk *)api transfer:(MEGATransfer *)transfer {
    [SVProgressHUD showImage:[UIImage imageNamed:@"hudDownload"] status:NSLocalizedString(@"downloadStarted", @"Message shown when a download starts")];
}

- (void)onTransferFinish:(MEGASdk *)api transfer:(MEGATransfer *)transfer error:(MEGAError *)error {
    if (![[NSUserDefaults standardUserDefaults] boolForKey:@"IsSavePhotoToGalleryEnabled"]) {
        NSURL *imageURL = [NSURL fileURLWithPath:transfer.path];
        
        [[PHPhotoLibrary sharedPhotoLibrary] performChanges:^{
            PHAssetCreationRequest *assetCreationRequest = [PHAssetCreationRequest creationRequestForAsset];
            [assetCreationRequest addResourceWithType:PHAssetResourceTypePhoto fileURL:imageURL options:nil];
            
        } completionHandler:^(BOOL success, NSError * _Nullable nserror) {
            [[NSFileManager defaultManager] removeItemAtPath:transfer.path error:nil];
            if (nserror) {
                MEGALogError(@"Add asset to camera roll: %@ (Domain: %@ - Code:%ld)", nserror.localizedDescription, nserror.domain, nserror.code);
            }
        }];
    }
}

@end
