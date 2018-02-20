
#import "ContactLinkQRViewController.h"

#import <AVKit/AVKit.h>

#import "MEGASdkManager.h"

#import "UIImageView+MNZCategory.h"

@interface ContactLinkQRViewController () <AVCaptureMetadataOutputObjectsDelegate>

@property (weak, nonatomic) IBOutlet UISegmentedControl *segmentedControl;
@property (weak, nonatomic) IBOutlet UIImageView *qrImageView;
@property (weak, nonatomic) IBOutlet UIImageView *avatarImageView;
@property (weak, nonatomic) IBOutlet UIView *cameraView;

@property (nonatomic) AVCaptureSession *captureSession;
@property (nonatomic) AVCaptureVideoPreviewLayer *videoPreviewLayer;

@end

@implementation ContactLinkQRViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    [self.segmentedControl setTitle:@"My Code" forSegmentAtIndex:0];
    [self.segmentedControl setTitle:@"Scan Code" forSegmentAtIndex:1];

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

#pragma mark - QR recognizing

- (BOOL)recognizeCodes {
    NSError *error;
    AVCaptureDevice *captureDevice = [AVCaptureDevice defaultDeviceWithMediaType:AVMediaTypeVideo];
    AVCaptureDeviceInput *input = [AVCaptureDeviceInput deviceInputWithDevice:captureDevice error:&error];
    
    if (input) {
        AVCaptureMetadataOutput *captureMetadataOutput = [[AVCaptureMetadataOutput alloc] init];
        
        self.captureSession = [[AVCaptureSession alloc] init];
        [self.captureSession addInput:input];
        [self.captureSession addOutput:captureMetadataOutput];
        
        dispatch_queue_t qrDispatchQueue = dispatch_queue_create("qrDispatchQueue", NULL);
        [captureMetadataOutput setMetadataObjectsDelegate:self queue:qrDispatchQueue];
        [captureMetadataOutput setMetadataObjectTypes:[NSArray<AVMetadataObjectType> arrayWithObject:AVMetadataObjectTypeQRCode]];

        self.videoPreviewLayer = [[AVCaptureVideoPreviewLayer alloc] initWithSession:self.captureSession];
        [self.videoPreviewLayer setVideoGravity:AVLayerVideoGravityResizeAspectFill];
        [self.videoPreviewLayer setFrame:self.cameraView.layer.bounds];
        [self.cameraView.layer addSublayer:self.videoPreviewLayer];
        
        [self.captureSession startRunning];
        
        return YES;
    } else {
        MEGALogError(@"%@", error.localizedDescription);
        return NO;
    }
}

#pragma mark - IBActions

- (IBAction)valueChangedAtSegmentedControl:(UISegmentedControl *)sender {
    switch (sender.selectedSegmentIndex) {
        case 0:
            if (self.captureSession) {
                [self.captureSession stopRunning];
                self.captureSession = nil;
                [self.videoPreviewLayer removeFromSuperlayer];
            }
            self.view.backgroundColor = [UIColor whiteColor];
            self.avatarImageView.hidden = self.qrImageView.hidden = NO;
            self.cameraView.hidden = YES;
            break;
            
        case 1:
            if ([self recognizeCodes]) {
                self.view.backgroundColor = [UIColor clearColor];
                self.avatarImageView.hidden = self.qrImageView.hidden = YES;
                self.cameraView.hidden = NO;
            } else {
                sender.selectedSegmentIndex = 0;
            }

            break;
            
        default:
            break;
    }
}

#pragma mark - AVCaptureMetadataOutputObjectsDelegate

- (void)captureOutput:(AVCaptureOutput *)captureOutput didOutputMetadataObjects:(NSArray *)metadataObjects fromConnection:(AVCaptureConnection *)connection {
    if (metadataObjects && metadataObjects.count > 0) {
        AVMetadataMachineReadableCodeObject *metadata = metadataObjects.firstObject;
        if ([metadata.type isEqualToString:AVMetadataObjectTypeQRCode]) {
            NSLog(@">>> QR: %@", metadata.stringValue);
        }
    }
}

@end
