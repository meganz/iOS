/**
 * @file PrivacyPolicyViewController.m
 * @brief View controller that allows to see the privacy policy of MEGA
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

#import "PrivacyPolicyViewController.h"
#import "SVProgressHUD.h"

@interface PrivacyPolicyViewController ()

@property (strong, nonatomic) IBOutlet UIWebView *webView;
@end

@implementation PrivacyPolicyViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    [self.navigationItem setTitle:NSLocalizedString(@"privacyPolicyLabel", nil)];
    
    [self.navigationController.navigationBar.topItem setTitle:@""];
    
    NSURL *url = [NSURL URLWithString:@"https://mega.co.nz/ios_privacy.html"];
    NSURLRequest *urlRequest = [NSURLRequest requestWithURL:url];
    
    [self.webView loadRequest:urlRequest];
}

#pragma mark - UIWebViewDelegate

- (void)webViewDidStartLoad:(UIWebView *)webView {
    [SVProgressHUD show];
}

- (void)webViewDidFinishLoad:(UIWebView *)webView {
    [SVProgressHUD dismiss];
}

- (void)webView:(UIWebView *)webView didFailLoadWithError:(NSError *)error {
    [SVProgressHUD showErrorWithStatus:NSLocalizedString(@"errorLoadingPrivacyPolicyWeb", @"The MEGA privacy policy web fail at loading.")];
}

@end
