
#import <Foundation/Foundation.h>
#import "Reachability.h"

@interface MEGAReachabilityManager : NSObject

+ (MEGAReachabilityManager *)sharedManager;

+ (BOOL)isReachable;
+ (BOOL)isReachableViaWWAN;
+ (BOOL)isReachableViaWiFi;
+ (bool)hasCellularConnection;

+ (BOOL)isReachableHUDIfNot;

- (void)retryOrReconnect;
- (void)retryPendingConnections;
- (void)reconnect;

@property (nonatomic, readonly) NSString *currentAddress;
@property (nonatomic, getter=isMobileDataEnabled, readonly) BOOL mobileDataEnabled;

@end
