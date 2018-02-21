
#import "ContactLinkQRViewController.h"

#import <AVKit/AVKit.h>

#import "SVProgressHUD.h"

#import "CustomModalAlertViewController.h"
#import "MEGASdkManager.h"

#import "UIImage+GKContact.h"
#import "UIImageView+MNZCategory.h"

@interface ContactLinkQRViewController () <AVCaptureMetadataOutputObjectsDelegate, MEGARequestDelegate>

@property (weak, nonatomic) IBOutlet UIButton *backButton;
@property (weak, nonatomic) IBOutlet UISegmentedControl *segmentedControl;
@property (weak, nonatomic) IBOutlet UIButton *shareButton;

@property (weak, nonatomic) IBOutlet UIImageView *qrImageView;
@property (weak, nonatomic) IBOutlet UIImageView *avatarImageView;
@property (weak, nonatomic) IBOutlet UILabel *contactLinkLabel;
@property (weak, nonatomic) IBOutlet UIButton *linkCopyButton;

@property (weak, nonatomic) IBOutlet UIView *cameraView;

@property (nonatomic) AVCaptureSession *captureSession;
@property (nonatomic) AVCaptureVideoPreviewLayer *videoPreviewLayer;

@property (nonatomic) BOOL queryInProgress;

@end

@implementation ContactLinkQRViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    [self.segmentedControl setTitle:@"My Code" forSegmentAtIndex:0];
    [self.segmentedControl setTitle:@"Scan Code" forSegmentAtIndex:1];
    [self.linkCopyButton setTitle:AMLocalizedString(@"copyLink", @"Title for a button to copy the link to the clipboard") forState:UIControlStateNormal];

    [[MEGASdkManager sharedMEGASdk] contactLinkCreateWithDelegate:self];
}

#pragma mark - QR generation

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

#pragma mark - IBActions

- (IBAction)valueChangedAtSegmentedControl:(UISegmentedControl *)sender {
    switch (sender.selectedSegmentIndex) {
        case 0:
            [self stopRecognizingCodes];
            self.view.backgroundColor = [UIColor whiteColor];
            self.qrImageView.hidden = self.avatarImageView.hidden = self.contactLinkLabel.hidden = NO;
            self.linkCopyButton.hidden = self.shareButton.hidden = self.contactLinkLabel.text.length==0;
            self.cameraView.hidden = YES;
            self.backButton.tintColor = self.segmentedControl.tintColor = [UIColor mnz_redF0373A];
            break;
            
        case 1:
            if ([self startRecognizingCodes]) {
                self.view.backgroundColor = [UIColor clearColor];
                self.qrImageView.hidden = self.avatarImageView.hidden = self.contactLinkLabel.hidden = self.linkCopyButton.hidden = self.shareButton.hidden = YES;
                self.cameraView.hidden = NO;
                self.queryInProgress = NO;
                self.backButton.tintColor = self.segmentedControl.tintColor = [UIColor whiteColor];
            } else {
                sender.selectedSegmentIndex = 0;
            }
            
            break;
            
        default:
            break;
    }
}

- (IBAction)backButtonTapped:(UIButton *)sender {
    [self stopRecognizingCodes];
    [self dismissViewControllerAnimated:YES completion:nil];
}

- (IBAction)linkCopyButtonTapped:(UIButton *)sender {
    [UIPasteboard generalPasteboard].string = self.contactLinkLabel.text;
    [SVProgressHUD showSuccessWithStatus:AMLocalizedString(@"copiedToTheClipboard", @"Text of the button after the links were copied to the clipboard")];
}

- (IBAction)openInButtonTapped:(UIButton *)sender {
    UIActivityViewController *activityVC = [[UIActivityViewController alloc] initWithActivityItems:@[self.contactLinkLabel.text] applicationActivities:nil];
    [activityVC.popoverPresentationController setSourceView:self.view];
    [activityVC.popoverPresentationController setSourceRect:sender.frame];

    [self presentViewController:activityVC animated:YES completion:nil];
}

#pragma mark - QR recognizing

- (BOOL)startRecognizingCodes {
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

- (void)stopRecognizingCodes {
    if (self.captureSession) {
        [self.captureSession stopRunning];
        self.captureSession = nil;
        [self.videoPreviewLayer removeFromSuperlayer];
    }
}

#pragma mark - AVCaptureMetadataOutputObjectsDelegate

- (void)captureOutput:(AVCaptureOutput *)captureOutput didOutputMetadataObjects:(NSArray *)metadataObjects fromConnection:(AVCaptureConnection *)connection {
    if (metadataObjects && metadataObjects.count > 0) {
        AVMetadataMachineReadableCodeObject *metadata = metadataObjects.firstObject;
        if ([metadata.type isEqualToString:AVMetadataObjectTypeQRCode]) {
            if (!self.queryInProgress) {
                NSString *detectedString = metadata.stringValue;
                NSString *baseString = @"https://mega.nz/C!";
                if ([detectedString containsString:baseString]) {
                    self.queryInProgress = YES;
                    NSString *base64Handle = [detectedString stringByReplacingOccurrencesOfString:baseString withString:@""];
                    [[MEGASdkManager sharedMEGASdk] contactLinkQueryWithHandle:[MEGASdk handleForBase64Handle:base64Handle] delegate:self];
                }
            }
        }
    }
}

#pragma mark - QR recognized

- (void)presentInviteModalForEmail:(NSString *)email contactLinkHandle:(uint64_t)contactLinkHandle {
    CustomModalAlertViewController *customModalAlertVC = [[CustomModalAlertViewController alloc] init];
    customModalAlertVC.modalPresentationStyle = UIModalPresentationOverCurrentContext;
    customModalAlertVC.image = [UIImage imageForName:email.uppercaseString size:CGSizeMake(128.0f, 128.0f) backgroundColor:[UIColor colorFromHexString:[MEGASdk avatarColorForBase64UserHandle:[MEGASdk base64HandleForUserHandle:contactLinkHandle]]] textColor:[UIColor whiteColor] font:[UIFont mnz_SFUIRegularWithSize:64.0f]]; // TODO: Use fullName.uppercaseString when available
    customModalAlertVC.viewTitle = @""; // TODO: Set here the fullName
    customModalAlertVC.detail = email;
    customModalAlertVC.action = AMLocalizedString(@"invite", @"A button on a dialog which invites a contact to join MEGA.");
    customModalAlertVC.dismiss = AMLocalizedString(@"dismiss", @"Label for any 'Dismiss' button, link, text, title, etc. - (String as short as possible).");
    
    __weak ContactLinkQRViewController *weakSelf = self;
    __weak CustomModalAlertViewController *weakModal = customModalAlertVC;
    customModalAlertVC.completion = ^{
        [[MEGASdkManager sharedMEGASdk] inviteContactWithEmail:email message:@"" action:MEGAInviteActionAdd handle:contactLinkHandle delegate:weakSelf];
        [weakModal dismissViewControllerAnimated:YES completion:^{
            weakSelf.queryInProgress = NO;
        }];
    };
    
    customModalAlertVC.onDismiss = ^{
        [weakModal dismissViewControllerAnimated:YES completion:^{
            weakSelf.queryInProgress = NO;
        }];
    };
    
    [self presentViewController:customModalAlertVC animated:YES completion:nil];
}

#pragma mark - MEGARequestDelegate

- (void)onRequestFinish:(MEGASdk *)api request:(MEGARequest *)request error:(MEGAError *)error {
    if (!error.type) {
        switch (request.type) {
            case MEGARequestTypeContactLinkCreate: {
                NSString *destination = [NSString stringWithFormat:@"https://mega.nz/C!%@", [MEGASdk base64HandleForHandle:request.nodeHandle]];
                self.contactLinkLabel.text = destination;
                if (self.segmentedControl.selectedSegmentIndex == 0) {
                    self.linkCopyButton.hidden = self.shareButton.hidden = NO;
                }
                
                self.qrImageView.image = [self qrImageFromString:destination withSize:self.qrImageView.frame.size];
                [self setUserAvatar];
                
                break;
            }
                
            case MEGARequestTypeContactLinkQuery: {
                [self presentInviteModalForEmail:request.email contactLinkHandle:request.nodeHandle];
                
                break;
            }
                
            default:
                break;
        }
    }
}

@end
