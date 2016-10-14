#import "MEGAChatPeerList.h"
#import "megachatapi.h"

@interface MEGAChatPeerList (init)

- (instancetype)initWithMegaChatPeerList:(megachat::MegaChatPeerList *)megaChatPeerList cMemoryOwn:(BOOL)cMemoryOwn;
- (megachat::MegaChatPeerList *)getCPtr;

@end

