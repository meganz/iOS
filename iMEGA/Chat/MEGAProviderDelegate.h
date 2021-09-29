
#import <Foundation/Foundation.h>
#import <CallKit/CallKit.h>

#import "MEGACallManager.h"


@interface MEGAProviderDelegate : NSObject <CXProviderDelegate>

@property (nonatomic, readonly) BOOL isAudioSessionActive;

- (instancetype)initWithMEGACallManager:(MEGACallManager *)megaCallManager;

- (void)reportIncomingCallWithCallId:(uint64_t)callId chatId:(uint64_t)chatId completion:(void (^)(void))completion;

- (void)invalidateProvider;

@end
