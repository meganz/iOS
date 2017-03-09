#import "RemoveLinkActivity.h"

#import "MEGAReachabilityManager.h"

#import "SVProgressHUD.h"

@interface RemoveLinkActivity ()

@property (strong, nonatomic) NSArray *nodes;

@end

@implementation RemoveLinkActivity

- (instancetype)initWithNodes:(NSArray *)nodesArray {
    _nodes = nodesArray;
    
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
            for (MEGANode *n in self.nodes) {
                [[MEGASdkManager sharedMEGASdk] disableExportNode:n];
            }
        }
    }
}

+ (UIActivityCategory)activityCategory {
    return UIActivityCategoryAction;
}

@end
