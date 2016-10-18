#import <Foundation/Foundation.h>
#import "MEGAChatRoom.h"
#import "MEGAChatMessage.h"

@class MEGAChatSdk;

@protocol MEGAChatRoomDelegate <NSObject>

@optional

- (void)onChatRoomUpdate:(MEGAChatSdk *)api chat:(MEGAChatRoom *)chat;
- (void)onMessageLoaded:(MEGAChatSdk *)api message:(MEGAChatMessage *)message;
- (void)onMessageReceived:(MEGAChatSdk *)api message:(MEGAChatMessage *)message;
- (void)onMessageUpdate:(MEGAChatSdk *)api message:(MEGAChatMessage *)message;

@end
