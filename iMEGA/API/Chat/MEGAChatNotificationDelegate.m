
#import "MEGAChatNotificationDelegate.h"

#import <UserNotifications/UserNotifications.h>

#import "Helper.h"
#import "MessagesViewController.h"
#import "MEGAGetThumbnailRequestDelegate.h"
#import "MEGAStore.h"
#import "NSString+MNZCategory.h"
#import "UIApplication+MNZCategory.h"

@implementation MEGAChatNotificationDelegate

#pragma mark - MEGAChatNotificationDelegate

- (void)onChatNotification:(MEGAChatSdk *)api chatId:(uint64_t)chatId message:(MEGAChatMessage *)message {
    MEGALogDebug(@"On chat %@ notification message %@", [MEGASdk base64HandleForUserHandle:chatId], message);
    
    [UIApplication sharedApplication].applicationIconBadgeNumber = api.unreadChats;
    
    if ([UIApplication.mnz_visibleViewController isKindOfClass:[MessagesViewController class]]) {
        MessagesViewController *messagesVC = (MessagesViewController *) UIApplication.mnz_visibleViewController;
        if (messagesVC.chatRoom.chatId == chatId && [UIApplication sharedApplication].applicationState == UIApplicationStateActive) {
            MEGALogDebug(@"The chat room %@ is opened, ignore notification", [MEGASdk base64HandleForHandle:chatId]);
            return;
        }
    }
    
    if (@available(iOS 10.0, *)) {
        if (message) {
            if (message.status == MEGAChatMessageStatusNotSeen) {
                if  (message.type == MEGAChatMessageTypeNormal || message.type == MEGAChatMessageTypeContact || message.type == MEGAChatMessageTypeAttachment) {
                    UNUserNotificationCenter *center = [UNUserNotificationCenter currentNotificationCenter];
                    if (message.deleted) {
                        [center getDeliveredNotificationsWithCompletionHandler:^(NSArray<UNNotification *> *notifications) {
                            NSString *notificationIdentifier = [NSString stringWithFormat:@"%@%@", [MEGASdk base64HandleForUserHandle:chatId], [MEGASdk base64HandleForUserHandle:message.messageId]];
                            for (UNNotification *notification in notifications) {
                                if ([notificationIdentifier isEqualToString:notification.request.identifier]) {
                                    [center removeDeliveredNotificationsWithIdentifiers:@[notification.request.identifier]];
                                    break;
                                }
                            }
                        }];
                        [center getPendingNotificationRequestsWithCompletionHandler:^(NSArray<UNNotificationRequest *> * _Nonnull requests) {
                            NSString *notificationIdentifier = [NSString stringWithFormat:@"%@%@", [MEGASdk base64HandleForUserHandle:chatId], [MEGASdk base64HandleForUserHandle:message.messageId]];
                            for (UNNotificationRequest *request in requests) {
                                if ([notificationIdentifier isEqualToString:request.identifier]) {
                                    [center removePendingNotificationRequestsWithIdentifiers:@[request.identifier]];
                                    break;
                                }
                            }
                        }];
                    } else {
                        MEGAChatRoom *chatRoom = [api chatRoomForChatId:chatId];
                        UNMutableNotificationContent *content = [UNMutableNotificationContent new];
                        
                        content.categoryIdentifier = @"nz.mega.chat.message";
                        UNTimeIntervalNotificationTrigger *trigger = [UNTimeIntervalNotificationTrigger triggerWithTimeInterval:1 repeats:NO];
                        NSString *identifier = [NSString stringWithFormat:@"%@%@", [MEGASdk base64HandleForUserHandle:chatRoom.chatId], [MEGASdk base64HandleForUserHandle:message.messageId]];
                        
                        content.userInfo = @{@"chatId" : @(chatId)};
                        content.title = chatRoom.title;
                        if (chatRoom.isGroup) {
                            MOUser *user = [[MEGAStore shareInstance] fetchUserWithUserHandle:message.userHandle];
                            content.subtitle = user.fullName;
                        }
                        
                        NSString *body;
                        BOOL waitForThumbnail = NO;
                        if (message.type == MEGAChatMessageTypeContact) {
                            if(message.usersCount == 1) {
                                body = [NSString stringWithFormat:@"👤 %@", [message userNameAtIndex:0]];
                            } else {
                                body = [message userNameAtIndex:0];
                                for (NSUInteger i = 1; i < message.usersCount; i++) {
                                    body = [body stringByAppendingString:[NSString stringWithFormat:@", %@", [message userNameAtIndex:i]]];
                                }
                            }
                        } else if (message.type == MEGAChatMessageTypeAttachment) {
                            MEGANodeList *nodeList = message.nodeList;
                            if(nodeList) {
                                if (nodeList.size.integerValue == 1) {
                                    MEGANode *node = [nodeList nodeAtIndex:0];
                                    
                                    if (node.hasThumbnail) {
                                        if (node.name.mnz_isVideoPathExtension) {
                                            body = [NSString stringWithFormat:@"📹 %@", node.name];
                                        } else if (node.name.mnz_isImagePathExtension) {
                                            body = [NSString stringWithFormat:@"📷 %@", node.name];
                                        } else {
                                            body = [NSString stringWithFormat:@"📄 %@", node.name];
                                        }
                                        
                                        waitForThumbnail = YES;
                                        NSString *thumbnailFilePath = [Helper pathForNode:node inSharedSandboxCacheDirectory:@"thumbnailsV3"];
                                        MEGAGetThumbnailRequestDelegate *getThumbnailRequestDelegate = [[MEGAGetThumbnailRequestDelegate alloc] initWithCompletion:^(MEGARequest *request) {
                                            NSError *error;
                                            if (![[NSFileManager defaultManager] createSymbolicLinkAtPath:[request.file stringByAppendingPathExtension:@"jpg"] withDestinationPath:request.file error:&error]) {
                                                MEGALogError(@"Create symbolic link at path failed %@", error);
                                            }
                                            NSURL *fileURL = [NSURL fileURLWithPath:[request.file stringByAppendingPathExtension:@"jpg"]];
                                            UNNotificationAttachment *notificationAttachment = [UNNotificationAttachment attachmentWithIdentifier:node.base64Handle URL:fileURL options:nil error:&error];
                                            
                                            content.body = body;
                                            content.sound = ([UIApplication sharedApplication].applicationState != UIApplicationStateActive) ? [UNNotificationSound defaultSound] : nil;
                                            
                                            if (!error) {
                                                content.attachments = @[notificationAttachment];
                                            }
                                            UNNotificationRequest *notificationRequest = [UNNotificationRequest requestWithIdentifier:identifier content:content trigger:trigger];
                                            [center addNotificationRequest:notificationRequest withCompletionHandler:^(NSError * _Nullable error) {
                                                if (error) {
                                                    MEGALogError(@"Add NotificationRequest failed with error: %@", error);
                                                }
                                            }];
                                        }];
                                        [[MEGASdkManager sharedMEGASdk] getThumbnailNode:node destinationFilePath:thumbnailFilePath delegate:getThumbnailRequestDelegate];
                                    } else {
                                        body = [NSString stringWithFormat:@"📄 %@", node.name];
                                    }
                                }
                            }
                        } else {
                            body = message.content;
                        }
                                                
                        if (!waitForThumbnail) {
                            if (message.isEdited) {
                                content.body = [NSString stringWithFormat:@"%@ %@", message.content, AMLocalizedString(@"edited", nil)];
                                content.sound = nil;
                            } else {
                                content.body = body;
                                content.sound = [UNNotificationSound defaultSound];
                            }
                            
                            if ([UIApplication sharedApplication].applicationState == UIApplicationStateActive) {
                                content.sound = nil;
                            }
                            UNNotificationRequest *request = [UNNotificationRequest requestWithIdentifier:identifier content:content trigger:trigger];
                            [center addNotificationRequest:request withCompletionHandler:^(NSError * _Nullable error) {
                                if (error) {
                                    MEGALogError(@"Add NotificationRequest failed with error: %@", error);
                                }
                            }];
                        }
                    }
                    
                } else if (message.type == MEGAChatMessageTypeTruncate) {
                    UNUserNotificationCenter *center = [UNUserNotificationCenter currentNotificationCenter];
                    [center getDeliveredNotificationsWithCompletionHandler:^(NSArray<UNNotification *> *notifications) {
                        NSString *base64ChatId = [NSString stringWithFormat:@"%@", [MEGASdk base64HandleForUserHandle:chatId]];
                        for (UNNotification *notification in notifications) {
                            if ([notification.request.identifier containsString:base64ChatId]) {
                                [center removeDeliveredNotificationsWithIdentifiers:@[notification.request.identifier]];
                            }
                        }
                    }];
                    
                    [center getPendingNotificationRequestsWithCompletionHandler:^(NSArray<UNNotificationRequest *> * _Nonnull requests) {
                        NSString *base64ChatId = [NSString stringWithFormat:@"%@", [MEGASdk base64HandleForUserHandle:chatId]];
                        for (UNNotificationRequest *request in requests) {
                            if ([request.identifier containsString:base64ChatId]) {
                                [center removePendingNotificationRequestsWithIdentifiers:@[request.identifier]];
                            }
                        }
                    }];
                }
            } else {
                UNUserNotificationCenter *center = [UNUserNotificationCenter currentNotificationCenter];
                [center getDeliveredNotificationsWithCompletionHandler:^(NSArray<UNNotification *> *notifications) {
                    NSString *notificationIdentifier = [NSString stringWithFormat:@"%@%@", [MEGASdk base64HandleForUserHandle:chatId], [MEGASdk base64HandleForUserHandle:message.messageId]];
                    for (UNNotification *notification in notifications) {
                        if ([notificationIdentifier isEqualToString:notification.request.identifier]) {
                            [center removeDeliveredNotificationsWithIdentifiers:@[notification.request.identifier]];
                            break;
                        }
                    }
                }];
                [center getPendingNotificationRequestsWithCompletionHandler:^(NSArray<UNNotificationRequest *> * _Nonnull requests) {
                    NSString *notificationIdentifier = [NSString stringWithFormat:@"%@%@", [MEGASdk base64HandleForUserHandle:chatId], [MEGASdk base64HandleForUserHandle:message.messageId]];
                    for (UNNotificationRequest *request in requests) {
                        if ([notificationIdentifier isEqualToString:request.identifier]) {
                            [center removePendingNotificationRequestsWithIdentifiers:@[request.identifier]];
                            break;
                        }
                    }
                }];
            }
        }
    }
}

@end
