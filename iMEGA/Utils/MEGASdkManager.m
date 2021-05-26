
#import "MEGASdkManager.h"

static const NSInteger MaximumNOFILE = 20000;

@implementation MEGASdkManager

+ (NSString *)userAgent {
    return [NSString stringWithFormat:@"%@/%@", MEGAiOSAppUserAgent, [[NSBundle mainBundle] objectForInfoDictionaryKey:@"CFBundleShortVersionString"]];
}

static MEGASdk *_megaSDK;
+ (MEGASdk *)sharedMEGASdk {
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

static MEGAChatSdk *_MEGAChatSdk;
+ (MEGAChatSdk *)sharedMEGAChatSdk {
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        _MEGAChatSdk = [[MEGAChatSdk alloc] init:[self sharedMEGASdk]];
        [MEGASdk setLogToConsole:NO];
        [MEGAChatSdk setLogToConsole:YES];
    });
    return _MEGAChatSdk;
}

static MEGASdk *_megaSDKFolder;
+ (MEGASdk *)sharedMEGASdkFolder {
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        NSString *basePath = NSSearchPathForDirectoriesInDomains(NSCachesDirectory, NSUserDomainMask, YES).firstObject;
        _megaSDKFolder = [[MEGASdk alloc] initWithAppKey:MEGAiOSAppKey userAgent:[self userAgent] basePath:basePath];
        [_megaSDKFolder setRLimitFileCount:MaximumNOFILE];
        [_megaSDKFolder retrySSLErrors:YES];
    });
    return _megaSDKFolder;
}

+ (void)deleteSharedSdks {
    [_MEGAChatSdk deleteMegaChatApi];
    [_megaSDK deleteMegaApi];
    [_megaSDKFolder deleteMegaApi];
}

@end
