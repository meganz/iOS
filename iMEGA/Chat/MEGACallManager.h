
#import <Foundation/Foundation.h>

@class MEGAChatCall;

@interface MEGACallManager : NSObject

- (void)startCall:(MEGAChatCall *)call;
- (void)endCall:(MEGAChatCall *)call;

- (void)addCall:(MEGAChatCall *)call;
- (void)removeCall:(MEGAChatCall *)call;
- (void)removeAllCalls;
- (MEGAChatCall *)callForUUID:(NSUUID *)uuid;

@end
