#import <Foundation/Foundation.h>
#import "MEGASdk.h"
#import "MEGAChatSdk.h"

NS_ASSUME_NONNULL_BEGIN

@interface MEGASdkManager : NSObject

+ (MEGASdk *)sharedMEGASdk;
+ (MEGAChatSdk *)sharedMEGAChatSdk;

+ (MEGASdk *)sharedMEGASdkFolder;

@end

NS_ASSUME_NONNULL_END
