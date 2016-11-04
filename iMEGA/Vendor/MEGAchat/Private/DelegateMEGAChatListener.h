#import "MEGAChatDelegate.h"
#import "megachatapi.h"
#import "MEGAChatSdk.h"

class DelegateMEGAChatListener : public megachat::MegaChatListener {
    
public:
    
    DelegateMEGAChatListener(MEGAChatSdk *megaChatSDK, id<MEGAChatDelegate>listener, bool singleListener = true);
    id<MEGAChatDelegate>getUserListener();
    
    void onChatRoomUpdate(megachat::MegaChatApi *api, megachat::MegaChatRoom *chat);
    void onChatListItemUpdate(megachat::MegaChatApi *api, megachat::MegaChatListItem *item);
    
private:
    MEGAChatSdk *megaChatSDK;
    id<MEGAChatDelegate>listener;
    bool singleListener;
};
