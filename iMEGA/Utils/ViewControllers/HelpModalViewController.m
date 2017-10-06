
#import "HelpModalViewController.h"

#import "UIViewController+MNZCategory.h"

@interface HelpModalViewController ()

@property (weak, nonatomic) IBOutlet UILabel *titleLabel;
@property (weak, nonatomic) IBOutlet UILabel *firstParagraphLabel;
@property (weak, nonatomic) IBOutlet UILabel *secondParagraphLabel;
@property (weak, nonatomic) IBOutlet UILabel *thirdParagraphLabel;

@end

@implementation HelpModalViewController

#pragma mark - Lifecycle

- (void)viewDidLoad {
    [super viewDidLoad];
    
    self.titleLabel.text = self.viewTitle;
    self.firstParagraphLabel.text = self.firstParagraph;
    self.secondParagraphLabel.text = self.secondParagraph;
    self.thirdParagraphLabel.text = self.thirdParagraph;
        
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
