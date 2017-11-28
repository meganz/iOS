
#import "MEGABaseRequestDelegate.h"

@interface MEGARemoveRequestDelegate : MEGABaseRequestDelegate

- (instancetype)initWithMode:(NSInteger)mode files:(NSUInteger)files folders:(NSUInteger)folders completion:(void (^)(void))completion;

@end
