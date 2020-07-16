
#import "MEGAChatNotificationDelegate.h"

#import "MEGALocalNotificationManager.h"
#import "MEGAStore.h"
#import "MessagesViewController.h"
#import "UIApplication+MNZCategory.h"

@implementation MEGAChatNotificationDelegate

#pragma mark - MEGAChatNotificationDelegate

- (void)onChatNotification:(MEGAChatSdk *)api chatId:(uint64_t)chatId message:(MEGAChatMessage *)message {
    MEGALogDebug(@"[Notification] On chat %@ message %@", [MEGASdk base64HandleForUserHandle:chatId], message);
    
    [UIApplication sharedApplication].applicationIconBadgeNumber = api.unreadChats;
    
    MOMessage *moMessage = [MEGAStore.shareInstance fetchMessageWithChatId:chatId messageId:message.messageId];
    if (moMessage) {
        [MEGAStore.shareInstance deleteMessage:moMessage];
        MEGALogDebug(@"[Notification] Already notified")
        return;
    }
    
    if (UIApplication.sharedApplication.applicationState != UIApplicationStateBackground || message.type == MEGAChatMessageTypeCallEnded) {
        if ([UIApplication.mnz_visibleViewController isKindOfClass:[MessagesViewController class]] && message.status != MEGAChatMessageStatusSeen) {
            MessagesViewController *messagesVC = (MessagesViewController *) UIApplication.mnz_visibleViewController;
            if (messagesVC.chatRoom.chatId == chatId) {
                MEGALogDebug(@"[Notification] The chat room %@ is opened, ignore notification", [MEGASdk base64HandleForHandle:chatId]);
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
