#import "MEGARequestDelegate.h"

NS_ASSUME_NONNULL_BEGIN

@interface MEGAMoveRequestDelegate : NSObject <MEGARequestDelegate>

- (instancetype)initToMoveToTheRubbishBinWithFiles:(NSUInteger)files folders:(NSUInteger)folders completion:(void (^)(void))completion;

@end

NS_ASSUME_NONNULL_END
