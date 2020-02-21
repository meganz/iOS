
#import <Foundation/Foundation.h>
#import <UserNotifications/UserNotifications.h>

#import "MEGAChatMessage.h"
#import "MEGAChatRoom.h"

NS_ASSUME_NONNULL_BEGIN

@interface MEGALocalNotificationManager : NSObject

- (instancetype)initWithChatRoom:(MEGAChatRoom *)chatRoom message:(MEGAChatMessage *)message silent:(BOOL)silent;

#ifndef MNZ_APP_EXTENSION
- (void)processNotification;
#endif

#pragma mark - Utils

- (NSString *)bodyString;
- (NSString *)subtitle;
- (nullable UNNotificationAttachment *)notificationAttachmentFor:(NSString *)file withIdentifier:(NSString *)identifier;

@end

NS_ASSUME_NONNULL_END
