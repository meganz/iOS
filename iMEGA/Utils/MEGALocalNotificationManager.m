
#import "MEGALocalNotificationManager.h"

#import <UserNotifications/UserNotifications.h>

#ifndef MNZ_APP_EXTENSION
#import "Helper.h"
#import "MEGAGetThumbnailRequestDelegate.h"
#import "MEGAStore.h"
#endif

#import "MEGASdkManager.h"
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
- (void)proccessNotification {
    if (self.message.status == MEGAChatMessageStatusNotSeen) {
        if  (self.message.type == MEGAChatMessageTypeNormal || self.message.type == MEGAChatMessageTypeContact || self.message.type == MEGAChatMessageTypeAttachment || self.message.containsMeta.type == MEGAChatContainsMetaTypeGeolocation || self.message.type == MEGAChatMessageTypeVoiceClip) {
            if (self.message.deleted) {
                [self removePendingAndDeliveredNotificationForMessage];
            } else {
                UNUserNotificationCenter *center = [UNUserNotificationCenter currentNotificationCenter];
                
                UNMutableNotificationContent *content = [UNMutableNotificationContent new];
                content.categoryIdentifier = @"nz.mega.chat.message";
                content.userInfo = @{@"chatId" : @(self.chatRoom.chatId)};
                content.title = self.chatRoom.title;
                content.sound = nil;
                content.body = [self bodyString];
                if (self.chatRoom.isGroup) {
                    content.subtitle = [self subtitle];
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
                                    NSError *error;
                                    if (![[NSFileManager defaultManager] createSymbolicLinkAtPath:[request.file stringByAppendingPathExtension:@"jpg"] withDestinationPath:request.file error:&error]) {
                                        MEGALogError(@"Create symbolic link at path failed %@", error);
                                    }
                                    NSURL *fileURL = [NSURL fileURLWithPath:[request.file stringByAppendingPathExtension:@"jpg"]];
                                    UNNotificationAttachment *notificationAttachment = [UNNotificationAttachment attachmentWithIdentifier:node.base64Handle URL:fileURL options:nil error:&error];
                                    
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
                            }
                        }
                    }
                }
                
                if (!waitForThumbnail) {
                    UNNotificationRequest *request = [UNNotificationRequest requestWithIdentifier:identifier content:content trigger:trigger];
                    [center addNotificationRequest:request withCompletionHandler:^(NSError * _Nullable error) {
                        if (error) {
                            MEGALogError(@"Add NotificationRequest failed with error: %@", error);
                        }
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
        body = [NSString stringWithFormat:@"📍 %@", NSLocalizedString(@"Pinned Location", @"Text shown in location-type messages")];
    } else {
        if (self.message.isEdited) {
            body = [NSString stringWithFormat:@"%@ (%@)", self.message.content, NSLocalizedString(@"edited", nil)];
        } else {
            body = self.message.content;
        }
    }
    
    return body;
}

- (NSString *)subtitle {
    NSString *subtitle = [self.chatRoom peerFullnameByHandle:self.message.userHandle];
    if (!subtitle.length) {
        subtitle = [self.chatRoom peerEmailByHandle:self.message.userHandle];
        if (!subtitle) {
            subtitle = @"";
        }
    }
    return subtitle;
}

#pragma mark - Private

- (void)removeAllPendingAndDeliveredNotificationsForChatRoom {
    UNUserNotificationCenter *center = [UNUserNotificationCenter currentNotificationCenter];
    [center getDeliveredNotificationsWithCompletionHandler:^(NSArray<UNNotification *> *notifications) {
        NSString *base64ChatId = [MEGASdk base64HandleForUserHandle:self.chatRoom.chatId];
        for (UNNotification *notification in notifications) {
            if ([notification.request.identifier containsString:base64ChatId]) {
                [center removeDeliveredNotificationsWithIdentifiers:@[notification.request.identifier]];
            }
        }
    }];
    
    [center getPendingNotificationRequestsWithCompletionHandler:^(NSArray<UNNotificationRequest *> * _Nonnull requests) {
        NSString *base64ChatId = [MEGASdk base64HandleForUserHandle:self.chatRoom.chatId];
        for (UNNotificationRequest *request in requests) {
            if ([request.identifier containsString:base64ChatId]) {
                [center removePendingNotificationRequestsWithIdentifiers:@[request.identifier]];
            }
        }
    }];
}

- (void)removePendingAndDeliveredNotificationForMessage {
    UNUserNotificationCenter *center = [UNUserNotificationCenter currentNotificationCenter];
    [center getDeliveredNotificationsWithCompletionHandler:^(NSArray<UNNotification *> *notifications) {
        NSString *notificationIdentifier = [NSString stringWithFormat:@"%@%@", [MEGASdk base64HandleForUserHandle:self.chatRoom.chatId], [MEGASdk base64HandleForUserHandle:self.message.messageId]];
        for (UNNotification *notification in notifications) {
            if ([notificationIdentifier isEqualToString:notification.request.identifier]) {
                [center removeDeliveredNotificationsWithIdentifiers:@[notification.request.identifier]];
                break;
            }
        }
    }];
    
    [center getPendingNotificationRequestsWithCompletionHandler:^(NSArray<UNNotificationRequest *> * _Nonnull requests) {
        NSString *notificationIdentifier = [NSString stringWithFormat:@"%@%@", [MEGASdk base64HandleForUserHandle:self.chatRoom.chatId], [MEGASdk base64HandleForUserHandle:self.message.messageId]];
        for (UNNotificationRequest *request in requests) {
            if ([notificationIdentifier isEqualToString:request.identifier]) {
                [center removePendingNotificationRequestsWithIdentifiers:@[request.identifier]];
                break;
            }
        }
    }];
}

@end
