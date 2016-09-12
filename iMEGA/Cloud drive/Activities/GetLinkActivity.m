#import "GetLinkActivity.h"

#import "Helper.h"
#import "MEGAReachabilityManager.h"

#import "SVProgressHUD.h"

@interface GetLinkActivity ()

@property (strong, nonatomic) MEGANode *node;
@property (strong, nonatomic) NSArray *nodes;

@end

@implementation GetLinkActivity

- (instancetype)initWithNode:(MEGANode *)nodeCopy {
    _node = nodeCopy;
    
    return self;
}

- (instancetype)initWithNodes:(NSArray *)nodesArray {
    _nodes = nodesArray;
    
    return self;
}

- (NSString *)activityType {
    return @"GetLinkActivity";
}

- (NSString *)activityTitle {
    if ([self.nodes count] > 1) {
        return AMLocalizedString(@"getLinks", nil);
    }
    
    return AMLocalizedString(@"getLink", nil);
}

- (UIImage *)activityImage {
    return [UIImage imageNamed:@"activity_getLink"];
}

- (BOOL)canPerformWithActivityItems:(NSArray *)activityItems {
    return YES;
}

- (void)performActivity {
    if ([MEGAReachabilityManager isReachableHUDIfNot]) {
        [Helper setCopyToPasteboard:YES];
        
        if (self.nodes != nil) {
            for (MEGANode *n in self.nodes) {
                [[MEGASdkManager sharedMEGASdk] exportNode:n];
            }
        } else {
            [[MEGASdkManager sharedMEGASdk] exportNode:self.node];
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
