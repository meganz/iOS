
#import "MEGAUserAlertList+MNZCategory.h"

#import "MEGAUserAlert.h"

@implementation MEGAUserAlertList (MNZCategory)

- (NSArray<MEGAUserAlert *> *)mnz_userAlertsArray {
    NSInteger userAlertListCount = self.size;
    
    NSMutableArray<MEGAUserAlert *> *userAlertsArray = [[NSMutableArray<MEGAUserAlert *> alloc] initWithCapacity:userAlertListCount];
    for (NSUInteger i = 0; i < userAlertListCount; i++) {
        MEGAUserAlert *userAlert = [self usertAlertAtIndex:i];
        [userAlertsArray insertObject:userAlert atIndex:0];
    }
    
    return [userAlertsArray copy];
}

- (NSUInteger)mnz_unseenCount {
    NSUInteger unseenCount = 0;
    
    NSInteger userAlertListCount = self.size;
    for (NSUInteger i = 0; i < userAlertListCount; i++) {
        MEGAUserAlert *userAlert = [self usertAlertAtIndex:i];
        if (!userAlert.isSeen) {
            unseenCount++;
        }
    }
    
    return unseenCount;
}

@end
