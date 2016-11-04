#import <Foundation/Foundation.h>

typedef NS_ENUM (NSInteger, MEGAChatListItemChangeType) {
    MEGAChatListItemChangeTypeStatus       = 0x01,
    MEGAChatListItemChangeTypeVisibility   = 0x02,
    MEGAChatListItemChangeTypeUnreadCount  = 0x04,
    MEGAChatListItemChangeTypeParticipants = 0x08,
    MEGAChatListItemChangeTypeTitle        = 0x10,
};

@interface MEGAChatListItem : NSObject

@property (readonly, nonatomic) uint64_t chatId;
@property (readonly, nonatomic) NSString *title;
@property (readonly, nonatomic) MEGAChatListItemChangeType changes;
@property (readonly, nonatomic) NSInteger onlineStatus;
@property (readonly, nonatomic) NSInteger visibility;
@property (readonly, nonatomic) NSInteger unreadCount;

- (instancetype)clone;

- (BOOL)hasChangedForType:(MEGAChatListItemChangeType)changeType;

@end
