
#import "MEGABaseRequestDelegate.h"

@interface MEGAShareRequestDelegate : MEGABaseRequestDelegate

- (instancetype)initWithNumberOfRequests:(NSUInteger)numberOfRequests completion:(void (^)(void))completion;
- (instancetype)initToChangePermissionsWithNumberOfRequests:(NSUInteger)numberOfRequests completion:(void (^)(void))completion;

@end
