#import "DelegateMEGAChatListener.h"
#import "MEGAChatRoom+init.h"
#import "MEGAChatListItem+init.h"
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

void DelegateMEGAChatListener::onChatRoomUpdate(megachat::MegaChatApi *api, megachat::MegaChatRoom *chat) {
    if (listener != nil && [listener respondsToSelector:@selector(onChatRoomUpdate:chat:)]) {
        MegaChatRoom *tempChat = chat->copy();
        dispatch_async(dispatch_get_main_queue(), ^{
            [listener onChatRoomUpdate:this->megaChatSDK chat:[[MEGAChatRoom alloc]initWithMegaChatRoom:tempChat cMemoryOwn:YES]];
        });
    }
}

void DelegateMEGAChatListener::onChatListItemUpdate(megachat::MegaChatApi *api, megachat::MegaChatListItem *item) {
    if (listener != nil && [listener respondsToSelector:@selector(onChatListItemUpdate:item:)]) {
        MegaChatListItem *tempItem = item->copy();
        dispatch_async(dispatch_get_main_queue(), ^{
            [listener onChatListItemUpdate:this->megaChatSDK item:[[MEGAChatListItem alloc]initWithMegaChatListItem:tempItem cMemoryOwn:YES]];
        });
    }

}
