#import <Foundation/Foundation.h>
#import "MEGAChatMessage.h"

typedef NS_ENUM (NSInteger, MEGAChatListItemChangeType) {
    MEGAChatListItemChangeTypeStatus       = 0x01,
    MEGAChatListItemChangeTypeVisibility   = 0x02,
    MEGAChatListItemChangeTypeUnreadCount  = 0x04,
    MEGAChatListItemChangeTypeParticipants = 0x08,
    MEGAChatListItemChangeTypeTitle        = 0x10,
    MEGAChatListItemChangeTypeClosed       = 0x20,
    MEGAChatListItemChangeTypeLastMsg      = 0x40
};

typedef NS_ENUM (NSInteger, MEGAChatStatus);

@interface MEGAChatListItem : NSObject

@property (readonly, nonatomic) uint64_t chatId;
@property (readonly, nonatomic) NSString *title;
@property (readonly, nonatomic) MEGAChatListItemChangeType changes;
@property (readonly, nonatomic) MEGAChatStatus onlineStatus;
@property (readonly, nonatomic) NSInteger visibility;
@property (readonly, nonatomic) NSInteger unreadCount;
@property (readonly, nonatomic) MEGAChatMessage *lastMessage;
@property (readonly, nonatomic, getter=isGroup) BOOL group;
@property (readonly, nonatomic) uint64_t peerHandle;

- (instancetype)clone;

- (BOOL)hasChangedForType:(MEGAChatListItemChangeType)changeType;

+ (NSString *)stringForChangeType:(MEGAChatListItemChangeType)changeType;
+ (NSString *)stringForStatus:(MEGAChatStatus)status;

@end
