
#import <Foundation/Foundation.h>
#import "MEGASdk.h"
#import "MEGAChatSdk.h"

@interface MEGALogger : NSObject

+ (MEGALogger *)sharedLogger;

- (void)preparingForLogging;
- (void)startLoggingToFile:(NSString *)file;
- (void)stopLogging;
- (void)stopLoggingToFile:(NSString *)file;

@end
