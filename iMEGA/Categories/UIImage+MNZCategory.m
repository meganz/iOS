
#import "UIImage+MNZCategory.h"

#import "Helper.h"
#import "MEGAStore.h"
#import "MEGASdkManager.h"
#import "NSString+MNZCategory.h"

#import "UIImage+GKContact.h"

@implementation UIImage (MNZCategory)

#pragma mark - Video calls

+ (UIImage *)mnz_convertBitmapRGBA8ToUIImage:(unsigned char *)buffer withWidth:(NSInteger)width withHeight:(NSInteger)height {
    size_t bufferLength = width * height * 4;
    CGDataProviderRef provider = CGDataProviderCreateWithData(NULL, buffer, bufferLength, NULL);
    size_t bitsPerComponent = 8;
    size_t bitsPerPixel = 32;
    size_t bytesPerRow = 4 * width;
    
    CGColorSpaceRef colorSpaceRef = CGColorSpaceCreateDeviceRGB();
    if (colorSpaceRef == NULL) {
        NSLog(@"Error allocating color space");
        CGDataProviderRelease(provider);
        return nil;
    }
    
    CGBitmapInfo bitmapInfo = kCGBitmapByteOrderDefault | kCGImageAlphaPremultipliedLast;
    CGColorRenderingIntent renderingIntent = kCGRenderingIntentDefault;
    
    CGImageRef iref = CGImageCreate(width, height, bitsPerComponent, bitsPerPixel, bytesPerRow, colorSpaceRef, bitmapInfo, provider, NULL, YES, renderingIntent);
    
    uint32_t* pixels = (uint32_t*)malloc(bufferLength);
    
    if (pixels == NULL) {
        NSLog(@"Error: Memory not allocated for bitmap");
        CGDataProviderRelease(provider);
        CGColorSpaceRelease(colorSpaceRef);
        CGImageRelease(iref);
        return nil;
    }
    
    CGContextRef context = CGBitmapContextCreate(pixels, width, height, bitsPerComponent, bytesPerRow, colorSpaceRef, bitmapInfo);
    
    if (context == NULL) {
        NSLog(@"Error context not created");
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
        NSString *colorString = [MEGASdk avatarColorForBase64UserHandle:base64Handle];
        NSString *secondaryColorString = [MEGASdk avatarSecondaryColorForBase64UserHandle:base64Handle];
        MOUser *user = [[MEGAStore shareInstance] fetchUserWithUserHandle:userHandle];
        NSString *initialForAvatar = nil;
        if (user != nil) {
            initialForAvatar = user.displayName.mnz_initialForAvatar;
        } else {
            initialForAvatar = name.mnz_initialForAvatar;
        }
        image = [UIImage imageForName:initialForAvatar size:size backgroundColor:[UIColor mnz_fromHexString:colorString] backgroundGradientColor:[UIColor mnz_fromHexString:secondaryColorString] textColor:UIColor.whiteColor font:[UIFont systemFontOfSize:(size.width/2.0f)]];
        
        [[MEGASdkManager sharedMEGASdk] getAvatarUserWithEmailOrHandle:base64Handle destinationFilePath:avatarFilePath delegate:delegate];
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
        case MEGAChatMessageEndCallReasonEnded:
            endCallReasonImage = [UIImage imageNamed:@"callEnded"];
            break;
            
        case MEGAChatMessageEndCallReasonRejected:
            endCallReasonImage = [UIImage imageNamed:@"callRejected"];
            break;
            
        case MEGAChatMessageEndCallReasonFailed:
            endCallReasonImage = [UIImage imageNamed:@"callFailed"];
            break;
            
        case MEGAChatMessageEndCallReasonCancelled:
            if (userHandle == [MEGASdkManager sharedMEGAChatSdk].myUserHandle) {
                endCallReasonImage = [UIImage imageNamed:@"callCancelled"];
            } else {
                endCallReasonImage = [UIImage imageNamed:@"missedCall"];
            }
            break;
            
        case MEGAChatMessageEndCallReasonNoAnswer:
            if (userHandle == [MEGASdkManager sharedMEGAChatSdk].myUserHandle) {
                endCallReasonImage = [UIImage imageNamed:@"callFailed"];
            } else {
                endCallReasonImage = [UIImage imageNamed:@"missedCall"];
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
    UIImage *image = [UIImage imageNamed:name];
    
    UIGraphicsBeginImageContextWithOptions(newSize, NO, 0.0);
    [image drawInRect:CGRectMake(0, 0, newSize.width, newSize.height)];
    UIImage *scaledImage = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();
    return scaledImage;
}
    
#pragma mark - Extensions

+ (UIImage *)mnz_genericImage {
    static UIImage *genericImage = nil;
    if (genericImage == nil) {
        genericImage = [UIImage imageNamed:@"generic"];
    }
    
    return genericImage;
}

+ (UIImage *)mnz_folderImage {
    static UIImage *folderImage = nil;
    if (folderImage == nil) {
        folderImage = [UIImage imageNamed:@"folder"];
    }
    
    return folderImage;
}

+ (UIImage *)mnz_incomingFolderImage {
    static UIImage *incomingFolderImage = nil;
    if (incomingFolderImage == nil) {
        incomingFolderImage = [UIImage imageNamed:@"folder_incoming"];
    }
    
    return incomingFolderImage;
}

+ (UIImage *)mnz_outgoingFolderImage {
    static UIImage *outgoingFolderImage = nil;
    if (outgoingFolderImage == nil) {
        outgoingFolderImage = [UIImage imageNamed:@"folder_outgoing"];
    }
    
    return outgoingFolderImage;
}

+ (UIImage *)mnz_folderCameraUploadsImage {
    static UIImage *folderCameraUploadsImage = nil;
    if (folderCameraUploadsImage == nil) {
        folderCameraUploadsImage = [UIImage imageNamed:@"folder_image"];
    }
    
    return folderCameraUploadsImage;
}

+ (UIImage *)mnz_folderMyChatFilesImage {
    static UIImage *folderCameraUploadsImage = nil;
    if (folderCameraUploadsImage == nil) {
        folderCameraUploadsImage = [UIImage imageNamed:@"folder_chat"];
    }
    
    return folderCameraUploadsImage;
}

+ (UIImage *)mnz_defaultPhotoImage {
    static UIImage *defaultPhotoImage = nil;
    if (defaultPhotoImage == nil) {
        defaultPhotoImage = [UIImage imageNamed:@"image"];
    }
    
    return defaultPhotoImage;
}

+ (UIImage *)mnz_downloadingTransferImage {
    static UIImage *downloadingTransferImage = nil;
    if (downloadingTransferImage == nil) {
        downloadingTransferImage = [UIImage imageNamed:@"downloading"];
    }
    
    return downloadingTransferImage;
}

+ (UIImage *)mnz_uploadingTransferImage {
    static UIImage *uploadingTransferImage = nil;
    if (uploadingTransferImage == nil) {
        uploadingTransferImage = [UIImage imageNamed:@"uploading"];
    }
    
    return uploadingTransferImage;
}

+ (UIImage *)mnz_downloadQueuedTransferImage {
    static UIImage *downloadQueuedTransferImage = nil;
    if (downloadQueuedTransferImage == nil) {
        downloadQueuedTransferImage = [UIImage imageNamed:@"downloadQueued"];
    }
    
    return downloadQueuedTransferImage;
}

+ (UIImage *)mnz_uploadQueuedTransferImage {
    static UIImage *uploadQueuedTransferImage = nil;
    if (uploadQueuedTransferImage == nil) {
        uploadQueuedTransferImage = [UIImage imageNamed:@"uploadQueued"];
    }
    
    return uploadQueuedTransferImage;
}

+ (UIImage * _Nullable)mnz_permissionsButtonImageForShareType:(MEGAShareType)shareType {
    UIImage *image;
    switch (shareType) {
        case MEGAShareTypeAccessRead:
            image = [UIImage imageNamed:@"readPermissions"];
            break;
            
        case MEGAShareTypeAccessReadWrite:
            image =  [UIImage imageNamed:@"readWritePermissions"];
            break;
            
        case MEGAShareTypeAccessFull:
            image = [UIImage imageNamed:@"fullAccessPermissions"];
            break;
            
        default:
            image = nil;
            break;
    }
    
    return image;
}

@end
