
#import "MEGALogger.h"

@implementation MEGALogger

- (instancetype)init {
    self = [super init];
    if (self) {
        [MEGASdk setLogLevel:MEGALogLevelMax];
        [MEGAChatSdk setLogLevel:MEGAChatLogLevelMax];
        NSString *logFilePath = [[NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES) objectAtIndex:0] stringByAppendingPathComponent:@"MEGAiOS.log"];
        freopen([logFilePath cStringUsingEncoding:NSASCIIStringEncoding],"a+", stderr);
        
        [[NSUserDefaults standardUserDefaults] setBool:YES forKey:@"logging"];
        [[NSUserDefaults standardUserDefaults] synchronize];
    }
    return self;
}

+ (void)stopLog {
    NSString *logFilePath = [[NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES) objectAtIndex:0] stringByAppendingPathComponent:@"MEGAiOS.log"];
    if ([[NSFileManager defaultManager] fileExistsAtPath:logFilePath]) {
        [[NSFileManager defaultManager] removeItemAtPath:logFilePath error:nil];
    }
    
    [[NSUserDefaults standardUserDefaults] setBool:NO forKey:@"logging"];
    [[NSUserDefaults standardUserDefaults] synchronize];
    
    [MEGAChatSdk setLogObject:nil];
    [MEGASdk setLogObject:nil];
}

- (void)logWithTime:(NSString *)time logLevel:(NSInteger)logLevel source:(NSString *)source message:(NSString *)message {
    NSString *m = [[NSString alloc] init];
    
    switch (logLevel) {
        case MEGALogLevelDebug:
            m = [m stringByAppendingString:@" (debug) "];
            break;
        case MEGALogLevelError:
            m = [m stringByAppendingString:@" (error) "];
            break;
        case MEGALogLevelFatal:
            m = [m stringByAppendingString:@" (fatal) "];
            break;
        case MEGALogLevelInfo:
            m = [m stringByAppendingString:@" (info) "];
            break;
        case MEGALogLevelMax:
            m = [m stringByAppendingString:@" (verb) "];
            break;
        case MEGALogLevelWarning:
            m = [m stringByAppendingString:@" (warn) "];
            break;
            
        default:
            break;
    }
    
    m = [m stringByAppendingString:message];
    m = [m stringByAppendingString:source];
    NSLog(@"%@", m);
}

- (void)logWithLevel:(NSInteger)logLevel message:(NSString *)message {
    fprintf(stderr, "%s", [message UTF8String]);
}

@end
