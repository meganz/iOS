#import <Foundation/Foundation.h>

typedef NS_ENUM (NSInteger, MEGAChatRequestType) {
    MEGAChatRequestTypeInitialize,
    MEGAChatRequestTypeConnect,
    MEGAChatRequestTypeDelete,
    MEGAChatRequestTypeLogout,
    MEGAChatRequestTypeSetOnlineStatus,
    MEGAChatRequestTypeStartChatCall,
    MEGAChatRequestTypeAnswerChatCall,
    MEGAChatRequestTypeMuteChatCall,
    MEGAChatRequestTypeHangChatCall,
    MEGAChatRequestTypeEditMessage,
    MEGAChatRequestTypeDeleteMessage,
    MEGAChatRequestTypeCreateChatRoom,
    MEGAChatRequestTypeRemoveFromChatRoom,
    MEGAChatRequestTypeInviteToChatRoom,
    MEGAChatRequestTypeUpdatePeerPermissions,
    MEGAChatRequestTypeEditChatRoomName,
    MEGAChatRequestTypeEditChatRoomPic,
    MEGAChatRequestTypeTruncateHistory,
    MEGAChatRequestTypeGetHistory,
    MEGAChatRequestTypeShareContact
};

@interface MEGAChatRequest : NSObject

@property (readonly, nonatomic) MEGAChatRequestType type;
@property (readonly, nonatomic) NSString *requestString;

- (instancetype)clone;

@end
