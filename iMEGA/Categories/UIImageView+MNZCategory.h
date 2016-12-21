#import <UIKit/UIKit.h>
#import "MEGAParticipant.h"

@interface UIImageView (MNZCategory) <MEGARequestDelegate>

- (void)mnz_setImageForUserHandle:(uint64_t)userHandle;
- (void)mnz_setImageForParticipant:(MEGAParticipant *)participant;

@end
