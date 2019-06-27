
#import "MEGAUserAlertList+MNZCategory.h"

#import "MEGAUserAlert.h"

@implementation MEGAUserAlertList (MNZCategory)

- (NSArray<MEGAUserAlert *> *)mnz_relevantUserAlertsArray {
    NSInteger userAlertListCount = self.size;
    
    NSMutableArray<MEGAUserAlert *> *userAlertsArray = [[NSMutableArray<MEGAUserAlert *> alloc] initWithCapacity:userAlertListCount];
    for (NSUInteger i = 0; i < userAlertListCount; i++) {
        MEGAUserAlert *userAlert = [self usertAlertAtIndex:i];
        if (userAlert.isRelevant) {
            [userAlertsArray insertObject:userAlert atIndex:0];
        }
    }
    
    return [userAlertsArray copy];
}

- (NSUInteger)mnz_relevantUnseenCount {
    NSUInteger unseenCount = 0;
    
    NSInteger userAlertListCount = self.size;
    for (NSUInteger i = 0; i < userAlertListCount; i++) {
        MEGAUserAlert *userAlert = [self usertAlertAtIndex:i];
        if (!userAlert.isSeen && userAlert.isRelevant) {
            unseenCount++;
        }
    }
    
    return unseenCount;
}

@end
