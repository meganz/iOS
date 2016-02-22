/**
 * @file MEGAReachabilityManager.m
 * @brief Reachability manager.
 *
 * (c) 2013-2015 by Mega Limited, Auckland, New Zealand
 *
 * This file is part of the MEGA SDK - Client Access Engine.
 *
 * Applications using the MEGA API must present a valid application key
 * and comply with the the rules set forth in the Terms of Service.
 *
 * The MEGA SDK is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.
 *
 * @copyright Simplified (2-clause) BSD License.
 *
 * You should have received a copy of the license along with this
 * program.
 */

#import <ifaddrs.h>
#import "MEGAReachabilityManager.h"

@implementation MEGAReachabilityManager

+ (MEGAReachabilityManager *)sharedManager {
    static MEGAReachabilityManager *_sharedManager = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        _sharedManager = [[self alloc] init];
    });
    
    return _sharedManager;
}
+ (BOOL)isReachable {
    return [[[MEGAReachabilityManager sharedManager] reachability] isReachable];
}

+ (BOOL)isReachableViaWWAN {
    return [[[MEGAReachabilityManager sharedManager] reachability] isReachableViaWWAN];
}

+ (BOOL)isReachableViaWiFi {
    return [[[MEGAReachabilityManager sharedManager] reachability] isReachableViaWiFi];
}

+ (bool)hasCellularConnection {
    struct ifaddrs * addrs;
    const struct ifaddrs * cursor;
    bool found = false;
    if (getifaddrs(&addrs) == 0) {
        cursor = addrs;
        while (cursor != NULL) {
            NSString *name = [NSString stringWithUTF8String:cursor->ifa_name];
            if ([name isEqualToString:@"pdp_ip0"]) {
                found = true;
                break;
            }
            cursor = cursor->ifa_next;
        }
        freeifaddrs(addrs);
    }
    return found;
}

#pragma mark - Private Initialization

- (id)init {
    self = [super init];
    
    if (self) {
        self.reachability = [Reachability reachabilityWithHostname:@"www.google.com"];
        [self.reachability startNotifier];
    }
    
    return self;
}

@end
