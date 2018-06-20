
#import "MEGABaseRequestDelegate.h"

@interface MEGALoginToFolderLinkRequestDelegate : MEGABaseRequestDelegate

- (instancetype)initWithCompletion:(void (^)(MEGARequest *request))completion;

@end
