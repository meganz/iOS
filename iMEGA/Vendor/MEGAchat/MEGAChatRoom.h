#import <Foundation/Foundation.h>

typedef NS_ENUM (NSInteger, MEGAChatRoomChangeType) {
    MEGAChatRoomChangeTypeStatus      = 0x01,
    MEGAChatRoomChangeTypeUnreadCount = 0x02,
    MEGAChatRoomChangeTypeParticipans = 0x04,
    MEGAChatRoomChangeTypeTitle       = 0x08,
    MEGAChatRoomChangeTypeChatState   = 0x10,
    MEGAChatRoomChangeTypeUserTyping  = 0x20,
    MEGAChatRoomChangeTypeClosed      = 0x40
};

typedef NS_ENUM (NSInteger, MEGAChatRoomPrivilege) {
    MEGAChatRoomPrivilegeUnknown   = -2,
    MEGAChatRoomPrivilegeRm        = -1,
    MEGAChatRoomPrivilegeRo        = 0,
    MEGAChatRoomPrivilegeStandard  = 2,
    MEGAChatRoomPrivilegeModerator = 3
};

typedef NS_ENUM (NSInteger, MEGAChatRoomState) {
    MEGAChatRoomStateOffline    = 0,
    MEGAChatRoomStateConnecting = 1,
    MEGAChatRoomStateJoinning   = 2,
    MEGAChatRoomStateOnline     = 3
};

@interface MEGAChatRoom : NSObject

/**
 * @brief The MegaChatHandle of the chat.
 */
@property (readonly, nonatomic) uint64_t chatId;

/**
 * @brief Your privilege level in this chat
 */
@property (readonly, nonatomic) NSInteger ownPrivilege;
@property (readonly, nonatomic) NSUInteger peerCount;
@property (readonly, nonatomic, getter=isGroup) BOOL group;
@property (readonly, nonatomic) NSString *title;
@property (readonly, nonatomic) MEGAChatRoomState onlineState;
@property (readonly, nonatomic) MEGAChatRoomChangeType changes;
@property (readonly, nonatomic) NSInteger unreadCount;
@property (readonly, nonatomic) NSInteger onlineStatus;

- (instancetype)clone;

- (NSInteger)peerPrivilegeByHandle:(uint64_t)userHande;
- (NSString *)peerFirstnameByHandle:(uint64_t)userHande;
- (NSString *)peerLastnameByHandle:(uint64_t)userHande;
- (uint64_t)peerHandleAtIndex:(NSUInteger)index;
- (MEGAChatRoomPrivilege)peerPrivilegeAtIndex:(NSUInteger)index;
- (NSString *)peerFirstnameAtIndex:(NSUInteger)index;
- (NSString *)peerLastnameAtIndex:(NSUInteger)index;
- (BOOL)hasChangedForType:(MEGAChatRoomChangeType)changeType;

@end
