#import "MEGARequestDelegate.h"

NS_ASSUME_NONNULL_BEGIN

@interface MEGAGenericRequestDelegate : NSObject <MEGARequestDelegate>

- (id)init NS_UNAVAILABLE;

- (instancetype)initWithStart:(void (^)(MEGARequest *request))start completion:(void (^)(MEGARequest *request, MEGAError *error))completion;
- (instancetype)initWithCompletion:(void (^)(MEGARequest *request, MEGAError *error))completion;

@end

NS_ASSUME_NONNULL_END
