
#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

typedef NS_ENUM(NSInteger, MEGAChatMessageEndCallReason);

@interface UIImage (MNZCategory)

+ (UIImage *)mnz_convertBitmapRGBA8ToUIImage:(unsigned char *)buffer withWidth:(NSInteger)width withHeight:(NSInteger)height;

+ (UIImage *)mnz_imageForUserHandle:(uint64_t)userHandle name:(NSString *)name size:(CGSize)size delegate:(id<MEGARequestDelegate>)delegate;
+ (UIImage *)imageWithColor:(UIColor *)color andBounds:(CGRect)imgBounds;

+ (UIImage *)mnz_qrImageFromString:(NSString *)qrString withSize:(CGSize)size color:(UIColor *)color;

+ (UIImage *)mnz_imageByEndCallReason:(MEGAChatMessageEndCallReason)endCallReason userHandle:(uint64_t)userHandle;

+ (UIImage *)mnz_imageNamed:(NSString *)name scaledToSize:(CGSize)newSize;

+ (UIImage *)mnz_genericImage;
+ (UIImage *)mnz_folderImage;
+ (UIImage *)mnz_incomingFolderImage;
+ (UIImage *)mnz_outgoingFolderImage;
+ (UIImage *)mnz_folderCameraUploadsImage;
+ (UIImage *)mnz_defaultPhotoImage;

+ (UIImage *)mnz_downloadingTransferImage;
+ (UIImage *)mnz_uploadingTransferImage;
+ (UIImage *)mnz_downloadQueuedTransferImage;
+ (UIImage *)mnz_uploadQueuedTransferImage;

+ (UIImage * _Nullable)mnz_permissionsButtonImageForShareType:(MEGAShareType)shareType;

NS_ASSUME_NONNULL_END

@end
