#import "MEGARequestDelegate.h"

@interface MEGARemoveContactRequestDelegate : NSObject <MEGARequestDelegate>

- (instancetype)initWithCompletion:(void (^)(void))completion;

@end
