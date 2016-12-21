#import "MEGAUser+MNZCategory.h"
#import "MEGAStore.h"

@implementation MEGAUser (MNZCategory)

- (NSString *)mnz_fullName {
    MOUser *moUser = [[MEGAStore shareInstance] fetchUserWithUserHandle:self.handle];
    NSString *fullName = nil;
    if (moUser) {
        if (moUser.firstname) {
            fullName = moUser.firstname;
            if (moUser.lastname) {
                fullName = [[fullName stringByAppendingString:@" "] stringByAppendingString:moUser.lastname];
            }
        } else {
            if (moUser.lastname) {
                fullName = moUser.lastname;
            }
        }
    }
    
    if(![[fullName stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]] length]) {
        fullName = nil;
    }
    
    return fullName;
}

@end
