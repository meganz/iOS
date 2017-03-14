#import "DelegateMEGAChatRequestListener.h"
#import "MEGAChatRequest+init.h"
#import "MEGAChatError+init.h"
#import "MEGAChatSdk+init.h"

using namespace megachat;

DelegateMEGAChatRequestListener::DelegateMEGAChatRequestListener(MEGAChatSdk *megaChatSDK, id<MEGAChatRequestDelegate>listener, bool singleListener) {
    this->megaChatSDK = megaChatSDK;
    this->listener = listener;
    this->singleListener = singleListener;
}

id<MEGAChatRequestDelegate>DelegateMEGAChatRequestListener::getUserListener() {
    return listener;
}

void DelegateMEGAChatRequestListener::onRequestStart(MegaChatApi *api, MegaChatRequest *request) {
    if (listener != nil && [listener respondsToSelector:@selector(onChatRequestStart:request:)]) {
        MegaChatRequest *tempRequest = request->copy();
        MEGAChatSdk *tempMegaChatSDK = this->megaChatSDK;
        id<MEGAChatRequestDelegate> tempListener = this->listener;
        dispatch_async(dispatch_get_main_queue(), ^{
            [tempListener onChatRequestStart:tempMegaChatSDK request:[[MEGAChatRequest alloc]initWithMegaChatRequest:tempRequest cMemoryOwn:YES]];
        });
    }
}

void DelegateMEGAChatRequestListener::onRequestFinish(MegaChatApi *api, MegaChatRequest *request, MegaChatError *e) {
    if (listener != nil && [listener respondsToSelector:@selector(onChatRequestFinish:request:error:)]) {
        MegaChatRequest *tempRequest = request->copy();
        MegaChatError *tempError = e->copy();
        MEGAChatSdk *tempMegaChatSDK = this->megaChatSDK;
        id<MEGAChatRequestDelegate> tempListener = this->listener;
        bool tempSingleListener = this->singleListener;
        dispatch_async(dispatch_get_main_queue(), ^{
            [tempListener onChatRequestFinish:tempMegaChatSDK request:[[MEGAChatRequest alloc]initWithMegaChatRequest:tempRequest cMemoryOwn:YES] error:[[MEGAChatError alloc] initWithMegaChatError:tempError cMemoryOwn:YES]];
            if (tempSingleListener) {
                [megaChatSDK freeRequestListener:this];
            }
        });
    }
}

void DelegateMEGAChatRequestListener::onRequestUpdate(MegaChatApi *api, MegaChatRequest *request) {
    if (listener != nil && [listener respondsToSelector:@selector(onChatRequestUpdate:request:)]) {
        MegaChatRequest *tempRequest = request->copy();
        MEGAChatSdk *tempMegaChatSDK = this->megaChatSDK;
        id<MEGAChatRequestDelegate> tempListener = this->listener;
        dispatch_async(dispatch_get_main_queue(), ^{
            [tempListener onChatRequestUpdate:tempMegaChatSDK request:[[MEGAChatRequest alloc] initWithMegaChatRequest:tempRequest cMemoryOwn:YES]];
        });
    }
}

void DelegateMEGAChatRequestListener::onRequestTemporaryError(MegaChatApi *api, MegaChatRequest *request, MegaChatError *e) {
    if (listener != nil && [listener respondsToSelector:@selector(onChatRequestTemporaryError:request:error:)]) {
        MegaChatRequest *tempRequest = request->copy();
        MegaChatError *tempError = e->copy();
        MEGAChatSdk *tempMegaChatSDK = this->megaChatSDK;
        id<MEGAChatRequestDelegate> tempListener = this->listener;
        dispatch_async(dispatch_get_main_queue(), ^{
            [tempListener onChatRequestTemporaryError:tempMegaChatSDK request:[[MEGAChatRequest alloc] initWithMegaChatRequest:tempRequest cMemoryOwn:YES] error:[[MEGAChatError alloc] initWithMegaChatError:tempError cMemoryOwn:YES]];
        });
    }
}
