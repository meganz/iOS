
#import "AboutTableViewController.h"

#import "SVProgressHUD.h"

#import "Helper.h"
#import "MEGAReachabilityManager.h"
#import "MEGASdkManager.h"

@interface AboutTableViewController ()

@property (weak, nonatomic) IBOutlet UILabel *versionLabel;
@property (weak, nonatomic) IBOutlet UILabel *versionNumberLabel;
@property (weak, nonatomic) IBOutlet UILabel *sdkVersionLabel;
@property (weak, nonatomic) IBOutlet UILabel *sdkVersionSHALabel;
@property (weak, nonatomic) IBOutlet UILabel *megachatSdkVersionLabel;
@property (weak, nonatomic) IBOutlet UILabel *megachatSdkSHALabel;
@property (weak, nonatomic) IBOutlet UILabel *acknowledgementsLabel;

@property (weak, nonatomic) IBOutlet UITableViewCell *versionCell;

@property (weak, nonatomic) IBOutlet UIView *debugView;

@end

@implementation AboutTableViewController

#pragma mark - Lifecycle

- (void)viewDidLoad {
    [super viewDidLoad];
    
    self.versionLabel.text = AMLocalizedString(@"App version", @"App means “Application”");
    [self.versionNumberLabel setText:[[NSBundle mainBundle] objectForInfoDictionaryKey:@"CFBundleShortVersionString"]];
    UITapGestureRecognizer *tapGestureRecognizer = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(appVersionTappedFiveTimes:)];
    tapGestureRecognizer.numberOfTapsRequired = 5;
    UILongPressGestureRecognizer *longPressGestureRecognizer = [[UILongPressGestureRecognizer alloc] initWithTarget:self action:@selector(appVersionPressedFiveSeconds:)];
    longPressGestureRecognizer.minimumPressDuration = 5.0f;
    self.versionCell.gestureRecognizers = @[tapGestureRecognizer, longPressGestureRecognizer];
    
    self.sdkVersionLabel.text = AMLocalizedString(@"sdkVersion", @"Title of the label where the SDK version is shown");
    self.sdkVersionSHALabel.text = @"df9a6947";
    
    self.megachatSdkVersionLabel.text = AMLocalizedString(@"megachatSdkVersion", @"Title of the label where the MEGAchat SDK version is shown");
    self.megachatSdkSHALabel.text = @"903f3d3b";
    
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

- (void)acknowledgements {
    if ([MEGAReachabilityManager isReachableHUDIfNot]) {
        [Helper presentSafariViewControllerWithURL:[NSURL URLWithString:@"https://github.com/meganz/iOS3/blob/master/CREDITS.md"]];
    }
}

#pragma mark - UITableViewDataSource

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return 2;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    NSInteger numberOfRows = 0;
    switch (section) {
        case 0:
            numberOfRows = 3;
            break;
            
        case 1:
            numberOfRows = 1;
            break;
    }
    return numberOfRows;
}

#pragma mark - UITableViewDelegate

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {

    switch (indexPath.section) {
        case 0: {
            break;
        }
            
        case 1: {
            if ([indexPath row] == 0) {
                [self acknowledgements];
            }
            break;
        }
    }
}

@end
