
#import "MEGABaseRequestDelegate.h"

@interface MEGACreateFolderRequestDelegate : MEGABaseRequestDelegate

- (id)init NS_UNAVAILABLE;

- (instancetype)initWithCompletion:(void (^)(void))completion;

@end
