
#import "MEGASdkManager.h"

@implementation MEGASdkManager

static MEGAChatSdk *_MEGAChatSdk = nil;

+ (NSString *)userAgent {
    return [NSString stringWithFormat:@"%@/%@", MEGAiOSAppUserAgent, [[NSBundle mainBundle] objectForInfoDictionaryKey:@"CFBundleShortVersionString"]];
}

+ (MEGASdk *)sharedMEGASdk {
    static MEGASdk *_megaSDK;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        NSError *error;
        NSURL *applicationSupportDirectoryURL = [[NSFileManager defaultManager] URLForDirectory:NSApplicationSupportDirectory inDomain:NSUserDomainMask appropriateForURL:nil create:YES error:&error];
        if (error) {
            MEGALogError(@"Failed to locate/create NSApplicationSupportDirectory with error: %@", error);
        }

        _megaSDK = [[MEGASdk alloc] initWithAppKey:MEGAiOSAppKey userAgent:[self userAgent] basePath:applicationSupportDirectoryURL.path];
        [_megaSDK retrySSLErrors:YES];
    });
    return _megaSDK;
}

+ (MEGAChatSdk *)sharedMEGAChatSdk {
    return _MEGAChatSdk;
}

+ (void)createSharedMEGAChatSdk {
    _MEGAChatSdk = [[MEGAChatSdk alloc] init:[self sharedMEGASdk]];
    [_MEGAChatSdk addChatDelegate:(id<MEGAChatDelegate>)[[UIApplication sharedApplication] delegate]];
    [_MEGAChatSdk addChatRequestDelegate:(id<MEGAChatRequestDelegate>)[[UIApplication sharedApplication] delegate]];
    MEGALogDebug(@"_MEGAChatSdk created: %@", _MEGAChatSdk);
    [MEGASdk setLogToConsole:NO];
    [MEGAChatSdk setLogToConsole:YES];
}

+ (void)destroySharedMEGAChatSdk {
    [_MEGAChatSdk removeChatDelegate:(id<MEGAChatDelegate>)[[UIApplication sharedApplication] delegate]];
    [_MEGAChatSdk removeChatRequestDelegate:(id<MEGAChatRequestDelegate>)[[UIApplication sharedApplication] delegate]];
    _MEGAChatSdk = nil;
    MEGALogDebug(@"_MEGAChatSdk destroyed: %@", _MEGAChatSdk);
    [MEGAChatSdk setLogToConsole:NO];
    [MEGASdk setLogToConsole:YES];
}

+ (MEGASdk *)sharedMEGASdkFolder {
    static MEGASdk *_megaSDKFolder = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        NSString *basePath = NSSearchPathForDirectoriesInDomains(NSCachesDirectory, NSUserDomainMask, YES).firstObject;
        _megaSDKFolder = [[MEGASdk alloc] initWithAppKey:MEGAiOSAppKey userAgent:[self userAgent] basePath:basePath];
        [_megaSDKFolder retrySSLErrors:YES];
    });
    return _megaSDKFolder;
}

@end
