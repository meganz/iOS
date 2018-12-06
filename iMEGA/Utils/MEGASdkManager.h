#import <Foundation/Foundation.h>
#import "MEGASdk.h"
#import "MEGAChatSdk.h"

@interface MEGASdkManager : NSObject

+ (MEGASdk *)sharedMEGASdk;
+ (MEGAChatSdk *)sharedMEGAChatSdk;
+ (MEGASdk *)createMEGASdk;

+ (void)createSharedMEGAChatSdk;
+ (void)destroySharedMEGAChatSdk;

+ (MEGASdk *)sharedMEGASdkFolder;

@end
