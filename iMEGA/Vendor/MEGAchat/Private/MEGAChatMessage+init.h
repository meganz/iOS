#import "MEGAChatMessage.h"
#import "megachatapi.h"

@interface MEGAChatMessage (init)

- (instancetype)initWithMegaChatMessage:(megachat::MegaChatMessage *)megaChatMessage cMemoryOwn:(BOOL)cMemoryOwn;
- (megachat::MegaChatMessage *)getCPtr;

@end
