#import "megachatapi.h"
#import "MEGAChatSdk.h"

class DelegateMEGAChatLoggerListener : public megachat::MegaChatLogger {
    
public:
    DelegateMEGAChatLoggerListener(id<MEGAChatLoggerDelegate> listener);
    void log(int loglevel, const char *message);
    
private:
    MEGAChatSdk *megaChatSDK;
    id<MEGAChatLoggerDelegate> listener;
};
