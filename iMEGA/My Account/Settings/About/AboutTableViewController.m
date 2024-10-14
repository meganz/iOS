#import "AboutTableViewController.h"

#import "Helper.h"
#import "MEGA-Swift.h"
#import "NSURL+MNZCategory.h"

@import MEGAL10nObjc;

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
    
    self.versionLabel.text = LocalizedString(@"App Version", @"App means “Application”");
    self.versionNumberLabel.text = [NSString stringWithFormat:@"%@ (%@)",
                                    [NSBundle.mainBundle objectForInfoDictionaryKey:@"CFBundleShortVersionString"],
                                    [NSBundle.mainBundle objectForInfoDictionaryKey:(NSString *)kCFBundleVersionKey]];
    UITapGestureRecognizer *tapGestureRecognizer = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(appVersionTappedFiveTimes:)];
    tapGestureRecognizer.numberOfTapsRequired = 5;
    UILongPressGestureRecognizer *longPressGestureRecognizer = [[UILongPressGestureRecognizer alloc] initWithTarget:self action:@selector(appVersionPressedFiveSeconds:)];
    longPressGestureRecognizer.minimumPressDuration = 5.0f;
    self.versionCell.gestureRecognizers = @[tapGestureRecognizer, longPressGestureRecognizer];
    
    self.sdkVersionLabel.text = LocalizedString(@"sdkVersion", @"Title of the label where the SDK version is shown");
    
    self.sdkVersionSHALabel.text = NSBundle.mainBundle.infoDictionary[@"SDK_GIT_COMMIT_HASH"];
    
    self.megachatSdkVersionLabel.text = LocalizedString(@"megachatSdkVersion", @"Title of the label where the MEGAchat SDK version is shown");
    self.megachatSdkSHALabel.text = NSBundle.mainBundle.infoDictionary[@"CHAT_SDK_GIT_COMMIT_HASH"];
    
    self.viewSourceCodeLabel.text = LocalizedString(@"View Source Code", @"Link to the public code of the ap");
    
    [self.acknowledgementsLabel setText:LocalizedString(@"acknowledgements", @"")];
    
    [self setupColors];
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    
    [self.navigationItem setTitle:LocalizedString(@"about", @"")];
    
}

#pragma mark - Private

- (void)setupColors {
    self.tableView.separatorColor = [UIColor mnz_separator];
    self.tableView.backgroundColor = [UIColor pageBackgroundColor];
    
    self.versionNumberLabel.textColor = self.sdkVersionSHALabel.textColor = self.megachatSdkSHALabel.textColor = UIColor.secondaryLabelColor;
}

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

#pragma mark - TableView Datasource and Delegate

- (void)tableView:(UITableView *)tableView willDisplayCell:(UITableViewCell *)cell forRowAtIndexPath:(NSIndexPath *)indexPath {
    cell.backgroundColor = [UIColor pageBackgroundColor];
}

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
