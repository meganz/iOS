#include "DelegateMEGAChatLoggerListener.h"
#include <sstream>

using namespace megachat;

DelegateMEGAChatLogerListener::DelegateMEGAChatLogerListener(id<MEGAChatLoggerDelegate>listener) {
    this->listener = listener;
    MegaChatApi::setLoggerObject(this);
}

void DelegateMEGAChatLogerListener::log(int logLevel, const char *message) {
    if (listener != nil && [listener respondsToSelector:@selector(logWithTime:logLevel:source:message:)]) {
        
        [listener logWithLevel:(NSInteger)logLevel message:(message ? [NSString stringWithUTF8String:message] : nil)];
    }
    else {
        NSString *output = [[NSString alloc] init];
        
        switch (logLevel) {
            case MEGAChatLogLevelDebug:
                output = [output stringByAppendingString:@" (debug) "];
                break;
            case MEGAChatLogLevelError:
                output = [output stringByAppendingString:@" (error) "];
                break;
            case MEGAChatLogLevelFatal:
                output = [output stringByAppendingString:@" (fatal) "];
                break;
            case MEGAChatLogLevelInfo:
                output = [output stringByAppendingString:@" (info) "];
                break;
            case MEGAChatLogLevelVerbose:
                output = [output stringByAppendingString:@" (verb) "];
                break;
            case MEGAChatLogLevelMax:
                output = [output stringByAppendingString:@" (max) "];
                break;
            case MEGAChatLogLevelWarning:
                output = [output stringByAppendingString:@" (warn) "];
                break;
                
            default:
                break;
        }
        
        output = [output stringByAppendingString:[NSString stringWithUTF8String:message]];
        NSLog(@"%@", output);
    }
}
