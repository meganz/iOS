#import "UIImageView+MNZCategory.h"
#import "UIImage+GKContact.h"
#import "MEGASdkManager.h"

@implementation UIImageView (MNZCategory)

- (void)mnz_setImageForUser:(MEGAUser *)user {
    self.layer.cornerRadius = self.frame.size.width / 2;
    self.layer.masksToBounds = YES;
    
    NSString *avatarFilePath = [[[NSSearchPathForDirectoriesInDomains(NSCachesDirectory, NSUserDomainMask, YES) objectAtIndex:0] stringByAppendingPathComponent:@"thumbnailsV3"] stringByAppendingPathComponent:user.email];
    if ([[NSFileManager defaultManager] fileExistsAtPath:avatarFilePath]) {
        self.image = [UIImage imageWithContentsOfFile:avatarFilePath];
    } else {
        NSString *colorString = [[MEGASdkManager sharedMEGASdk] avatarColorForUser:user];
        UIImage *avatar = [UIImage imageForName:[user email].uppercaseString size:self.frame.size backgroundColor:[UIColor colorFromHexString:colorString] textColor:[UIColor whiteColor] font:[UIFont fontWithName:@"SFUIText-Light" size:(self.frame.size.width/2)]];
        self.image = avatar;
        
        [[MEGASdkManager sharedMEGASdk] getAvatarUser:user destinationFilePath:avatarFilePath delegate:self];
    }
}

- (void)mnz_setImageForParticipant:(MEGAParticipant *)participant {
    self.layer.cornerRadius = self.frame.size.width / 2;
    self.layer.masksToBounds = YES;
    
    NSString *participantBase64Handle = [MEGASdk base64HandleForHandle:participant.handle];
    NSString *avatarFilePath = [[[NSSearchPathForDirectoriesInDomains(NSCachesDirectory, NSUserDomainMask, YES) objectAtIndex:0] stringByAppendingPathComponent:@"thumbnailsV3"] stringByAppendingPathComponent:participantBase64Handle];
    if ([[NSFileManager defaultManager] fileExistsAtPath:avatarFilePath]) {
        self.image = [UIImage imageWithContentsOfFile:avatarFilePath];
    } else {
        NSString *colorString = [[MEGASdkManager sharedMEGASdk] avatarColorForBase64UserHandle:participantBase64Handle];
        NSString *initialsForAvatar = (participant.email) ? participant.email.uppercaseString : participant.name.uppercaseString;
        UIImage *avatar = [UIImage imageForName:initialsForAvatar size:self.frame.size backgroundColor:[UIColor colorFromHexString:colorString] textColor:[UIColor whiteColor] font:[UIFont fontWithName:@"SFUIText-Light" size:(self.frame.size.width/2)]];
        self.image = avatar;
        
        [[MEGASdkManager sharedMEGASdk] getAvatarUserWithEmailOrHandle:participantBase64Handle destinationFilePath:avatarFilePath delegate:self];
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
