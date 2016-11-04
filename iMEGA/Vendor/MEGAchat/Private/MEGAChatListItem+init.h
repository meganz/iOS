#import "MEGAChatListItem.h"
#import "megachatapi.h"

@interface MEGAChatListItem (init)

- (instancetype)initWithMegaChatListItem:(megachat::MegaChatListItem *)megaChatListItem cMemoryOwn:(BOOL)cMemoryOwn;
- (megachat::MegaChatListItem *)getCPtr;

@end
