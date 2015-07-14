/**
 * @file SortByTableViewController.m
 * @brief View controller that shows sort options
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

#import "SortByTableViewController.h"
#import "SortFieldsTableViewController.h"
#import "MEGASdk.h"

@interface SortByTableViewController ()

@property (weak, nonatomic) IBOutlet UILabel *detailLabel;
@property (weak, nonatomic) IBOutlet UISwitch *alphabeticallySwitch;

@property (weak, nonatomic) IBOutlet UILabel *fieldLabel;
@property (weak, nonatomic) IBOutlet UILabel *ascendingLabel;

@property (weak, nonatomic) IBOutlet UIBarButtonItem *saveBarButtonItem;
@property (weak, nonatomic) IBOutlet UIBarButtonItem *cancelBarButtonItem;

@property (nonatomic) MEGASortOrderType sortType;

@end

@implementation SortByTableViewController

#pragma mark - Lifecycle

- (void)viewDidLoad {
    [super viewDidLoad];
    
    self.title = AMLocalizedString(@"sortTitle", @"Sort");
    
    [self.fieldLabel setText:AMLocalizedString(@"fieldLabel", @"Campo")];
    [self.ascendingLabel setText:AMLocalizedString(@"ascendingLabel", @"Ascending")];
    [self.cancelBarButtonItem setTitle:AMLocalizedString(@"cancel", nil)];
    [self.saveBarButtonItem setTitle:AMLocalizedString(@"save", @"Save")];
    
    self.sortType = [[NSUserDefaults standardUserDefaults] integerForKey:@"SortOrderType"];
    [self setDetailLabelText];
    
    if (self.sortType % 2) {
        [self.alphabeticallySwitch setOn:YES];
    } else {
        [self.alphabeticallySwitch setOn:NO];
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

- (IBAction)cancelAction:(UIBarButtonItem *)sender {
    [self dismissViewControllerAnimated:YES completion:nil];
}

- (IBAction)saveAction:(UIBarButtonItem *)sender {
    [[NSUserDefaults standardUserDefaults] setInteger:self.sortType forKey:@"SortOrderType"];
    [[NSUserDefaults standardUserDefaults] synchronize];
    [self dismissViewControllerAnimated:YES completion:nil];
}

- (IBAction)alphabeticallySwitchValueChanged:(UISwitch *)sender {
    if (sender.isOn) {
        self.sortType--;
    } else {
        self.sortType++;
    }
    
}

- (IBAction)unwindFromSortFieldsTableViewController:(UIStoryboardSegue *)segue {
    if ([segue.sourceViewController isKindOfClass:[SortFieldsTableViewController class]]) {
        SortFieldsTableViewController *sortFieldsTableViewController = segue.sourceViewController;
        self.sortType = sortFieldsTableViewController.sortType;
        [self setDetailLabelText];
    }
}

#pragma mark - 

- (void)setDetailLabelText {
    
    switch (self.sortType) {
        case 1:
        case 2:
            self.detailLabel.text = AMLocalizedString(@"name", nil);
            break;
            
        case 3:
        case 4:
            self.detailLabel.text = AMLocalizedString(@"size", nil);
            break;
            
        case 5:
        case 6:
            self.detailLabel.text = AMLocalizedString(@"dateField", @"Date");
            break;
            
        default:
            break;
    }
}

#pragma mark - UITableViewDataSource

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return 2;
}

- (NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section {
    return AMLocalizedString(@"orderByTableHeader", @"Order by");
}

#pragma mark - UITableViewDelegate 

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    if (indexPath.row == 0) {
        UIStoryboard *storyboard = [UIStoryboard storyboardWithName:@"Cloud" bundle:nil];
        SortFieldsTableViewController *sortFieldsTableViewController = [storyboard instantiateViewControllerWithIdentifier:@"SortFieldsTableViewControllerID"];
        
        [self.navigationController pushViewController:sortFieldsTableViewController animated:YES];
        
        [sortFieldsTableViewController setSortType:self.sortType];
        [sortFieldsTableViewController setAscending:self.alphabeticallySwitch.isOn];
    }
}

@end
