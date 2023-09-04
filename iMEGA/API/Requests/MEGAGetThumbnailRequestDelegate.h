#import "MEGARequestDelegate.h"

NS_ASSUME_NONNULL_BEGIN

@interface MEGAGetThumbnailRequestDelegate : NSObject <MEGARequestDelegate>

- (instancetype)initWithCompletion:(void (^)(MEGARequest *request))completion;

@end

NS_ASSUME_NONNULL_END
