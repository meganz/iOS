#import "ContactLinkQRViewController.h"

#import <AVKit/AVKit.h>

#import "SVProgressHUD.h"

#import "CustomModalAlertViewController.h"

#import "MEGAContactLinkQueryRequestDelegate.h"
#import "MEGAInviteContactRequestDelegate.h"
#import "MEGA-Swift.h"
#import "QRSettingsTableViewController.h"

#import "NSString+MNZCategory.h"
#import "UIImage+GKContact.h"
#import "UIImage+MNZCategory.h"
#import "UIImageView+MNZCategory.h"

@import MEGAL10nObjc;
@import MEGASDKRepo;
@import MEGAUIKit;

@interface ContactLinkQRViewController () <AVCaptureMetadataOutputObjectsDelegate>

@property (weak, nonatomic) IBOutlet MEGASegmentedControl *segmentedControl;

@property (nonatomic) AVCaptureSession *captureSession;
@property (nonatomic) AVCaptureVideoPreviewLayer *videoPreviewLayer;

@end

@implementation ContactLinkQRViewController

#pragma mark - Lifecycle

- (void)viewDidLoad {
    [super viewDidLoad];
    
    [self.segmentedControl setTitle:LocalizedString(@"My QR code", @"Label for any ‘My QR code’ button, link, text, title, etc. - (String as short as possible).") forSegmentAtIndex:0];
    [self.segmentedControl setTitle:LocalizedString(@"scanCode", @"Segmented control title for view that allows the user to scan QR codes. String as short as possible.") forSegmentAtIndex:1];
    [self.linkCopyButton setTitle:LocalizedString(@"copyLink", @"Title for a button to copy the link to the clipboard") forState:UIControlStateNormal];
    
    self.hintLabel.text = LocalizedString(@"lineCodeWithCamera", @"Label that encourage the user to line the QR to scan with the camera");
    
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
        
        [self setupQRImageFrom: destination];
        [self setUserAvatar];
        [self setMoreButtonAction];
    }];
    
    [self updateAppearance: self.segmentedControl];
    [self configureContextMenuManager];
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    
    [MEGASdk.shared contactLinkCreateRenew:NO delegate:self.contactLinkCreateDelegate];
}

- (void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];
    
    if (self.scanCode) {
        [self startRecognizingCodes];
    }
}

- (void)viewDidLayoutSubviews {
    [super viewDidLayoutSubviews];
    
    self.avatarImageView.layer.cornerRadius = self.avatarImageView.frame.size.width / 2;
    [self setupCameraMask];
}

- (void)viewWillTransitionToSize:(CGSize)size withTransitionCoordinator:(id<UIViewControllerTransitionCoordinator>)coordinator {
    [self stopRecognizingCodes];
    self.cameraMaskView.hidden = YES;
    [coordinator animateAlongsideTransition:^(id<UIViewControllerTransitionCoordinatorContext>  _Nonnull context) {
        [self.videoPreviewLayer.connection setVideoOrientation:(AVCaptureVideoOrientation) self.view.window.windowScene.interfaceOrientation];
        if (self.segmentedControl.selectedSegmentIndex == QRSectionScanCode) {
            [self startRecognizingCodes];
            [self setupCameraMask];
        }
        
    } completion:^(id<UIViewControllerTransitionCoordinatorContext>  _Nonnull context) {
        self.cameraMaskView.hidden = self.segmentedControl.selectedSegmentIndex == QRSectionMyCode;
    }];
}

- (UIStatusBarStyle)preferredStatusBarStyle {
    return (self.segmentedControl.selectedSegmentIndex == QRSectionMyCode) ? UIStatusBarStyleDefault : UIStatusBarStyleLightContent;
}

#pragma mark - User avatar and camera mask

- (void)setUserAvatar {
    [self.avatarImageView mnz_setImageForUserHandle:MEGASdk.currentUserHandle.unsignedLongLongValue];
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
    [self updateAppearance: self.segmentedControl];
    
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
                DevicePermissionsHandlerObjC *handler = [[DevicePermissionsHandlerObjC alloc] init];
                [handler alertVideoPermission];
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
    [SVProgressHUD showSuccessWithStatus:LocalizedString(@"copiedToTheClipboard", @"Text of the button after the links were copied to the clipboard")];
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
        
        dispatch_async(qrDispatchQueue, ^{
            [self.captureSession startRunning];
        });
        
        
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
                    
                    [MEGASdk.shared contactLinkQueryWithHandle:[MEGASdk handleForBase64Handle:base64Handle] delegate:delegate];
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
        inviteOrDismissModal.image = [UIImage imageForName:fullName.mnz_initialForAvatar size:CGSizeMake(128.0f, 128.0f) backgroundColor:[UIColor mnz_fromHexString:[MEGASdk avatarColorForBase64UserHandle:[MEGASdk base64HandleForUserHandle:contactLinkHandle]]] backgroundGradientColor:[UIColor mnz_fromHexString:[MEGASdk avatarSecondaryColorForBase64UserHandle:[MEGASdk base64HandleForUserHandle:contactLinkHandle]]] textColor:UIColor.whiteTextColor font:[UIFont systemFontOfSize:64.0f]];
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
        [MEGASdk.shared inviteContactWithEmail:email message:@"" action:MEGAInviteActionAdd handle:contactLinkHandle delegate:delegate];
        [weakInviteOrDismissModal dismissViewControllerAnimated:YES completion:nil];
    };
    
    void (^dismissCompletion)(void) = ^{
        [weakInviteOrDismissModal dismissViewControllerAnimated:YES completion:^{
            weakSelf.queryInProgress = NO;
        }];
    };
    
    MEGAUser *user = [MEGASdk.shared contactForEmail:email];
    if (user && user.visibility == MEGAUserVisibilityVisible) {
        inviteOrDismissModal.detail = [LocalizedString(@"alreadyAContact", @"Error message displayed when trying to invite a contact who is already added.") stringByReplacingOccurrencesOfString:@"%s" withString:email];
        inviteOrDismissModal.firstButtonTitle = LocalizedString(@"dismiss", @"Label for any 'Dismiss' button, link, text, title, etc. - (String as short as possible).");
        inviteOrDismissModal.firstCompletion = dismissCompletion;
    } else {
        BOOL isInOutgoingContactRequest = NO;
        MEGAContactRequestList *outgoingContactRequestList = [MEGASdk.shared outgoingContactRequests];
        for (NSInteger i = 0; i < outgoingContactRequestList.size; i++) {
            MEGAContactRequest *contactRequest = [outgoingContactRequestList contactRequestAtIndex:i];
            if ([email isEqualToString:contactRequest.targetEmail]) {
                isInOutgoingContactRequest = YES;
                break;
            }
        }
        if (isInOutgoingContactRequest) {
            inviteOrDismissModal.image = [UIImage imageNamed:@"contactInviteSent"];
            inviteOrDismissModal.viewTitle = LocalizedString(@"inviteSent", @"Title shown when the user sends a contact invitation");
            NSString *detailText = LocalizedString(@"dialog.inviteContact.outgoingContactRequest", @"Detail message shown when a contact has been invited. The [X] placeholder will be replaced on runtime for the email of the invited user");
            detailText = [detailText stringByReplacingOccurrencesOfString:@"[X]" withString:email];
            inviteOrDismissModal.detail = detailText;
            inviteOrDismissModal.boldInDetail = email;
            inviteOrDismissModal.firstButtonTitle = LocalizedString(@"close", @"");
            inviteOrDismissModal.firstCompletion = dismissCompletion;
        } else {
            inviteOrDismissModal.detail = email;
            inviteOrDismissModal.firstButtonTitle = LocalizedString(@"invite", @"A button on a dialog which invites a contact to join MEGA.");
            inviteOrDismissModal.dismissButtonTitle = LocalizedString(@"dismiss", @"Label for any 'Dismiss' button, link, text, title, etc. - (String as short as possible).");
            inviteOrDismissModal.firstCompletion = firstCompletion;
            inviteOrDismissModal.dismissCompletion = dismissCompletion;
        }
    }
    
    [self presentViewController:inviteOrDismissModal animated:YES completion:nil];
}

@end
