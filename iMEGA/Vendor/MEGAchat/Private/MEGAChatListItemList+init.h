#import "MEGAChatListItemList.h"
#import "megachatapi.h"

@interface MEGAChatListItemList (init)


- (instancetype)initWithMegaChatListItemList:(megachat::MegaChatListItemList *)megaChatListItemList cMemoryOwn:(BOOL)cMemoryOwn;
- (megachat::MegaChatListItemList *)getCPtr;

@end
