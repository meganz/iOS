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
        dispatch_async(dispatch_get_main_queue(), ^{
            [listener onChatRoomUpdate:this->megaChatSDK chat:[[MEGAChatRoom alloc]initWithMegaChatRoom:tempChat cMemoryOwn:YES]];
        });
    }
}

void DelegateMEGAChatRoomListener::onMessageLoaded(megachat::MegaChatApi *api, megachat::MegaChatMessage *message) {
    if (listener != nil && [listener respondsToSelector:@selector(onMessageLoaded:message:)]) {
        MegaChatMessage *tempMessage = message ? message->copy() : NULL;
        dispatch_async(dispatch_get_main_queue(), ^{
            [listener onMessageLoaded:this->megaChatSDK message:tempMessage ? [[MEGAChatMessage alloc] initWithMegaChatMessage:tempMessage cMemoryOwn:YES] : nil];
        });
    }
}

void DelegateMEGAChatRoomListener::onMessageReceived(megachat::MegaChatApi *api, megachat::MegaChatMessage *message) {
    if (listener != nil && [listener respondsToSelector:@selector(onMessageReceived:message:)]) {
        MegaChatMessage *tempMessage = message->copy();
        dispatch_async(dispatch_get_main_queue(), ^{
            [listener onMessageReceived:this->megaChatSDK message:[[MEGAChatMessage alloc] initWithMegaChatMessage:tempMessage cMemoryOwn:YES]];
        });
    }
}

void DelegateMEGAChatRoomListener::onMessageUpdate(megachat::MegaChatApi *api, megachat::MegaChatMessage *message) {
    if (listener != nil && [listener respondsToSelector:@selector(onMessageUpdate:message:)]) {
        MegaChatMessage *tempMessage = message->copy();
        dispatch_async(dispatch_get_main_queue(), ^{
            [listener onMessageUpdate:this->megaChatSDK message:[[MEGAChatMessage alloc] initWithMegaChatMessage:tempMessage cMemoryOwn:YES]];
        });
    }
}

const id<MEGAChatRoomDelegate> DelegateMEGAChatRoomListener::getListener () {
    return this->listener;
}
