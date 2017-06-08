#import <Foundation/Foundation.h>
#import "MEGASdk.h"
#import "MEGAChatSdk.h"

@interface MEGASdkManager : NSObject

@property (nonatomic, strong) MEGASdk *megaSDK;
@property (nonatomic, strong) MEGAChatSdk *MEGAChatSdk;

+ (void)setAppKey:(NSString *)appKey;
+ (void)setUserAgent:(NSString *)userAgent;
+ (MEGASdk *)sharedMEGASdk;
+ (MEGAChatSdk *)sharedMEGAChatSdk;
+ (void)createSharedMEGAChatSdk;
+ (void)destroySharedMEGAChatSdk;

+ (MEGASdk *)sharedMEGASdkFolder;

@end
