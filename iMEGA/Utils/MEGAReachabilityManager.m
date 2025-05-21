#import "MEGAReachabilityManager.h"

#import <ifaddrs.h>
#import <arpa/inet.h>
#import <CoreTelephony/CTCellularData.h>

#import "SVProgressHUD.h"

#import "UIApplication+MNZCategory.h"

#ifdef MNZ_SHARE_EXTENSION
#import "MEGAShare-Swift.h"
#elif MNZ_NOTIFICATION_EXTENSION
#import "MEGANotifications-Swift.h"
#else
#import "MEGA-Swift.h"
#endif

@import MEGAL10nObjc;

@interface MEGAReachabilityManager ()

@property (nonatomic, strong) Reachability *reachability;
@property (nonatomic) NSString *lastKnownAddress;

@property (nonatomic, getter=isMobileDataEnabled) BOOL mobileDataEnabled;
@property (nonatomic) CTCellularDataRestrictedState mobileDataState;

@end

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
    NetworkStatus status = [[[MEGAReachabilityManager sharedManager] reachability] currentReachabilityStatus];
    return status == ReachableViaWiFi || status == ReachableViaWWAN;
}

+ (BOOL)isReachableViaWWAN {
    NetworkStatus status = [[[MEGAReachabilityManager sharedManager] reachability] currentReachabilityStatus];
    return status == ReachableViaWWAN;
}

+ (BOOL)isReachableViaWiFi {
    NetworkStatus status = [[[MEGAReachabilityManager sharedManager] reachability] currentReachabilityStatus];
    return status == ReachableViaWiFi;
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

+ (BOOL)isReachableHUDIfNot {
    BOOL isReachable = [self isReachable];
    if (!isReachable) {
        switch (MEGAReachabilityManager.sharedManager.mobileDataState) {
            case kCTCellularDataRestricted:
                [MEGAReachabilityManager.sharedManager mobileDataIsTurnedOffAlert];
                break;
            
            case kCTCellularDataRestrictedStateUnknown:
            case kCTCellularDataNotRestricted:
#if defined(SV_APP_EXTENSIONS) || defined(MAIN_APP_TARGET)
                [SVProgressHUD showImage:[UIImage megaImageWithNamed:@"hudForbidden"] status:LocalizedString(@"noInternetConnection", @"Text shown on the app when you don't have connection to the internet or when you have lost it")];
#endif
                break;
        }
    }
    
    return isReachable;
}

#pragma mark - Private Initialization

- (id)init {
    self = [super init];
    
    if (self) {
        self.reachability = [Reachability reachabilityForInternetConnection];
        [self.reachability startNotifier];
        _lastKnownAddress = self.currentAddress;
        [[NSNotificationCenter defaultCenter] addObserver:self
                                                 selector:@selector(reachabilityDidChange:)
                                                     name:kReachabilityChangedNotification object:nil];
        [self monitorAccessToMobileData];
    }
    
    return self;
}

#pragma mark - Get IP Address

- (NSString *)currentAddress {
    NSString *address = nil;
    
    struct ifaddrs *interfaces = NULL;
    struct ifaddrs *temp_addr = NULL;
    
    int success = 0;
    success = getifaddrs(&interfaces);
    if (success == 0) {
        
        temp_addr = interfaces;
        while(temp_addr != NULL) {
            if(temp_addr->ifa_addr->sa_family == AF_INET) {
                if([[NSString stringWithUTF8String:temp_addr->ifa_name] isEqualToString:@"en0"] || [[NSString stringWithUTF8String:temp_addr->ifa_name] isEqualToString:@"pdp_ip0"]) {
                    char straddr[INET_ADDRSTRLEN];
                    inet_ntop(AF_INET, (void *)&((struct sockaddr_in *)temp_addr->ifa_addr)->sin_addr, straddr, sizeof(straddr));
                    
                    if(strncasecmp(straddr, "127.", 4) && strncasecmp(straddr, "169.254.", 8)) {
                        address = [NSString stringWithUTF8String:straddr];
                    }
                }
            }
            
            if(temp_addr->ifa_addr->sa_family == AF_INET6) {
                if([[NSString stringWithUTF8String:temp_addr->ifa_name] isEqualToString:@"en0"] || [[NSString stringWithUTF8String:temp_addr->ifa_name] isEqualToString:@"pdp_ip0"]) {
                    char straddr[INET6_ADDRSTRLEN];
                    inet_ntop(AF_INET6, (void *)&((struct sockaddr_in6 *)temp_addr->ifa_addr)->sin6_addr, straddr, sizeof(straddr));
                    
                    if(strncasecmp(straddr, "FE80:", 5) && strncasecmp(straddr, "FD00:", 5)) {
                        address = [NSString stringWithFormat:@"[%@]", [NSString stringWithUTF8String:straddr]];
                    }
                }
            }
            
            temp_addr = temp_addr->ifa_next;
        }
    }
    
    freeifaddrs(interfaces);
    
    return address;
}

- (void)retryOrReconnect {
    if ([MEGAReachabilityManager isReachable]) {
        NSString *currentAddress = self.currentAddress;
        if ([self.lastKnownAddress isEqualToString:currentAddress]) {
            MEGALogDebug(@"[Reachability] IP didn't change (%@), retrying...", self.lastKnownAddress);
            [self retryPendingConnections];
        } else {
            MEGALogDebug(@"[Reachability] IP has changed (%@ -> %@), reconnecting...", self.lastKnownAddress, currentAddress);
            [self reconnect];
            self.lastKnownAddress = currentAddress;
        }
    }
}

- (void)retryPendingConnections {
    [MEGASdk.shared retryPendingConnections];
    [MEGAChatSdk.shared retryPendingConnections];
}

- (void)reconnect {
    MEGALogDebug(@"[Reachability] Reconnecting...");
    [MEGASdk.shared reconnect];
    [MEGASdk.sharedFolderLink reconnect];
    [MEGAChatSdk.shared reconnect];
}

- (void)monitorAccessToMobileData {
    CTCellularData *cellularData = CTCellularData.alloc.init;
    [self recordMobileDataState:cellularData.restrictedState];
    
    [cellularData setCellularDataRestrictionDidUpdateNotifier:^(CTCellularDataRestrictedState state) {
        [self recordMobileDataState:state];
    }];
}

- (void)recordMobileDataState:(CTCellularDataRestrictedState)state {
    self.mobileDataState = state;
    switch (state) {
        case kCTCellularDataRestrictedStateUnknown:
            MEGALogInfo(@"[Reachability] Access to Mobile Data is unknown");
            self.mobileDataEnabled = YES; //To avoid possible issues with devices that do not have 'Mobile Data', this value is YES when the state is unknown.
            break;
            
        case kCTCellularDataRestricted:
            MEGALogInfo(@"[Reachability] Access to Mobile Data is restricted");
            self.mobileDataEnabled = NO;
            break;
            
        case kCTCellularDataNotRestricted:
            MEGALogInfo(@"[Reachability] Access to Mobile Data is NOT restricted");
            self.mobileDataEnabled = YES;
            break;
    }
}

- (void)mobileDataIsTurnedOffAlert {
#ifdef MAIN_APP_TARGET
    UIAlertController *alertController = [UIAlertController alertControllerWithTitle:LocalizedString(@"Mobile Data is turned off", @"Information shown when the user has disabled the 'Mobile Data' setting for MEGA in the iOS Settings.") message:LocalizedString(@"You can turn on mobile data for this app in Settings.", @"Extra information shown when the user has disabled the 'Mobile Data' setting for MEGA in the iOS Settings.") preferredStyle:UIAlertControllerStyleAlert];
    [alertController addAction:[UIAlertAction actionWithTitle:LocalizedString(@"settingsTitle", @"Title of the Settings section") style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
        [UIApplication.sharedApplication openURL:[NSURL URLWithString:UIApplicationOpenSettingsURLString] options:@{} completionHandler:nil];
    }]];
    [alertController addAction:[UIAlertAction actionWithTitle:LocalizedString(@"ok", @"") style:UIAlertActionStyleDefault handler:nil]];
    
    dispatch_async(dispatch_get_main_queue(), ^{
        [UIApplication.mnz_presentingViewController presentViewController:alertController animated:YES completion:nil];
    });
#endif
}

#pragma mark - Reachability Changes

- (void)reachabilityDidChange:(NSNotification *)notification {
    [self retryOrReconnect];
}

@end
