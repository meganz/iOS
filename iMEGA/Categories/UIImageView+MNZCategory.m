#import "UIImageView+MNZCategory.h"
#import "UIImage+GKContact.h"
#import "MEGASdkManager.h"
#import "MEGAStore.h"

@implementation UIImageView (MNZCategory)

- (void)mnz_setImageForUserHandle:(uint64_t)userHandle {
    self.layer.cornerRadius = self.frame.size.width / 2;
    self.layer.masksToBounds = YES;
    
    NSString *base64Handle = [MEGASdk base64HandleForUserHandle:userHandle];
    NSString *avatarFilePath = [[[NSSearchPathForDirectoriesInDomains(NSCachesDirectory, NSUserDomainMask, YES) objectAtIndex:0] stringByAppendingPathComponent:@"thumbnailsV3"] stringByAppendingPathComponent:base64Handle];
    if ([[NSFileManager defaultManager] fileExistsAtPath:avatarFilePath]) {
        self.image = [UIImage imageWithContentsOfFile:avatarFilePath];
    } else {
        NSString *colorString = [MEGASdk avatarColorForBase64UserHandle:base64Handle];
        MOUser *user = [[MEGAStore shareInstance] fetchUserWithUserHandle:userHandle];
        NSString *initialsForAvatar = nil;
        if (user) {
            if (user.email.length) {
                initialsForAvatar = user.email.uppercaseString;
            } else {
                initialsForAvatar = [NSString stringWithFormat:@"%@ %@", user.firstname, user.lastname];
            }
        } else {
            initialsForAvatar = @"?";
        }
        UIImage *avatar = [UIImage imageForName:initialsForAvatar size:self.frame.size backgroundColor:[UIColor colorFromHexString:colorString] textColor:[UIColor whiteColor] font:[UIFont mnz_SFUILightWithSize:(self.frame.size.width/2.0f)]];
        self.image = avatar;
        
        [[MEGASdkManager sharedMEGASdk] getAvatarUserWithEmailOrHandle:base64Handle destinationFilePath:avatarFilePath delegate:self];
    }
}

- (void)onRequestFinish:(MEGASdk *)api request:(MEGARequest *)request error:(MEGAError *)error {
    if (error.type != MEGAErrorTypeApiOk) {
        return;
    }
    
    if (request.type == MEGARequestTypeGetAttrUser) {
        self.image = [UIImage imageWithContentsOfFile:request.file];
    }
}

@end
