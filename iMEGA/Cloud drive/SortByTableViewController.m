
#import "SortByTableViewController.h"

#import "Helper.h"
#import "MEGA-Swift.h"

@interface SortByTableViewController ()

@property (weak, nonatomic) IBOutlet UIBarButtonItem *saveBarButtonItem;
@property (weak, nonatomic) IBOutlet UIBarButtonItem *cancelBarButtonItem;

@property (nonatomic) NSArray *sortByArray;

@property (nonatomic) SortingPreference sortingPreference;
@property (nonatomic) MEGASortOrderType sortType;
@property (nonatomic) MEGASortOrderType selectedSortType;

@end

@implementation SortByTableViewController

#pragma mark - Lifecycle

- (void)viewDidLoad {
    [super viewDidLoad];
    
    self.title = AMLocalizedString(@"sortTitle", nil);
    
    [self.cancelBarButtonItem setTitle:AMLocalizedString(@"cancel", nil)];
    [self.saveBarButtonItem setTitle:AMLocalizedString(@"save", @"Save")];
    [self.saveBarButtonItem setTitleTextAttributes:@{NSFontAttributeName:[UIFont systemFontOfSize:17.0f weight:UIFontWeightMedium]} forState:UIControlStateNormal];
    
    if (self.node) {
        self.sortingPreference = [NSUserDefaults.standardUserDefaults integerForKey:MEGASortingPreference];
        self.sortType = [Helper sortTypeFor:self.node];
    } else if (self.path) {
        self.sortingPreference = [NSUserDefaults.standardUserDefaults integerForKey:MEGASortingPreference];
        self.sortType = [Helper sortTypeFor:self.path];
    } else {
        self.sortingPreference = SortingPreferenceSameForAll;
        MEGASortOrderType currentSortType = [NSUserDefaults.standardUserDefaults integerForKey:MEGASortingPreferenceType];
        self.sortType = currentSortType ? currentSortType : Helper.defaultSortType;
    }
    self.selectedSortType = self.sortType;
    
    self.sortByArray = @[AMLocalizedString(@"nameAscending", @"Sort by option (1/6). This one orders the files alphabethically"), AMLocalizedString(@"nameDescending", @"Sort by option (2/6). This one arranges the files on reverse alphabethical order"), AMLocalizedString(@"largest", @"Sort by option (3/6). This one order the files by its size, in this case from bigger to smaller size"), AMLocalizedString(@"smallest", @"Sort by option (4/6). This one order the files by its size, in this case from smaller to bigger size"), AMLocalizedString(@"newest", @"Sort by option (5/6). This one order the files by its modification date, newer first"), AMLocalizedString(@"oldest", @"Sort by option (6/6). This one order the files by its modification date, older first")];
    
    [self.tableView registerNib:[UINib nibWithNibName:@"SelectableTableViewCell" bundle:nil] forCellReuseIdentifier:@"SelectableTableViewCellID"];
    
    [self updateAppearance];
}

- (UIInterfaceOrientationMask)supportedInterfaceOrientations {
    return UIInterfaceOrientationMaskAll;
}

- (void)traitCollectionDidChange:(UITraitCollection *)previousTraitCollection {
    [super traitCollectionDidChange:previousTraitCollection];
    
    if (@available(iOS 13.0, *)) {
        if ([self.traitCollection hasDifferentColorAppearanceComparedToTraitCollection:previousTraitCollection]) {
            [self updateAppearance];
        }
    }
}

#pragma mark - Private

- (void)updateAppearance {
    self.view.backgroundColor = [UIColor mnz_backgroundGroupedForTraitCollection:self.traitCollection];
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
    if (self.selectedSortType != self.sortType) {
        if (self.sortingPreference == SortingPreferencePerFolder) {
            if (self.node) {
                [MEGAStore.shareInstance insertOrUpdateCloudSortTypeWithHandle:self.node.handle sortType:self.selectedSortType];
            } else if (self.path) {
                [MEGAStore.shareInstance insertOrUpdateOfflineSortTypeWithPath:self.path sortType:self.selectedSortType];
            }
            
            [NSNotificationCenter.defaultCenter postNotificationName:MEGASortingPreference object:self userInfo:@{MEGASortingPreference : @(self.sortingPreference), MEGASortingPreferenceType : @(self.selectedSortType)}];
        } else {
            self.sortingPreference = SortingPreferenceSameForAll;
            [NSUserDefaults.standardUserDefaults setInteger:self.sortingPreference forKey:MEGASortingPreference];
            [NSUserDefaults.standardUserDefaults setInteger:self.selectedSortType forKey:MEGASortingPreferenceType];
            if (@available(iOS 12.0, *)) {} else {
                [NSUserDefaults.standardUserDefaults synchronize];
            }
            
            [NSNotificationCenter.defaultCenter postNotificationName:MEGASortingPreference object:self userInfo:@{MEGASortingPreference : @(self.sortingPreference), MEGASortingPreferenceType : @(self.selectedSortType)}];
        }
    }
    
    [self dismissViewControllerAnimated:YES completion:nil];
}

#pragma mark - UITableViewDataSource

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return self.sortByArray.count;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    SelectableTableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"SelectableTableViewCellID"];
    if (cell == nil) {
        cell = [SelectableTableViewCell.alloc initWithStyle:UITableViewCellStyleDefault reuseIdentifier:@"SelectableTableViewCellID"];
    }
    
    [cell.imageView setImage:[UIImage imageNamed:[self imageNameForRow:indexPath.row]]];
    cell.textLabel.text = self.sortByArray[indexPath.row];
    
    if (self.selectedSortType == [self orderTypeForRow:indexPath.row]) {
        cell.redCheckmarkImageView.hidden = NO;
    } else {
        cell.redCheckmarkImageView.hidden = YES;
    }

    return cell;
}

#pragma mark - UITableViewDelegate 

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    [tableView deselectRowAtIndexPath:indexPath animated:YES];
    
    MEGASortOrderType justSelectedSortType = [self orderTypeForRow:indexPath.row];
    if (justSelectedSortType != self.selectedSortType) {
        self.selectedSortType = justSelectedSortType;
        
        [self.tableView reloadData];
    }
}

@end
