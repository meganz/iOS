#import "DelegateMEGAChatListener.h"
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

void DelegateMEGAChatListener::onChatListItemUpdate(megachat::MegaChatApi *api, megachat::MegaChatListItem *item) {
    if (listener != nil && [listener respondsToSelector:@selector(onChatListItemUpdate:item:)]) {
        MegaChatListItem *tempItem = item->copy();
        dispatch_async(dispatch_get_main_queue(), ^{
            [listener onChatListItemUpdate:this->megaChatSDK item:[[MEGAChatListItem alloc]initWithMegaChatListItem:tempItem cMemoryOwn:YES]];
        });
    }
}

void DelegateMEGAChatListener::onChatInitStateUpdate(megachat::MegaChatApi *api, int newState) {
    if (listener != nil && [listener respondsToSelector:@selector(onChatInitStateUpdate:newState:)]) {
        dispatch_async(dispatch_get_main_queue(), ^{
            [listener onChatInitStateUpdate:this->megaChatSDK newState:(MEGAChatInit)newState];
        });
    }
}
