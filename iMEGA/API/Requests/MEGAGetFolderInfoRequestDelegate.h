
#import "MEGABaseRequestDelegate.h"

@interface MEGAGetFolderInfoRequestDelegate : MEGABaseRequestDelegate

- (id)init NS_UNAVAILABLE;

- (instancetype)initWithCompletion:(void (^)(MEGARequest *request))completion;

@end
