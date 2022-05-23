
#import <Foundation/Foundation.h>
#import <CallKit/CallKit.h>

#import "MEGACallManager.h"

@class TonePlayer;

@interface MEGAProviderDelegate : NSObject <CXProviderDelegate>

@property (nonatomic, readonly) BOOL isAudioSessionActive;
@property (getter=isOutgoingCall) BOOL outgoingCall;
@property(nonatomic, strong) TonePlayer *tonePlayer;

- (instancetype)initWithMEGACallManager:(MEGACallManager *)megaCallManager;

- (void)reportIncomingCallWithCallId:(uint64_t)callId chatId:(uint64_t)chatId completion:(void (^)(void))completion;

- (void)invalidateProvider;

@end
