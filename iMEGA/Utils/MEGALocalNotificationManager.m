
#import "MEGALocalNotificationManager.h"

#import "LocalizationSystem.h"

#ifndef MNZ_APP_EXTENSION
#import "Helper.h"
#import "MEGAGetThumbnailRequestDelegate.h"
#endif

#import "MEGASdkManager.h"
#import "MEGAStore.h"
#import "NSString+MNZCategory.h"

@interface MEGALocalNotificationManager ()

@property (nonatomic) MEGAChatMessage *message;
@property (nonatomic) MEGAChatRoom *chatRoom;
@property (nonatomic, getter=isSilent) BOOL silent;

@end

@implementation MEGALocalNotificationManager

- (instancetype)initWithChatRoom:(MEGAChatRoom *)chatRoom message:(MEGAChatMessage *)message silent:(BOOL)silent {
    self = [super init];
    
    if (self) {
        _chatRoom = chatRoom;
        _message = message;
        _silent = silent;
    }
    
    return self;
}

#ifndef MNZ_APP_EXTENSION

- (void)processNotification {
    if (self.message.status == MEGAChatMessageStatusNotSeen) {
        if  (self.message.type == MEGAChatMessageTypeNormal || self.message.type == MEGAChatMessageTypeContact || self.message.type == MEGAChatMessageTypeAttachment || self.message.containsMeta.type == MEGAChatContainsMetaTypeGeolocation || self.message.type == MEGAChatMessageTypeVoiceClip) {
            if (self.message.deleted) {
                [self removePendingAndDeliveredNotificationForMessage];
            } else {
                UNUserNotificationCenter *center = [UNUserNotificationCenter currentNotificationCenter];
                
                UNMutableNotificationContent *content = [UNMutableNotificationContent new];
                content.categoryIdentifier = @"nz.mega.chat.message";
                content.userInfo = @{@"chatId" : @(self.chatRoom.chatId), @"msgId" : @(self.message.messageId)};
                content.title = self.chatRoom.title;
                content.sound = nil;
                content.body = [self bodyString];
                if (self.chatRoom.isGroup) {
                    content.subtitle = [self displayName];
                }
                
                content.threadIdentifier = [MEGASdk base64HandleForUserHandle:self.chatRoom.chatId] ?: @"";
                if (@available(iOS 12.0, *)) {
                    content.summaryArgument = self.chatRoom.title;
                }
                
                UNTimeIntervalNotificationTrigger *trigger = [UNTimeIntervalNotificationTrigger triggerWithTimeInterval:1 repeats:NO];
                NSString *identifier = [NSString stringWithFormat:@"%@%@", [MEGASdk base64HandleForUserHandle:self.chatRoom.chatId], [MEGASdk base64HandleForUserHandle:self.message.messageId]];
                
                BOOL waitForThumbnail = NO;
                if (self.message.type == MEGAChatMessageTypeAttachment) {
                    MEGANodeList *nodeList = self.message.nodeList;
                    if (nodeList) {
                        if (nodeList.size.integerValue == 1) {
                            MEGANode *node = [nodeList nodeAtIndex:0];
                            if (node.hasThumbnail) {
                                waitForThumbnail = YES;
                                NSString *thumbnailFilePath = [Helper pathForNode:node inSharedSandboxCacheDirectory:@"thumbnailsV3"];
                                MEGAGetThumbnailRequestDelegate *getThumbnailRequestDelegate = [[MEGAGetThumbnailRequestDelegate alloc] initWithCompletion:^(MEGARequest *request) {
                                    UNNotificationAttachment *notificationAttachment = [self notificationAttachmentFor:request.file withIdentifier:node.base64Handle];
                                    if (notificationAttachment) {
                                        content.attachments = @[notificationAttachment];
                                    }
                                    UNNotificationRequest *notificationRequest = [UNNotificationRequest requestWithIdentifier:identifier content:content trigger:trigger];
                                    [center addNotificationRequest:notificationRequest withCompletionHandler:^(NSError * _Nullable error) {
                                        dispatch_async(dispatch_get_main_queue(), ^{
                                            if (error) {
                                                MEGALogError(@"[Chat notification] Add NotificationRequest failed with error: %@", error);
                                            } else {
                                                MOMessage *moMessage = [MEGAStore.shareInstance fetchMessageWithChatId:self.chatRoom.chatId messageId:self.message.messageId];
                                                if (moMessage) {
                                                    [MEGAStore.shareInstance deleteMessage:moMessage];
                                                } else {
                                                    [MEGAStore.shareInstance insertMessage:self.message.messageId chatId:self.chatRoom.chatId];
                                                }
                                            }
                                        });
                                    }];
                                }];
                                [[MEGASdkManager sharedMEGASdk] getThumbnailNode:node destinationFilePath:thumbnailFilePath delegate:getThumbnailRequestDelegate];
                            }
                        }
                    }
                }
                
                if (!waitForThumbnail) {
                    UNNotificationRequest *request = [UNNotificationRequest requestWithIdentifier:identifier content:content trigger:trigger];
                    [center addNotificationRequest:request withCompletionHandler:^(NSError * _Nullable error) {
                        dispatch_async(dispatch_get_main_queue(), ^{
                            if (error) {
                                MEGALogError(@"[Chat notification] Add NotificationRequest failed with error: %@", error);
                            } else {
                                MOMessage *moMessage = [MEGAStore.shareInstance fetchMessageWithChatId:self.chatRoom.chatId messageId:self.message.messageId];
                                if (moMessage) {
                                    [MEGAStore.shareInstance deleteMessage:moMessage];
                                } else {
                                    [MEGAStore.shareInstance insertMessage:self.message.messageId chatId:self.chatRoom.chatId];
                                }
                            }
                        });
                    }];
                }
            }
            
        } else if (self.message.type == MEGAChatMessageTypeTruncate) {
            [self removeAllPendingAndDeliveredNotificationsForChatRoom];
        }
    } else {
        [self removePendingAndDeliveredNotificationForMessage];
    }
}

#endif

#pragma mark - Utils

- (NSString *)bodyString {
    NSString *body;
    
    if (self.message.type == MEGAChatMessageTypeContact) {
        if (self.message.usersCount == 1) {
            body = [NSString stringWithFormat:@"👤 %@", [self.message userNameAtIndex:0]];
        } else {
            body = [self.message userNameAtIndex:0];
            for (NSUInteger i = 1; i < self.message.usersCount; i++) {
                body = [body stringByAppendingString:[NSString stringWithFormat:@", %@", [self.message userNameAtIndex:i]]];
            }
        }
    } else if (self.message.type == MEGAChatMessageTypeAttachment) {
        MEGANodeList *nodeList = self.message.nodeList;
        if (nodeList) {
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
                } else {
                    body = [NSString stringWithFormat:@"📄 %@", node.name];
                }
            }
        }
    } else if (self.message.type == MEGAChatMessageTypeVoiceClip) {
        NSString *durationString;
        if (self.message.nodeList && self.message.nodeList.size.integerValue == 1) {
            MEGANode *node = [self.message.nodeList nodeAtIndex:0];
            NSTimeInterval duration = node.duration > 0 ? node.duration : 0;
            durationString = [NSString mnz_stringFromTimeInterval:duration];
        } else {
            durationString = @"00:00";
        }
        body = [NSString stringWithFormat:@"🎙 %@", durationString];
    } else if (self.message.containsMeta.type == MEGAChatContainsMetaTypeGeolocation) {
        body = [NSString stringWithFormat:@"📍 %@", AMLocalizedString(@"Pinned Location", @"Text shown in location-type messages")];
    } else {
        if (self.message.isEdited) {
            body = [NSString stringWithFormat:@"%@ (%@)", self.message.content, AMLocalizedString(@"edited", nil)];
        } else {
            body = self.message.content;
        }
    }
    
    return body;
}

- (NSString *)displayName {
    MOUser *user = [MEGAStore.shareInstance fetchUserWithUserHandle:self.message.userHandle];
    return user ? user.displayName : [self.chatRoom peerFullnameByHandle:self.message.userHandle];
}

- (nullable UNNotificationAttachment *)notificationAttachmentFor:(NSString *)file withIdentifier:(NSString *)identifier {
    NSString *jpgPath = [file stringByAppendingPathExtension:@"jpg"];
    NSError *error;
    if ([NSFileManager.defaultManager createSymbolicLinkAtPath:jpgPath withDestinationPath:file error:&error]) {
        NSURL *fileURL = [NSURL fileURLWithPath:jpgPath];
        UNNotificationAttachment *notificationAttachment = [UNNotificationAttachment attachmentWithIdentifier:identifier URL:fileURL options:nil error:&error];
        if (error) {
            MEGALogError(@"[Chat notification] Error creating notification attachment %@", error);
            return nil;
        } else {
            return notificationAttachment;
        }
    } else {
        MEGALogError(@"[Chat notification] Create symbolic link at path failed %@", error);
        return nil;
    }
}

#pragma mark - Private

- (void)removeAllPendingAndDeliveredNotificationsForChatRoom {
    UNUserNotificationCenter *center = [UNUserNotificationCenter currentNotificationCenter];
    [center getDeliveredNotificationsWithCompletionHandler:^(NSArray<UNNotification *> *notifications) {
        for (UNNotification *notification in notifications) {
            NSNumber *chatId = notification.request.content.userInfo[@"chatId"];
            if ([chatId isEqualToNumber:@(self.chatRoom.chatId)]) {
                [center removeDeliveredNotificationsWithIdentifiers:@[notification.request.identifier]];
            }
        }
    }];
    
    [center getPendingNotificationRequestsWithCompletionHandler:^(NSArray<UNNotificationRequest *> * _Nonnull requests) {
        for (UNNotificationRequest *request in requests) {
            NSNumber *chatId = request.content.userInfo[@"chatId"];
            if ([chatId isEqualToNumber:@(self.chatRoom.chatId)]) {
                [center removePendingNotificationRequestsWithIdentifiers:@[request.identifier]];
            }
        }
    }];
}

- (void)removePendingAndDeliveredNotificationForMessage {
    UNUserNotificationCenter *center = [UNUserNotificationCenter currentNotificationCenter];
    [center getDeliveredNotificationsWithCompletionHandler:^(NSArray<UNNotification *> *notifications) {
        for (UNNotification *notification in notifications) {
            NSNumber *chatId = notification.request.content.userInfo[@"chatId"];
            NSNumber *msgId = notification.request.content.userInfo[@"msgId"];
            if ([chatId isEqualToNumber:@(self.chatRoom.chatId)] && [msgId isEqualToNumber:@(self.message.messageId)]) {
                [center removeDeliveredNotificationsWithIdentifiers:@[notification.request.identifier]];
                break;
            }
        }
    }];
    
    [center getPendingNotificationRequestsWithCompletionHandler:^(NSArray<UNNotificationRequest *> * _Nonnull requests) {
        for (UNNotificationRequest *request in requests) {
            NSNumber *chatId = request.content.userInfo[@"chatId"];
            NSNumber *msgId = request.content.userInfo[@"msgId"];
            if ([chatId isEqualToNumber:@(self.chatRoom.chatId)] && [msgId isEqualToNumber:@(self.message.messageId)]) {
                [center removePendingNotificationRequestsWithIdentifiers:@[request.identifier]];
                break;
            }
        }
    }];
}

@end
