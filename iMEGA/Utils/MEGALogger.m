
#import "MEGALogger.h"
#import "MEGASdkManager.h"

@implementation MEGALogger

static MEGALogger *_megaLogger = nil;

+ (MEGALogger *)sharedLogger {
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        _megaLogger = [[MEGALogger alloc] init];
    });
    
    return _megaLogger;
}

- (void)startLogging {
    NSString *logFilePath = [[NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES) objectAtIndex:0] stringByAppendingPathComponent:@"MEGAiOS.log"];
    [self startLoggingToFile:logFilePath];
}

- (void)startLoggingToFile:(NSString *)logFilePath {
    freopen([logFilePath cStringUsingEncoding:NSASCIIStringEncoding],"a+", stdout);
    freopen([logFilePath cStringUsingEncoding:NSASCIIStringEncoding],"a+", stderr);
    
    [MEGASdk setLogLevel:MEGALogLevelMax];
    [MEGAChatSdk setLogLevel:MEGAChatLogLevelMax];
    
    [[NSUserDefaults standardUserDefaults] setBool:YES forKey:@"logging"];
    [[NSUserDefaults standardUserDefaults] synchronize];
    
    [[[NSUserDefaults alloc] initWithSuiteName:@"group.mega.ios"] setBool:YES forKey:@"logging"];
}

- (void)stopLogging {
    NSString *logFilePath = [[NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES) objectAtIndex:0] stringByAppendingPathComponent:@"MEGAiOS.log"];
    [self stopLoggingToFile:logFilePath];
}

- (void)stopLoggingToFile:(NSString *)logFilePath {    
    if ([[NSFileManager defaultManager] fileExistsAtPath:logFilePath]) {
        [[NSFileManager defaultManager] removeItemAtPath:logFilePath error:nil];
    }
    
#ifndef DEBUG
    [MEGASdk setLogLevel:MEGALogLevelFatal];
    [MEGAChatSdk setLogLevel:MEGAChatLogLevelFatal];
#endif
    
    [[NSUserDefaults standardUserDefaults] setBool:NO forKey:@"logging"];
    [[NSUserDefaults standardUserDefaults] synchronize];
    
    [[[NSUserDefaults alloc] initWithSuiteName:@"group.mega.ios"] setBool:NO forKey:@"logging"];
}

- (void)enableSDKlogs {
    [MEGAChatSdk setLogToConsole:NO];
    [MEGASdk setLogToConsole:YES];
}

- (void)enableChatlogs {
    [MEGASdk setLogToConsole:NO];
    [MEGAChatSdk setLogToConsole:YES];
}

@end
