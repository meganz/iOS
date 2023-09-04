#import "MEGARequestDelegate.h"

NS_ASSUME_NONNULL_BEGIN

@interface MEGAContactLinkCreateRequestDelegate : NSObject <MEGARequestDelegate>

- (id)init NS_UNAVAILABLE;

- (instancetype)initWithCompletion:(void (^)(MEGARequest *request))completion;

@end

NS_ASSUME_NONNULL_END
