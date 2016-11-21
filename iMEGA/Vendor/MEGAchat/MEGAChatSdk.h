#import <Foundation/Foundation.h>

#import "MEGAChatRequest.h"
#import "MEGAChatError.h"
#import "MEGAChatRoom.h"
#import "MEGAChatRoomList.h"
#import "MEGAChatPeerList.h"
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
    MEGAChatStatusOffline = 0,
    MEGAChatStatusBusy,
    MEGAChatStatusAway,
    MEGAChatStatusOnline,
    MEGAChatStatusChatty
};

typedef NS_ENUM (NSInteger, MEGAChatSource) {
    MEGAChatSourceError = -1,
    MEGAChatSourceNone  = 0,
    MEGAChatSourceLocal,
    MEGAChatSourceRemote
};

@interface MEGAChatSdk : NSObject


@property (nonatomic, readonly) MEGAChatRoomList *chatRooms;

#pragma mark - Init

- (instancetype)init:(MEGASdk *)megaSDK;

- (void)initKarereWithDelegate:(id<MEGAChatRequestDelegate>)delegate;
- (void)initKarere;

- (void)connectWithDelegate:(id<MEGAChatRequestDelegate>)delegate;
- (void)connect;

#pragma mark - Logout

- (void)logoutWithDelegate:(id<MEGAChatRequestDelegate>)delegate;
- (void)logout;
- (void)localLogoutWithDelegate:(id<MEGAChatRequestDelegate>)delegate;
- (void)localLogout;

- (void)setOnlineStatus:(NSInteger)status delegate:(id<MEGAChatRequestDelegate>)delegate;
- (void)setOnlineStatus:(NSInteger)status;

#pragma mark - Add and remove delegates

- (void)addChatRoomDelegate:(uint64_t)chatId delegate:(id<MEGAChatRoomDelegate>)delegate;

- (void)addChatDelegate:(id<MEGAChatDelegate>)delegate;
- (void)removeChatDelegate:(id<MEGAChatDelegate>)delegate;

#pragma mark - Chat rooms

- (MEGAChatRoom *)chatRoomForChatId:(uint64_t)chatId;
- (MEGAChatRoom *)chatRoomByUser:(uint64_t)userHandle;

#pragma mark - Chat management

- (void)createChatGroup:(BOOL)group peers:(MEGAChatPeerList *)peers delegate:(id<MEGAChatRequestDelegate>)delegate;
- (void)createChatGroup:(BOOL)group peers:(MEGAChatPeerList *)peers;

- (void)inviteToChat:(uint64_t)chatId user:(uint64_t)userHandle privilege:(NSInteger)privilege
            delegate:(id<MEGAChatRequestDelegate>)delegate;
- (void)inviteToChat:(uint64_t)chatId user:(uint64_t)userHandle privilege:(NSInteger)privilege;

- (void)removeFromChat:(uint64_t)chatId userHandle:(uint64_t)userHandle
              delegate:(id<MEGAChatRequestDelegate>)delegate;

- (void)removeFromChat:(uint64_t)chatId userHandle:(uint64_t)userHandle;

- (void)updateChatPermissions:(uint64_t)chatId userHandle:(uint64_t)userHandle privilege:(NSInteger)privilege
                     delegate:(id<MEGAChatRequestDelegate>)delegate;
- (void)updateChatPermissions:(uint64_t)chatId userHandle:(uint64_t)userHandle privilege:(NSInteger)privilege;

- (void)truncateChat:(uint64_t)chatId messageId:(uint64_t)messageId delegate:(id<MEGAChatRequestDelegate>)delegate;
- (void)truncateChat:(uint64_t)chatId messageId:(uint64_t)messageId;

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

@end
