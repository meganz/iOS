
#import <Foundation/Foundation.h>
#import <CallKit/CallKit.h>

#import "MEGACallManager.h"

@class MEGAChatCall;

@interface MEGAProviderDelegate : NSObject <CXProviderDelegate>

- (instancetype)initWithMEGACallManager:(MEGACallManager *)megaCallManager;

- (void)reportIncomingCallWithCallId:(uint64_t)callId chatId:(uint64_t)chatId;

@end
