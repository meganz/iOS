#import "MEGAUser+MNZCategory.h"
#import "MEGAStore.h"

@implementation MEGAUser (MNZCategory)

- (NSString *)mnz_fullName {
    MOUser *moUser = [[MEGAStore shareInstance] fetchUserWithUserHandle:self.handle];
    return moUser.fullName;
}

- (NSString *)mnz_firstName {
    MOUser *moUser = [[MEGAStore shareInstance] fetchUserWithUserHandle:self.handle];
    return moUser.firstname;
}

@end
