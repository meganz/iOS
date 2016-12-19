
#import <Foundation/Foundation.h>
#import "MEGAChatListItem.h"
#import "MEGAChatRoom.h"

@class MEGAChatSdk;

@protocol MEGAChatDelegate <NSObject>

@optional

- (void)onChatListItemUpdate:(MEGAChatSdk *)api item:(MEGAChatListItem *)item;
- (void)onChatInitStateUpdate:(MEGAChatSdk *)api newState:(NSInteger)newState;

@end
