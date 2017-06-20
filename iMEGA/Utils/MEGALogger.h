
#import <Foundation/Foundation.h>
#import "MEGASdk.h"
#import "MEGAChatSdk.h"

@interface MEGALogger : NSObject <MEGALoggerDelegate, MEGAChatLoggerDelegate>

+ (MEGALogger *)sharedLogger;

- (void)startLogging;
- (void)startLoggingToFile:(NSString *)file;
- (void)stopLogging;
- (void)stopLoggingToFile:(NSString *)file;

- (void)useSDKLogger;
- (void)useChatSDKLogger;

@end
