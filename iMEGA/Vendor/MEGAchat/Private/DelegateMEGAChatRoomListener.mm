#import "DelegateMEGAChatRoomListener.h"
#import "MEGAChatRoom+init.h"
#import "MEGAChatMessage+init.h"
#import "MEGAChatSdk+init.h"

using namespace megachat;

DelegateMEGAChatRoomListener::DelegateMEGAChatRoomListener(MEGAChatSdk *megaChatSDK, id<MEGAChatRoomDelegate>listener, bool singleListener) {
    this->megaChatSDK = megaChatSDK;
    this->listener = listener;
    this->singleListener = singleListener;
}

id<MEGAChatRoomDelegate>DelegateMEGAChatRoomListener::getUserListener() {
    return listener;
}

void DelegateMEGAChatRoomListener::onChatRoomUpdate(megachat::MegaChatApi *api, megachat::MegaChatRoom *chat) {
    if (listener != nil && [listener respondsToSelector:@selector(onChatRoomUpdate:chat:)]) {
        MegaChatRoom *tempChat = chat->copy();
        MEGAChatSdk *tempMegaChatSDK = this->megaChatSDK;
        id<MEGAChatRoomDelegate> tempListener = this->listener;
        dispatch_async(dispatch_get_main_queue(), ^{
            [tempListener onChatRoomUpdate:tempMegaChatSDK chat:[[MEGAChatRoom alloc]initWithMegaChatRoom:tempChat cMemoryOwn:YES]];
        });
    }
}

void DelegateMEGAChatRoomListener::onMessageLoaded(megachat::MegaChatApi *api, megachat::MegaChatMessage *message) {
    if (listener != nil && [listener respondsToSelector:@selector(onMessageLoaded:message:)]) {
        MegaChatMessage *tempMessage = message ? message->copy() : NULL;
        MEGAChatSdk *tempMegaChatSDK = this->megaChatSDK;
        id<MEGAChatRoomDelegate> tempListener = this->listener;
        dispatch_async(dispatch_get_main_queue(), ^{
            [tempListener onMessageLoaded:tempMegaChatSDK message:tempMessage ? [[MEGAChatMessage alloc] initWithMegaChatMessage:tempMessage cMemoryOwn:YES] : nil];
        });
    }
}

void DelegateMEGAChatRoomListener::onMessageReceived(megachat::MegaChatApi *api, megachat::MegaChatMessage *message) {
    if (listener != nil && [listener respondsToSelector:@selector(onMessageReceived:message:)]) {
        MegaChatMessage *tempMessage = message->copy();
        MEGAChatSdk *tempMegaChatSDK = this->megaChatSDK;
        id<MEGAChatRoomDelegate> tempListener = this->listener;
        dispatch_async(dispatch_get_main_queue(), ^{
            [tempListener onMessageReceived:tempMegaChatSDK message:[[MEGAChatMessage alloc] initWithMegaChatMessage:tempMessage cMemoryOwn:YES]];
        });
    }
}

void DelegateMEGAChatRoomListener::onMessageUpdate(megachat::MegaChatApi *api, megachat::MegaChatMessage *message) {
    if (listener != nil && [listener respondsToSelector:@selector(onMessageUpdate:message:)]) {
        MegaChatMessage *tempMessage = message->copy();
        MEGAChatSdk *tempMegaChatSDK = this->megaChatSDK;
        id<MEGAChatRoomDelegate> tempListener = this->listener;
        dispatch_async(dispatch_get_main_queue(), ^{
            [tempListener onMessageUpdate:tempMegaChatSDK message:[[MEGAChatMessage alloc] initWithMegaChatMessage:tempMessage cMemoryOwn:YES]];
        });
    }
}
