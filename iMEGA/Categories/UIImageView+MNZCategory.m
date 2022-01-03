
#import "UIImageView+MNZCategory.h"

#import "Helper.h"
#import "MEGASdkManager.h"
#import "UIImage+MNZCategory.h"
#import "MEGAGetThumbnailRequestDelegate.h"
#import "MEGAGetPreviewRequestDelegate.h"
#import "MEGAGenericRequestDelegate.h"
#import <SDWebImage/SDWebImage.h>
#import <objc/runtime.h>
#import "MEGASdk+MNZCategory.h"

#ifdef MNZ_SHARE_EXTENSION
#import "MEGAShare-Swift.h"
#elif MNZ_PICKER_EXTENSION
#import "MEGAPicker-Swift.h"
#else
#import "MEGA-Swift.h"
#endif

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
        [[MEGASdkManager sharedMEGASdk] getAvatarUserWithEmailOrHandle:base64Handle destinationFilePath:avatarFilePath delegate:getThumbnailRequestDelegate];
    }
}

- (void)mnz_setImageUsingCurrentUserAvatarOrColor {
    [self mnz_setImageAvatarOrColorForUserHandle:MEGASdkManager.sharedMEGASdk.myUser.handle];
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
            [self mnz_imageForNode:node];
            [[MEGASdkManager sharedMEGASdk] getThumbnailNode:node destinationFilePath:path delegate:delegate];
        }
    } else {
        [self mnz_imageForNode:node];
    }
}

- (void)mnz_setPreviewByNode:(MEGANode *)node completion:(nullable MNZWebImageCompletionBlock)completion {
    if (node.hasPreview) {
        NSString *path = [Helper pathForNode:node inSharedSandboxCacheDirectory:@"previewsV3"];
        NSString *originalPath = [Helper pathWithOriginalNameForNode:node inSharedSandboxCacheDirectory:@"originalV3"];
    
        if ([[NSFileManager defaultManager] fileExistsAtPath:path]) {
            [self sd_setImageWithURL:[NSURL fileURLWithPath:path]];
        } else if ([[NSFileManager defaultManager] fileExistsAtPath:originalPath]) {
            [self sd_setImageWithURL:[NSURL fileURLWithPath:originalPath]];
        } else {
            MEGAGetPreviewRequestDelegate *delegate = [[MEGAGetPreviewRequestDelegate alloc] initWithCompletion:^(MEGARequest *request) {
                if (completion) {
                    completion(request);
                }
            }];
            self.image = nil;
            [[MEGASdkManager sharedMEGASdk] getPreviewNode:node destinationFilePath:path delegate:delegate];
        }
    } else {
        [self mnz_imageForNode:node];
    }
}

- (void)mnz_setImageForExtension:(NSString *)extension {
    extension = extension.lowercaseString;
    UIImage *image;
    if ([extension isEqualToString:@"jpg"] || [extension isEqualToString:@"jpeg"]) {
        image = UIImage.mnz_defaultPhotoImage;
    } else {
        NSDictionary *fileTypesDictionary = [Helper fileTypesDictionary];
        NSString *filetypeImage = fileTypesDictionary[extension];
        if (filetypeImage && filetypeImage.length > 0) {
            image = [UIImage imageNamed:filetypeImage];
        } else {
            image = UIImage.mnz_genericImage;
        }
    }
    
    self.image = image;
}

- (void)mnz_imageForNode:(MEGANode *)node {
    switch (node.type) {
        case MEGANodeTypeFolder: {
            if ([MyChatFilesFolderNodeAccess.shared isTargetNodeFor:node]) {
                self.image = UIImage.mnz_folderMyChatFilesImage;
            } else if ([node isBackupNode]) {
                if ([node.parent isBackupRootNode]) {
                    ![node.deviceId isEqualToString:@""] ? self.image = UIImage.mnz_devicePCFolderBackUpImage : [self mnz_commonFolderImageForNode:node];
                } else {
                    self.image = UIImage.mnz_folderBackUpImage;
                }
            } else if ([node isBackupRootNode]) {
                self.image = UIImage.mnz_rootFolderBackUpImage;
            } else {
                [self mnz_commonFolderImageForNode:node];
            }
            
#ifdef MAIN_APP_TARGET
            if ([CameraUploadNodeAccess.shared isTargetNodeFor:node]) {
                self.image = UIImage.mnz_folderCameraUploadsImage;
            }
#endif
            
            break;
        }
            
        case MEGANodeTypeFile:
            [self mnz_setImageForExtension:node.name.pathExtension];
            break;
            
        default:
            self.image = UIImage.mnz_genericImage;
    }
}

- (void)mnz_commonFolderImageForNode:(MEGANode *)node {
    if (node.isInShare) {
        self.image = UIImage.mnz_incomingFolderImage;
    } else if (node.isOutShare) {
        self.image = UIImage.mnz_outgoingFolderImage;
    } else {
        self.image = UIImage.mnz_folderImage;
    }
}

@end
