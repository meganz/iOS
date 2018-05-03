
#import <ifaddrs.h>
#import <arpa/inet.h>

#import "SVProgressHUD.h"

#import "MEGAReachabilityManager.h"
#import "MEGASdkManager.h"

#import "CameraUploads.h"

@interface MEGAReachabilityManager ()

@property (nonatomic, strong) Reachability *reachability;
@property (nonatomic, copy) NSString *IpAddress;

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
        [SVProgressHUD showImage:[UIImage imageNamed:@"hudForbidden"] status:NSLocalizedString(@"noInternetConnection", @"Text shown on the app when you don't have connection to the internet or when you have lost it")];
    }
    
    return isReachable;
}

#pragma mark - Private Initialization

- (id)init {
    self = [super init];
    
    if (self) {
        self.reachability = [Reachability reachabilityForInternetConnection];
        [self.reachability startNotifier];
        _IpAddress = [self getIpAddress];
        [[NSNotificationCenter defaultCenter] addObserver:self
                                                 selector:@selector(reachabilityDidChange:)
                                                     name:kReachabilityChangedNotification object:nil];
    }
    
    return self;
}

#pragma mark - Get IP Address

- (NSString *)getIpAddress {
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
                    inet_ntop(AF_INET6, (void *)&((struct sockaddr_in *)temp_addr->ifa_addr)->sin_addr, straddr, sizeof(straddr));
                    
                    if(strncasecmp(straddr, "FE80:", 5) && strncasecmp(straddr, "FD00:", 5)) {
                        address = [NSString stringWithUTF8String:straddr];
                    }
                }
            }
            
            temp_addr = temp_addr->ifa_next;
        }
    }
    
    freeifaddrs(interfaces);
    
    return address;
}

- (void)reconnectIfIPHasChanged {
    if ([MEGAReachabilityManager isReachable]) {
        NSString *currentIP = [self getIpAddress];
        if (![self.IpAddress isEqualToString:currentIP]) {
            MEGALogDebug(@"IP has changed (%@ -> %@), reconnecting...", self.IpAddress, currentIP);
            [[MEGASdkManager sharedMEGASdk] reconnect];
            self.IpAddress = currentIP;
        }
    }
}


#pragma mark - Reachability Changes

- (void)reachabilityDidChange:(NSNotification *)notification {
    [self reconnectIfIPHasChanged];
    
    if ([[CameraUploads syncManager] isCameraUploadsEnabled]) {
        if (![[CameraUploads syncManager] isUseCellularConnectionEnabled]) {
            if ([MEGAReachabilityManager isReachableViaWWAN]) {
                [[CameraUploads syncManager] resetOperationQueue];
            }
            
            if ([[MEGASdkManager sharedMEGASdk] isLoggedIn] && [MEGAReachabilityManager isReachableViaWiFi]) {
                MEGALogInfo(@"Enable Camera Uploads");
                [[CameraUploads syncManager] setIsCameraUploadsEnabled:YES];
            }
        }
    }
    
    if ([MEGAReachabilityManager isReachable]) {
        NSUInteger chatsConnected = 0;
        MEGAChatListItemList *chatList = [[MEGASdkManager sharedMEGAChatSdk] activeChatListItems];
        for (NSUInteger i=0; i<chatList.size; i++) {
            MEGAChatListItem *chat = [chatList chatListItemAtIndex:i];
            MEGAChatConnection state = [[MEGASdkManager sharedMEGAChatSdk] chatConnectionState:chat.chatId];
            if (state == MEGAChatConnectionOnline) {
                chatsConnected++;
            }
        }
        self.chatRoomListState = chatsConnected == chatList.size ? MEGAChatRoomListStateOnline : MEGAChatRoomListStateInProgress;
    } else {
        self.chatRoomListState = MEGAChatRoomListStateOffline;
    }
}

@end
