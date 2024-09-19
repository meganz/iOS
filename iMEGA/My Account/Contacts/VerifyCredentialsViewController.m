#import "VerifyCredentialsViewController.h"

#import "SVProgressHUD.h"

#import "MEGA-Swift.h"

@import MEGAL10nObjc;
@import MEGASDKRepo;

@interface VerifyCredentialsViewController ()

@property (weak, nonatomic) IBOutlet UIView *userCredentialsView;

@property (weak, nonatomic) IBOutlet UILabel *userNameLabel;
@property (weak, nonatomic) IBOutlet UILabel *userEmailLabel;

@property (weak, nonatomic) IBOutlet UILabel *firstPartOfUserCredentialsLabel;
@property (weak, nonatomic) IBOutlet UILabel *secondPartOfUserCredentialsLabel;
@property (weak, nonatomic) IBOutlet UILabel *thirdPartOfUserCredentialsLabel;
@property (weak, nonatomic) IBOutlet UILabel *fourthPartOfUserCredentialsLabel;
@property (weak, nonatomic) IBOutlet UILabel *fifthPartOfUserCredentialsLabel;
@property (weak, nonatomic) IBOutlet UILabel *sixthPartOfUserCredentialsLabel;
@property (weak, nonatomic) IBOutlet UILabel *seventhPartOfUserCredentialsLabel;
@property (weak, nonatomic) IBOutlet UILabel *eighthPartOfUserCredentialsLabel;
@property (weak, nonatomic) IBOutlet UILabel *ninthPartOfUserCredentialsLabel;
@property (weak, nonatomic) IBOutlet UILabel *tenthPartOfUserCredentialsLabel;

@property (weak, nonatomic) IBOutlet UIView *myCredentialsTopSeparatorView;
@property (weak, nonatomic) IBOutlet UIView *myCredentialsView;
@property (weak, nonatomic) IBOutlet UIView *myCredentialsSubView;

@property (weak, nonatomic) IBOutlet UILabel *yourCredentialsLabel;
@property (weak, nonatomic) IBOutlet UILabel *firstPartOfYourCredentialsLabel;
@property (weak, nonatomic) IBOutlet UILabel *secondPartOfYourCredentialsLabel;
@property (weak, nonatomic) IBOutlet UILabel *thirdPartOfYourCredentialsLabel;
@property (weak, nonatomic) IBOutlet UILabel *fourthPartOfYourCredentialsLabel;
@property (weak, nonatomic) IBOutlet UILabel *fifthPartOfYourCredentialsLabel;
@property (weak, nonatomic) IBOutlet UILabel *sixthPartOfYourCredentialsLabel;
@property (weak, nonatomic) IBOutlet UILabel *seventhPartOfYourCredentialsLabel;
@property (weak, nonatomic) IBOutlet UILabel *eighthPartOfYourCredentialsLabel;
@property (weak, nonatomic) IBOutlet UILabel *ninthPartOfYourCredentialsLabel;
@property (weak, nonatomic) IBOutlet UILabel *tenthPartOfYourCredentialsLabel;

@property (weak, nonatomic) IBOutlet UIButton *verifyOrResetButton;

@end

@implementation VerifyCredentialsViewController

#pragma mark - Lifecycle

- (void)viewDidLoad {
    [super viewDidLoad];
    
    self.userNameLabel.text = self.userName;
    self.userEmailLabel.text = self.user.email;
    
    NSInteger length = 4;
    NSInteger position = 4;
    
    RequestDelegate *userCredentialsDelegate = [RequestDelegate.alloc initWithCompletion:^(MEGARequest *request, MEGAError *error) {
        if (error.type) {
            [SVProgressHUD showErrorWithStatus:[NSString stringWithFormat:@"%@", LocalizedString(error.name, @"")]];
        } else {
            NSString *userCredentials = request.password;
            if (userCredentials.length == 40) {
                self.firstPartOfUserCredentialsLabel.text =  [userCredentials substringWithRange:NSMakeRange(0, length)];
                self.secondPartOfUserCredentialsLabel.text =  [userCredentials substringWithRange:NSMakeRange(position, length)];
                self.thirdPartOfUserCredentialsLabel.text =  [userCredentials substringWithRange:NSMakeRange((position * 2), length)];
                self.fourthPartOfUserCredentialsLabel.text =  [userCredentials substringWithRange:NSMakeRange((position * 3), length)];
                self.fifthPartOfUserCredentialsLabel.text =  [userCredentials substringWithRange:NSMakeRange((position * 4), length)];
                self.sixthPartOfUserCredentialsLabel.text =  [userCredentials substringWithRange:NSMakeRange((position * 5), length)];
                self.seventhPartOfUserCredentialsLabel.text =  [userCredentials substringWithRange:NSMakeRange((position * 6), length)];
                self.eighthPartOfUserCredentialsLabel.text =  [userCredentials substringWithRange:NSMakeRange((position * 7), length)];
                self.ninthPartOfUserCredentialsLabel.text =  [userCredentials substringWithRange:NSMakeRange((position * 8), length)];
                self.tenthPartOfUserCredentialsLabel.text =  [userCredentials substringWithRange:NSMakeRange((position * 9), length)];
            }
        }
    }];
    [MEGASdk.shared getUserCredentials:self.user delegate:userCredentialsDelegate];
    
    self.yourCredentialsLabel.text = LocalizedString(@"verifyCredentials.yourCredentials.title", @"Title of the label in the my account section. It shows the credentials of the current user so it can be used to be verified by other contacts");
    NSString *yourCredentials = MEGASdk.shared.myCredentials;
    if (yourCredentials.length == 40) {
        self.firstPartOfYourCredentialsLabel.text =  [yourCredentials substringWithRange:NSMakeRange(0, length)];
        self.secondPartOfYourCredentialsLabel.text =  [yourCredentials substringWithRange:NSMakeRange(position, length)];
        self.thirdPartOfYourCredentialsLabel.text =  [yourCredentials substringWithRange:NSMakeRange((position * 2), length)];
        self.fourthPartOfYourCredentialsLabel.text =  [yourCredentials substringWithRange:NSMakeRange((position * 3), length)];
        self.fifthPartOfYourCredentialsLabel.text =  [yourCredentials substringWithRange:NSMakeRange((position * 4), length)];
        self.sixthPartOfYourCredentialsLabel.text =  [yourCredentials substringWithRange:NSMakeRange((position * 5), length)];
        self.seventhPartOfYourCredentialsLabel.text =  [yourCredentials substringWithRange:NSMakeRange((position * 6), length)];
        self.eighthPartOfYourCredentialsLabel.text =  [yourCredentials substringWithRange:NSMakeRange((position * 7), length)];
        self.ninthPartOfYourCredentialsLabel.text =  [yourCredentials substringWithRange:NSMakeRange((position * 8), length)];
        self.tenthPartOfYourCredentialsLabel.text =  [yourCredentials substringWithRange:NSMakeRange((position * 9), length)];
    }

    [self setContentMessages];
    
    [self updateVerifyOrResetButton];
    
    [self updateAppearance];

    [self setLabelColors];
}

- (void)traitCollectionDidChange:(UITraitCollection *)previousTraitCollection {
    [super traitCollectionDidChange:previousTraitCollection];
        
    if ([self.traitCollection hasDifferentColorAppearanceComparedToTraitCollection:previousTraitCollection]) {
        [self updateAppearance];
    }
}

#pragma mark - Public

- (void)setContactVerification:(BOOL)isIncomingSharedItem {
    self.incomingSharedItem = isIncomingSharedItem;
    self.verifyContactForSharedItem = true;
}

#pragma mark - Private

- (void)updateAppearance {
    self.view.backgroundColor = [UIColor mnz_backgroundElevated];
    
    self.myCredentialsTopSeparatorView.backgroundColor = [UIColor mnz_separator];
    self.myCredentialsView.backgroundColor = [UIColor mnz_secondaryBackgroundElevated:self.traitCollection];
    self.userEmailLabel.textColor = [UIColor mnz_subtitles];
    
    self.myCredentialsSubView.backgroundColor = [UIColor mnz_tertiaryBackgroundElevated:self.traitCollection];
    self.myCredentialsSubView.layer.borderColor = [UIColor mnz_separator].CGColor;

    [self setLabelColors];
    [self updateVerifyOrResetButton];
}

- (void)updateVerifyOrResetButton {
    if ([MEGASdk.shared areCredentialsVerifiedOfUser:self.user]) {
        [self.verifyOrResetButton setTitle:LocalizedString(@"reset", @"Button to reset the password") forState:UIControlStateNormal];
        [self setResetButtonColor:self.verifyOrResetButton];
    } else {
        [self.verifyOrResetButton setTitle:LocalizedString(@"account.verifyContact.confirmButtonText", @"Mark as verified") forState:UIControlStateNormal];
        [self.verifyOrResetButton mnz_setupPrimary:self.traitCollection];
    }
}

#pragma mark - IBActions

- (IBAction)verifyOrResetTouchUpInside:(UIButton *)sender {
    if ([MEGASdk.shared areCredentialsVerifiedOfUser:self.user]) {
        RequestDelegate *resetCredentialsOfUserDelegate = [RequestDelegate.alloc initWithCompletion:^(MEGARequest *request, MEGAError *error) {
            if (error.type) {
                [SVProgressHUD showErrorWithStatus:[NSString stringWithFormat:@"%@", LocalizedString(error.name, @"")]];
            } else {
                [self updateVerifyOrResetButton];
                self.statusUpdateCompletionBlock();
            }
        }];
        [MEGASdk.shared resetCredentialsOfUser:self.user delegate:resetCredentialsOfUserDelegate];
    } else {
        RequestDelegate *verifyCredentialsOfUserDelegate = [RequestDelegate.alloc initWithCompletion:^(MEGARequest *request, MEGAError *error) {
            if (error.type) {
                [SVProgressHUD showErrorWithStatus:[NSString stringWithFormat:@"%@", LocalizedString(error.name, @"")]];
            } else {
                [SVProgressHUD showSuccessWithStatus:LocalizedString(@"verified", @"Button title")];
                
                [self updateVerifyOrResetButton];
                self.statusUpdateCompletionBlock();
            }
        }];
        [MEGASdk.shared verifyCredentialsOfUser:self.user delegate:verifyCredentialsOfUserDelegate];
    }
}

@end
