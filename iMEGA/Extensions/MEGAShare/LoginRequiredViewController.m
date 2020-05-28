
#import "LoginRequiredViewController.h"

#import "MEGAShare-Swift.h"

@interface LoginRequiredViewController ()

@property (weak, nonatomic) IBOutlet UILabel *loginLabel;
@property (weak, nonatomic) IBOutlet UIButton *openButton;

@end

@implementation LoginRequiredViewController

#pragma mark - Lifecycle

- (void)viewDidLoad {
    [super viewDidLoad];
    
    self.loginLabel.text = AMLocalizedString(@"openMEGAAndSignInToContinue", @"Text shown when you try to use a MEGA extension in iOS and you aren't logged");
    
    [self.openButton setTitle:AMLocalizedString(@"openButton", @"Button title to trigger the action of opening the file without downloading or opening it.") forState:UIControlStateNormal];
}

- (void)traitCollectionDidChange:(UITraitCollection *)previousTraitCollection {
    [super traitCollectionDidChange:previousTraitCollection];
    
    if (@available(iOS 13.0, *)) {
        if ([self.traitCollection hasDifferentColorAppearanceComparedToTraitCollection:previousTraitCollection]) {
            [ExtensionAppearanceManager setupAppearance:self.traitCollection];
            [ExtensionAppearanceManager forceNavigationBarUpdate:self.navigationController.navigationBar traitCollection:self.traitCollection];
            
            [self updateAppearance];
        }
    }
}

#pragma mark - Private

- (void)updateAppearance {
    self.view.backgroundColor = UIColor.mnz_background;
    
    [self.openButton mnz_setupPrimary:self.traitCollection];
}

#pragma mark - IBActions

- (IBAction)openMegaTouchUpInside:(id)sender {
    [UIApplication.sharedApplication openURL:[NSURL URLWithString:@"mega://#loginrequired"] options:@{} completionHandler:nil];
}

- (IBAction)cancel:(UIBarButtonItem *)sender {
    if (self.cancelCompletion) {
        self.cancelCompletion();
    }
}

@end
