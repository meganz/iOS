
#import "WhyDoINeedARecoveryKeyViewController.h"

#import "UIViewController+MNZCategory.h"

@interface WhyDoINeedARecoveryKeyViewController ()

@property (weak, nonatomic) IBOutlet UILabel *whyDoINeedARecoveryKeyLabel;
@property (weak, nonatomic) IBOutlet UILabel *firstParagraphLabel;
@property (weak, nonatomic) IBOutlet UILabel *secondParagraphLabel;
@property (weak, nonatomic) IBOutlet UILabel *thirdParagraphLabel;

@end

@implementation WhyDoINeedARecoveryKeyViewController

#pragma mark - Lifecycle

- (void)viewDidLoad {
    [super viewDidLoad];
    
    self.whyDoINeedARecoveryKeyLabel.text = AMLocalizedString(@"whyDoINeedARecoveryKey", @"Question button to present a view where it's explained what is the Recovery Key");
    self.firstParagraphLabel.text = AMLocalizedString(@"masterKey_firstParagraph", @"Detailed explanation of how the master encryption key (now renamed 'Recovery Key') works, and why it is important to remember your password.");
    self.secondParagraphLabel.text = AMLocalizedString(@"exportMasterKeyFooter", @"Footer shown on the Settings / Security Options section that explains what means to export the Recovery Key");
    self.thirdParagraphLabel.text = AMLocalizedString(@"masterKey_thirdParagraph", nil);
        
    [self mnz_customBackBarButtonItem];
}

- (UIInterfaceOrientationMask)supportedInterfaceOrientations {
    if ([[UIDevice currentDevice] iPhone4X] || [[UIDevice currentDevice] iPhone5X]) {
        return UIInterfaceOrientationMaskPortrait | UIInterfaceOrientationMaskPortraitUpsideDown;
    }
    
    return UIInterfaceOrientationMaskAll;
}

#pragma mark - IBActions

- (IBAction)cancelTouchUpInside:(UIButton *)sender {
    [self dismissViewControllerAnimated:YES completion:nil];
}

@end
