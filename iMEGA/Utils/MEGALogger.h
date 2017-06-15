
#import <Foundation/Foundation.h>
#import "MEGASdk.h"
#import "MEGAChatSdk.h"

@interface MEGALogger : NSObject

+ (MEGALogger *)sharedLogger;

- (void)startLogging;
- (void)stopLogging;

- (void)enableSDKlogs;
- (void)enableChatlogs;

@end
