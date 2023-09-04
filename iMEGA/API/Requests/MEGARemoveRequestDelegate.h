#import "MEGARequestDelegate.h"

@interface MEGARemoveRequestDelegate : NSObject <MEGARequestDelegate>

- (instancetype)initWithMode:(NSInteger)mode files:(NSUInteger)files folders:(NSUInteger)folders completion:(void (^)(void))completion;

@end
