
#import "SaveToCameraRollActivity.h"
#import "MEGASdkManager.h"
#import "MEGAReachabilityManager.h"
#import "SVProgressHUD.h"

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

- (void)image:(UIImage *)image didFinishSavingWithError:(NSError *)error contextInfo:(void *)contextInfo {
    if (!error) {
        NSString *imagePath = CFBridgingRelease(contextInfo);
        [[NSFileManager defaultManager] removeItemAtPath:imagePath error:nil];
    }
}

#pragma mark - MEGATransferDelegate

- (void)onTransferStart:(MEGASdk *)api transfer:(MEGATransfer *)transfer {
    [SVProgressHUD showImage:[UIImage imageNamed:@"hudDownload"] status:NSLocalizedString(@"downloadStarted", @"Message shown when a download starts")];
}

- (void)onTransferFinish:(MEGASdk *)api transfer:(MEGATransfer *)transfer error:(MEGAError *)error {
    if (![[NSUserDefaults standardUserDefaults] boolForKey:@"IsSavePhotoToGalleryEnabled"]) {
        UIImage *image = [UIImage imageWithContentsOfFile:transfer.path];
        dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_LOW, 0), ^(void){
            UIImageWriteToSavedPhotosAlbum(image, self, @selector(image:didFinishSavingWithError:contextInfo:), (void*)CFBridgingRetain(transfer.path));
        });
    }
}

@end
