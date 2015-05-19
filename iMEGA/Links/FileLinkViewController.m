/**
 * @file FileLinkViewController.m
 * @brief View controller that allows to see and manage MEGA file links.
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

#import "SVProgressHUD.h"
#import "SSKeychain.h"

#import "MEGASdkManager.h"
#import "Helper.h"

#import "LoginViewController.h"
#import "MainTabBarController.h"
#import "FileLinkViewController.h"
#import "BrowserViewController.h"
#import "UnavailableLinkView.h"
#import "OfflineTableViewController.h"

@interface FileLinkViewController () <MEGADelegate, MEGARequestDelegate, MEGATransferDelegate>

@property (strong, nonatomic) MEGANode *node;

@property (weak, nonatomic) IBOutlet UIBarButtonItem *cancelBarButtonItem;

@property (weak, nonatomic) IBOutlet UILabel *nameLabel;
@property (weak, nonatomic) IBOutlet UILabel *sizeLabel;

@property (weak, nonatomic) IBOutlet UIImageView *thumbnailImageView;

@property (weak, nonatomic) IBOutlet UIButton *importButton;
@property (weak, nonatomic) IBOutlet UIButton *downloadButton;

@end

@implementation FileLinkViewController

#pragma mark - Lifecycle

- (void)viewDidLoad {
    [super viewDidLoad];
    
    [self.navigationItem setLeftBarButtonItem:self.cancelBarButtonItem];
    
    [self setEdgesForExtendedLayout:UIRectEdgeNone];
    
    [self.navigationItem setTitle:NSLocalizedString(@"megaLink", nil)];
    [[UIApplication sharedApplication] setStatusBarStyle:UIStatusBarStyleLightContent animated:NO];
    
    [self setUIItemsEnabled:NO];
    
    self.importButton.layer.cornerRadius = 6;
    self.importButton.layer.masksToBounds = YES;
    [self.importButton setTitle:NSLocalizedString(@"importButton", nil) forState:UIControlStateNormal];
    
    self.downloadButton.layer.cornerRadius = 6;
    self.downloadButton.layer.masksToBounds = YES;
    [self.downloadButton setTitle:NSLocalizedString(@"downloadButton", nil) forState:UIControlStateNormal];
    
    [[MEGASdkManager sharedMEGASdk] publicNodeForMegaFileLink:self.fileLinkString delegate:self];
}

#pragma mark - Private
- (void)setUIItemsEnabled:(BOOL)boolValue {
    [self.nameLabel setHidden:!boolValue];
    [self.sizeLabel setHidden:!boolValue];
    
    [self.thumbnailImageView setHidden:!boolValue];
    
    [self.importButton setEnabled:boolValue];
    [self.downloadButton setEnabled:boolValue];
}

- (void)showUnavailableLinkView {
    [self setUIItemsEnabled:NO];
    
    UnavailableLinkView *unavailableLinkView = [[[NSBundle mainBundle] loadNibNamed:@"UnavailableLinkView" owner:self options: nil] firstObject];
    [unavailableLinkView setFrame:self.view.bounds];
    [unavailableLinkView.imageView setImage:[UIImage imageNamed:@"emptyCloud"]];
    [unavailableLinkView.titleLabel setText:NSLocalizedString(@"fileLinkUnavailableTitle", nil)];
    [unavailableLinkView.textView setText:NSLocalizedString(@"fileLinkUnavailableText", nil)];
    [unavailableLinkView.textView setFont:[UIFont systemFontOfSize:14.0]];
    [unavailableLinkView.textView setTextColor:[UIColor darkGrayColor]];
    
    [self.view addSubview:unavailableLinkView];
}

#pragma mark - IBActions

- (IBAction)cancelTouchUpInside:(UIBarButtonItem *)sender {
    [Helper setLinkNode:nil];
    [Helper setSelectedOptionOnLink:0];
    
    UIStoryboard* storyboard = [UIStoryboard storyboardWithName:@"Main" bundle:nil];
    if ([SSKeychain passwordForService:@"MEGA" account:@"session"]) {
        MainTabBarController *mainTBC = [storyboard instantiateViewControllerWithIdentifier:@"TabBarControllerID"];
        [[[[UIApplication sharedApplication] delegate] window] setRootViewController:mainTBC];
    } else {
        UIViewController *viewController = [storyboard instantiateViewControllerWithIdentifier:@"initialViewControllerID"];
        [[[[UIApplication sharedApplication] delegate] window] setRootViewController:viewController];
    }
}

- (IBAction)importTouchUpInside:(UIButton *)sender {
    UIStoryboard *storyboard = [UIStoryboard storyboardWithName:@"Main" bundle:nil];
    if ([SSKeychain passwordForService:@"MEGA" account:@"session"]) {
        MainTabBarController *mainTBC = [storyboard instantiateViewControllerWithIdentifier:@"TabBarControllerID"];
        
        [[[[UIApplication sharedApplication] delegate] window] setRootViewController:mainTBC];
        
        if ([self.node type] == MEGANodeTypeFile) {
            UIStoryboard *cloudStoryboard = [UIStoryboard storyboardWithName:@"Cloud" bundle:nil];
            UINavigationController *navigationController = [cloudStoryboard instantiateViewControllerWithIdentifier:@"moveNodeNav"];
            [[[[[UIApplication sharedApplication] delegate] window] rootViewController] presentViewController:navigationController animated:YES completion:nil];
            
            BrowserViewController *moveCopyNodeVC = navigationController.viewControllers.firstObject;
            moveCopyNodeVC.parentNode = [[MEGASdkManager sharedMEGASdk] rootNode];
            moveCopyNodeVC.selectedNodesArray = [NSArray arrayWithObject:self.node];
            
            [moveCopyNodeVC setIsPublicNode:YES];
        }
    } else {
        LoginViewController *loginVC = [storyboard instantiateViewControllerWithIdentifier:@"LoginViewControllerID"];
        
        [Helper setLinkNode:self.node];
        [Helper setSelectedOptionOnLink:[(UIButton *)sender tag]];
        
        [self.navigationController pushViewController:loginVC animated:YES];
    }
}

- (IBAction)downloadTouchUpInside:(UIButton *)sender {
    
    if (![Helper isFreeSpaceEnoughToDownloadNode:self.node]) {
        return;
    }
    
    if ([SSKeychain passwordForService:@"MEGA" account:@"session"]) {
        
        UIStoryboard *storyboard = [UIStoryboard storyboardWithName:@"Main" bundle:nil];
        MainTabBarController *mainTBC = [storyboard instantiateViewControllerWithIdentifier:@"TabBarControllerID"];
        
        [[[[UIApplication sharedApplication] delegate] window] setRootViewController:mainTBC];
        [Helper changeToViewController:[OfflineTableViewController class] onTabBarController:self.tabBarController];
        
        if ([self.node type] == MEGANodeTypeFile) {
            [Helper downloadNode:self.node folder:@"" folderLink:NO];
        }
        
    } else {
        UIStoryboard* storyboard = [UIStoryboard storyboardWithName:@"Main" bundle:nil];
        LoginViewController *loginVC = [storyboard instantiateViewControllerWithIdentifier:@"LoginViewControllerID"];
        
        [Helper setLinkNode:self.node];
        [Helper setSelectedOptionOnLink:[(UIButton *)sender tag]];
        
        [self.navigationController pushViewController:loginVC animated:YES];
    }
}

#pragma mark - MEGARequestDelegate

- (void)onRequestStart:(MEGASdk *)api request:(MEGARequest *)request {
}

- (void)onRequestFinish:(MEGASdk *)api request:(MEGARequest *)request error:(MEGAError *)error {
    
    if ([error type]) {
        if ([error type] == MEGAErrorTypeApiENoent) {
            if ([request type] == MEGARequestTypeGetPublicNode) {
                [self showUnavailableLinkView];
            }
        }
        return;
    }
    
    switch ([request type]) {
            
        case MEGARequestTypeGetPublicNode: {
            self.node = [request publicNode];
            NSString *name = [self.node name];
            
            [self.nameLabel setText:name];
            
            NSString *sizeString = [NSByteCountFormatter stringFromByteCount:[[self.node size] longLongValue] countStyle:NSByteCountFormatterCountStyleMemory];
            [self.sizeLabel setText:sizeString];
            
            NSString *fileTypeIconString = [Helper fileTypeIconForExtension:[name.pathExtension lowercaseString]];
            UIImage *image = [UIImage imageNamed:fileTypeIconString];
            [self.thumbnailImageView setImage:image];
            
            [self setUIItemsEnabled:YES];
            break;
        }
      
        default:
            break;
    }
}

- (void)onRequestUpdate:(MEGASdk *)api request:(MEGARequest *)request {
}

- (void)onRequestTemporaryError:(MEGASdk *)api request:(MEGARequest *)request error:(MEGAError *)error {
}

@end
