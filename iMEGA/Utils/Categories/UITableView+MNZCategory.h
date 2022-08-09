
#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface UITableView (MNZCategory)

- (void)mnz_performBatchUpdates:(void (^)(void))updates completion:(void (^ __nullable)(BOOL))completion;

@end

NS_ASSUME_NONNULL_END
