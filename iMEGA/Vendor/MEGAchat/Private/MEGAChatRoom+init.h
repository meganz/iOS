#import "MEGAChatRoom.h"
#import "megachatapi.h"

@interface MEGAChatRoom (init)

- (instancetype)initWithMegaChatRoom:(megachat::MegaChatRoom *)megaChatRoom cMemoryOwn:(BOOL)cMemoryOwn;
- (megachat::MegaChatRoom *)getCPtr;

@end
