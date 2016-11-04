#import "MEGAChatSdk.h"
#import "megachatapi.h"
#import "MEGASdk+init.h"
#import "MEGAChatSdk+init.h"
#import "MEGAChatError+init.h"
#import "MEGAChatRoom+init.h"
#import "MEGAChatRoomList+init.h"
#import "MEGAChatPeerList+init.h"
#import "MEGAChatMessage+init.h"
#import "DelegateMEGAChatRequestListener.h"
#import "DelegateMEGAChatLoggerListener.h"
#import "DelegateMEGAChatRoomListener.h"

#import <set>
#import <pthread.h>

using namespace megachat;

@interface MEGAChatSdk () {
    pthread_mutex_t listenerMutex;
}

@property (nonatomic, assign) std::set<DelegateMEGAChatRequestListener *>activeRequestListeners;
@property (nonatomic, assign) std::set<DelegateMEGAChatRoomListener *>activeChatRoomListeners;

- (MegaChatRequestListener *)createDelegateMEGAChatRequestListener:(id<MEGAChatRequestDelegate>)delegate singleListener:(BOOL)singleListener;

@property MegaChatApi *megaChatApi;
- (MegaChatApi *)getCPtr;

@end

@implementation MEGAChatSdk

//static DelegateMEGAChatLogerListener *externalLogger = NULL;

#pragma mark - Init

- (instancetype)init:(MEGASdk *)megaSDK {
    
//    if (!externalLogger)
//    {
//        externalLogger = new DelegateMEGAChatLogerListener(nil);
//    }
    
    self.megaChatApi = new MegaChatApi((mega::MegaApi *)[megaSDK getCPtr]);
    
    if (pthread_mutex_init(&listenerMutex, NULL)) {
        return nil;
    }
    
    return self;
}

- (void)initKarereWithDelegate:(id<MEGAChatRequestDelegate>)delegate {
    self.megaChatApi->init([self createDelegateMEGAChatRequestListener:delegate singleListener:YES]);
}

- (void)initKarere {
    self.megaChatApi->init();
}

- (void)connectWithDelegate:(id<MEGAChatRequestDelegate>)delegate {
    self.megaChatApi->connect([self createDelegateMEGAChatRequestListener:delegate singleListener:YES]);
}

- (void)connect {
    self.megaChatApi->connect();
}

- (void)dealloc {
    delete _megaChatApi;
    pthread_mutex_destroy(&listenerMutex);
}

- (MegaChatApi *)getCPtr {
    return _megaChatApi;
}

#pragma mark - Logout

- (void)logoutWithDelegate:(id<MEGAChatRequestDelegate>)delegate {
    self.megaChatApi->logout([self createDelegateMEGAChatRequestListener:delegate singleListener:YES]);
}

- (void)logout {
    self.megaChatApi->logout();
}

- (void)localLogoutWithDelegate:(id<MEGAChatRequestDelegate>)delegate {
    self.megaChatApi->localLogout([self createDelegateMEGAChatRequestListener:delegate singleListener:YES]);
}

- (void)localLogout {
    self.megaChatApi->localLogout();
}

#pragma mark - Add and remove delegates

- (void)addChatRoomDelegate:(uint64_t)chatId delegate:(id<MEGAChatRoomDelegate>)delegate {
    self.megaChatApi->addChatRoomListener(chatId, [self createDelegateMEGAChatRoomListener:delegate singleListener:YES]);
}

#pragma mark - Chat rooms

- (MEGAChatRoomList *)chatRooms {
    return [[MEGAChatRoomList alloc] initWithMegaChatRoomList:self.megaChatApi->getChatRooms() cMemoryOwn:YES];
}

- (MEGAChatRoom *)chatRoomForChatId:(uint64_t)chatId {
    return [[MEGAChatRoom alloc] initWithMegaChatRoom:self.megaChatApi->getChatRoom(chatId) cMemoryOwn:YES];
}

- (MEGAChatRoom *)chatRoomByUser:(uint64_t)userHandle {
    return [[MEGAChatRoom alloc] initWithMegaChatRoom:self.megaChatApi->getChatRoomByUser(userHandle) cMemoryOwn:YES];
}

#pragma mark - Chat management

- (void)createChatGroup:(BOOL)group peers:(MEGAChatPeerList *)peers delegate:(id<MEGAChatRequestDelegate>)delegate {
    self.megaChatApi->createChat(group, peers ? [peers getCPtr] : NULL, [self createDelegateMEGAChatRequestListener:delegate singleListener:YES]);
}

- (void)createChatGroup:(BOOL)group peers:(MEGAChatPeerList *)peers {
    self.megaChatApi->createChat(group, peers ? [peers getCPtr] : NULL);
}

- (void)inviteToChat:(uint64_t)chatId user:(uint64_t)userHandle privilege:(NSInteger)privilege delegate:(id<MEGAChatRequestDelegate>)delegate {
    self.megaChatApi->inviteToChat(chatId, userHandle, (int)privilege, [self createDelegateMEGAChatRequestListener:delegate singleListener:YES]);
}

- (void)inviteToChat:(uint64_t)chatId user:(uint64_t)userHandle privilege:(NSInteger)privilege {
    self.megaChatApi->inviteToChat(chatId, userHandle, (int)privilege);
}

- (void)removeFromChat:(uint64_t)chatId userHandle:(uint64_t)userHandle delegate:(id<MEGAChatRequestDelegate>)delegate {
    self.megaChatApi->removeFromChat(chatId, userHandle, [self createDelegateMEGAChatRequestListener:delegate singleListener:YES]);
}

- (void)removeFromChat:(uint64_t)chatId userHandle:(uint64_t)userHandle {
    self.megaChatApi->removeFromChat(chatId, userHandle);
}

- (void)updateChatPermissions:(uint64_t)chatId userHandle:(uint64_t)userHandle privilege:(NSInteger)privilege delegate:(id<MEGAChatRequestDelegate>)delegate {
    self.megaChatApi->updateChatPermissions(chatId, userHandle, (int)privilege, [self createDelegateMEGAChatRequestListener:delegate singleListener:YES]);
}

- (void)updateChatPermissions:(uint64_t)chatId userHandle:(uint64_t)userHandle privilege:(NSInteger)privilege {
    self.megaChatApi->updateChatPermissions(chatId, userHandle, (int)privilege);
}

- (void)truncateChat:(uint64_t)chatId messageId:(uint64_t)messageId delegate:(id<MEGAChatRequestDelegate>)delegate {
    self.megaChatApi->truncateChat(chatId, messageId, [self createDelegateMEGAChatRequestListener:delegate singleListener:YES]);
}

- (void)truncateChat:(uint64_t)chatId messageId:(uint64_t)messageId {
    self.megaChatApi->truncateChat(chatId, messageId);
}

- (void)setChatTitle:(uint64_t)chatId title:(NSString *)title delegate:(id<MEGAChatRequestDelegate>)delegate {
    self.megaChatApi->setChatTitle(chatId, title ? [title UTF8String] : NULL, [self createDelegateMEGAChatRequestListener:delegate singleListener:YES]);
}

- (void)setChatTitle:(uint64_t)chatId title:(NSString *)title {
    self.megaChatApi->setChatTitle(chatId, title ? [title UTF8String] : NULL);
}

- (BOOL)openChatRoom:(uint64_t)chatId delegate:(id<MEGAChatRoomDelegate>)delegate {
    return self.megaChatApi->openChatRoom(chatId, [self createDelegateMEGAChatRoomListener:delegate singleListener:YES]);
}

- (void)closeChatRoom:(uint64_t)chatId delegate:(id<MEGAChatRoomDelegate>)delegate {
    for (std::set<DelegateMEGAChatRoomListener *>::iterator it = _activeChatRoomListeners.begin() ; it != _activeChatRoomListeners.end() ; it++) {        
        if ((*it)->getUserListener() == delegate) {
            self.megaChatApi->closeChatRoom(chatId, (*it));
            [self freeChatRoomListener:(*it)];
            break;
        }
    }
}

- (NSInteger)loadMessagesForChat:(uint64_t)chatId count:(NSInteger)count {
    return self.megaChatApi->loadMessages(chatId, (int)count);
}

- (BOOL)isFullHistoryLoadedForChat:(uint64_t)chatId {
    return self.megaChatApi->isFullHistoryLoaded(chatId);
}

- (MEGAChatMessage *)messageForChat:(uint64_t)chatId messageId:(uint64_t)messageId {
    return self.megaChatApi ? [[MEGAChatMessage alloc] initWithMegaChatMessage:self.megaChatApi->getMessage(chatId, messageId) cMemoryOwn:YES] : nil;
}

- (MEGAChatMessage *)sendMessageToChat:(uint64_t)chatId message:(NSString *)message {
    return self.megaChatApi ? [[MEGAChatMessage alloc] initWithMegaChatMessage:self.megaChatApi->sendMessage(chatId, message ? [message UTF8String] : NULL) cMemoryOwn:YES] : nil;
}

- (MEGAChatMessage *)editMessageForChat:(uint64_t)chatId messageId:(uint64_t)messageId message:(NSString *)message {
    return self.megaChatApi ? [[MEGAChatMessage alloc] initWithMegaChatMessage:self.megaChatApi->editMessage(chatId, messageId, message ? [message UTF8String] : NULL) cMemoryOwn:YES] : nil;
}

- (MEGAChatMessage *)deleteMessageForChat:(uint64_t)chatId messageId:(uint64_t)messageId {
    return self.megaChatApi ? [[MEGAChatMessage alloc] initWithMegaChatMessage:self.megaChatApi->deleteMessage(chatId, messageId) cMemoryOwn:YES] : nil;
}

- (BOOL)setMessageSeenForChat:(uint64_t)chatId messageId:(uint64_t)messageId {
    return self.megaChatApi->setMessageSeen(chatId, messageId);
}

- (MEGAChatMessage *)lastChatMessageSeenForChat:(uint64_t)chatId {
    return self.megaChatApi ? [[MEGAChatMessage alloc] initWithMegaChatMessage:self.megaChatApi->getLastMessageSeen(chatId) cMemoryOwn:YES] : nil;
}

#pragma mark - Private methods

- (MegaChatRequestListener *)createDelegateMEGAChatRequestListener:(id<MEGAChatRequestDelegate>)delegate singleListener:(BOOL)singleListener {
    if (delegate == nil) return nil;
    
    DelegateMEGAChatRequestListener *delegateListener = new DelegateMEGAChatRequestListener(self, delegate, singleListener);
    pthread_mutex_lock(&listenerMutex);
    _activeRequestListeners.insert(delegateListener);
    pthread_mutex_unlock(&listenerMutex);
    return delegateListener;
}

- (void)freeRequestListener:(DelegateMEGAChatRequestListener *)delegate {
    if (delegate == nil) return;
    
    pthread_mutex_lock(&listenerMutex);
    _activeRequestListeners.erase(delegate);
    pthread_mutex_unlock(&listenerMutex);
    delete delegate;
}


- (MegaChatRoomListener *)createDelegateMEGAChatRoomListener:(id<MEGAChatRoomDelegate>)delegate singleListener:(BOOL)singleListener {
    if (delegate == nil) return nil;
    
    DelegateMEGAChatRoomListener *delegateListener = new DelegateMEGAChatRoomListener(self, delegate, singleListener);
    pthread_mutex_lock(&listenerMutex);
    _activeChatRoomListeners.insert(delegateListener);
    pthread_mutex_unlock(&listenerMutex);
    return delegateListener;
}

- (void)freeChatRoomListener:(DelegateMEGAChatRoomListener *)delegate {
    if (delegate == nil) return;
    
    pthread_mutex_lock(&listenerMutex);
    _activeChatRoomListeners.erase(delegate);
    pthread_mutex_unlock(&listenerMutex);
    delete delegate;
}

@end
