
#import <Foundation/Foundation.h>
#import "MEGASdk.h"
#import "MEGAChatSdk.h"

@interface MEGALogger : NSObject <MEGALoggerDelegate, MEGAChatLoggerDelegate>

+ (void)stopLog;

@end
