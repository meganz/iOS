#import <UIKit/UIKit.h>

@interface UIImageView (MNZCategory) <MEGARequestDelegate>

- (void)mnz_setImageForUserHandle:(uint64_t)userHandle;
- (void)mnz_setThumbnailByNodeHandle:(uint64_t)nodeHandle;
- (void)mnz_setImageForExtension:(NSString *)extension;

@end
