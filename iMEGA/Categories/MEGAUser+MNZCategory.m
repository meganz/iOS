
#import "MEGAUser+MNZCategory.h"

#import "Helper.h"
#import "MEGAStore.h"
#import "NSString+MNZCategory.h"

@implementation MEGAUser (MNZCategory)

- (NSString *)mnz_fullName {
    MOUser *moUser = [[MEGAStore shareInstance] fetchUserWithUserHandle:self.handle];
    return moUser.fullName;
}

- (NSString *)mnz_firstName {
    MOUser *moUser = [[MEGAStore shareInstance] fetchUserWithUserHandle:self.handle];
    return moUser.firstname;
}

- (NSString *)mnz_nickname {
    return [MEGAStore.shareInstance fetchUserWithUserHandle:self.handle].nickname;
}

- (void)setMnz_nickname:(NSString *)mnz_nickname {
    [MEGAStore.shareInstance updateUserWithUserHandle:self.handle
                                               nickname:mnz_nickname
                                              context:nil];
}

- (NSString *)mnz_displayName {
    MOUser *moUser = [MEGAStore.shareInstance fetchUserWithUserHandle:self.handle];
    return moUser.displayName;
}

@end
