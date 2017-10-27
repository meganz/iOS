
#import "MEGABaseRequestDelegate.h"

@interface MEGACreateFolderRequestDelegate : MEGABaseRequestDelegate

- (id)init NS_UNAVAILABLE;

- (instancetype)initWithCompletion:(void (^)(MEGARequest *request))completion;

@end
