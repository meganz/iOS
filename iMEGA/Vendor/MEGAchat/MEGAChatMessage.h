#import <Foundation/Foundation.h>

typedef NS_ENUM(NSInteger, MEGAChatMessageStatus) {
    MEGAChatMessageStatusUnknown        = -1,
    MEGAChatMessageStatusSending        = 0,
    MEGAChatMessageStatusSendingManual  = 1,
    MEGAChatMessageStatusServerReceived = 2,
    MEGAChatMessageStatusServerRejected = 3,
    MEGAChatMessageStatusDelivered      = 4,
    MEGAChatMessageStatusNotSeen        = 5,
    MEGAChatMessageStatusSeen           = 6
};

typedef NS_ENUM(NSInteger, MEGAChatMessageType) {
    MEGAChatMessageTypeUnknown           = -1,
    MEGAChatMessageTypeNormal            = 1,
    MEGAChatMessageTypeAlterParticipants = 2,
    MEGAChatMessageTypeTruncate          = 3,
    MEGAChatMessageTypePrivilegeChange   = 4,
    MEGAChatMessageTypeChatTitle         = 5,
    MEGAChatMessageTypeUserMessage       = 16
};

typedef NS_ENUM(NSInteger, MEGAChatMessageChangeType) {
    MEGAChatMessageChangeTypeStatus = 0x01,
    MEGAChatMessageChangeTypeContent = 0x02
};

@interface MEGAChatMessage : NSObject

@property (readonly, nonatomic) NSInteger status;
@property (readonly, nonatomic) uint64_t messageId;
@property (readonly, nonatomic) uint64_t temporalId;
@property (readonly, nonatomic) NSInteger messageIndex;
@property (readonly, nonatomic) uint64_t userHande;
@property (readonly, nonatomic) MEGAChatMessageType type;
@property (readonly, nonatomic) NSDate *timestamp;
@property (readonly, nonatomic) NSString *content;
@property (readonly, nonatomic, getter=isEdited) BOOL edited;
@property (readonly, nonatomic, getter=isDeleted) BOOL deleted;
@property (readonly, nonatomic, getter=isEditable) BOOL editable;
@property (readonly, nonatomic) NSInteger changes;

- (instancetype)clone;

- (BOOL)hasChangedForType:(MEGAChatMessageChangeType)changeType;

@end
