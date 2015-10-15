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
    
    UILongPressGestureRecognizer *lpgr = [[UILongPressGestureRecognizer alloc]
                                          initWithTarget:self action:@selector(handleLongPress:)];
    lpgr.minimumPressDuration = 5.0;
    lpgr.delegate = self;
    [self.versionCell addGestureRecognizer:lpgr];
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

- (NSUInteger)supportedInterfaceOrientations {
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

- (void)handleLongPress:(UILongPressGestureRecognizer *)gestureRecognizer {
    if (gestureRecognizer.state == UIGestureRecognizerStateBegan) {
        UIAlertView *alertView = [[UIAlertView alloc] initWithTitle:@"Switching api server" message:@"Enter the API_URL (DEBUG /!\\)" delegate:self cancelButtonTitle:@"Cancel" otherButtonTitles:@"Ok", nil];
        [alertView setAlertViewStyle:UIAlertViewStylePlainTextInput];
        [alertView textFieldAtIndex:0].text = @"";
        alertView.tag = 2;
        [alertView show];
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
                    UIAlertView *gApiAlertView = [[UIAlertView alloc] initWithTitle:@"Switching api server" message:@"Do you want switch to 'https://g.api.mega.co.nz/'?" delegate:self cancelButtonTitle:@"Cancel" otherButtonTitles:@"Ok", nil];
                    gApiAlertView.tag = 0;
                    [gApiAlertView show];
                }
                return;
            } else if ([indexPath row] == 1) {
                versionCounter = 0;
                megaSdkVersionCounter++;
                if (megaSdkVersionCounter == 5) {
                    megaSdkVersionCounter = 0;
                    
                    UIAlertView *stagingApiAlertView = [[UIAlertView alloc] initWithTitle:@"Switching api server" message:@"Do you want switch to 'https://staging.api.mega.co.nz/'?" delegate:self cancelButtonTitle:@"Cancel" otherButtonTitles:@"Ok", nil];
                    stagingApiAlertView.tag = 1;
                    [stagingApiAlertView show];
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
        if (alertView.tag == 0) {
            [[MEGASdkManager sharedMEGASdk] changeApiUrl:@"https://g.api.mega.co.nz/" disablepkp:NO];
            for (UIView *view in [[[[UIApplication sharedApplication] delegate] window] subviews]) {
                // Remove all overlapping views in the status bar
                if (view.tag == 1) {
                    [view removeFromSuperview];
                }
            }
        } else if (alertView.tag == 1) {
            [[MEGASdkManager sharedMEGASdk] changeApiUrl:@"https://staging.api.mega.co.nz/" disablepkp:NO];
            [self.debugView setBackgroundColor:[UIColor yellowColor]];
            [[[[UIApplication sharedApplication] delegate] window] addSubview:self.debugView];
        } else {
            [self.debugView setBackgroundColor:[UIColor orangeColor]];
            [[[[UIApplication sharedApplication] delegate] window] addSubview:self.debugView];
            [[MEGASdkManager sharedMEGASdk] changeApiUrl:[[alertView textFieldAtIndex:0] text] disablepkp:YES];
        }
    }
    
    versionCounter = 0;
    megaSdkVersionCounter = 0;
}

@end
