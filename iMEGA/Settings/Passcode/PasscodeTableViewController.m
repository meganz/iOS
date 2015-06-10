/**
 * @file PasscodeTableViewController.m
 * @brief View controller that shows passcode options
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

#import "PasscodeTableViewController.h"
#import "LTHPasscodeViewController.h"
#import "Helper.h"

@interface PasscodeTableViewController ()

@property (weak, nonatomic) IBOutlet UILabel *turnOnOffPasscodeLabel;
@property (weak, nonatomic) IBOutlet UISwitch *turnOnOffPasscodeSwitch;
@property (weak, nonatomic) IBOutlet UILabel *changePasscodeLabel;
@property (weak, nonatomic) IBOutlet UILabel *simplePasscodeLabel;
@property (weak, nonatomic) IBOutlet UISwitch *simplePasscodeSwitch;
@property (weak, nonatomic) IBOutlet UILabel *eraseLocalDataLabel;
@property (weak, nonatomic) IBOutlet UISwitch *eraseLocalDataSwitch;

@end

@implementation PasscodeTableViewController

#pragma mark - Lifecycle

- (void)viewDidLoad {
    [super viewDidLoad];
    
    [self.navigationItem setTitle:AMLocalizedString(@"passcodeTitle", @"Passcode")];
    [self.turnOnOffPasscodeLabel setText:AMLocalizedString(@"passcodeTitle", @"Passcode")];
    [self.changePasscodeLabel setText:AMLocalizedString(@"changePasscodeLabel", @"Change passcode")];
    [self.simplePasscodeLabel setText:AMLocalizedString(@"simplePasscodeLabel", @"Simple passcode")];
    [self.eraseLocalDataLabel setText:AMLocalizedString(@"eraseAllLocalDataLabel", @"Erase all local data")];
    
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];

    [self.turnOnOffPasscodeSwitch setOn:[LTHPasscodeViewController doesPasscodeExist]];
    
    [self.simplePasscodeSwitch setOn:[[LTHPasscodeViewController sharedUser] isSimple]];
    
    if ([[NSUserDefaults standardUserDefaults] boolForKey:kIsEraseAllLocalDataEnabled]) {
        [self.eraseLocalDataSwitch setOn:YES];
        [[LTHPasscodeViewController sharedUser] setMaxNumberOfAllowedFailedAttempts:10];
    } else {
        [self.eraseLocalDataSwitch setOn:NO];
    }
    
    [self.tableView reloadData];
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

- (IBAction)passcodeSwitchValueChanged:(UISwitch *)sender {
    if (![LTHPasscodeViewController doesPasscodeExist]) {
        [[LTHPasscodeViewController sharedUser] setNavigationBarTintColor:megaRed];
        [[LTHPasscodeViewController sharedUser] showForEnablingPasscodeInViewController:self asModal:YES];
        [[LTHPasscodeViewController sharedUser] setMaxNumberOfAllowedFailedAttempts:10];
        
        [[NSUserDefaults standardUserDefaults] setBool:YES forKey:kIsEraseAllLocalDataEnabled];
        [self.eraseLocalDataSwitch setOn:YES];
    } else {
        [[LTHPasscodeViewController sharedUser] setNavigationBarTintColor:megaRed];
        [[LTHPasscodeViewController sharedUser] showForDisablingPasscodeInViewController:self asModal:YES];
        [[NSUserDefaults standardUserDefaults] setBool:NO forKey:kIsEraseAllLocalDataEnabled];
        [self.eraseLocalDataSwitch setOn:NO];
    }
}

- (IBAction)simplePasscodeSwitchValueChanged:(UISwitch *)sender {
    [[LTHPasscodeViewController sharedUser] setIsSimple:self.simplePasscodeSwitch.isOn inViewController:self asModal:YES];
}

- (IBAction)eraseLocalDataSwitchValueChanged:(UISwitch *)sender {
    BOOL isEraseLocalData = ![[NSUserDefaults standardUserDefaults] boolForKey:kIsEraseAllLocalDataEnabled];
    
    [[NSUserDefaults standardUserDefaults] setBool:isEraseLocalData forKey:kIsEraseAllLocalDataEnabled];
    if (isEraseLocalData) {
        [[LTHPasscodeViewController sharedUser] setMaxNumberOfAllowedFailedAttempts:10];
        [self.eraseLocalDataSwitch setOn:YES animated:YES];
    } else {
        [self.eraseLocalDataSwitch setOn:NO animated:YES];
    }
}

#pragma mark - UITableViewDataSource

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    if ([LTHPasscodeViewController doesPasscodeExist]) {
        return 4;
    } else {
        return 1;
    }
}

- (NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section {
    if (section == 3) {
        return AMLocalizedString(@"failedAttempstSectionTitle", @"Log out and erase all local data on MEGA’s app after 10 failed passcode attempts");
    }
    
    return nil;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return 1;
}

#pragma mark - UITableViewDelegate

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    switch (indexPath.section) {
        case 1: {
            [[LTHPasscodeViewController sharedUser] setNavigationBarTintColor:megaRed];
            [[LTHPasscodeViewController sharedUser] showForChangingPasscodeInViewController:self asModal:YES];
            break;
        }
            
        default:
            break;
    }
}

@end
