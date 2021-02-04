
#import "MEGARequestDelegate.h"

@interface MEGAGetFolderInfoRequestDelegate : NSObject <MEGARequestDelegate>

- (id)init NS_UNAVAILABLE;

- (instancetype)initWithCompletion:(void (^)(MEGARequest *request))completion;

@end
