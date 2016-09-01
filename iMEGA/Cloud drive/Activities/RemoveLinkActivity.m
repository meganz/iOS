#import "RemoveLinkActivity.h"

#import "MEGAReachabilityManager.h"

#import "SVProgressHUD.h"

@interface RemoveLinkActivity ()

@property (strong, nonatomic) MEGANode *node;
@property (strong, nonatomic) NSArray *nodes;

@end

@implementation RemoveLinkActivity

- (instancetype)initWithNode:(MEGANode *)nodeCopy {
    _node = nodeCopy;
    
    return self;
}

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
        } else {
            [[MEGASdkManager sharedMEGASdk] disableExportNode:self.node];
        }
        
        if (([[[UIDevice currentDevice] systemVersion] compare:@"8.0" options:NSNumericSearch] != NSOrderedDescending)) {
            [self activityDidFinish:YES];
        }
    }
}

+ (UIActivityCategory)activityCategory {
    return UIActivityCategoryAction;
}

@end
