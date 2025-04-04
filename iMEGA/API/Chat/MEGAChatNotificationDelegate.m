#import "MEGAChatNotificationDelegate.h"

#import "MEGALocalNotificationManager.h"
#import "MEGAStore.h"
#import "UIApplication+MNZCategory.h"
#import "MEGA-Swift.h"
@import MEGAAppSDKRepo;

@implementation MEGAChatNotificationDelegate

#pragma mark - MEGAChatNotificationDelegate

- (void)onChatNotification:(MEGAChatSdk *)api chatId:(uint64_t)chatId message:(MEGAChatMessage *)message {
    MEGALogDebug(@"[Notification] On chat %@ message %@", [MEGASdk base64HandleForUserHandle:chatId], message);
    
    if (MEGASdk.isGuest) {
        return;
    }
    
    MOMessage *moMessage = [MEGAStore.shareInstance fetchMessageWithChatId:chatId messageId:message.messageId];
    if (moMessage) {
        [MEGAStore.shareInstance deleteMessage:moMessage];
        MEGALogDebug(@"[Notification] Already notified")
        return;
    }
    
    if (UIApplication.sharedApplication.applicationState != UIApplicationStateBackground || message.type == MEGAChatMessageTypeCallEnded) {
        if ([UIApplication.mnz_visibleViewController isKindOfClass:[ChatViewController class]] && message.status != MEGAChatMessageStatusSeen) {
            ChatViewController *chatViewController = (ChatViewController *) UIApplication.mnz_visibleViewController;
            if (chatViewController.chatId == chatId) {
                MEGALogDebug(@"[Chat notification] The chat room %@ is opened, ignore notification", [MEGASdk base64HandleForHandle:chatId]);
                return;
            }
        }
        MEGAChatRoom *chatRoom = [api chatRoomForChatId:chatId];
        
        if (chatRoom && message) {
            MEGALocalNotificationManager *localNotificationManager = [[MEGALocalNotificationManager alloc] initWithChatRoom:chatRoom message:message];
            [localNotificationManager processNotification];
        }
    }
}

@end
