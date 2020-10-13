#import <Foundation/Foundation.h>
#import "MEGASdk.h"
#import "MEGAChatSdk.h"

NS_ASSUME_NONNULL_BEGIN

@interface MEGASdkManager : NSObject

+ (MEGASdk *)sharedMEGASdk;
+ (nullable MEGAChatSdk *)sharedMEGAChatSdk;

+ (void)createSharedMEGAChatSdk;
+ (void)destroySharedMEGAChatSdk;

+ (MEGASdk *)sharedMEGASdkFolder;

@end

NS_ASSUME_NONNULL_END
