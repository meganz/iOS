#import "UIImage+MNZCategory.h"
#import <mach/mach.h>

#ifdef MNZ_SHARE_EXTENSION
#import "MEGAShare-Swift.h"
#else
#import "MEGA-Swift.h"
#endif

#import "Helper.h"
#import "MEGAStore.h"
#import "NSString+MNZCategory.h"
@import GKContactImage;
@import MEGAUIKit;

@implementation UIImage (MNZCategory)

- (UIImage *)imageByRotateRight90 {
    CGFloat radians = -90 * M_PI / 180;
    size_t width = (size_t)CGImageGetWidth(self.CGImage);
    size_t height = (size_t)CGImageGetHeight(self.CGImage);
    CGRect newRect = CGRectApplyAffineTransform(CGRectMake(0., 0., width, height), CGAffineTransformMakeRotation(radians));
    
    CGColorSpaceRef colorSpace = CGColorSpaceCreateDeviceRGB();
    CGContextRef context = CGBitmapContextCreate(NULL,
                                                 (size_t)newRect.size.width,
                                                 (size_t)newRect.size.height,
                                                 8,
                                                 (size_t)newRect.size.width * 4,
                                                 colorSpace,
                                                 kCGBitmapByteOrderDefault | kCGImageAlphaPremultipliedFirst);
    CGColorSpaceRelease(colorSpace);
    if (!context) return nil;
    
    CGContextSetShouldAntialias(context, true);
    CGContextSetAllowsAntialiasing(context, true);
    CGContextSetInterpolationQuality(context, kCGInterpolationHigh);
    
    CGContextTranslateCTM(context, +(newRect.size.width * 0.5), +(newRect.size.height * 0.5));
    CGContextRotateCTM(context, radians);
    
    CGContextDrawImage(context, CGRectMake(-(width * 0.5), -(height * 0.5), width, height), self.CGImage);
    CGImageRef imgRef = CGBitmapContextCreateImage(context);
    UIImage *img = [UIImage imageWithCGImage:imgRef scale:self.scale orientation:self.imageOrientation];
    CGImageRelease(imgRef);
    CGContextRelease(context);
    return img;
}

#pragma mark - Video calls

+ (UIImage *)mnz_convertToUIImage:(NSData *)data withWidth:(NSInteger)width withHeight:(NSInteger)height {
    return [UIImage mnz_convertBitmapRGBA8ToUIImage:(unsigned char *)data.bytes withWidth:width withHeight:height];
}

+ (UIImage *)mnz_convertBitmapRGBA8ToUIImage:(unsigned char *)buffer withWidth:(NSInteger)width withHeight:(NSInteger)height {
    size_t bufferLength = width * height * 4;
    CGDataProviderRef provider = CGDataProviderCreateWithData(NULL, buffer, bufferLength, NULL);
    size_t bitsPerComponent = 8;
    size_t bitsPerPixel = 32;
    size_t bytesPerRow = 4 * width;
    
    CGColorSpaceRef colorSpaceRef = CGColorSpaceCreateDeviceRGB();
    if (colorSpaceRef == NULL) {
        MEGALogError(@"Error allocating color space");
        CGDataProviderRelease(provider);
        return nil;
    }
    
    CGBitmapInfo bitmapInfo = kCGBitmapByteOrderDefault | kCGImageAlphaPremultipliedLast;
    CGColorRenderingIntent renderingIntent = kCGRenderingIntentDefault;
    
    CGImageRef iref = CGImageCreate(width, height, bitsPerComponent, bitsPerPixel, bytesPerRow, colorSpaceRef, bitmapInfo, provider, NULL, YES, renderingIntent);
    
    uint32_t* pixels = (uint32_t*)malloc(bufferLength);
    
    if (pixels == NULL) {
        MEGALogError(@"Error: Memory not allocated for bitmap");
        CGDataProviderRelease(provider);
        CGColorSpaceRelease(colorSpaceRef);
        CGImageRelease(iref);
        return nil;
    }
    
    CGContextRef context = CGBitmapContextCreate(pixels, width, height, bitsPerComponent, bytesPerRow, colorSpaceRef, bitmapInfo);
    
    if (context == NULL) {
        MEGALogError(@"Error context not created");
    }
    
    UIImage *image = nil;
    if (context) {
        CGContextDrawImage(context, CGRectMake(0.0f, 0.0f, width, height), iref);
        
        CGImageRef imageRef = CGBitmapContextCreateImage(context);
        
        // Support both iPad 3.2 and iPhone 4 Retina displays with the correct scale
        if ([UIImage respondsToSelector:@selector(imageWithCGImage:scale:orientation:)]) {
            float scale = [[UIScreen mainScreen] scale];
            image = [UIImage imageWithCGImage:imageRef scale:scale orientation:UIImageOrientationUp];
        } else {
            image = [UIImage imageWithCGImage:imageRef];
        }
        
        CGImageRelease(imageRef);
        CGContextRelease(context);
    }
    
    CGColorSpaceRelease(colorSpaceRef);
    CGImageRelease(iref);
    CGDataProviderRelease(provider);
    
    if (pixels) {
        free(pixels);
    }
    
    return image;
}

#pragma mark - Avatars

+ (UIImage *)mnz_imageForUserHandle:(uint64_t)userHandle name:(NSString *)name size:(CGSize)size delegate:(id<MEGARequestDelegate>)delegate {
    UIImage *image = nil;
    
    NSString *base64Handle = [MEGASdk base64HandleForUserHandle:userHandle];
    NSString *avatarFilePath = [[Helper pathForSharedSandboxCacheDirectory:@"thumbnailsV3"] stringByAppendingPathComponent:base64Handle];
    if ([[NSFileManager defaultManager] fileExistsAtPath:avatarFilePath]) {
        image = [UIImage imageWithContentsOfFile:avatarFilePath];
    } else {
#ifdef MNZ_SHARE_EXTENSION
        task_vm_info_data_t vmInfo;
        mach_msg_type_number_t count = TASK_VM_INFO_COUNT;
        task_info(mach_task_self(),
                  TASK_VM_INFO,
                  (task_info_t)&vmInfo,
                  &count);
        
        // Do not generate avatar image with initials if remaining memory is less than 40MB in Share extension.
        if (vmInfo.limit_bytes_remaining > 40 * 1024 * 1024) {
#endif
            NSString *colorString = [MEGASdk avatarColorForBase64UserHandle:base64Handle];
            NSString *secondaryColorString = [MEGASdk avatarSecondaryColorForBase64UserHandle:base64Handle];
            MOUser *user = [[MEGAStore shareInstance] fetchUserWithUserHandle:userHandle];
            NSString *initialForAvatar = nil;
            if (user != nil) {
                initialForAvatar = user.displayName.mnz_initialForAvatar;
            } else {
                initialForAvatar = name.mnz_initialForAvatar;
            }
            
            image = [UIImage imageForName:initialForAvatar size:size backgroundColor:[UIColor mnz_fromHexString:colorString] backgroundGradientColor:[UIColor mnz_fromHexString:secondaryColorString] textColor:UIColor.whiteTextColor font:[UIFont systemFontOfSize:(size.width/2.0f)]];
            [UIImageJPEGRepresentation(image, 1) writeToFile:avatarFilePath atomically:YES];
#ifdef MNZ_SHARE_EXTENSION
        } else {
            image = [UIImage megaImageWithNamed:@"contactGroups"];
        }
#endif
        
        [MEGASdk.shared getAvatarUserWithEmailOrHandle:base64Handle destinationFilePath:avatarFilePath delegate:delegate];
    }
    
    return image;
}

+ (UIImage *)imageWithColor:(UIColor *)color andBounds:(CGRect)imgBounds {
    UIGraphicsBeginImageContextWithOptions(imgBounds.size, NO, 0);
    [color setFill];
    UIRectFill(imgBounds);
    UIImage *img = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();
    
    return img;
}

#pragma mark - QR generation

+ (UIImage *)mnz_qrImageFromString:(NSString *)qrString withSize:(CGSize)size color:(UIColor *)qrColor backgroundColor:(UIColor *)backgroundColor {
    NSData *qrData = [qrString dataUsingEncoding:NSISOLatin1StringEncoding];
    NSString *qrCorrectionLevel = @"H";
    
    CIFilter *qrFilter = [CIFilter filterWithName:@"CIQRCodeGenerator"];
    [qrFilter setValue:qrData forKey:@"inputMessage"];
    [qrFilter setValue:qrCorrectionLevel forKey:@"inputCorrectionLevel"];
    
    CIFilter *colorFilter = [CIFilter filterWithName:@"CIFalseColor"];
    [colorFilter setValue:qrFilter.outputImage forKey:@"inputImage"];
    [colorFilter setValue:[CIColor colorWithCGColor:qrColor.CGColor] forKey:@"inputColor0"];
    [colorFilter setValue:[CIColor colorWithCGColor:backgroundColor.CGColor] forKey:@"inputColor1"];
    
    CIImage *ciImage = colorFilter.outputImage;
    float scaleX = size.width / ciImage.extent.size.width;
    float scaleY = size.height / ciImage.extent.size.height;
    
    ciImage = [ciImage imageByApplyingTransform:CGAffineTransformMakeScale(scaleX, scaleY)];
    
    UIImage *image = [UIImage imageWithCIImage:ciImage
                                         scale:UIScreen.mainScreen.scale
                                   orientation:UIImageOrientationUp];
    
    return image;
}

#pragma mark - Chat

+ (UIImage *)mnz_imageByEndCallReason:(MEGAChatMessageEndCallReason)endCallReason userHandle:(uint64_t)userHandle {
    UIImage *endCallReasonImage;
    
    switch (endCallReason) {
        case MEGAChatMessageEndCallReasonByModerator:
        case MEGAChatMessageEndCallReasonEnded:
            endCallReasonImage = [UIImage megaImageWithNamed:@"callEnded"];
            break;
            
        case MEGAChatMessageEndCallReasonRejected:
            endCallReasonImage = [UIImage megaImageWithNamed:@"callRejected"];
            break;
            
        case MEGAChatMessageEndCallReasonFailed:
            endCallReasonImage = [UIImage megaImageWithNamed:@"callFailed"];
            break;
            
        case MEGAChatMessageEndCallReasonCancelled:
            if (userHandle == MEGAChatSdk.shared.myUserHandle) {
                endCallReasonImage = [UIImage megaImageWithNamed:@"callCancelled"];
            } else {
                endCallReasonImage = [UIImage megaImageWithNamed:@"missedCall"];
            }
            break;
            
        case MEGAChatMessageEndCallReasonNoAnswer:
            if (userHandle == MEGAChatSdk.shared.myUserHandle) {
                endCallReasonImage = [UIImage megaImageWithNamed:@"callFailed"];
            } else {
                endCallReasonImage = [UIImage megaImageWithNamed:@"missedCall"];
            }
            break;
            
        default:
            endCallReasonImage = nil;
            break;
    }
    
    return endCallReasonImage;
}

#pragma mark - Utils

+ (UIImage *)mnz_imageNamed:(NSString *)name scaledToSize:(CGSize)newSize {
    UIImage *image = [UIImage megaImageWithNamed:name];
    
    UIGraphicsBeginImageContextWithOptions(newSize, NO, 0.0);
    [image drawInRect:CGRectMake(0, 0, newSize.width, newSize.height)];
    UIImage *scaledImage = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();
    return scaledImage;
}
    
#pragma mark - Extensions - Oh my god
+ (UIImage *)mnz_genericImage {
    return [UIImage megaImageWithNamed:@"generic"];
}

+ (UIImage *)mnz_folderImage {
    return [UIImage megaImageWithNamed:@"filetype_folder"];
}

+ (UIImage *)mnz_incomingFolderImage {
    return [UIImage megaImageWithNamed:@"folder_incoming"];
}

+ (UIImage *)mnz_outgoingFolderImage {
    return [UIImage megaImageWithNamed:@"folder_outgoing"];
}

+ (UIImage *)mnz_folderCameraUploadsImage {
    return [UIImage megaImageWithNamed:@"folder_camera"];
}

+ (UIImage *)mnz_folderMyChatFilesImage {
    return [UIImage megaImageWithNamed:@"folder_chat"];
}

+ (UIImage *)mnz_folderBackUpImage {
    return [UIImage megaImageWithNamed:@"folder_sync"];
}

+ (UIImage *)mnz_devicePCFolderBackUpImage {
    return [UIImage megaImageWithNamed:@"pc"];
}

+ (UIImage *)mnz_rootFolderBackUpImage {
    return [UIImage megaImageWithNamed:@"folder_backup"];
}

+ (UIImage *)mnz_defaultPhotoImage {
    return [UIImage megaImageWithNamed:@"image"];
}

+ (UIImage *)mnz_downloadingOverquotaTransferImage {
    return [UIImage megaImageWithNamed:@"downloadingOverquota"];
}

+ (UIImage *)mnz_uploadingOverquotaTransferImage {
    return [UIImage megaImageWithNamed:@"uploadingOverquota"];
}

+ (UIImage *)mnz_downloadingTransferImage {
    return [UIImage megaImageWithNamed:@"downloading"];
}

+ (UIImage *)mnz_uploadingTransferImage {
    return [UIImage megaImageWithNamed:@"uploading"];
}

+ (UIImage *)mnz_downloadQueuedTransferImage {
    return [UIImage megaImageWithNamed:@"downloadQueued"];
}

+ (UIImage *)mnz_uploadQueuedTransferImage {    
    return [UIImage megaImageWithNamed:@"uploading"];
}

+ (UIImage *)mnz_errorTransferImage {
    return [UIImage megaImageWithNamed:@"downloadError"];
}

+ (UIImage * _Nullable)mnz_permissionsButtonImageForShareType:(MEGAShareType)shareType {
    UIImage *image;
    switch (shareType) {
        case MEGAShareTypeAccessRead:
            image = [UIImage megaImageWithNamed:@"readPermissions"];
            break;
            
        case MEGAShareTypeAccessReadWrite:
            image =  [UIImage megaImageWithNamed:@"readWritePermissions"];
            break;
            
        case MEGAShareTypeAccessFull:
            image = [UIImage megaImageWithNamed:@"fullAccessPermissions"];
            break;
            
        default:
            image = nil;
            break;
    }
    
    return image;
}

@end
