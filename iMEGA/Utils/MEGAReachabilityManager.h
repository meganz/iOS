
#import <Foundation/Foundation.h>
#import "Reachability.h"

typedef NS_ENUM (NSInteger, MEGAChatRoomListState) {
    MEGAChatRoomListStateOffline,
    MEGAChatRoomListStateInProgress,
    MEGAChatRoomListStateOnline
};

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

@property (nonatomic) MEGAChatRoomListState chatRoomListState;
@property (nonatomic, readonly) NSString *currentAddress;

@end
