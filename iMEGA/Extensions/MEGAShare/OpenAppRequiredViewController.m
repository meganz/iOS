#import "OpenAppRequiredViewController.h"
#import "UIViewController+MNZCategory.h"

#import "MEGAShare-Swift.h"

@import MEGAL10nObjc;

@interface OpenAppRequiredViewController ()

@property (weak, nonatomic) IBOutlet UILabel *descriptionLabel;
@property (weak, nonatomic) IBOutlet UIButton *openButton;

@end

@implementation OpenAppRequiredViewController

#pragma mark - Lifecycle

- (void)viewDidLoad {
    [super viewDidLoad];
    
    self.descriptionLabel.text = LocalizedString(@"openMEGAAndSignInToContinue", @"Text shown when you try to use a MEGA extension in iOS and you aren't logged");
    
    [self.openButton setTitle:LocalizedString(@"openButton", @"Button title to trigger the action of opening the file without downloading or opening it.") forState:UIControlStateNormal];
}

- (void)traitCollectionDidChange:(UITraitCollection *)previousTraitCollection {
    [super traitCollectionDidChange:previousTraitCollection];
    
    if ([self.traitCollection hasDifferentColorAppearanceComparedToTraitCollection:previousTraitCollection]) {
        [AppearanceManager setupAppearance:self.traitCollection];
        [AppearanceManager forceNavigationBarUpdate:self.navigationController.navigationBar traitCollection:self.traitCollection];
        
        [self updateAppearance];
    }
}

#pragma mark - Private

- (void)updateAppearance {
    self.view.backgroundColor = [UIColor pageBackgroundColor];
    
    [self.openButton mnz_setupPrimary];
}

#pragma mark - IBActions

- (IBAction)openMegaTouchUpInside:(id)sender {
    [self openURL:[NSURL URLWithString:@"mega://#loginrequired"]];
}

- (IBAction)cancel:(UIBarButtonItem *)sender {
    if (self.cancelCompletion) {
        self.cancelCompletion();
    }
}

@end
