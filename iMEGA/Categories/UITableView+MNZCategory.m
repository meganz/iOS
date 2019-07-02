
#import "UITableView+MNZCategory.h"

@implementation UITableView (MNZCategory)

- (void)mnz_performBatchUpdates:(void (^)(void))updates completion:(void (^ __nullable)(BOOL))completion {
    if (@available(iOS 11.0, *)) {
        [self performBatchUpdates:updates completion:completion];
    } else {
        [self beginUpdates];
        updates();
        [self endUpdates];
        if (completion) {
            completion(YES);
        }
    }
}

@end
