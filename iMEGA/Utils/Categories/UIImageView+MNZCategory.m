#import "UIImageView+MNZCategory.h"

#import "Helper.h"
#import "UIImage+MNZCategory.h"
#import "MEGAGetThumbnailRequestDelegate.h"
#import "MEGAGetPreviewRequestDelegate.h"
#import <objc/runtime.h>
#import "MEGASdk+MNZCategory.h"

@import MEGAUIKit;
#ifdef MNZ_SHARE_EXTENSION
#import "MEGAShare-Swift.h"
#else
#import "MEGA-Swift.h"
#endif

@import SDWebImage;
@import MEGAAppSDKRepo;

static const void *base64HandleKey = &base64HandleKey;

@implementation UIImageView (MNZCategory)

- (NSString *)base64Handle {
    return objc_getAssociatedObject(self, base64HandleKey);
}

- (void)setBase64Handle:(NSString *)base64Handle {
    objc_setAssociatedObject(self, &base64HandleKey, base64Handle, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
}

- (void)mnz_setImageForUserHandle:(uint64_t)userHandle {
    [self mnz_setImageForUserHandle:userHandle name:@"Unknown"];
}

- (void)mnz_setImageForUserHandle:(uint64_t)userHandle name:(NSString *)name {
    self.layer.cornerRadius = self.frame.size.width / 2;
    self.layer.masksToBounds = YES;
    
    self.base64Handle = [MEGASdk base64HandleForUserHandle:userHandle];
    MEGAGetThumbnailRequestDelegate *getThumbnailRequestDelegate = [[MEGAGetThumbnailRequestDelegate alloc] initWithCompletion:^(MEGARequest *request) {
        if ([request.file containsString:self.base64Handle]) {
            self.image = [UIImage imageWithContentsOfFile:request.file];
        }
    }];
    
    // "mnz_imageForUserHandle" saves the image to the disk. In case the image already exists in the path then returns the image.
    // The problem with passing the image view size is that if the other imageview is using the same method but larger in size.
    // Then the image may look pixelated in the image view. So it is better to use the largest size possible that is used in the application
    // So I think 100 is the good number.
    CGSize imageSize = CGSizeMake(UIScreen.mainScreen.scale * 100, UIScreen.mainScreen.scale * 100);
    self.image = [UIImage mnz_imageForUserHandle:userHandle name:name size:imageSize delegate:getThumbnailRequestDelegate];
}

- (void)mnz_setImageAvatarOrColorForUserHandle:(uint64_t)userHandle {
    NSString *base64Handle = [MEGASdk base64HandleForUserHandle:userHandle];
    NSString *avatarFilePath = [[Helper pathForSharedSandboxCacheDirectory:@"thumbnailsV3"] stringByAppendingPathComponent:base64Handle];
    
    self.base64Handle =  base64Handle;
    if ([[NSFileManager defaultManager] fileExistsAtPath:avatarFilePath]) {
        self.image = [UIImage imageWithContentsOfFile:avatarFilePath];
    } else {
        self.image = [UIImage imageWithColor:[UIColor mnz_fromHexString:[MEGASdk avatarColorForBase64UserHandle:base64Handle]] andBounds:self.bounds];
        MEGAGetThumbnailRequestDelegate *getThumbnailRequestDelegate = [[MEGAGetThumbnailRequestDelegate alloc] initWithCompletion:^(MEGARequest *request) {
            if ([request.file containsString:self.base64Handle]) {
                self.image = [UIImage imageWithContentsOfFile:request.file];
            }
        }];
        [MEGASdk.shared getAvatarUserWithEmailOrHandle:base64Handle destinationFilePath:avatarFilePath delegate:getThumbnailRequestDelegate];
    }
}

- (void)mnz_setImageUsingCurrentUserAvatarOrColor {
    [self mnz_setImageAvatarOrColorForUserHandle:MEGASdk.currentUserHandle.unsignedLongLongValue];
}

- (void)mnz_setThumbnailByNode:(MEGANode *)node {
    if (node.hasThumbnail) {
        NSString *path = [Helper pathForNode:node inSharedSandboxCacheDirectory:@"thumbnailsV3"];
        if ([[NSFileManager defaultManager] fileExistsAtPath:path]) {
            [self sd_setImageWithURL:[NSURL fileURLWithPath:path]];
        } else {
            MEGAGetThumbnailRequestDelegate *delegate = [[MEGAGetThumbnailRequestDelegate alloc] initWithCompletion:^(MEGARequest *request) {
                [self sd_setImageWithURL:[NSURL fileURLWithPath:request.file]];
            }];
            [self setImage:[NodeAssetsManager.shared iconFor:node]];
            [MEGASdk.shared getThumbnailNode:node destinationFilePath:path delegate:delegate];
        }
    } else {
        [self setImage:[NodeAssetsManager.shared iconFor:node]];
    }
}

- (void)mnz_setPreviewByNode:(MEGANode *)node completion:(nullable MNZWebImageCompletionBlock)completion {
    if (node.hasPreview) {
        NSString *path = [Helper pathForNode:node inSharedSandboxCacheDirectory:@"previewsV3"];
        NSString *originalPath = [Helper pathWithOriginalNameForNode:node inSharedSandboxCacheDirectory:@"originalV3"];
    
        if ([[NSFileManager defaultManager] fileExistsAtPath:path]) {
            [self sd_setImageWithURL:[NSURL fileURLWithPath:path]];
        } else if ([[NSFileManager defaultManager] fileExistsAtPath:originalPath] && [FileExtensionGroupOCWrapper verifyIsImage:node.name]) {
            [self sd_setImageWithURL:[NSURL fileURLWithPath:originalPath]];
        } else {
            MEGAGetPreviewRequestDelegate *delegate = [[MEGAGetPreviewRequestDelegate alloc] initWithCompletion:^(MEGARequest *request) {
                if (completion) {
                    completion(request);
                }
            }];
            self.image = nil;
            [MEGASdk.shared getPreviewNode:node destinationFilePath:path delegate:delegate];
        }
    } else {
        [self setImage:[NodeAssetsManager.shared iconFor:node]];
    }
}

@end
