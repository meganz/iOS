#import "MEGAChatPresenceConfig.h"
#import "megachatapi.h"

@interface MEGAChatPresenceConfig (init)

- (instancetype)initWithMegaChatPresenceConfig:(megachat::MegaChatPresenceConfig *)megaChatPresenceConfig cMemoryOwn:(BOOL)cMemoryOwn;
- (megachat::MegaChatPresenceConfig *)getCPtr;

@end
