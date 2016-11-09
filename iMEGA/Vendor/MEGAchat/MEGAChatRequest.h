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
    MEGAChatRequestTypeCreateChatRoom,
    MEGAChatRequestTypeRemoveFromChatRoom,
    MEGAChatRequestTypeInviteToChatRoom,
    MEGAChatRequestTypeUpdatePeerPermissions,
    MEGAChatRequestTypeEditChatRoomName,
    MEGAChatRequestTypeEditChatRoomPic,
    MEGAChatRequestTypeTruncateHistory,
    MEGAChatRequestTypeShareContact,
    MEGAChatRequestTypeGetFirstname,
    MEGAChatRequestTypeGetLastname
};

@interface MEGAChatRequest : NSObject

@property (readonly, nonatomic) MEGAChatRequestType type;
@property (readonly, nonatomic) NSString *requestString;

- (instancetype)clone;

@end
