#import "MEGAChatRoomList.h"
#import "megachatapi.h"

@interface MEGAChatRoomList (init)

- (instancetype)initWithMegaChatRoomList:(megachat::MegaChatRoomList *)megaChatRoomList cMemoryOwn:(BOOL)cMemoryOwn;
- (megachat::MegaChatRoomList *)getCPtr;

@end
