#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

typedef void (^MNZWebImageCompletionBlock)(MEGARequest *request);

@interface UIImageView (MNZCategory)

- (void)mnz_setImageAvatarOrColorForUserHandle:(uint64_t)userHandle;
- (void)mnz_setImageUsingCurrentUserAvatarOrColor;
- (void)mnz_setImageForUserHandle:(uint64_t)userHandle;
- (void)mnz_setImageForUserHandle:(uint64_t)userHandle name:(NSString *)name;

/**
 A convenient method to set thumbnail image by a MEGANode object
 
 If the node has thumbnail, we first try to search the thumbnail image from local cache, if not found, we will download the thumbnail image from MEGA server.
 If the node doesn't have thubnail, we will set some predefined placeholder images according to the node data type
 
 @param node MEGANode object
 */
- (void)mnz_setThumbnailByNode:(MEGANode *)node;

/**
A convenient method to set preview image by a MEGANode object

If the node has thumbnail, we first try to search the preview image from local cache, if not found, we will download the preview image from MEGA server.
If the node doesn't have preview, we will set some predefined placeholder images according to the node data type

@param node MEGANode object
*/
- (void)mnz_setPreviewByNode:(MEGANode *)node completion:(nullable MNZWebImageCompletionBlock)completion;

@end

NS_ASSUME_NONNULL_END
