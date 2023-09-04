#import <Foundation/Foundation.h>

@class MEGAChatCall;

@interface MEGACallManager : NSObject

- (void)startCall:(MEGAChatCall *)call;
- (void)answerCall:(MEGAChatCall *)call;
- (void)endCallWithCallId:(uint64_t)callId chatId:(uint64_t)chatId;
- (void)muteUnmuteCallWithCallId:(uint64_t)callId chatId:(uint64_t)chatId muted:(BOOL)muted;

- (void)addCall:(MEGAChatCall *)call;
- (void)addCallWithCallId:(uint64_t)callId uuid:(NSUUID *)uuid;
- (void)removeCallByUUID:(NSUUID *)uuid;
- (void)removeAllCalls;
- (uint64_t)callIdForUUID:(NSUUID *)uuid;
- (uint64_t)chatIdForUUID:(NSUUID *)uuid;
- (NSUUID *)uuidForChatId:(uint64_t)chatId callId:(uint64_t)callId;


- (void)startCallWithChatId:(MEGAHandle)chatId;
- (void)answerCallWithChatId:(MEGAHandle)chatId;
- (void)addCallRemovedHandler:(void(^)(NSUUID *))handler;
- (void)removeCallRemovedHandler;
@end
