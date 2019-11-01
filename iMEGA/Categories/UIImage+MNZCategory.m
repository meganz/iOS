
#import "UIImage+MNZCategory.h"

#import "Helper.h"
#import "MEGAStore.h"
#import "MEGASdkManager.h"
#import "NSString+MNZCategory.h"

#import "UIImage+GKContact.h"
#import "UIColor+MNZCategory.h"

@implementation UIImage (MNZCategory)

#pragma mark - Video calls

+ (UIImage *)mnz_convertBitmapRGBA8ToUIImage:(unsigned char *)buffer
                               withWidth:(NSInteger)width
                              withHeight:(NSInteger)height {
    size_t bufferLength = width * height * 4;
    CGDataProviderRef provider = CGDataProviderCreateWithData(NULL, buffer, bufferLength, NULL);
    size_t bitsPerComponent = 8;
    size_t bitsPerPixel = 32;
    size_t bytesPerRow = 4 * width;
    
    CGColorSpaceRef colorSpaceRef = CGColorSpaceCreateDeviceRGB();
    if(colorSpaceRef == NULL) {
        NSLog(@"Error allocating color space");
        CGDataProviderRelease(provider);
        return nil;
    }
    
    CGBitmapInfo bitmapInfo = kCGBitmapByteOrderDefault | kCGImageAlphaPremultipliedLast;
    CGColorRenderingIntent renderingIntent = kCGRenderingIntentDefault;
    
    CGImageRef iref = CGImageCreate(width,
                                    height,
                                    bitsPerComponent,
                                    bitsPerPixel,
                                    bytesPerRow,
                                    colorSpaceRef,
                                    bitmapInfo,
                                    provider,    // data provider
                                    NULL,        // decode
                                    YES,            // should interpolate
                                    renderingIntent);
    
    uint32_t* pixels = (uint32_t*)malloc(bufferLength);
    
    if(pixels == NULL) {
        NSLog(@"Error: Memory not allocated for bitmap");
        CGDataProviderRelease(provider);
        CGColorSpaceRelease(colorSpaceRef);
        CGImageRelease(iref);
        return nil;
    }
    
    CGContextRef context = CGBitmapContextCreate(pixels,
                                                 width,
                                                 height,
                                                 bitsPerComponent,
                                                 bytesPerRow,
                                                 colorSpaceRef,
                                                 bitmapInfo);
    
    if(context == NULL) {
        NSLog(@"Error context not created");
    }
    
    UIImage *image = nil;
    if(context) {
        
        CGContextDrawImage(context, CGRectMake(0.0f, 0.0f, width, height), iref);
        
        CGImageRef imageRef = CGBitmapContextCreateImage(context);
        
        // Support both iPad 3.2 and iPhone 4 Retina displays with the correct scale
        if([UIImage respondsToSelector:@selector(imageWithCGImage:scale:orientation:)]) {
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
    
    if(pixels) {
        free(pixels);
    }
    
    return image;
}

#pragma mark - Avatars

+ (UIImage *)mnz_imageForUserHandle:(uint64_t)userHandle size:(CGSize)size delegate:(id<MEGARequestDelegate>)delegate {
    return [self mnz_imageForUserHandle:userHandle name:@"?" size:size delegate:delegate];
}

+ (UIImage *)mnz_imageForUserHandle:(uint64_t)userHandle name:(NSString *)name size:(CGSize)size delegate:(id<MEGARequestDelegate>)delegate {
    UIImage *image = nil;
    
    NSString *base64Handle = [MEGASdk base64HandleForUserHandle:userHandle];
    NSString *avatarFilePath = [[Helper pathForSharedSandboxCacheDirectory:@"thumbnailsV3"] stringByAppendingPathComponent:base64Handle];
    if ([[NSFileManager defaultManager] fileExistsAtPath:avatarFilePath]) {
        image = [UIImage imageWithContentsOfFile:avatarFilePath];
    } else {
        NSString *colorString = [MEGASdk avatarColorForBase64UserHandle:base64Handle];
        MOUser *user = [[MEGAStore shareInstance] fetchUserWithUserHandle:userHandle];
        NSString *initialForAvatar = nil;
        if (user.nickname.length > 0) {
            initialForAvatar = user.nickname.mnz_initialForAvatar;
        } else
            if (user) {
            if (user.fullName.length) {
                initialForAvatar = user.fullName.mnz_initialForAvatar;
            } else {
                initialForAvatar = user.email.mnz_initialForAvatar;
            }
        } else {
            initialForAvatar = name.mnz_initialForAvatar;
        }
        image = [UIImage imageForName:initialForAvatar size:size backgroundColor:[UIColor colorFromHexString:colorString] textColor:[UIColor whiteColor] font:[UIFont mnz_SFUIRegularWithSize:(size.width/2.0f)]];
        
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

+ (UIImage *)mnz_qrImageFromString:(NSString *)qrString withSize:(CGSize)size color:(UIColor *)color {
    NSData *qrData = [qrString dataUsingEncoding:NSISOLatin1StringEncoding];
    NSString *qrCorrectionLevel = @"H";
    
    CIFilter *qrFilter = [CIFilter filterWithName:@"CIQRCodeGenerator"];
    [qrFilter setValue:qrData forKey:@"inputMessage"];
    [qrFilter setValue:qrCorrectionLevel forKey:@"inputCorrectionLevel"];
    
    CIFilter *colorFilter = [CIFilter filterWithName:@"CIFalseColor"];
    [colorFilter setValue:qrFilter.outputImage forKey:@"inputImage"];
    [colorFilter setValue:[CIColor colorWithCGColor:color.CGColor] forKey:@"inputColor0"];
    [colorFilter setValue:[CIColor colorWithRed:1.0f green:1.0f blue:1.0f] forKey:@"inputColor1"];
    
    CIImage *ciImage = colorFilter.outputImage;
    float scaleX = size.width / ciImage.extent.size.width;
    float scaleY = size.height / ciImage.extent.size.height;
    
    ciImage = [ciImage imageByApplyingTransform:CGAffineTransformMakeScale(scaleX, scaleY)];
    
    UIImage *image = [UIImage imageWithCIImage:ciImage
                                         scale:UIScreen.mainScreen.scale
                                   orientation:UIImageOrientationUp];
    
    return image;
}

+ (UIImage *)mnz_qrImageWithDotsFromString:(NSString *)qrString withSize:(CGSize)size color:(UIColor *)color {
    NSData *qrData = [qrString dataUsingEncoding: NSISOLatin1StringEncoding];
    NSString *qrCorrectionLevel = @"H";
    
    CIFilter *qrFilter = [CIFilter filterWithName:@"CIQRCodeGenerator"];
    [qrFilter setValue:qrData forKey:@"inputMessage"];
    [qrFilter setValue:qrCorrectionLevel forKey:@"inputCorrectionLevel"];
    
    UIGraphicsBeginImageContextWithOptions(size, NO, 0.0f);
    CGContextRef ctx = UIGraphicsGetCurrentContext();
    CGContextSaveGState(ctx);
    CGContextSetFillColorWithColor(ctx, color.CGColor);
    
    CGImageRef cgImageRef = [[CIContext contextWithOptions:nil] createCGImage:qrFilter.outputImage fromRect:qrFilter.outputImage.extent];
    CFDataRef rawData = CGDataProviderCopyData(CGImageGetDataProvider(cgImageRef));
    UInt8 * buf = (UInt8 *) CFDataGetBytePtr(rawData);
    int length = (int)CFDataGetLength(rawData);
    unsigned int rows = qrFilter.outputImage.extent.size.height;
    unsigned int columns = length / (rows * 4);
    
    CGFloat dotHeight = size.height / rows;
    CGFloat dotWidth = size.width / columns;
    CGFloat dotSize = dotHeight > dotWidth ? dotWidth : dotHeight;
    CGFloat padding = dotSize / 8;
    
    NSUInteger maxHorizontalPoints = 0;
    // Draw dots:
    for(unsigned int i = 0; i < rows; i++) {
        // (columns - 1) because there is a last column of points with invalid data
        for(unsigned int j = 0; j < (columns - 1); j++) {
            if (buf[(i * columns + j) * 4] == 0) {
                CGRect rect = CGRectMake(j * dotWidth + padding, i * dotHeight + padding, dotSize - (2 * padding), dotSize - (2 * padding));
                CGContextFillEllipseInRect(ctx, rect);
                if (j > maxHorizontalPoints) {
                    maxHorizontalPoints = j;
                }
            }
        }
    }
    // For some unknown reason, sometimes the generated QR has an extra column
    // without points at the end. So, it is needed to add (or not) a trailing
    // padding for the top right reference square.
    NSUInteger trailingPoints = (columns - 1) - (maxHorizontalPoints + 1);
    
    // The following bunch of code is used to draw the reference squares that
    // appear in three corners of the QR code:
    
    // Calculate the reference size
    NSUInteger referenceSize = 0;
    NSUInteger iInitial = 0;
    NSUInteger jInitial = 0;
    BOOL stop = NO;
    for(unsigned int i = 0; i < rows && !stop; i++) {
        for(unsigned int j = 0; j < (columns - 1) && !stop; j++) {
            if (buf[(i * columns + j) * 4] == 0) {
                if (referenceSize == 0) {
                    iInitial = i;
                    jInitial = j;
                }
                referenceSize++;
            } else {
                if (referenceSize > 0) {
                    stop = YES;
                }
            }
        }
    }
    
    // Calculate starting points for reference squares
    CGFloat referencePaddingX = dotWidth * jInitial;
    CGFloat referencePaddingY = dotHeight * iInitial;

    // Draw reference squares at the top left corner:
    CGRect rectTL0 = CGRectMake(referencePaddingX, referencePaddingY, dotWidth * referenceSize, dotHeight * referenceSize);
    CGContextSetFillColorWithColor(ctx, [UIColor whiteColor].CGColor);
    CGContextFillRect(ctx, rectTL0);
    
    CGRect rectTL1 = CGRectMake(referencePaddingX, referencePaddingY, dotWidth * referenceSize, dotHeight * referenceSize);
    UIBezierPath *bezierPathTL1 = [UIBezierPath bezierPathWithRoundedRect:rectTL1 cornerRadius:dotSize];
    CGContextSetFillColorWithColor(ctx, color.CGColor);
    [bezierPathTL1 fill];
    
    CGRect rectTL2 = CGRectMake(referencePaddingX * 2, referencePaddingY * 2, dotWidth * (referenceSize - 2), dotHeight * (referenceSize - 2));
    UIBezierPath *bezierPathTL2 = [UIBezierPath bezierPathWithRoundedRect:rectTL2 cornerRadius:dotSize];
    CGContextSetFillColorWithColor(ctx, [UIColor whiteColor].CGColor);
    [bezierPathTL2 fill];
    
    CGRect rectTL3 = CGRectMake(referencePaddingX * 3, referencePaddingY * 3, dotWidth * (referenceSize - 4), dotHeight * (referenceSize - 4));
    CGContextSetFillColorWithColor(ctx, color.CGColor);
    CGContextFillEllipseInRect(ctx, rectTL3);
    
    // Draw reference squares at the top right corner:
    // (The horizontal padding here is the double for the same reason that before we had columns-1)
    CGRect rectTR0 = CGRectMake(size.width - referencePaddingX - (trailingPoints * referencePaddingX) - (dotWidth * referenceSize), referencePaddingY, dotWidth * referenceSize, dotHeight * referenceSize);
    CGContextSetFillColorWithColor(ctx, [UIColor whiteColor].CGColor);
    CGContextFillRect(ctx, rectTR0);

    CGRect rectTR1 = CGRectMake(size.width - referencePaddingX - (trailingPoints * referencePaddingX) - (dotWidth * referenceSize), referencePaddingY, dotWidth * referenceSize, dotHeight * referenceSize);
    UIBezierPath *bezierPathTR1 = [UIBezierPath bezierPathWithRoundedRect:rectTR1 cornerRadius:dotSize];
    CGContextSetFillColorWithColor(ctx, color.CGColor);
    [bezierPathTR1 fill];
    
    CGRect rectTR2 = CGRectMake(size.width - referencePaddingX * 2 - (trailingPoints * referencePaddingX) - (dotWidth * (referenceSize - 2)), referencePaddingY * 2, dotWidth * (referenceSize - 2), dotHeight * (referenceSize - 2));
    UIBezierPath *bezierPathTR2 = [UIBezierPath bezierPathWithRoundedRect:rectTR2 cornerRadius:dotSize];
    CGContextSetFillColorWithColor(ctx, [UIColor whiteColor].CGColor);
    [bezierPathTR2 fill];
    
    CGRect rectTR3 = CGRectMake(size.width - referencePaddingX * 3 - (trailingPoints * referencePaddingX) - (dotWidth * (referenceSize - 4)), referencePaddingY * 3, dotWidth * (referenceSize - 4), dotHeight * (referenceSize - 4));
    CGContextSetFillColorWithColor(ctx, color.CGColor);
    CGContextFillEllipseInRect(ctx, rectTR3);
    
    // Draw reference squares at the bottom left corner:
    CGRect rectBL0 = CGRectMake(referencePaddingX, size.height - referencePaddingY - (dotHeight * referenceSize), dotWidth * referenceSize, dotHeight * referenceSize);
    CGContextSetFillColorWithColor(ctx, [UIColor whiteColor].CGColor);
    CGContextFillRect(ctx, rectBL0);
    
    CGRect rectBL1 = CGRectMake(referencePaddingX, size.height - referencePaddingY - (dotHeight * referenceSize), dotWidth * referenceSize, dotHeight * referenceSize);
    UIBezierPath *bezierPathBL1 = [UIBezierPath bezierPathWithRoundedRect:rectBL1 cornerRadius:dotSize];
    CGContextSetFillColorWithColor(ctx, color.CGColor);
    [bezierPathBL1 fill];
    
    CGRect rectBL2 = CGRectMake(referencePaddingX * 2, size.height - referencePaddingY * 2 - (dotHeight * (referenceSize - 2)), dotWidth * (referenceSize - 2), dotHeight * (referenceSize - 2));
    UIBezierPath *bezierPathBL2 = [UIBezierPath bezierPathWithRoundedRect:rectBL2 cornerRadius:dotSize];
    CGContextSetFillColorWithColor(ctx, [UIColor whiteColor].CGColor);
    [bezierPathBL2 fill];
    
    CGRect rectBL3 = CGRectMake(referencePaddingX * 3, size.height - referencePaddingY * 3 - (dotHeight * (referenceSize - 4)), dotWidth * (referenceSize - 4), dotHeight * (referenceSize - 4));
    CGContextSetFillColorWithColor(ctx, color.CGColor);
    CGContextFillEllipseInRect(ctx, rectBL3);
    
    // At this point, the QR code is ready:
    CFRelease(rawData);
    CGImageRelease(cgImageRef);

    CGContextRestoreGState(ctx);
    UIImage *qrImage = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();
    
    return qrImage;
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

@end
