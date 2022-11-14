
#import "ContactLinkQRViewController.h"

#import <AVKit/AVKit.h>

#import "SVProgressHUD.h"

#import "CustomModalAlertViewController.h"
#import "DevicePermissionsHelper.h"
#import "MEGAContactLinkQueryRequestDelegate.h"
#import "MEGAInviteContactRequestDelegate.h"
#import "MEGASdkManager.h"
#import "MEGA-Swift.h"
#import "QRSettingsTableViewController.h"

#import "NSString+MNZCategory.h"
#import "UIImage+GKContact.h"
#import "UIImage+MNZCategory.h"
#import "UIImageView+MNZCategory.h"

typedef NS_ENUM(NSInteger, QRSection) {
    QRSectionMyCode = 0,
    QRSectionScanCode
};

@interface ContactLinkQRViewController () <AVCaptureMetadataOutputObjectsDelegate>

@property (weak, nonatomic) IBOutlet UIButton *backButton;
@property (weak, nonatomic) IBOutlet MEGASegmentedControl *segmentedControl;

@property (weak, nonatomic) IBOutlet UIView *avatarBackgroundView;
@property (weak, nonatomic) IBOutlet UIImageView *avatarImageView;
@property (weak, nonatomic) IBOutlet UIButton *linkCopyButton;

@property (weak, nonatomic) IBOutlet UIView *cameraView;
@property (weak, nonatomic) IBOutlet UIView *cameraMaskView;
@property (weak, nonatomic) IBOutlet UIView *cameraMaskBorderView;
@property (weak, nonatomic) IBOutlet UILabel *hintLabel;
@property (weak, nonatomic) IBOutlet UILabel *errorLabel;

@property (weak, nonatomic) IBOutlet NSLayoutConstraint *contactLinkConstraint;
@property (weak, nonatomic) IBOutlet NSLayoutConstraint *linkCopyConstraint;
@property (weak, nonatomic) IBOutlet NSLayoutConstraint *hintConstraint;
@property (weak, nonatomic) IBOutlet NSLayoutConstraint *errorConstraint;

@property (nonatomic) AVCaptureSession *captureSession;
@property (nonatomic) AVCaptureVideoPreviewLayer *videoPreviewLayer;

@property (nonatomic) BOOL queryInProgress;

@end

@implementation ContactLinkQRViewController

#pragma mark - Lifecycle

- (void)viewDidLoad {
    [super viewDidLoad];
    
    [self.segmentedControl setTitle:NSLocalizedString(@"My QR code", @"Label for any ‘My QR code’ button, link, text, title, etc. - (String as short as possible).") forSegmentAtIndex:0];
    [self.segmentedControl setTitle:NSLocalizedString(@"scanCode", @"Segmented control title for view that allows the user to scan QR codes. String as short as possible.") forSegmentAtIndex:1];
    [self.linkCopyButton setTitle:NSLocalizedString(@"copyLink", @"Title for a button to copy the link to the clipboard") forState:UIControlStateNormal];
    
    self.hintLabel.text = NSLocalizedString(@"lineCodeWithCamera", @"Label that encourage the user to line the QR to scan with the camera");

    if (self.scanCode) {
        self.segmentedControl.selectedSegmentIndex = QRSectionScanCode;
        [self valueChangedAtSegmentedControl:self.segmentedControl];
        [self stopRecognizingCodes];
    }
    
    self.contactLinkCreateDelegate = [[MEGAContactLinkCreateRequestDelegate alloc] initWithCompletion:^(MEGARequest *request) {
        NSString *destination = [NSString stringWithFormat:@"https://mega.nz/C!%@", [MEGASdk base64HandleForHandle:request.nodeHandle]];
        self.contactLinkLabel.text = destination;
        if (self.segmentedControl.selectedSegmentIndex == QRSectionMyCode) {
            self.linkCopyButton.hidden = self.moreButton.hidden = NO;
        }
        
        self.qrImageView.image = [UIImage mnz_qrImageFromString:destination withSize:self.qrImageView.frame.size color:[UIColor mnz_qr:self.traitCollection] backgroundColor:[UIColor mnz_secondaryBackgroundForTraitCollection:self.traitCollection]];
        [self setUserAvatar];
        [self setMoreButtonAction];
    }];
    
    [self updateAppearance];
    
    [self configureContextMenuManager];
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    
    [[MEGASdkManager sharedMEGASdk] contactLinkCreateRenew:NO delegate:self.contactLinkCreateDelegate];
}

- (void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];
    
    if (self.scanCode) {
        [self startRecognizingCodes];
    }
}

- (void)viewDidLayoutSubviews {
    [super viewDidLayoutSubviews];

    [self setupCameraMask];
}

- (void)viewWillTransitionToSize:(CGSize)size withTransitionCoordinator:(id<UIViewControllerTransitionCoordinator>)coordinator {
    [self stopRecognizingCodes];
    self.cameraMaskView.hidden = YES;
    [coordinator animateAlongsideTransition:^(id<UIViewControllerTransitionCoordinatorContext>  _Nonnull context) {
        [self.videoPreviewLayer.connection setVideoOrientation:(AVCaptureVideoOrientation) self.view.window.windowScene.interfaceOrientation];
        [self setupCameraMask];
        [self startRecognizingCodes];
    } completion:^(id<UIViewControllerTransitionCoordinatorContext>  _Nonnull context) {
        self.cameraMaskView.hidden = self.segmentedControl.selectedSegmentIndex == QRSectionMyCode;
    }];
}

- (UIInterfaceOrientationMask)supportedInterfaceOrientations {
    if ([[UIDevice currentDevice] iPhoneDevice]) {
        return UIInterfaceOrientationMaskPortrait | UIInterfaceOrientationMaskPortraitUpsideDown;
    }
    
    return UIInterfaceOrientationMaskAll;
}

- (UIStatusBarStyle)preferredStatusBarStyle {
    return (self.segmentedControl.selectedSegmentIndex == QRSectionMyCode) ? UIStatusBarStyleDefault : UIStatusBarStyleLightContent;
}

- (void)traitCollectionDidChange:(UITraitCollection *)previousTraitCollection {
    [super traitCollectionDidChange:previousTraitCollection];
    
    if ([self.traitCollection hasDifferentColorAppearanceComparedToTraitCollection:previousTraitCollection]) {
        [self updateAppearance];
    }
}

#pragma mark - Private

- (void)updateAppearance {
    switch (self.segmentedControl.selectedSegmentIndex) {
        case QRSectionMyCode: {
            self.view.backgroundColor = [UIColor mnz_backgroundElevated:self.traitCollection];
            self.backButton.tintColor = self.moreButton.tintColor = [UIColor mnz_primaryGrayForTraitCollection:self.traitCollection];
            [self.segmentedControl setTitleTextColor:UIColor.mnz_label selectedColor:UIColor.mnz_label];
            
            //The SVProgressHUD appearance is not updated when enabling/disabling dark mode. By updating the appearance and dismissing the HUD, it will have the correct configuration the next time is shown.
            [AppearanceManager configureSVProgressHUD:self.traitCollection];
            [SVProgressHUD dismiss];
            break;
        }
        
        case QRSectionScanCode: {
            self.view.backgroundColor = UIColor.clearColor;
            self.backButton.tintColor = UIColor.whiteColor;
            self.hintLabel.textColor = UIColor.whiteColor;
            UIColor *scanCodeLabelTextColor = (self.traitCollection.userInterfaceStyle == UIUserInterfaceStyleDark ? UIColor.whiteColor : UIColor.blackColor);
            [self.segmentedControl setTitleTextColor:UIColor.whiteColor selectedColor:scanCodeLabelTextColor];
            break;
        }
    }
    
    self.qrImageView.image = [UIImage mnz_qrImageFromString:self.contactLinkLabel.text withSize:self.qrImageView.frame.size color:[UIColor mnz_qr:self.traitCollection] backgroundColor:[UIColor mnz_secondaryBackgroundForTraitCollection:self.traitCollection]];
    
    [self.linkCopyButton mnz_setupPrimary:self.traitCollection];
}

#pragma mark - User avatar and camera mask

- (void)setUserAvatar {
    MEGAUser *myUser = [[MEGASdkManager sharedMEGASdk] myUser];
    [self.avatarImageView mnz_setImageForUserHandle:myUser.handle];
}

- (void)setupCameraMask {
    CGMutablePathRef mutablePath = CGPathCreateMutable();
    CGPathAddRect(mutablePath, nil, self.cameraMaskView.frame);
    CGPathAddRoundedRect(mutablePath, nil, self.qrImageView.frame, 46.0f, 46.0f);
    CAShapeLayer *mask = [[CAShapeLayer alloc] init];
    mask.path = mutablePath;
    mask.fillRule = kCAFillRuleEvenOdd;
    self.cameraMaskView.layer.mask = mask;
    CGPathRelease(mutablePath);
}

#pragma mark - IBActions

- (IBAction)valueChangedAtSegmentedControl:(UISegmentedControl *)sender {
    [self updateAppearance];
    
    switch (sender.selectedSegmentIndex) {
        case QRSectionMyCode:
            [self stopRecognizingCodes];
            self.qrImageView.hidden = self.avatarBackgroundView.hidden = self.avatarImageView.hidden = self.contactLinkLabel.hidden = NO;
            self.linkCopyButton.hidden = self.moreButton.hidden = (self.contactLinkLabel.text.length == 0);
            self.cameraView.hidden = self.cameraMaskView.hidden = self.cameraMaskBorderView.hidden = self.hintLabel.hidden = self.errorLabel.hidden = YES;
            break;
            
        case QRSectionScanCode:
            if ([self startRecognizingCodes]) {
                self.qrImageView.hidden = self.avatarBackgroundView.hidden = self.avatarImageView.hidden = self.contactLinkLabel.hidden = self.linkCopyButton.hidden = self.moreButton.hidden = YES;
                self.cameraView.hidden = self.cameraMaskView.hidden = self.cameraMaskBorderView.hidden = self.hintLabel.hidden = self.errorLabel.hidden = NO;
                self.queryInProgress = NO;
            } else {
                sender.selectedSegmentIndex = QRSectionMyCode;
                [self valueChangedAtSegmentedControl:sender];
                [DevicePermissionsHelper alertVideoPermissionWithCompletionHandler:nil];
            }
            
            break;
            
        default:
            break;
    }
    
    [self setNeedsStatusBarAppearanceUpdate];
}

- (IBAction)backButtonTapped:(UIButton *)sender {
    [self stopRecognizingCodes];
    [self dismissViewControllerAnimated:YES completion:nil];
}

- (IBAction)linkCopyButtonTapped:(UIButton *)sender {
    [UIPasteboard generalPasteboard].string = self.contactLinkLabel.text;
    [SVProgressHUD showSuccessWithStatus:NSLocalizedString(@"copiedToTheClipboard", @"Text of the button after the links were copied to the clipboard")];
}

#pragma mark - QR recognizing

- (BOOL)startRecognizingCodes {
    if (self.captureSession.isRunning) {
        return YES;
    }
    
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
        captureMetadataOutput.metadataObjectTypes = [NSArray<AVMetadataObjectType> arrayWithObject:AVMetadataObjectTypeQRCode];

        self.videoPreviewLayer = [[AVCaptureVideoPreviewLayer alloc] initWithSession:self.captureSession];
        self.videoPreviewLayer.videoGravity = AVLayerVideoGravityResizeAspectFill;
        self.videoPreviewLayer.connection.videoOrientation = (AVCaptureVideoOrientation)self.view.window.windowScene.interfaceOrientation;
        self.videoPreviewLayer.frame = self.cameraView.layer.bounds;
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
                self.queryInProgress = YES;
                NSString *detectedString = metadata.stringValue;
                NSString *baseString = @"https://mega.nz/C!";
                if ([detectedString containsString:baseString]) {
                    NSString *base64Handle = [detectedString stringByReplacingOccurrencesOfString:baseString withString:@""];
                    
                    MEGAContactLinkQueryRequestDelegate *delegate = [[MEGAContactLinkQueryRequestDelegate alloc] initWithCompletion:^(MEGARequest *request) {
                        switch (self.contactLinkQRType) {
                            case ContactLinkQRTypeContactRequest: {
                                [self feedbackWithSuccess:YES];
                                NSString *fullName = [NSString stringWithFormat:@"%@ %@", request.name, request.text];
                                [self presentInviteModalForEmail:request.email fullName:fullName contactLinkHandle:request.nodeHandle image:request.file];
                                break;
                            }
                                
                            case ContactLinkQRTypeShareFolder: {
                                [self dismissViewControllerAnimated:YES completion:^{
                                    if ([self.contactLinkQRDelegate respondsToSelector:@selector(emailForScannedQR:)]) {
                                        [self.contactLinkQRDelegate emailForScannedQR:request.email];
                                    }
                                }];
                                break;
                            }
                                
                            default:
                                break;
                        }
                    } onError:^(MEGAError *error) {
                        if (error.type == MEGAErrorTypeApiENoent) {
                            [self feedbackWithSuccess:NO];
                        }
                    }];
                    
                    [[MEGASdkManager sharedMEGASdk] contactLinkQueryWithHandle:[MEGASdk handleForBase64Handle:base64Handle] delegate:delegate];
                } else {
                    [self feedbackWithSuccess:NO];
                }
            }
        }
    }
}

#pragma mark - QR recognized

- (void)presentInviteModalForEmail:(NSString *)email fullName:(NSString *)fullName contactLinkHandle:(uint64_t)contactLinkHandle image:(NSString *)imageOnBase64URLEncoding {
    CustomModalAlertViewController *inviteOrDismissModal = [[CustomModalAlertViewController alloc] init];
    
    if (imageOnBase64URLEncoding.mnz_isEmpty) {
        inviteOrDismissModal.image = [UIImage imageForName:fullName.mnz_initialForAvatar size:CGSizeMake(128.0f, 128.0f) backgroundColor:[UIColor mnz_fromHexString:[MEGASdk avatarColorForBase64UserHandle:[MEGASdk base64HandleForUserHandle:contactLinkHandle]]] backgroundGradientColor:[UIColor mnz_fromHexString:[MEGASdk avatarSecondaryColorForBase64UserHandle:[MEGASdk base64HandleForUserHandle:contactLinkHandle]]] textColor:UIColor.whiteColor font:[UIFont systemFontOfSize:64.0f]];
    } else {
        inviteOrDismissModal.roundImage = YES;
        NSData *imageData = [[NSData alloc] initWithBase64EncodedString:[NSString mnz_base64FromBase64URLEncoding:imageOnBase64URLEncoding] options:NSDataBase64DecodingIgnoreUnknownCharacters];
        inviteOrDismissModal.image = [UIImage imageWithData:imageData];
    }
    
    inviteOrDismissModal.viewTitle = fullName;
    
    __weak ContactLinkQRViewController *weakSelf = self;
    __weak CustomModalAlertViewController *weakInviteOrDismissModal = inviteOrDismissModal;
    void (^firstCompletion)(void) = ^{
        MEGAInviteContactRequestDelegate *delegate = [[MEGAInviteContactRequestDelegate alloc] initWithNumberOfRequests:1 presentSuccessOver:weakSelf completion:^{
            __weak ContactLinkQRViewController *weakSelf = self;
            weakSelf.queryInProgress = NO;
        }];
        [[MEGASdkManager sharedMEGASdk] inviteContactWithEmail:email message:@"" action:MEGAInviteActionAdd handle:contactLinkHandle delegate:delegate];
        [weakInviteOrDismissModal dismissViewControllerAnimated:YES completion:nil];
    };
    
    void (^dismissCompletion)(void) = ^{
        [weakInviteOrDismissModal dismissViewControllerAnimated:YES completion:^{
            weakSelf.queryInProgress = NO;
        }];
    };
    
    MEGAUser *user = [[MEGASdkManager sharedMEGASdk] contactForEmail:email];
    if (user && user.visibility == MEGAUserVisibilityVisible) {
        inviteOrDismissModal.detail = [NSLocalizedString(@"alreadyAContact", @"Error message displayed when trying to invite a contact who is already added.") stringByReplacingOccurrencesOfString:@"%s" withString:email];
        inviteOrDismissModal.firstButtonTitle = NSLocalizedString(@"dismiss", @"Label for any 'Dismiss' button, link, text, title, etc. - (String as short as possible).");
        inviteOrDismissModal.firstCompletion = dismissCompletion;
    } else {
        BOOL isInOutgoingContactRequest = NO;
        MEGAContactRequestList *outgoingContactRequestList = [[MEGASdkManager sharedMEGASdk] outgoingContactRequests];
        for (NSInteger i = 0; i < outgoingContactRequestList.size.integerValue; i++) {
            MEGAContactRequest *contactRequest = [outgoingContactRequestList contactRequestAtIndex:i];
            if ([email isEqualToString:contactRequest.targetEmail]) {
                isInOutgoingContactRequest = YES;
                break;
            }
        }
        if (isInOutgoingContactRequest) {
            inviteOrDismissModal.image = [UIImage imageNamed:@"inviteSent"];
            inviteOrDismissModal.viewTitle = NSLocalizedString(@"inviteSent", @"Title shown when the user sends a contact invitation");
            NSString *detailText = NSLocalizedString(@"dialog.inviteContact.outgoingContactRequest", @"Detail message shown when a contact has been invited. The [X] placeholder will be replaced on runtime for the email of the invited user");
            detailText = [detailText stringByReplacingOccurrencesOfString:@"[X]" withString:email];
            inviteOrDismissModal.detail = detailText;
            inviteOrDismissModal.boldInDetail = email;
            inviteOrDismissModal.firstButtonTitle = NSLocalizedString(@"close", nil);
            inviteOrDismissModal.firstCompletion = dismissCompletion;
        } else {
            inviteOrDismissModal.detail = email;
            inviteOrDismissModal.firstButtonTitle = NSLocalizedString(@"invite", @"A button on a dialog which invites a contact to join MEGA.");
            inviteOrDismissModal.dismissButtonTitle = NSLocalizedString(@"dismiss", @"Label for any 'Dismiss' button, link, text, title, etc. - (String as short as possible).");
            inviteOrDismissModal.firstCompletion = firstCompletion;
            inviteOrDismissModal.dismissCompletion = dismissCompletion;
        }
    }
    
    [self presentViewController:inviteOrDismissModal animated:YES completion:nil];
}

- (void)feedbackWithSuccess:(BOOL)success {
    NSString *message = success ? NSLocalizedString(@"codeScanned", @"Success text shown in a label when the user scans a valid QR. String as short as possible.") : NSLocalizedString(@"invalidCode", @"Error text shown when the user scans a QR that is not valid. String as short as possible.");
    UIColor *color = success ? [UIColor greenColor] : [UIColor redColor];
    dispatch_async(dispatch_get_main_queue(), ^{
        self.errorLabel.text = message;
        CABasicAnimation *colorAnimation = [CABasicAnimation animationWithKeyPath:@"borderColor"];
        colorAnimation.fromValue = (id)color.CGColor;
        colorAnimation.toValue = (id)[UIColor whiteColor].CGColor;
        colorAnimation.duration = 1;
        [self.cameraMaskBorderView.layer addAnimation:colorAnimation forKey:@"borderColor"];
    });
    
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(1 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        self.queryInProgress = success; // If success, queryInProgress will be NO later
        self.errorLabel.text = @"";
    });
}

@end
