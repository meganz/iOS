#import <UIKit/UIKit.h>

@interface UIImageView (MNZCategory) <MEGARequestDelegate>

- (void)mnz_setImageForUserHandle:(uint64_t)userHandle;
- (void)mnz_setThumbnailByNode:(MEGANode *)node;

- (void)mnz_setImageForExtension:(NSString *)extension;
- (void)mnz_imageForNode:(MEGANode *)node;

- (void)mnz_setImageForChatSharedContactHandle:(uint64_t)userHandle initial:(NSString*)initial;

@end
