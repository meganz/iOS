
#import "MEGABaseRequestDelegate.h"

NS_ASSUME_NONNULL_BEGIN

@interface MEGAContactLinkCreateRequestDelegate : MEGABaseRequestDelegate

- (id)init NS_UNAVAILABLE;

- (instancetype)initWithCompletion:(void (^)(MEGARequest *request))completion;

@end

NS_ASSUME_NONNULL_END
