
#import "MEGASdkManager.h"

static const NSInteger MaximumNOFILE = 20000;

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
        NSURL *basePathURL;
#ifndef MNZ_NOTIFICATION_EXTENSION
        basePathURL = [NSFileManager.defaultManager URLForDirectory:NSApplicationSupportDirectory inDomain:NSUserDomainMask appropriateForURL:nil create:YES error:&error];
#else
        NSURL *containerURL = [NSFileManager.defaultManager containerURLForSecurityApplicationGroupIdentifier:MEGAGroupIdentifier];
        basePathURL = [containerURL URLByAppendingPathComponent:MEGANotificationServiceExtensionCacheFolder isDirectory:YES];
        [NSFileManager.defaultManager createDirectoryAtURL:basePathURL withIntermediateDirectories:YES attributes:nil error:&error];
#endif
        if (error) {
            MEGALogError(@"Failed to locate/create basePathURL with error: %@", error);
        }

        _megaSDK = [[MEGASdk alloc] initWithAppKey:MEGAiOSAppKey userAgent:[self userAgent] basePath:basePathURL.path];
        [_megaSDK setRLimitFileCount:MaximumNOFILE];
        [_megaSDK retrySSLErrors:YES];
    });
    return _megaSDK;
}

+ (MEGAChatSdk *)sharedMEGAChatSdk {
    return _MEGAChatSdk;
}

+ (void)createSharedMEGAChatSdk {
    _MEGAChatSdk = [[MEGAChatSdk alloc] init:[self sharedMEGASdk]];
#ifndef MNZ_APP_EXTENSION
    [_MEGAChatSdk addChatDelegate:(id<MEGAChatDelegate>)[[UIApplication sharedApplication] delegate]];
    [_MEGAChatSdk addChatRequestDelegate:(id<MEGAChatRequestDelegate>)[[UIApplication sharedApplication] delegate]];
#endif
    MEGALogDebug(@"_MEGAChatSdk created: %@", _MEGAChatSdk);
    [MEGASdk setLogToConsole:NO];
    [MEGAChatSdk setLogToConsole:YES];
}

+ (void)destroySharedMEGAChatSdk {
#ifndef MNZ_APP_EXTENSION
    [_MEGAChatSdk removeChatDelegate:(id<MEGAChatDelegate>)[[UIApplication sharedApplication] delegate]];
    [_MEGAChatSdk removeChatRequestDelegate:(id<MEGAChatRequestDelegate>)[[UIApplication sharedApplication] delegate]];
#endif
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
        [_megaSDKFolder setRLimitFileCount:MaximumNOFILE];
        [_megaSDKFolder retrySSLErrors:YES];
    });
    return _megaSDKFolder;
}

@end
