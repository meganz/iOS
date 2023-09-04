#import "MEGARequestDelegate.h"

@interface MEGAShareRequestDelegate : NSObject <MEGARequestDelegate>

- (instancetype)initWithNumberOfRequests:(NSUInteger)numberOfRequests completion:(void (^)(void))completion;
- (instancetype)initToChangePermissionsWithNumberOfRequests:(NSUInteger)numberOfRequests completion:(void (^)(void))completion;

@end
