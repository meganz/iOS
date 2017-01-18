#include "DelegateMEGAChatLoggerListener.h"
#include <sstream>

using namespace megachat;

DelegateMEGAChatLoggerListener::DelegateMEGAChatLoggerListener(id<MEGAChatLoggerDelegate>listener) {
    this->listener = listener;
    MegaChatApi::setLoggerObject(this);
}

void DelegateMEGAChatLoggerListener::log(int logLevel, const char *message) {
    if (listener != nil && [listener respondsToSelector:@selector(logWithTime:logLevel:source:message:)]) {
        [listener logWithLevel:(NSInteger)logLevel message:(message ? [NSString stringWithUTF8String:message] : nil)];
    }
}
