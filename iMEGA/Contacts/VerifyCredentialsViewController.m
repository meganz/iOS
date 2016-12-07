#import "VerifyCredentialsViewController.h"

#import "MEGASdkManager.h"

@interface VerifyCredentialsViewController ()

@property (weak, nonatomic) IBOutlet UILabel *contactCredentialsLabel;
@property (weak, nonatomic) IBOutlet UILabel *firstPartOfContactCredentialsLabel;
@property (weak, nonatomic) IBOutlet UILabel *secondPartOfContactCredentialsLabel;
@property (weak, nonatomic) IBOutlet UILabel *thirdPartOfContactCredentialsLabel;
@property (weak, nonatomic) IBOutlet UILabel *fourthPartOfContactCredentialsLabel;
@property (weak, nonatomic) IBOutlet UILabel *fifthPartOfContactCredentialsLabel;
@property (weak, nonatomic) IBOutlet UILabel *sixthPartOfContactCredentialsLabel;
@property (weak, nonatomic) IBOutlet UILabel *seventhPartOfContactCredentialsLabel;
@property (weak, nonatomic) IBOutlet UILabel *eighthPartOfContactCredentialsLabel;
@property (weak, nonatomic) IBOutlet UILabel *ninthPartOfContactCredentialsLabel;
@property (weak, nonatomic) IBOutlet UILabel *tenthPartOfContactCredentialsLabel;
@property (weak, nonatomic) IBOutlet UILabel *explanationLabel;

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

@property (weak, nonatomic) IBOutlet UIButton *resetButton;
@property (weak, nonatomic) IBOutlet UIButton *approveButton;

@end

@implementation VerifyCredentialsViewController

#pragma mark - Lifecycle

- (void)viewDidLoad {
    [super viewDidLoad];
    
    self.navigationItem.title = AMLocalizedString(@"verifyCredentials", @"Title for a section on the fingerprint warning dialog. Below it is a button which will allow the user to verify their contact's fingerprint credentials.");
    
    NSInteger length = 4;
    NSInteger position = 4;
    
    self.contactCredentialsLabel.text = AMLocalizedString(@"contactCredentials", @"Label title above the fingerprint credentials of a user's contact. A credential in this case is a stored piece of information representing the identity of the contact");
    //TODO: Show contact credentials
    self.explanationLabel.text = AMLocalizedString(@"thisIsBestDoneInRealLife", @"'Verify user' dialog description");
    
    self.yourCredentialsLabel.text = AMLocalizedString(@"yourCredentials", @"Label title above your fingerprint credentials.  A credential in this case is a stored piece of information representing your identity");
    NSString *yourCredentials = [[MEGASdkManager sharedMEGASdk] myFingerprint];
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
    
    self.resetButton.layer.cornerRadius = 4.0f;
    [self.resetButton setTitle:AMLocalizedString(@"reset", @"Button to reset the password") forState:UIControlStateNormal];
    
    self.approveButton.layer.cornerRadius = 4.0f;
    [self.approveButton setTitle:AMLocalizedString(@"approve", @"Button title") forState:UIControlStateNormal];
}

#pragma mark - IBActions

- (IBAction)resetTouchUpInside:(UIButton *)sender {
    //TODO: Reset contact credentials
}

- (IBAction)approveTouchUpInside:(UIButton *)sender {
    //TODO: Approve contact credentials
}

@end
