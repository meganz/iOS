
#import "MEGAUser+MNZCategory.h"

#import "Helper.h"
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

- (CNContact *)mnz_cnContact {
    CNMutableContact *cnContact = [[CNMutableContact alloc] init];
    
    MOUser *moUser = [[MEGAStore shareInstance] fetchUserWithUserHandle:self.handle];
    if (moUser.firstName) {
        cnContact.givenName = moUser.firstname;
    }
    if (moUser.lastname) {
        cnContact.familyName = moUser.lastname;
    }
    if (moUser.email) {
        cnContact.emailAddresses = @[[CNLabeledValue labeledValueWithLabel:CNLabelHome value:moUser.email]];
    }
    
    NSString *avatarFilePath = [[Helper pathForSharedSandboxCacheDirectory:@"thumbnailsV3"] stringByAppendingPathComponent:[MEGASdk base64HandleForUserHandle:self.handle]];
    if ([[NSFileManager defaultManager] fileExistsAtPath:avatarFilePath]) {
        UIImage *avatarImage = [UIImage imageWithContentsOfFile:avatarFilePath];
        cnContact.imageData = UIImageJPEGRepresentation(avatarImage, 1.0f);
    }
    
    return cnContact;
}

@end
