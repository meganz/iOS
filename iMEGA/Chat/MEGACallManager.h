
#import <Foundation/Foundation.h>

@class MEGAChatCall;

@interface MEGACallManager : NSObject

- (void)startCall:(MEGAChatCall *)call;
- (void)endCall:(MEGAChatCall *)call;

- (void)addCall:(MEGAChatCall *)call;
- (void)addCallWithCallId:(uint64_t)callId uuid:(NSUUID *)uuid;
- (void)removeCall:(MEGAChatCall *)call;
- (void)removeAllCalls;
- (uint64_t)callForUUID:(NSUUID *)uuid;

@end
