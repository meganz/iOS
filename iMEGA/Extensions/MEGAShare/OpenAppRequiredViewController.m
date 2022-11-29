
#import "OpenAppRequiredViewController.h"
#import "UIViewController+MNZCategory.h"

#import "MEGAShare-Swift.h"

@interface OpenAppRequiredViewController ()

@property (weak, nonatomic) IBOutlet UILabel *descriptionLabel;
@property (weak, nonatomic) IBOutlet UIButton *openButton;

@end

@implementation OpenAppRequiredViewController

#pragma mark - Lifecycle

- (void)viewDidLoad {
    [super viewDidLoad];
    
    if (self.isLoginRequired) {
        self.descriptionLabel.text = NSLocalizedString(@"openMEGAAndSignInToContinue", @"Text shown when you try to use a MEGA extension in iOS and you aren't logged");
    } else {
        self.descriptionLabel.text = NSLocalizedString(@"extensions.OpenApp.Message", nil);
    }
    
    [self.openButton setTitle:NSLocalizedString(@"openButton", @"Button title to trigger the action of opening the file without downloading or opening it.") forState:UIControlStateNormal];
}

- (void)traitCollectionDidChange:(UITraitCollection *)previousTraitCollection {
    [super traitCollectionDidChange:previousTraitCollection];
    
    if ([self.traitCollection hasDifferentColorAppearanceComparedToTraitCollection:previousTraitCollection]) {
        [ExtensionAppearanceManager setupAppearance:self.traitCollection];
        [ExtensionAppearanceManager forceNavigationBarUpdate:self.navigationController.navigationBar traitCollection:self.traitCollection];
        
        [self updateAppearance];
    }
}

#pragma mark - Private

- (void)updateAppearance {
    self.view.backgroundColor = [UIColor mnz_backgroundElevated:self.traitCollection];
    
    [self.openButton mnz_setupPrimary:self.traitCollection];
}

#pragma mark - IBActions

- (IBAction)openMegaTouchUpInside:(id)sender {
    if (self.isLoginRequired) {
        [self openURL:[NSURL URLWithString:@"mega://#loginrequired"]];
    } else {
        [self openURL:[NSURL URLWithString:@"mega://"]];
    }
}

- (IBAction)cancel:(UIBarButtonItem *)sender {
    if (self.cancelCompletion) {
        self.cancelCompletion();
    }
}

@end
