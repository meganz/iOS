/**
 * @file SettingsTableViewController.m
 * @brief View controller that show your settings
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

#import "SettingsTableViewController.h"
#import "Helper.h"
#import "SVProgressHUD.h"
#import "FeedbackTableViewController.h"
#import "MEGASdkManager.h"
#import "UIImage+GKContact.h"
#import "PieChartView.h"
#import "UpgradeTableViewController.h"

@interface SettingsTableViewController () <UIActionSheetDelegate>

@property (weak, nonatomic) IBOutlet UILabel *cameraUploadsLabel;
@property (weak, nonatomic) IBOutlet UILabel *passcodeLabel;
@property (weak, nonatomic) IBOutlet UILabel *applicationLanguageLabel;
@property (weak, nonatomic) IBOutlet UILabel *aboutLabel;
@property (weak, nonatomic) IBOutlet UILabel *feedbackLabel;
@property (weak, nonatomic) IBOutlet UILabel *advancedLabel;

@property (nonatomic, strong) MEGAPricing *pricing;
@property (nonatomic) MEGAAccountType megaAccountType;

@end

@implementation SettingsTableViewController

#pragma mark - Lifecycle

- (void)viewDidLoad {
    [super viewDidLoad];
    
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    
    [self.navigationItem setTitle:AMLocalizedString(@"settingsTitle", @"Settings")];
    
    [self.cameraUploadsLabel setText:AMLocalizedString(@"cameraUploadsLabel", nil)];
    [self.passcodeLabel setText:AMLocalizedString(@"passcode", nil)];
    [self.applicationLanguageLabel setText:AMLocalizedString(@"applicationLanguageLabel", @"Application language")];
    [self.aboutLabel setText:AMLocalizedString(@"aboutLabel", nil)];
    [self.feedbackLabel setText:AMLocalizedString(@"feedbackLabel", nil)];
    [self.advancedLabel setText:AMLocalizedString(@"advancedLabel", nil)];
    
    //Tab bar item titles
    for (NSInteger i = 0; i < [self.tabBarController.viewControllers count]; i++) {
        switch ([[[[[self tabBarController] viewControllers] objectAtIndex:i] tabBarItem] tag]) {
            case 3:
                [[[[[self tabBarController] viewControllers] objectAtIndex:i] tabBarItem] setTitle:AMLocalizedString(@"contactsTitle", @"Contacts")];
                break;
                
            case 4:
                [[[[[self tabBarController] viewControllers] objectAtIndex:i] tabBarItem] setTitle:AMLocalizedString(@"transfers", @"Transfers")];
                break;
                
            case 5:
                [[[[[self tabBarController] viewControllers] objectAtIndex:i] tabBarItem] setTitle:AMLocalizedString(@"settingsTitle", @"Settings")];
                break;
                
            case 6:
                [[[[[self tabBarController] viewControllers] objectAtIndex:i] tabBarItem] setTitle:AMLocalizedString(@"myAccount", @"My Account")];
                break;
                
            default:
                break;
        }
    }
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

#pragma mark - IBActions

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    
    // Feedback
    if (indexPath.row == 4) {
        UIActionSheet *actionSheet = [[UIActionSheet alloc] initWithTitle:AMLocalizedString(@"feedbackActionSheet_title", @"How are you feeling?")
                                                                 delegate:self
                                                        cancelButtonTitle:AMLocalizedString(@"cancel", nil)
                                                   destructiveButtonTitle:nil
                                                        otherButtonTitles:AMLocalizedString(@"feedbackActionSheet_happyButton", @"Happy"), AMLocalizedString(@"feedbackActionSheet_confusedButton", @"Confused"), AMLocalizedString(@"feedbackActionSheet_unhappyButton", @"Unhappy"), nil];
        [actionSheet showFromTabBar:self.tabBarController.tabBar];
    }
}

#pragma mark - UIActionSheetDelegate

- (void)actionSheet:(UIActionSheet *)actionSheet clickedButtonAtIndex:(NSInteger)buttonIndex {
    if (buttonIndex != FeedbackFeelingNone) {
        UIStoryboard *storyboard = [UIStoryboard storyboardWithName:@"Settings" bundle:nil];
        FeedbackTableViewController *feedbackTableViewController = [storyboard instantiateViewControllerWithIdentifier:@"FeedbackID"];
        feedbackTableViewController.feeling = buttonIndex;
        [self.navigationController pushViewController:feedbackTableViewController animated:YES];
    }
}

//For iOS 7 UIActionSheet color
- (void)willPresentActionSheet:(UIActionSheet *)actionSheet {
    for (UIView *subview in actionSheet.subviews) {
        if ([subview isKindOfClass:[UIButton class]]) {
            UIButton *button = (UIButton *)subview;
            [button setTitleColor:megaRed forState:UIControlStateNormal];
        }
    }
}

@end
