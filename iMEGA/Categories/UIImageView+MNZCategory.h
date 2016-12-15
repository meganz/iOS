#import <UIKit/UIKit.h>
#import "MEGAParticipant.h"

@interface UIImageView (MNZCategory) <MEGARequestDelegate>

- (void)mnz_setImageForUser:(MEGAUser *)user;
- (void)mnz_setImageForParticipant:(MEGAParticipant *)participant;

@end
