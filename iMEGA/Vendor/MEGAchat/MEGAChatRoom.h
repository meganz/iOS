#import <Foundation/Foundation.h>

typedef NS_ENUM (NSInteger, MEGAChatRoomChangeType) {
    MEGAChatRoomChangeTypeStatus      = 0x01,
    MEGAChatRoomChangeTypeUnreadCount = 0x02,
    MEGAChatRoomChangeTypeParticipans = 0x04,
    MEGAChatRoomChangeTypeTitle       = 0x08,
    MEGAChatRoomChangeTypeUserTyping  = 0x10,
    MEGAChatRoomChangeTypeClosed      = 0x20
};

typedef NS_ENUM (NSInteger, MEGAChatRoomPrivilege) {
    MEGAChatRoomPrivilegeUnknown   = -2,
    MEGAChatRoomPrivilegeRm        = -1,
    MEGAChatRoomPrivilegeRo        = 0,
    MEGAChatRoomPrivilegeStandard  = 2,
    MEGAChatRoomPrivilegeModerator = 3
};

typedef NS_ENUM (NSInteger, MEGAChatStatus);

@interface MEGAChatRoom : NSObject

/**
 * @brief The MegaChatHandle of the chat.
 */
@property (readonly, nonatomic) uint64_t chatId;

/**
 * @brief Your privilege level in this chat
 */
@property (readonly, nonatomic) MEGAChatRoomPrivilege ownPrivilege;
@property (readonly, nonatomic) NSUInteger peerCount;
@property (readonly, nonatomic, getter=isGroup) BOOL group;
@property (readonly, nonatomic) NSString *title;
@property (readonly, nonatomic) MEGAChatRoomChangeType changes;
@property (readonly, nonatomic) NSInteger unreadCount;
@property (readonly, nonatomic) MEGAChatStatus onlineStatus;
@property (readonly, nonatomic) uint64_t userTypingHandle;
@property (readonly, nonatomic, getter=isActive) BOOL active;


- (instancetype)clone;

- (NSInteger)peerPrivilegeByHandle:(uint64_t)userHande;
- (NSString *)peerFirstnameByHandle:(uint64_t)userHande;
- (NSString *)peerLastnameByHandle:(uint64_t)userHande;
- (NSString *)peerFullnameByHandle:(uint64_t)userHande;
- (uint64_t)peerHandleAtIndex:(NSUInteger)index;
- (MEGAChatRoomPrivilege)peerPrivilegeAtIndex:(NSUInteger)index;
- (NSString *)peerFirstnameAtIndex:(NSUInteger)index;
- (NSString *)peerLastnameAtIndex:(NSUInteger)index;
- (NSString *)peerFullnameAtIndex:(NSUInteger)index;
- (BOOL)hasChangedForType:(MEGAChatRoomChangeType)changeType;

+ (NSString *)stringForPrivilege:(MEGAChatRoomPrivilege)privilege;
+ (NSString *)stringForChangeType:(MEGAChatRoomChangeType)changeType;
+ (NSString *)stringForStatus:(MEGAChatStatus)status;

@end
