#import "AboutTableViewController.h"

#import "SVProgressHUD.h"
#import "SVWebViewController.h"

#import "Helper.h"
#import "MEGALogger.h"
#import "MEGAReachabilityManager.h"
#import "MEGASdkManager.h"

@interface AboutTableViewController ()

@property (weak, nonatomic) IBOutlet UILabel *versionLabel;
@property (weak, nonatomic) IBOutlet UILabel *versionNumberLabel;
@property (weak, nonatomic) IBOutlet UILabel *sdkVersionLabel;
@property (weak, nonatomic) IBOutlet UILabel *sdkVersionSHALabel;
@property (weak, nonatomic) IBOutlet UILabel *acknowledgementsLabel;

@property (weak, nonatomic) IBOutlet UITableViewCell *versionCell;

@property (weak, nonatomic) IBOutlet UIView *debugView;

@end

@implementation AboutTableViewController

#pragma mark - Lifecycle

- (void)viewDidLoad {
    [super viewDidLoad];
    
    [self.versionLabel setText:AMLocalizedString(@"version", nil)];
    [self.versionNumberLabel setText:[[NSBundle mainBundle] objectForInfoDictionaryKey:@"CFBundleShortVersionString"]];
    UITapGestureRecognizer *tapGestureRecognizer = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(logoTappedFiveTimes:)];
    tapGestureRecognizer.numberOfTapsRequired = 5;
    self.versionCell.gestureRecognizers = @[tapGestureRecognizer];
    
    [self.sdkVersionLabel setText:[NSString stringWithFormat:@"MEGA SDK %@", AMLocalizedString(@"version", nil)]];
    self.sdkVersionSHALabel.text = @"5d53663";
    
    [self.acknowledgementsLabel setText:AMLocalizedString(@"acknowledgements", nil)];
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    
    [self.navigationItem setTitle:AMLocalizedString(@"about", nil)];
    
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (UIInterfaceOrientationMask)supportedInterfaceOrientations {
    return UIInterfaceOrientationMaskAll;
}

#pragma mark - Private

- (void)logoTappedFiveTimes:(UITapGestureRecognizer *)sender {
    if (sender.state == UIGestureRecognizerStateEnded) {
        BOOL enableLogging = ![[NSUserDefaults standardUserDefaults] boolForKey:@"logging"];
        UIAlertView *logAlertView = [Helper logAlertView:enableLogging];
        logAlertView.delegate = self;
        [logAlertView show];
    }
}

- (void)acknowledgements {
    if ([MEGAReachabilityManager isReachableHUDIfNot]) {
        NSURL *URL = [NSURL URLWithString:@"https://mega.nz/ios_acknowledgements.html"];
        SVWebViewController *webViewController = [[SVWebViewController alloc] initWithURL:URL];
        [self.navigationController pushViewController:webViewController animated:YES];
    }
}

#pragma mark - UIAlertViewDelegate

- (void)alertView:(UIAlertView *)alertView clickedButtonAtIndex:(NSInteger)buttonIndex {
    if (buttonIndex == 1) {
        (alertView.tag == 0) ? [[MEGALogger sharedLogger] stopLogging] : [[MEGALogger sharedLogger] startLogging];
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
            numberOfRows = 2;
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
