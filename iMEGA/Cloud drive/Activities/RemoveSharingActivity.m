#import "RemoveSharingActivity.h"

#import "MEGAReachabilityManager.h"
#import "MEGASdkManager.h"
#import "MEGAShareRequestDelegate.h"

@interface RemoveSharingActivity ()

@property (strong, nonatomic) NSArray *nodes;
@property (nonatomic) NSUInteger sharesCount;

@end

@implementation RemoveSharingActivity

- (instancetype)initWithNodes:(NSArray *)nodesArray {
    self = [super init];
    if (self) {
        _nodes = nodesArray;
    }
    
    return self;
}

- (NSString *)activityType {
    return @"RemoveSharingActivity";
}

- (NSString *)activityTitle {
    return AMLocalizedString(@"removeSharing", @"Alert title shown on the Shared Items section when you want to remove 1 share");
}

- (UIImage *)activityImage {
    return [UIImage imageNamed:@"activity_removeSharing"];
}

- (BOOL)canPerformWithActivityItems:(NSArray *)activityItems {
    return YES;
}

- (void)prepareWithActivityItems:(NSArray *)activityItems {
    if (self.nodes != nil) {
        for (MEGANode *node in self.nodes) {
            MEGAShareList *shareList = [[MEGASdkManager sharedMEGASdk] outSharesForNode:node];
            NSUInteger count = shareList.size.unsignedIntegerValue;
            self.sharesCount += count;
        }
    }
}

- (void)performActivity {
    if ([MEGAReachabilityManager isReachableHUDIfNot]) {
        if (self.nodes != nil) {
            MEGAShareRequestDelegate *shareRequestDelegate = [[MEGAShareRequestDelegate alloc] initToChangePermissionsWithNumberOfRequests:self.sharesCount completion:nil];
            for (MEGANode *node in self.nodes) {
                MEGAShareList *shareList = [[MEGASdkManager sharedMEGASdk] outSharesForNode:node];
                for (NSUInteger i = 0; i < shareList.size.unsignedIntegerValue; i++) {
                    MEGAShare *share = [shareList shareAtIndex:i];
                    [[MEGASdkManager sharedMEGASdk] shareNode:node withEmail:share.user level:MEGAShareTypeAccessUnkown delegate:shareRequestDelegate];
                }
            }
        }
    }
}

+ (UIActivityCategory)activityCategory {
    return UIActivityCategoryAction;
}

@end
