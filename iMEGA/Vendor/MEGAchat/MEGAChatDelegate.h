
#import <Foundation/Foundation.h>
#import "MEGAChatListItem.h"
#import "MEGAChatPresenceConfig.h"

@class MEGAChatSdk;

typedef NS_ENUM (NSInteger, MEGAChatInit);

@protocol MEGAChatDelegate <NSObject>

@optional

- (void)onChatListItemUpdate:(MEGAChatSdk *)api item:(MEGAChatListItem *)item;
- (void)onChatInitStateUpdate:(MEGAChatSdk *)api newState:(MEGAChatInit)newState;
- (void)onChatOnlineStatusUpdate:(MEGAChatSdk *)api status:(MEGAChatStatus)onlineStatus inProgress:(BOOL)inProgress;
- (void)onChatPresenceConfigUpdate:(MEGAChatSdk *)api presenceConfig:(MEGAChatPresenceConfig *)presenceConfig;

@end
