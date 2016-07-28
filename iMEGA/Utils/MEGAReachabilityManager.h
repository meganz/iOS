
#import <Foundation/Foundation.h>
#import "Reachability.h"

@interface MEGAReachabilityManager : NSObject

+ (MEGAReachabilityManager *)sharedManager;

+ (BOOL)isReachable;
+ (BOOL)isReachableViaWWAN;
+ (BOOL)isReachableViaWiFi;
+ (bool)hasCellularConnection;

+ (BOOL)isReachableHUDIfNot;

@end
