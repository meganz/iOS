#import "MEGARequestDelegate.h"

@interface MEGAGetPublicNodeRequestDelegate : NSObject <MEGARequestDelegate>

@property (nonatomic) BOOL savePublicHandle;

- (id)init NS_UNAVAILABLE;

- (instancetype)initWithCompletion:(void (^)(MEGARequest *request, MEGAError *error))completion;

@end
