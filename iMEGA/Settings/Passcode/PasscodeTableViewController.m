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
@property (weak, nonatomic) IBOutlet UILabel *changePasscodeLabel;
@property (weak, nonatomic) IBOutlet UILabel *simplePasscodeLabel;
@property (weak, nonatomic) IBOutlet UILabel *eraseAllLocalDataLabel;

@property (weak, nonatomic) IBOutlet UITableViewCell *eraseAllLocalDataCell;

@property (weak, nonatomic) IBOutlet UISwitch *simpleSwitch;

@end

@implementation PasscodeTableViewController

#pragma mark - Lifecycle

- (void)viewDidLoad {
    [super viewDidLoad];
    
    [self.changePasscodeLabel setText:NSLocalizedString(@"changePasscodeLabel", "Change passcode")];
    [self.simplePasscodeLabel setText:NSLocalizedString(@"simplePasscodeLabel", "Simple passcode")];
    [self.eraseAllLocalDataLabel setText:NSLocalizedString(@"eraseAllLocalDataLabel", "Erase all local data")];
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    
    [self.navigationItem setTitle:NSLocalizedString(@"passcodeTitle", "The title for the passcode view")];
    
    if ([LTHPasscodeViewController doesPasscodeExist]) {
        [self.turnOnOffPasscodeLabel setText:NSLocalizedString(@"turnOffLabel", "Turn passcode off")];
    } else {
        [self.turnOnOffPasscodeLabel setText:NSLocalizedString(@"turnOnLabel", "Turn passcode on")];
    }
    
    if ([[LTHPasscodeViewController sharedUser] isSimple]) {
        [self.simpleSwitch setOn:YES];
    } else {
        [self.simpleSwitch setOn:NO];
    }
    
    if ([[NSUserDefaults standardUserDefaults] boolForKey:kIsEraseAllLocalDataEnabled]) {
        [self.eraseAllLocalDataCell setAccessoryType:UITableViewCellAccessoryCheckmark];
        [[LTHPasscodeViewController sharedUser] setMaxNumberOfAllowedFailedAttempts:10];
    } else {
        [self.eraseAllLocalDataCell setAccessoryType:UITableViewCellAccessoryNone];
    }
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

#pragma mark - Table view data source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    // Return the number of sections.
    if ([LTHPasscodeViewController doesPasscodeExist]) {
        return 4;
    } else {
        return 1;
    }
}

- (NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section {
    if (section == 3) {
        return NSLocalizedString(@"failedAttempstSectionTitle", "If number of failed attempts reached");
    }
    
    return nil;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {

    // Return the number of rows in the section.
    return 1;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    switch (indexPath.section) {
        case 0:
            if (![LTHPasscodeViewController doesPasscodeExist]) {
                [[LTHPasscodeViewController sharedUser] setNavigationBarTintColor:megaRed];
                [[LTHPasscodeViewController sharedUser] showForEnablingPasscodeInViewController:self asModal:YES];
                [[NSUserDefaults standardUserDefaults] setBool:YES forKey:kIsEraseAllLocalDataEnabled];
                [self.eraseAllLocalDataCell setAccessoryType:UITableViewCellAccessoryCheckmark];
                [[LTHPasscodeViewController sharedUser] setMaxNumberOfAllowedFailedAttempts:10];
            } else {
                [[LTHPasscodeViewController sharedUser] setNavigationBarTintColor:megaRed];
                [[LTHPasscodeViewController sharedUser] showForDisablingPasscodeInViewController:self asModal:YES];
                [[NSUserDefaults standardUserDefaults] setBool:NO forKey:kIsEraseAllLocalDataEnabled];
            }
            break;
            
        case 1:
            [[LTHPasscodeViewController sharedUser] setNavigationBarTintColor:megaRed];
            [[LTHPasscodeViewController sharedUser] showForChangingPasscodeInViewController:self asModal:YES];
            break;
            
        case 3: {
            BOOL isEraseAllLocalData = ![[NSUserDefaults standardUserDefaults] boolForKey:kIsEraseAllLocalDataEnabled];
            
            [[NSUserDefaults standardUserDefaults] setBool:isEraseAllLocalData forKey:kIsEraseAllLocalDataEnabled];
            if (isEraseAllLocalData) {
                [self.eraseAllLocalDataCell setAccessoryType:UITableViewCellAccessoryCheckmark];
                [[LTHPasscodeViewController sharedUser] setMaxNumberOfAllowedFailedAttempts:10];
            } else {
                [self.eraseAllLocalDataCell setAccessoryType:UITableViewCellAccessoryNone];
            }
            
            break;
        }
            
        default:
            break;
    }
}

- (IBAction)simpleSwitchValueChanged:(UISwitch *)sender {
    [[LTHPasscodeViewController sharedUser] setIsSimple:self.simpleSwitch.isOn inViewController:self asModal:YES];
}


@end
