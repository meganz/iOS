#import "DelegateMEGAChatListener.h"
#import "MEGAChatListItem+init.h"
#import "MEGAChatPresenceConfig+init.h"
#import "MEGAChatSdk+init.h"

using namespace megachat;

DelegateMEGAChatListener::DelegateMEGAChatListener(MEGAChatSdk *megaChatSDK, id<MEGAChatDelegate>listener, bool singleListener) {
    this->megaChatSDK = megaChatSDK;
    this->listener = listener;
    this->singleListener = singleListener;
}

id<MEGAChatDelegate>DelegateMEGAChatListener::getUserListener() {
    return listener;
}

void DelegateMEGAChatListener::onChatListItemUpdate(megachat::MegaChatApi *api, megachat::MegaChatListItem *item) {
    if (listener != nil && [listener respondsToSelector:@selector(onChatListItemUpdate:item:)]) {
        MegaChatListItem *tempItem = item->copy();
        MEGAChatSdk *tempMegaChatSDK = this->megaChatSDK;
        id<MEGAChatDelegate> tempListener = this->listener;
        dispatch_async(dispatch_get_main_queue(), ^{
            [tempListener onChatListItemUpdate:tempMegaChatSDK item:[[MEGAChatListItem alloc]initWithMegaChatListItem:tempItem cMemoryOwn:YES]];
        });
    }
}

void DelegateMEGAChatListener::onChatInitStateUpdate(megachat::MegaChatApi *api, int newState) {
    if (listener != nil && [listener respondsToSelector:@selector(onChatInitStateUpdate:newState:)]) {
        MEGAChatSdk *tempMegaChatSDK = this->megaChatSDK;
        id<MEGAChatDelegate> tempListener = this->listener;
        dispatch_async(dispatch_get_main_queue(), ^{
            [tempListener onChatInitStateUpdate:tempMegaChatSDK newState:(MEGAChatInit)newState];
        });
    }
}

void DelegateMEGAChatListener::onChatOnlineStatusUpdate(megachat::MegaChatApi *api, int status, BOOL inProgress) {
    if (listener != nil && [listener respondsToSelector:@selector(onChatOnlineStatusUpdate:status:inProgress:)]) {
        MEGAChatSdk *tempMegaChatSDK = this->megaChatSDK;
        id<MEGAChatDelegate> tempListener = this->listener;
        dispatch_async(dispatch_get_main_queue(), ^{
            [tempListener onChatOnlineStatusUpdate:tempMegaChatSDK status:(MEGAChatStatus)status inProgress:inProgress];
        });
    }
}

void DelegateMEGAChatListener::onChatPresenceConfigUpdate(megachat::MegaChatApi *api, megachat::MegaChatPresenceConfig *config) {
    if (listener != nil && [listener respondsToSelector:@selector(onChatPresenceConfigUpdate:presenceConfig:)]) {
        MegaChatPresenceConfig *tempConfig = config->copy();
        MEGAChatSdk *tempMegaChatSDK = this->megaChatSDK;
        id<MEGAChatDelegate> tempListener = this->listener;
        dispatch_async(dispatch_get_main_queue(), ^{
            [tempListener onChatPresenceConfigUpdate:tempMegaChatSDK presenceConfig:[[MEGAChatPresenceConfig alloc] initWithMegaChatPresenceConfig:tempConfig cMemoryOwn:YES]];
        });
    }
}
