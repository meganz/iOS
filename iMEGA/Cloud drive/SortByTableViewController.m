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

#import "MEGASdk.h"
#import "Helper.h"

@interface SortByTableViewController () {
    NSArray *sortByArray;
}

@property (weak, nonatomic) IBOutlet UIBarButtonItem *saveBarButtonItem;
@property (weak, nonatomic) IBOutlet UIBarButtonItem *cancelBarButtonItem;

@property (nonatomic) MEGASortOrderType sortType;

@end

@implementation SortByTableViewController

#pragma mark - Lifecycle

- (void)viewDidLoad {
    [super viewDidLoad];
    
    self.title = AMLocalizedString(@"sortTitle", nil);
    
    [self.cancelBarButtonItem setTitle:AMLocalizedString(@"cancel", nil)];
    [_cancelBarButtonItem setTitleTextAttributes:[self titleTextAttributesForButton:_cancelBarButtonItem.tag] forState:UIControlStateNormal];

    [self.saveBarButtonItem setTitle:AMLocalizedString(@"save", @"Save")];
    [_saveBarButtonItem setTitleTextAttributes:[self titleTextAttributesForButton:_saveBarButtonItem.tag] forState:UIControlStateNormal];
    
    if (!self.isOffline) {
        self.sortType = [[NSUserDefaults standardUserDefaults] integerForKey:@"SortOrderType"];
    } else {
        self.sortType = [[NSUserDefaults standardUserDefaults] integerForKey:@"OfflineSortOrderType"];
    }
    
    sortByArray = @[AMLocalizedString(@"nameAscending", nil), AMLocalizedString(@"nameDescending", nil), AMLocalizedString(@"largest", nil), AMLocalizedString(@"smallest", nil), AMLocalizedString(@"newest", nil), AMLocalizedString(@"oldest", nil)];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (UIInterfaceOrientationMask)supportedInterfaceOrientations {
    return UIInterfaceOrientationMaskAll;
}

#pragma mark - Private

- (NSDictionary *)titleTextAttributesForButton:(NSInteger)buttonTag {
    
    NSMutableDictionary *titleTextAttributesDictionary = [[NSMutableDictionary alloc] init];
    
    switch (buttonTag) {
        case 0:
            [titleTextAttributesDictionary setValue:[UIFont fontWithName:kFont size:17.0] forKey:NSFontAttributeName];
            break;
            
        case 1:
            [titleTextAttributesDictionary setValue:[UIFont fontWithName:@"SFUIText-Regular" size:17.0] forKey:NSFontAttributeName];
            break;
    }
    
    [titleTextAttributesDictionary setObject:[UIColor mnz_redD90007] forKey:NSForegroundColorAttributeName];
    
    return titleTextAttributesDictionary;
}

- (MEGASortOrderType)orderTypeForRow:(NSInteger)row {
    
    MEGASortOrderType sortOrderType;
    
    switch (row) {
        case 0: //Name (ascending)
            sortOrderType = MEGASortOrderTypeDefaultAsc;
            break;
        case 1: //Name (descending)
            sortOrderType = MEGASortOrderTypeDefaultDesc;
            break;
        case 2: //Largest
            sortOrderType = MEGASortOrderTypeSizeDesc;
            break;
        case 3: //Smallest
            sortOrderType = MEGASortOrderTypeSizeAsc;
            break;
        case 4: //Newest
            sortOrderType = MEGASortOrderTypeModificationDesc;
            break;
        case 5: //Oldest
            sortOrderType = MEGASortOrderTypeModificationAsc;
            break;
        default:
            sortOrderType = MEGASortOrderTypeDefaultAsc;
            break;
    }
    
    return sortOrderType;
}

- (NSString *)imageNameForRow:(NSInteger)row {
    
    NSString *imageName;
    
    switch (row) {
        case 0: //Name (ascending)
            imageName = @"ascending";
            break;
        case 1: //Name (descending)
            imageName = @"descending";
            break;
        case 2: //Largest
            imageName = @"largest";
            break;
        case 3: //Smallest
            imageName = @"smallest";
            break;
        case 4: //Newest
            imageName = @"newest";
            break;
        case 5: //Oldest
            imageName = @"oldest";
            break;
    }
    
    return imageName;
}

#pragma mark - IBActions


- (IBAction)cancelAction:(UIBarButtonItem *)sender {
    [self dismissViewControllerAnimated:YES completion:nil];
}

- (IBAction)saveAction:(UIBarButtonItem *)sender {
    if (!self.isOffline) {
        [[NSUserDefaults standardUserDefaults] setInteger:self.sortType forKey:@"SortOrderType"];
    } else {
        [[NSUserDefaults standardUserDefaults] setInteger:self.sortType forKey:@"OfflineSortOrderType"];
    }
    [[NSUserDefaults standardUserDefaults] synchronize];
    [self dismissViewControllerAnimated:YES completion:nil];
}

#pragma mark - UITableViewDataSource

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return [sortByArray count];
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"SortByTableViewCellID"];
    if (cell == nil) {
        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:@"SortByTableViewCellID"];
    }
    
    [cell.imageView setImage:[UIImage imageNamed:[self imageNameForRow:indexPath.row]]];
    [cell.textLabel setText:[sortByArray objectAtIndex:indexPath.row]];
    
    if (self.sortType == [self orderTypeForRow:indexPath.row]) {
        cell.accessoryType = UITableViewCellAccessoryCheckmark;
    } else {
        cell.accessoryType = UITableViewCellAccessoryNone;
    }
    
    UIView *view = [[UIView alloc] init];
    [view setBackgroundColor:[UIColor mnz_grayF7F7F7]];
    [cell setSelectedBackgroundView:view];

    return cell;
}

#pragma mark - UITableViewDelegate 

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    
    self.sortType = [self orderTypeForRow:indexPath.row];
    
    [self.tableView reloadData];
}

@end
