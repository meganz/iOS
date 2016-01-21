/**
 * @file AboutTableViewController.m
 * @brief View controller that show info about us
 *
 * (c) 2013-2015 by Mega Limited, Auckland, New Zealand
 *
 * This file is part of the MEGA SDK - Client Access Engine.
 *
 * Applications using the MEGA API must present a valid application key
 * and comply with the the rules set forth in the Terms of Service.
 *
 * The MEGA SDK is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.
 *
 * @copyright Simplified (2-clause) BSD License.
 *
 * You should have received a copy of the license along with this
 * program.
 */

#import "AboutTableViewController.h"
#import "MEGASdkManager.h"
#import "MEGAReachabilityManager.h"
#import "SVProgressHUD.h"
#import "SVWebViewController.h"

@interface AboutTableViewController () <UIGestureRecognizerDelegate> {
    int megaSdkVersionCounter;
    int versionCounter;
}

@property (weak, nonatomic) IBOutlet UILabel *versionLabel;
@property (weak, nonatomic) IBOutlet UILabel *versionNumberLabel;
@property (weak, nonatomic) IBOutlet UILabel *sdkVersionLabel;
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
    [self.sdkVersionLabel setText:[NSString stringWithFormat:@"MEGA SDK %@", AMLocalizedString(@"version", nil)]];
    [self.acknowledgementsLabel setText:AMLocalizedString(@"acknowledgements", nil)];
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    
    [self.navigationItem setTitle:AMLocalizedString(@"about", nil)];
    
    megaSdkVersionCounter = 0;
    versionCounter = 0;
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (UIInterfaceOrientationMask)supportedInterfaceOrientations {
    return UIInterfaceOrientationMaskPortrait;
}

- (UIInterfaceOrientation)preferredInterfaceOrientationForPresentation {
    return UIInterfaceOrientationPortrait;
}

#pragma mark - Private

- (void)acknowledgements {
    if ([MEGAReachabilityManager isReachable]) {
        NSURL *URL = [NSURL URLWithString:@"https://mega.nz/ios_acknowledgements.html"];
        SVWebViewController *webViewController = [[SVWebViewController alloc] initWithURL:URL];
        [self.navigationController pushViewController:webViewController animated:YES];
    } else {
        [SVProgressHUD showImage:[UIImage imageNamed:@"hudForbidden"] status:AMLocalizedString(@"noInternetConnection", nil)];
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
            if ([indexPath row] == 0) {
                megaSdkVersionCounter = 0;
                versionCounter++;
                if (versionCounter == 5) {
                    versionCounter = 0;
                    UIAlertView *disableLogsAlertView = [[UIAlertView alloc] initWithTitle:AMLocalizedString(@"disableDebugMode_title", nil)
                                                                                   message:AMLocalizedString(@"disableDebugMode_message", nil)
                                                                                  delegate:self
                                                                         cancelButtonTitle:AMLocalizedString(@"cancel", nil)
                                                                         otherButtonTitles:AMLocalizedString(@"ok", nil), nil];
                    disableLogsAlertView.tag = 0;
                    [disableLogsAlertView show];
                }
                return;
            } else if ([indexPath row] == 1) {
                versionCounter = 0;
                megaSdkVersionCounter++;
                if (megaSdkVersionCounter == 5) {
                    megaSdkVersionCounter = 0;
                    
                    UIAlertView *enableLogsAlertView = [[UIAlertView alloc] initWithTitle:AMLocalizedString(@"enableDebugMode_title", nil)
                                                                                  message:AMLocalizedString(@"enableDebugMode_message", nil)
                                                                                 delegate:self
                                                                        cancelButtonTitle:AMLocalizedString(@"cancel", nil)
                                                                        otherButtonTitles:AMLocalizedString(@"ok", nil), nil];
                    enableLogsAlertView.tag = 1;
                    [enableLogsAlertView show];
                }
                return;
            }
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

#pragma mark - UIAlertViewDelegate

- (void)alertView:(UIAlertView *)alertView clickedButtonAtIndex:(NSInteger)buttonIndex {
    if (buttonIndex == 1) {
        NSString *logPath = [[NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES) objectAtIndex:0] stringByAppendingPathComponent:@"MEGAiOS.log"];
        if (alertView.tag == 0) {
            [MEGASdk setLogLevel:MEGALogLevelFatal];
            
            if ([[NSFileManager defaultManager] fileExistsAtPath:logPath]) {
                [[NSFileManager defaultManager] removeItemAtPath:logPath error:nil];
            }
            
            [[NSUserDefaults standardUserDefaults] setBool:NO forKey:@"logging"];
            [[NSUserDefaults standardUserDefaults] synchronize];
        } else {
            [MEGASdk setLogLevel:MEGALogLevelDebug];
            
            freopen([logPath cStringUsingEncoding:NSASCIIStringEncoding],"a+",stderr);
            
            [[NSUserDefaults standardUserDefaults] setBool:YES forKey:@"logging"];
            [[NSUserDefaults standardUserDefaults] synchronize];
        }
    }
    
    versionCounter = 0;
    megaSdkVersionCounter = 0;
}

@end
