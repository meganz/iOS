
#import "SaveToCameraRollActivity.h"

#import "SVProgressHUD.h"

#import "MEGAReachabilityManager.h"
#import "MEGASdkManager.h"
#import "MEGANode+MNZCategory.h"
#import "NSFileManager+MNZCategory.h"

@interface SaveToCameraRollActivity () <MEGATransferDelegate>

@property (nonatomic, strong) MEGANode *node;

@end

@implementation SaveToCameraRollActivity


- (instancetype)initWithNode:(MEGANode *)node {
    self = [super init];
    if (self) {
        _node = node;
    }
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

- (void)performActivity {
    NSString *temporaryPath = [[NSTemporaryDirectory() stringByAppendingPathComponent:self.node.base64Handle] stringByAppendingPathComponent:self.node.name];
    NSString *temporaryFingerprint = [[MEGASdkManager sharedMEGASdk] fingerprintForFilePath:temporaryPath];
    if ([temporaryFingerprint isEqualToString:[[MEGASdkManager sharedMEGASdk] fingerprintForNode:self.node]]) {
        [self.node mnz_copyToGalleryFromTemporaryPath:temporaryPath];
    } else if ([MEGAReachabilityManager isReachableHUDIfNot]) {
        NSString *downloadsDirectory = [[NSFileManager defaultManager] downloadsDirectory];
        downloadsDirectory = [downloadsDirectory stringByReplacingOccurrencesOfString:[NSHomeDirectory() stringByAppendingString:@"/"] withString:@""];
        NSString *offlineNameString = [[MEGASdkManager sharedMEGASdkFolder] escapeFsIncompatible:self.node.name];
        NSString *localPath = [downloadsDirectory stringByAppendingPathComponent:offlineNameString];
        [[MEGASdkManager sharedMEGASdk] startDownloadNode:self.node localPath:localPath appData:@"SaveInPhotosApp" delegate:self];
    }
}

+ (UIActivityCategory)activityCategory {
    return UIActivityCategoryAction;
}

#pragma mark - MEGATransferDelegate

- (void)onTransferStart:(MEGASdk *)api transfer:(MEGATransfer *)transfer {
    [SVProgressHUD showImage:[UIImage imageNamed:@"hudDownload"] status:NSLocalizedString(@"downloadStarted", @"Message shown when a download starts")];
}

@end
