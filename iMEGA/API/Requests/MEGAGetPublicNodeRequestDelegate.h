
#import "MEGABaseRequestDelegate.h"

@interface MEGAGetPublicNodeRequestDelegate : MEGABaseRequestDelegate

@property (nonatomic) BOOL savePublicHandle;

- (id)init NS_UNAVAILABLE;

- (instancetype)initWithCompletion:(void (^)(MEGARequest *request, MEGAError *error))completion;

@end
