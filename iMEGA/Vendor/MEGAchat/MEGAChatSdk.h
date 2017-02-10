#import <Foundation/Foundation.h>

#import "MEGAChatRequest.h"
#import "MEGAChatError.h"
#import "MEGAChatRoom.h"
#import "MEGAChatRoomList.h"
#import "MEGAChatPeerList.h"
#import "MEGAChatListItemList.h"
#import "MEGAChatRequestDelegate.h"
#import "MEGAChatLoggerDelegate.h"
#import "MEGAChatRoomDelegate.h"
#import "MEGAChatDelegate.h"

typedef NS_ENUM (NSInteger, MEGAChatLogLevel) {
    MEGAChatLogLevelFatal = 0,
    MEGAChatLogLevelError,
    MEGAChatLogLevelWarning,
    MEGAChatLogLevelInfo,
    MEGAChatLogLevelVerbose,
    MEGAChatLogLevelDebug,
    MEGAChatLogLevelMax
};

typedef NS_ENUM (NSInteger, MEGAChatStatus) {
    MEGAChatStatusOffline = 1,
    MEGAChatStatusAway    = 2,
    MEGAChatStatusOnline  = 3,
    MEGAChatStatusBusy    = 4
};

typedef NS_ENUM (NSInteger, MEGAChatSource) {
    MEGAChatSourceError = -1,
    MEGAChatSourceNone  = 0,
    MEGAChatSourceLocal,
    MEGAChatSourceRemote
};

typedef NS_ENUM (NSInteger, MEGAChatInit) {
    MEGAChatInitError             = -1,
    MEGAChatInitWaitingNewSession = 1,
    MEGAChatInitOfflineSession    = 2,
    MEGAChatInitOnlineSession     = 3,
    MEGAChatInitNoCache           = 7
};

@interface MEGAChatSdk : NSObject

@property (nonatomic, assign) uint64_t myUserHandle;
@property (nonatomic, readonly) NSString *myFirstname;
@property (nonatomic, readonly) NSString *myLastname;
@property (nonatomic, readonly) NSString *myFullname;
@property (nonatomic, readonly) NSString *myEmail;
@property (nonatomic, readonly) MEGAChatRoomList *chatRooms;
@property (nonatomic, readonly) MEGAChatListItemList *chatListItems;
@property (nonatomic, readonly) NSInteger unreadChats;
@property (nonatomic, readonly) MEGAChatListItemList *activeChatListItems;
@property (nonatomic, readonly) MEGAChatListItemList *inactiveChatListItems;

#pragma mark - Init

- (instancetype)init:(MEGASdk *)megaSDK;

- (MEGAChatInit)initKarereWithSid:(NSString *)sid;

- (MEGAChatInit)initState;

- (void)connectWithDelegate:(id<MEGAChatRequestDelegate>)delegate;
- (void)connect;

- (void)disconnectWithDelegate:(id<MEGAChatRequestDelegate>)delegate;
- (void)disconnect;

#pragma mark - Logout

- (void)logoutWithDelegate:(id<MEGAChatRequestDelegate>)delegate;
- (void)logout;
- (void)localLogoutWithDelegate:(id<MEGAChatRequestDelegate>)delegate;
- (void)localLogout;

- (void)setOnlineStatus:(MEGAChatStatus)status delegate:(id<MEGAChatRequestDelegate>)delegate;
- (void)setOnlineStatus:(MEGAChatStatus)status;
- (MEGAChatStatus)onlineStatus;

#pragma mark - Add and remove delegates

- (void)addChatRoomDelegate:(uint64_t)chatId delegate:(id<MEGAChatRoomDelegate>)delegate;
- (void)removeChatRoomDelegate:(id<MEGAChatRoomDelegate>)delegate;

- (void)addChatRequestDelegate:(id<MEGAChatRequestDelegate>)delegate;
- (void)removeChatRequestDelegate:(id<MEGAChatRequestDelegate>)delegate;

- (void)addChatDelegate:(id<MEGAChatDelegate>)delegate;
- (void)removeChatDelegate:(id<MEGAChatDelegate>)delegate;

#pragma mark - Chat rooms and chat list items

- (MEGAChatRoom *)chatRoomForChatId:(uint64_t)chatId;
- (MEGAChatRoom *)chatRoomByUser:(uint64_t)userHandle;

- (MEGAChatListItem *)chatListItemForChatId:(uint64_t)chatId;

- (uint64_t)chatIdByUserHandle:(uint64_t)userHandle;

#pragma mark - Users attributes

- (void)userEmailByUserHandle:(uint64_t)userHandle delegate:(id<MEGAChatRequestDelegate>)delegate;
- (void)userEmailByUserHandle:(uint64_t)userHandle;
- (void)userFirstnameByUserHandle:(uint64_t)userHandle delegate:(id<MEGAChatRequestDelegate>)delegate;
- (void)userFirstnameByUserHandle:(uint64_t)userHandle;
- (void)userLastnameByUserHandle:(uint64_t)userHandle delegate:(id<MEGAChatRequestDelegate>)delegate;
- (void)userLastnameByUserHandle:(uint64_t)userHandle;


- (NSString *)contacEmailByHandle:(uint64_t)userHandle;

#pragma mark - Chat management

- (void)createChatGroup:(BOOL)group peers:(MEGAChatPeerList *)peers delegate:(id<MEGAChatRequestDelegate>)delegate;
- (void)createChatGroup:(BOOL)group peers:(MEGAChatPeerList *)peers;

- (void)inviteToChat:(uint64_t)chatId user:(uint64_t)userHandle privilege:(NSInteger)privilege
            delegate:(id<MEGAChatRequestDelegate>)delegate;
- (void)inviteToChat:(uint64_t)chatId user:(uint64_t)userHandle privilege:(NSInteger)privilege;

- (void)removeFromChat:(uint64_t)chatId userHandle:(uint64_t)userHandle
              delegate:(id<MEGAChatRequestDelegate>)delegate;
- (void)removeFromChat:(uint64_t)chatId userHandle:(uint64_t)userHandle;

- (void)leaveChat:(uint64_t)chatId delegate:(id<MEGAChatRequestDelegate>)delegate;
- (void)leaveChat:(uint64_t)chatId;

- (void)updateChatPermissions:(uint64_t)chatId userHandle:(uint64_t)userHandle privilege:(NSInteger)privilege
                     delegate:(id<MEGAChatRequestDelegate>)delegate;
- (void)updateChatPermissions:(uint64_t)chatId userHandle:(uint64_t)userHandle privilege:(NSInteger)privilege;

- (void)truncateChat:(uint64_t)chatId messageId:(uint64_t)messageId delegate:(id<MEGAChatRequestDelegate>)delegate;
- (void)truncateChat:(uint64_t)chatId messageId:(uint64_t)messageId;

- (void)clearChatHistory:(uint64_t)chatId delegate:(id<MEGAChatRequestDelegate>)delegate;
- (void)clearChatHistory:(uint64_t)chatId;

- (void)setChatTitle:(uint64_t)chatId title:(NSString *)title delegate:(id<MEGAChatRequestDelegate>)delegate;
- (void)setChatTitle:(uint64_t)chatId title:(NSString *)title;

- (BOOL)openChatRoom:(uint64_t)chatId delegate:(id<MEGAChatRoomDelegate>)delegate;

- (void)closeChatRoom:(uint64_t)chatId delegate:(id<MEGAChatRoomDelegate>)delegate;

- (MEGAChatSource)loadMessagesForChat:(uint64_t)chatId count:(NSInteger)count;
- (BOOL)isFullHistoryLoadedForChat:(uint64_t)chatId;

- (MEGAChatMessage *)messageForChat:(uint64_t)chatId messageId:(uint64_t)messageId;
- (MEGAChatMessage *)sendMessageToChat:(uint64_t)chatId message:(NSString *)message;
- (MEGAChatMessage *)editMessageForChat:(uint64_t)chatId messageId:(uint64_t)messageId message:(NSString *)message;
- (MEGAChatMessage *)deleteMessageForChat:(uint64_t)chatId messageId:(uint64_t)messageId;
- (BOOL)setMessageSeenForChat:(uint64_t)chatId messageId:(uint64_t)messageId;
- (MEGAChatMessage *)lastChatMessageSeenForChat:(uint64_t)chatId;
- (void)removeUnsentMessageForChat:(uint64_t)chatId temporalId:(uint64_t)temporalId;

- (void)sendTypingNotificationForChat:(uint64_t)chatId;

#pragma mark - Debug log messages

+ (void)setLogLevel:(MEGAChatLogLevel)level;
+ (void)setLogObject:(id<MEGAChatLoggerDelegate>)delegate;
+ (void)setLogWithColors:(BOOL)userColors;

@end
