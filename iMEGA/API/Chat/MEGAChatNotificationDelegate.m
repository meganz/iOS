
#import "MEGAChatNotificationDelegate.h"

#import "MEGALocalNotificationManager.h"
#import "MEGAStore.h"
#import "MessagesViewController.h"
#import "UIApplication+MNZCategory.h"

@implementation MEGAChatNotificationDelegate

#pragma mark - MEGAChatNotificationDelegate

- (void)onChatNotification:(MEGAChatSdk *)api chatId:(uint64_t)chatId message:(MEGAChatMessage *)message {
    MEGALogDebug(@"On chat %@ notification message %@", [MEGASdk base64HandleForUserHandle:chatId], message);
    
    [UIApplication sharedApplication].applicationIconBadgeNumber = api.unreadChats;
    
    if (UIApplication.sharedApplication.applicationState != UIApplicationStateBackground) {
        if ([UIApplication.mnz_visibleViewController isKindOfClass:[MessagesViewController class]] && message.status != MEGAChatMessageStatusSeen) {
            MessagesViewController *messagesVC = (MessagesViewController *) UIApplication.mnz_visibleViewController;
            if (messagesVC.chatRoom.chatId == chatId) {
                MEGALogDebug(@"The chat room %@ is opened, ignore notification", [MEGASdk base64HandleForHandle:chatId]);
                return;
            }
        }
        MEGAChatRoom *chatRoom = [api chatRoomForChatId:chatId];
        if (chatRoom && message) {
            MEGALocalNotificationManager *localNotificationManager = [[MEGALocalNotificationManager alloc] initWithChatRoom:chatRoom message:message silent:YES];
            [localNotificationManager processNotification];
        }
    }
}

@end
