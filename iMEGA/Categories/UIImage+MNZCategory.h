
#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

typedef NS_ENUM(NSInteger, MEGAChatMessageEndCallReason);

@interface UIImage (MNZCategory)

/**
 Returns a new image rotated clockwise by a quarter‑turn (90°). ⤼
 The width and height will be exchanged.
 */
- (nullable UIImage *)imageByRotateRight90;

+ (UIImage *)mnz_convertToUIImage:(NSData *)data withWidth:(NSInteger)width withHeight:(NSInteger)height;
+ (UIImage *)mnz_convertBitmapRGBA8ToUIImage:(unsigned char *)buffer withWidth:(NSInteger)width withHeight:(NSInteger)height;

+ (UIImage *)mnz_imageForUserHandle:(uint64_t)userHandle name:(NSString *)name size:(CGSize)size delegate:(id<MEGARequestDelegate>)delegate;
+ (UIImage *)imageWithColor:(UIColor *)color andBounds:(CGRect)imgBounds;

+ (UIImage *)mnz_qrImageFromString:(NSString *)qrString withSize:(CGSize)size color:(UIColor *)qrColor backgroundColor:(UIColor *)backgroundColor;

+ (UIImage *)mnz_imageByEndCallReason:(MEGAChatMessageEndCallReason)endCallReason userHandle:(uint64_t)userHandle;

+ (UIImage *)mnz_imageNamed:(NSString *)name scaledToSize:(CGSize)newSize;

+ (UIImage *)mnz_genericImage;
+ (UIImage *)mnz_folderImage;
+ (UIImage *)mnz_incomingFolderImage;
+ (UIImage *)mnz_outgoingFolderImage;
+ (UIImage *)mnz_folderCameraUploadsImage;
+ (UIImage *)mnz_folderMyChatFilesImage;
+ (UIImage *)mnz_folderBackUpImage;
+ (UIImage *)mnz_devicePCFolderBackUpImage;
+ (UIImage *)mnz_rootFolderBackUpImage;
+ (UIImage *)mnz_defaultPhotoImage;

+ (UIImage *)mnz_downloadingOverquotaTransferImage;
+ (UIImage *)mnz_uploadingOverquotaTransferImage;
+ (UIImage *)mnz_downloadingTransferImage;
+ (UIImage *)mnz_uploadingTransferImage;
+ (UIImage *)mnz_downloadQueuedTransferImage;
+ (UIImage *)mnz_uploadQueuedTransferImage;
+ (UIImage *)mnz_errorTransferImage;

+ (UIImage * _Nullable)mnz_permissionsButtonImageForShareType:(MEGAShareType)shareType;

NS_ASSUME_NONNULL_END

@end
