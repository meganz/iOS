#import "RemoveLinkActivity.h"

#import "SVProgressHUD.h"

#import "MEGAExportRequestDelegate.h"
#import "MEGAReachabilityManager.h"

@interface RemoveLinkActivity ()

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
            
            MEGAExportRequestDelegate *requestDelegate = [[MEGAExportRequestDelegate alloc] initWithCompletion:^(MEGARequest *request) {
                if (--self.pending==0) {
                    NSString *status = self.nodes.count > 1 ? AMLocalizedString(@"linksRemoved", @"Message shown when the links to files and folders have been removed") : AMLocalizedString(@"linkRemoved", @"Message shown when the links to a file or folder has been removed");
                    [SVProgressHUD showSuccessWithStatus:status];
                }
            } multipleLinks:self.nodes.count > 1];
            
            for (MEGANode *n in self.nodes) {
                [[MEGASdkManager sharedMEGASdk] disableExportNode:n delegate:requestDelegate];
            }
        }
    }
}

+ (UIActivityCategory)activityCategory {
    return UIActivityCategoryAction;
}

@end
