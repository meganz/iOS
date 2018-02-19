
#import "ContactLinkQRViewController.h"

#import "MEGASdkManager.h"

#import "UIImageView+MNZCategory.h"

@interface ContactLinkQRViewController ()

@property (weak, nonatomic) IBOutlet UIImageView *qrImageView;
@property (weak, nonatomic) IBOutlet UIImageView *avatarImageView;

@end

@implementation ContactLinkQRViewController

- (void)viewDidLoad {
    [super viewDidLoad];

    UIImage *qrImage = [self qrImageFromString:@"mega.nz" withSize:self.qrImageView.frame.size];
    self.qrImageView.image = qrImage;
    
    [self setUserAvatar];
}

#pragma mark - QR

- (UIImage *)qrImageFromString:(NSString *)qrString withSize:(CGSize)size {
    NSData *qrData = [qrString dataUsingEncoding: NSISOLatin1StringEncoding];
    NSString *qrCorrectionLevel = @"H";
    
    CIFilter *qrFilter = [CIFilter filterWithName:@"CIQRCodeGenerator"];
    [qrFilter setValue:qrData forKey:@"inputMessage"];
    [qrFilter setValue:qrCorrectionLevel forKey:@"inputCorrectionLevel"];
    
    CIFilter *colorFilter = [CIFilter filterWithName:@"CIFalseColor"];
    [colorFilter setValue:qrFilter.outputImage forKey:@"inputImage"];
    [colorFilter setValue:[CIColor colorWithRed:0.94 green:0.22 blue:0.23] forKey:@"inputColor0"];
    [colorFilter setValue:[CIColor whiteColor] forKey:@"inputColor1"];
    
    CIImage *ciImage = colorFilter.outputImage;
    float scaleX = size.width / ciImage.extent.size.width;
    float scaleY = size.height / ciImage.extent.size.height;
    
    ciImage = [ciImage imageByApplyingTransform:CGAffineTransformMakeScale(scaleX, scaleY)];
    
    UIImage *image = [UIImage imageWithCIImage:ciImage
                                         scale:UIScreen.mainScreen.scale
                                   orientation:UIImageOrientationUp];
    
    return image;
}

#pragma mark - User avatar

- (void)setUserAvatar {
    MEGAUser *myUser = [[MEGASdkManager sharedMEGASdk] myUser];
    [self.avatarImageView mnz_setImageForUserHandle:myUser.handle];
}

@end
