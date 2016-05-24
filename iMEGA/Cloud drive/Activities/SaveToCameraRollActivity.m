
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
    return AMLocalizedString(@"saveToCameraRollActivity", nil);
}

- (UIImage *)activityImage {
    return [UIImage imageNamed:@"offlineIcon"];
}

- (BOOL)canPerformWithActivityItems:(NSArray *)activityItems {
    return YES;
}

- (void)prepareWithActivityItems:(NSArray *)activityItems {
    
}

- (void)performActivity {
    if ([MEGAReachabilityManager isReachable]) {
        [[MEGASdkManager sharedMEGASdk] startDownloadNode:self.node localPath:NSTemporaryDirectory() delegate:self];
    } else {
        [SVProgressHUD showImage:[UIImage imageNamed:@"hudForbidden"] status:AMLocalizedString(@"noInternetConnection", nil)];
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

- (void)onTransferFinish:(MEGASdk *)api transfer:(MEGATransfer *)transfer error:(MEGAError *)error {
    UIImage *image = [UIImage imageWithContentsOfFile:transfer.path];
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_LOW, 0), ^(void){
        UIImageWriteToSavedPhotosAlbum(image, self, @selector(image:didFinishSavingWithError:contextInfo:), (void*)CFBridgingRetain(transfer.path));
    });
}

@end
