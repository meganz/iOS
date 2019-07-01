
#import "MEGABaseRequestDelegate.h"

NS_ASSUME_NONNULL_BEGIN

@interface MEGAGetRegisteredContactsRequestDelegate : MEGABaseRequestDelegate

- (instancetype)initWithCompletion:(void (^)(MEGARequest *request, MEGAError *error))completion;

@end

NS_ASSUME_NONNULL_END
