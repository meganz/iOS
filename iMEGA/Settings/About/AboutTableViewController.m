
#import "AboutTableViewController.h"

#import "Helper.h"
#import "NSURL+MNZCategory.h"

@interface AboutTableViewController ()

@property (weak, nonatomic) IBOutlet UILabel *versionLabel;
@property (weak, nonatomic) IBOutlet UILabel *versionNumberLabel;
@property (weak, nonatomic) IBOutlet UILabel *sdkVersionLabel;
@property (weak, nonatomic) IBOutlet UILabel *sdkVersionSHALabel;
@property (weak, nonatomic) IBOutlet UILabel *megachatSdkVersionLabel;
@property (weak, nonatomic) IBOutlet UILabel *megachatSdkSHALabel;
@property (weak, nonatomic) IBOutlet UILabel *acknowledgementsLabel;
@property (weak, nonatomic) IBOutlet UILabel *viewSourceCodeLabel;

@property (weak, nonatomic) IBOutlet UITableViewCell *versionCell;

@end

@implementation AboutTableViewController

#pragma mark - Lifecycle

- (void)viewDidLoad {
    [super viewDidLoad];
    
    self.versionLabel.text = AMLocalizedString(@"App version", @"App means “Application”");
    self.versionNumberLabel.text = [NSString stringWithFormat:@"%@ (%@)",
                                    [NSBundle.mainBundle objectForInfoDictionaryKey:@"CFBundleShortVersionString"],
                                    [NSBundle.mainBundle objectForInfoDictionaryKey:(NSString *)kCFBundleVersionKey]];
    UITapGestureRecognizer *tapGestureRecognizer = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(appVersionTappedFiveTimes:)];
    tapGestureRecognizer.numberOfTapsRequired = 5;
    UILongPressGestureRecognizer *longPressGestureRecognizer = [[UILongPressGestureRecognizer alloc] initWithTarget:self action:@selector(appVersionPressedFiveSeconds:)];
    longPressGestureRecognizer.minimumPressDuration = 5.0f;
    self.versionCell.gestureRecognizers = @[tapGestureRecognizer, longPressGestureRecognizer];
    
    self.sdkVersionLabel.text = AMLocalizedString(@"sdkVersion", @"Title of the label where the SDK version is shown");
    self.sdkVersionSHALabel.text = @"29bebb21";
    
    self.megachatSdkVersionLabel.text = AMLocalizedString(@"megachatSdkVersion", @"Title of the label where the MEGAchat SDK version is shown");
    self.megachatSdkSHALabel.text = @"5bc31c1a";
    
    self.viewSourceCodeLabel.text = AMLocalizedString(@"View source code", @"Link to the public code of the ap");
    
    [self.acknowledgementsLabel setText:AMLocalizedString(@"acknowledgements", nil)];
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    
    [self.navigationItem setTitle:AMLocalizedString(@"about", nil)];
    
}

- (UIInterfaceOrientationMask)supportedInterfaceOrientations {
    return UIInterfaceOrientationMaskAll;
}

#pragma mark - Private

- (void)appVersionTappedFiveTimes:(UITapGestureRecognizer *)sender {
    if (sender.state == UIGestureRecognizerStateEnded) {
        [Helper enableOrDisableLog];
    }
}

- (void)appVersionPressedFiveSeconds:(UITapGestureRecognizer *)sender {
    if (sender.state == UIGestureRecognizerStateBegan) {
        [Helper changeApiURL];
    }
}

#pragma mark - UITableViewDelegate

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    switch (indexPath.section) {
        case 0: {
            break;
        }
            
        case 1: {
            if (indexPath.row == 0) { //View source code
                [[NSURL URLWithString:@"https://github.com/meganz/iOS"] mnz_presentSafariViewController];
            } else if (indexPath.row == 1) { //Acknowledgements
                [[NSURL URLWithString:@"https://github.com/meganz/iOS3/blob/master/CREDITS.md"] mnz_presentSafariViewController];
            }
            break;
        }
    }
}

@end
