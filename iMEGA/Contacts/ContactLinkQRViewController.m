
#import "ContactLinkQRViewController.h"

#import <AVKit/AVKit.h>

#import "SVProgressHUD.h"

#import "CustomModalAlertViewController.h"
#import "MEGAInviteContactRequestDelegate.h"
#import "MEGASdkManager.h"

#import "UIAlertAction+MNZCategory.h"
#import "UIImage+GKContact.h"
#import "UIImage+MNZCategory.h"
#import "UIImageView+MNZCategory.h"

@interface ContactLinkQRViewController () <AVCaptureMetadataOutputObjectsDelegate, MEGARequestDelegate>

@property (weak, nonatomic) IBOutlet UIButton *backButton;
@property (weak, nonatomic) IBOutlet UISegmentedControl *segmentedControl;
@property (weak, nonatomic) IBOutlet UIButton *moreButton;

@property (weak, nonatomic) IBOutlet UIImageView *qrImageView;
@property (weak, nonatomic) IBOutlet UIImageView *avatarImageView;
@property (weak, nonatomic) IBOutlet UILabel *contactLinkLabel;
@property (weak, nonatomic) IBOutlet UIButton *linkCopyButton;

@property (weak, nonatomic) IBOutlet UIView *cameraView;
@property (weak, nonatomic) IBOutlet UIView *cameraMaskView;
@property (weak, nonatomic) IBOutlet UIView *cameraMaskBorderView;

@property (nonatomic) AVCaptureSession *captureSession;
@property (nonatomic) AVCaptureVideoPreviewLayer *videoPreviewLayer;

@property (nonatomic) BOOL queryInProgress;

@property (nonatomic) uint64_t contactLinkHandle; // TODO: Delete this property as it is going to be useless

@end

@implementation ContactLinkQRViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    [self.segmentedControl setTitle:@"My Code" forSegmentAtIndex:0];
    [self.segmentedControl setTitle:@"Scan Code" forSegmentAtIndex:1];
    [self.linkCopyButton setTitle:AMLocalizedString(@"copyLink", @"Title for a button to copy the link to the clipboard") forState:UIControlStateNormal];
    
    if (self.scanCode) {
        self.segmentedControl.selectedSegmentIndex = 1;
        [self valueChangedAtSegmentedControl:self.segmentedControl];
    }

    [[MEGASdkManager sharedMEGASdk] contactLinkCreateWithDelegate:self];
}

- (void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];
    
    CGMutablePathRef mutablePath = CGPathCreateMutable();
    CGPathAddRect(mutablePath, nil, self.cameraMaskView.frame);
    CGPathAddRoundedRect(mutablePath, nil, self.qrImageView.frame, 46.0f, 46.0f);
    CAShapeLayer *mask = [[CAShapeLayer alloc] init];
    mask.path = mutablePath;
    mask.fillRule = kCAFillRuleEvenOdd;
    self.cameraMaskView.layer.mask = mask;
    CGPathRelease(mutablePath);
    
    self.cameraMaskBorderView.layer.borderColor = [UIColor whiteColor].CGColor;
    self.cameraMaskBorderView.layer.borderWidth = 2.0f;
    self.cameraMaskBorderView.layer.cornerRadius = 46.0f;
}

#pragma mark - User avatar

- (void)setUserAvatar {
    MEGAUser *myUser = [[MEGASdkManager sharedMEGASdk] myUser];
    [self.avatarImageView mnz_setImageForUserHandle:myUser.handle];
    self.avatarImageView.layer.borderColor = [UIColor whiteColor].CGColor;
    self.avatarImageView.layer.borderWidth = 6.0f;
    self.avatarImageView.layer.cornerRadius = 40.0f;
}

#pragma mark - IBActions

- (IBAction)valueChangedAtSegmentedControl:(UISegmentedControl *)sender {
    switch (sender.selectedSegmentIndex) {
        case 0:
            [self stopRecognizingCodes];
            self.view.backgroundColor = [UIColor whiteColor];
            self.qrImageView.hidden = self.avatarImageView.hidden = self.contactLinkLabel.hidden = NO;
            self.linkCopyButton.hidden = self.moreButton.hidden = self.contactLinkLabel.text.length==0;
            self.cameraView.hidden = self.cameraMaskView.hidden = self.cameraMaskBorderView.hidden = YES;
            self.backButton.tintColor = self.segmentedControl.tintColor = [UIColor mnz_redF0373A];
            break;
            
        case 1:
            if ([self startRecognizingCodes]) {
                self.view.backgroundColor = [UIColor clearColor];
                self.qrImageView.hidden = self.avatarImageView.hidden = self.contactLinkLabel.hidden = self.linkCopyButton.hidden = self.moreButton.hidden = YES;
                self.cameraView.hidden = self.cameraMaskView.hidden = self.cameraMaskBorderView.hidden = NO;
                self.queryInProgress = NO;
                self.backButton.tintColor = self.segmentedControl.tintColor = [UIColor whiteColor];
            } else {
                sender.selectedSegmentIndex = 0;
                [self valueChangedAtSegmentedControl:sender];
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

- (IBAction)moreButtonTapped:(UIButton *)sender {
    UIAlertController *moreAlertController = [UIAlertController alertControllerWithTitle:nil message:nil preferredStyle:UIAlertControllerStyleActionSheet];
    [moreAlertController addAction:[UIAlertAction actionWithTitle:AMLocalizedString(@"cancel", @"Button title to cancel something") style:UIAlertActionStyleCancel handler:nil]];
    
    if (self.contactLinkLabel.text.length>0) {
        UIAlertAction *shareAlertAction = [UIAlertAction actionWithTitle:AMLocalizedString(@"share", nil) style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
            UIActivityViewController *activityVC = [[UIActivityViewController alloc] initWithActivityItems:@[self.contactLinkLabel.text] applicationActivities:nil];
            [activityVC.popoverPresentationController setSourceView:self.view];
            [activityVC.popoverPresentationController setSourceRect:sender.frame];
            
            [self presentViewController:activityVC animated:YES completion:nil];
        }];
        [shareAlertAction mnz_setTitleTextColor:[UIColor mnz_black333333]];
        [moreAlertController addAction:shareAlertAction];
    }
    
    UIAlertAction *resetAlertAction = [UIAlertAction actionWithTitle:@"Reset QR Code" style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
        self.qrImageView.image = nil;
        [[MEGASdkManager sharedMEGASdk] contactLinkDeleteWithHandle:self.contactLinkHandle delegate:self];
    }];
    [resetAlertAction mnz_setTitleTextColor:[UIColor redColor]];
    [moreAlertController addAction:resetAlertAction];
    
    moreAlertController.modalPresentationStyle = UIModalPresentationPopover;
    moreAlertController.popoverPresentationController.sourceRect = sender.frame;
    moreAlertController.popoverPresentationController.sourceView = sender.superview;

    [self presentViewController:moreAlertController animated:YES completion:nil];
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

- (void)presentInviteModalForEmail:(NSString *)email fullName:(NSString *)fullName contactLinkHandle:(uint64_t)contactLinkHandle {
    CustomModalAlertViewController *inviteOrDismissModal = [[CustomModalAlertViewController alloc] init];
    inviteOrDismissModal.modalPresentationStyle = UIModalPresentationOverCurrentContext;
    inviteOrDismissModal.image = [UIImage imageForName:fullName.uppercaseString size:CGSizeMake(128.0f, 128.0f) backgroundColor:[UIColor colorFromHexString:[MEGASdk avatarColorForBase64UserHandle:[MEGASdk base64HandleForUserHandle:contactLinkHandle]]] textColor:[UIColor whiteColor] font:[UIFont mnz_SFUIRegularWithSize:64.0f]];
    inviteOrDismissModal.viewTitle = fullName;
    inviteOrDismissModal.detail = email;
    inviteOrDismissModal.action = AMLocalizedString(@"invite", @"A button on a dialog which invites a contact to join MEGA.");
    inviteOrDismissModal.dismiss = AMLocalizedString(@"dismiss", @"Label for any 'Dismiss' button, link, text, title, etc. - (String as short as possible).");
    
    __weak ContactLinkQRViewController *weakSelf = self;
    __weak CustomModalAlertViewController *weakInviteOrDismissModal = inviteOrDismissModal;
    inviteOrDismissModal.completion = ^{
        BOOL isInOutgoingContactRequest = NO;
        MEGAContactRequestList *outgoingContactRequestList = [[MEGASdkManager sharedMEGASdk] outgoingContactRequests];
        for (NSInteger i = 0; i < [[outgoingContactRequestList size] integerValue]; i++) {
            MEGAContactRequest *contactRequest = [outgoingContactRequestList contactRequestAtIndex:i];
            if ([email isEqualToString:contactRequest.targetEmail]) {
                isInOutgoingContactRequest = YES;
                break;
            }
        }
        if (isInOutgoingContactRequest) {
            CustomModalAlertViewController *inviteSentModal = [[CustomModalAlertViewController alloc] init];
            inviteSentModal.modalPresentationStyle = UIModalPresentationOverCurrentContext;
            inviteSentModal.image = [UIImage imageNamed:@"inviteSent"];
            inviteSentModal.viewTitle = AMLocalizedString(@"inviteSent", @"Title shown when the user sends a contact invitation");
            inviteSentModal.detail = [NSString stringWithFormat:@"The user %@ has been invited and will appear in your contact list once accepted", email];
            inviteSentModal.boldInDetail = email;
            inviteSentModal.action = AMLocalizedString(@"close", nil);
            inviteSentModal.dismiss = nil;
            
            __weak typeof(CustomModalAlertViewController) *weakInviteSentModal = inviteSentModal;
            inviteSentModal.completion = ^{
                [weakInviteSentModal dismissViewControllerAnimated:YES completion:nil];
                weakSelf.queryInProgress = NO;
            };
            [weakInviteOrDismissModal dismissViewControllerAnimated:YES completion:^{
                [weakSelf presentViewController:inviteSentModal animated:YES completion:nil];
            }];
        } else {
            MEGAInviteContactRequestDelegate *inviteContactRequestDelegate = [[MEGAInviteContactRequestDelegate alloc] initWithNumberOfRequests:1];
            [[MEGASdkManager sharedMEGASdk] inviteContactWithEmail:email message:@"" action:MEGAInviteActionAdd delegate:inviteContactRequestDelegate];
            [weakInviteOrDismissModal dismissViewControllerAnimated:YES completion:^{
                weakSelf.queryInProgress = NO;
            }];
        }
    };
    
    inviteOrDismissModal.onDismiss = ^{
        [weakInviteOrDismissModal dismissViewControllerAnimated:YES completion:^{
            weakSelf.queryInProgress = NO;
        }];
    };
    
    [self presentViewController:inviteOrDismissModal animated:YES completion:nil];
}

#pragma mark - MEGARequestDelegate

- (void)onRequestFinish:(MEGASdk *)api request:(MEGARequest *)request error:(MEGAError *)error {
    if (!error.type) {
        switch (request.type) {
            case MEGARequestTypeContactLinkCreate: {
                NSString *destination = [NSString stringWithFormat:@"https://mega.nz/C!%@", [MEGASdk base64HandleForHandle:request.nodeHandle]];
                self.contactLinkHandle = request.nodeHandle;
                self.contactLinkLabel.text = destination;
                if (self.segmentedControl.selectedSegmentIndex == 0) {
                    self.linkCopyButton.hidden = self.moreButton.hidden = NO;
                }
                
                self.qrImageView.image = [UIImage mnz_qrImageFromString:destination withSize:self.qrImageView.frame.size];
                [self setUserAvatar];
                
                break;
            }
                
            case MEGARequestTypeContactLinkQuery: {
                NSString *fullName = [NSString stringWithFormat:@"%@ %@", request.name, request.text];
                [self presentInviteModalForEmail:request.email fullName:fullName contactLinkHandle:request.nodeHandle];
                
                break;
            }
                
            case MEGARequestTypeContactLinkDelete: {
                [[MEGASdkManager sharedMEGASdk] contactLinkCreateWithDelegate:self];

                break;
            }
                
            default:
                break;
        }
    }
}

@end
