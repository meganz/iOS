
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

- (void)reconnectIfIPHasChanged;

@property (nonatomic) MEGAChatRoomListState chatRoomListState;

@end
