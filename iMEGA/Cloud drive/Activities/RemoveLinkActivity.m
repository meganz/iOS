#import "RemoveLinkActivity.h"

#import "MEGAReachabilityManager.h"

#import "SVProgressHUD.h"

@interface RemoveLinkActivity () <MEGARequestDelegate>

@property (strong, nonatomic) NSArray *nodes;
@property (nonatomic) NSUInteger pending;

@end

@implementation RemoveLinkActivity

- (instancetype)initWithNodes:(NSArray *)nodesArray {
    self = [super init];
    if (self) {
        _nodes = nodesArray;
    }
    
    return self;
}

- (NSString *)activityType {
    return @"RemoveLinkActivity";
}

- (NSString *)activityTitle {
    if ([self.nodes count] > 1) {
        return AMLocalizedString(@"removeLinks", nil);
    }
    
    return AMLocalizedString(@"removeLink", nil);
}

- (UIImage *)activityImage {
    return [UIImage imageNamed:@"activity_removeLink"];
}

- (BOOL)canPerformWithActivityItems:(NSArray *)activityItems {
    return YES;
}

- (void)performActivity {
    if ([MEGAReachabilityManager isReachableHUDIfNot]) {
        if (self.nodes != nil) {
            self.pending = self.nodes.count;
            for (MEGANode *n in self.nodes) {
                [[MEGASdkManager sharedMEGASdk] disableExportNode:n delegate:self];
            }
        }
    }
}

+ (UIActivityCategory)activityCategory {
    return UIActivityCategoryAction;
}

#pragma mark - MEGARequestDelegate

- (void)onRequestStart:(MEGASdk *)api request:(MEGARequest *)request {
    if ([request type] == MEGARequestTypeExport && ![request access]) {
        [SVProgressHUD show];
    }
}

- (void)onRequestFinish:(MEGASdk *)api request:(MEGARequest *)request error:(MEGAError *)error {
    if ([error type]) {
        [SVProgressHUD showErrorWithStatus:error.name];
        return;
    }
    
    if ([request type] == MEGARequestTypeExport && ![request access] && --self.pending==0) {
        NSString *status = self.nodes.count > 1 ? AMLocalizedString(@"linksRemoved", @"Message shown when the links to files and folders have been removed") : AMLocalizedString(@"linkRemoved", @"Message shown when the links to a file or folder has been removed");
        [SVProgressHUD showSuccessWithStatus:status];
    }
}

@end
