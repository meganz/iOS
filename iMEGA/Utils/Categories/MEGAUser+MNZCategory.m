
#import "MEGAUser+MNZCategory.h"

#import "Helper.h"
#import "MEGAStore.h"
#import "NSString+MNZCategory.h"
#import "NSFileManager+MNZCategory.h"

@implementation MEGAUser (MNZCategory)

- (NSString *)mnz_fullName {
    return [[self class] mnz_fullName:self.handle];
}

+ (NSString *)mnz_fullName:(uint64_t)handle {
    MOUser *moUser = [[MEGAStore shareInstance] fetchUserWithUserHandle:handle];
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
    [MEGAStore.shareInstance updateUserWithUserHandle:self.handle nickname:mnz_nickname];
}

- (NSString *)mnz_displayName {
    MOUser *moUser = [MEGAStore.shareInstance fetchUserWithUserHandle:self.handle];
    return moUser.displayName == nil ? @"" : moUser.displayName;
}

- (void)resetAvatarIfNeededInSdk:(MEGASdk *)sdk {
    if ([self hasChangedType:MEGAUserChangeTypeAvatar] || [self hasChangedType:MEGAUserChangeTypeFirstname]) {
        [self removeAvatarFromLocalCache];
        [sdk getAvatarUser:self destinationFilePath:[self avatarFilePath]];
    }
}

- (void)removeAvatarFromLocalCache {
    [NSFileManager.defaultManager mnz_removeItemAtPath:[self avatarFilePath]];
}

- (NSString *)avatarFilePath {
    NSString *userBase64Handle = [MEGASdk base64HandleForUserHandle:self.handle];
    return [[Helper pathForSharedSandboxCacheDirectory:@"thumbnailsV3"] stringByAppendingPathComponent:userBase64Handle];
}

@end
