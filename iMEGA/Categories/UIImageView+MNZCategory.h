#import <UIKit/UIKit.h>

@interface UIImageView (MNZCategory) <MEGARequestDelegate>

- (void)mnz_setImageForUserHandle:(uint64_t)userHandle;

@end
