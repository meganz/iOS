#import "megachatapi.h"
#import "MEGAChatSdk.h"

class DelegateMEGAChatLogerListener : public megachat::MegaChatLogger {
    
public:
    DelegateMEGAChatLogerListener(id<MEGAChatLoggerDelegate> listener);
    void log(int loglevel, const char *message);
    
private:
    MEGAChatSdk *megaChatSDK;
    id<MEGAChatLoggerDelegate> listener;
};
