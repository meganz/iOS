
#import "UITableView+MNZCategory.h"

@implementation UITableView (MNZCategory)

- (void)mnz_performBatchUpdates:(void (^)(void))updates completion:(void (^ __nullable)(BOOL))completion {
    [self performBatchUpdates:updates completion:completion];
}

@end
