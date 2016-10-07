#import <Foundation/Foundation.h>

#import "MEGAChatRequest.h"
#import "MEGAChatError.h"
#import "MEGAChatRequestDelegate.h"
#import "MEGAChatLoggerDelegate.h"

typedef NS_ENUM (NSInteger, MEGAChatLogLevel) {
    MEGAChatLogLevelFatal = 0,
    MEGAChatLogLevelError,
    MEGAChatLogLevelWarning,
    MEGAChatLogLevelInfo,
    MEGAChatLogLevelVerbose,
    MEGAChatLogLevelDebug,
    MEGAChatLogLevelMax
};

@interface MEGAChatSdk : NSObject

#pragma mark - Init

- (instancetype)init:(MEGASdk *)megaSDK;

- (void)openSession:(BOOL) resumeSession delegate:(id<MEGAChatRequestDelegate>)delegate;
- (void)openSession:(BOOL) resumeSession;

- (void)connectWithDelegate:(id<MEGAChatRequestDelegate>)delegate;
- (void)connect;

@end
