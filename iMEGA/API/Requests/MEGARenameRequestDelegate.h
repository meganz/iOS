
#import "MEGARequestDelegate.h"

@interface MEGARenameRequestDelegate : NSObject <MEGARequestDelegate>

- (id)init NS_UNAVAILABLE;

- (instancetype)initWithCompletion:(void (^)(MEGARequest *request))completion;

@end
