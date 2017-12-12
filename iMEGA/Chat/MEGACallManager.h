
#import <Foundation/Foundation.h>
#import "MEGAChatCall+MNZCategory.h"

@interface MEGACallManager : NSObject

- (void)startCall:(MEGAChatCall *)call email:(NSString *)email;
- (void)endCall:(MEGAChatCall *)call;

- (void)addCall:(MEGAChatCall *)call;
- (void)removeCallByUUID:(NSUUID *)uuid;
- (void)removeAllCalls;
- (MEGAChatCall *)callForUUID:(NSUUID *)uuid;

@end
