
#import <Foundation/Foundation.h>
#import "MEGASdk.h"
#import "MEGAChatSdk.h"

@interface MEGALogger : NSObject <MEGALoggerDelegate, MEGAChatLoggerDelegate>

+ (MEGALogger *)sharedLogger;

- (void)startLogging;
- (void)stopLogging;

- (void)useSDKLogger;
- (void)useChatSDKLogger;

@end
