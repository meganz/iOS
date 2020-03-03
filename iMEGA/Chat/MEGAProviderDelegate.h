
#import <Foundation/Foundation.h>
#import <CallKit/CallKit.h>

#import "MEGACallManager.h"


@interface MEGAProviderDelegate : NSObject <CXProviderDelegate>

- (instancetype)initWithMEGACallManager:(MEGACallManager *)megaCallManager;

- (void)reportIncomingCallWithCallId:(uint64_t)callId chatId:(uint64_t)chatId;

@end
