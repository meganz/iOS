
#import <Foundation/Foundation.h>

#import "MEGAChatMessage.h"
#import "MEGAChatRoom.h"

NS_ASSUME_NONNULL_BEGIN

@interface MEGALocalNotificationManager : NSObject

- (instancetype)initWithChatRoom:(MEGAChatRoom *)chatRoom message:(MEGAChatMessage *)message silent:(BOOL)silent;
- (void)proccessNotification;

@end

NS_ASSUME_NONNULL_END
