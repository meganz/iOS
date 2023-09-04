#import "MEGARequestDelegate.h"

@interface MEGALoginToFolderLinkRequestDelegate : NSObject <MEGARequestDelegate>

- (instancetype)initWithCompletion:(void (^)(MEGARequest *request))completion;

@end
