/**
 * @file UpgradeTableViewController.m
 * @brief View controller that shows the products available in MEGA.
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

#import "UpgradeTableViewController.h"
#import "ProductTableViewCell.h"

#define TOBYTES 1024*1024*1024

@interface UpgradeTableViewController () <UIActionSheetDelegate>

@property (nonatomic, strong) NSString *monthlyPrice;
@property (nonatomic, strong) NSString *yearlyPrice;

@end

@implementation UpgradeTableViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    self.title = NSLocalizedString(@"upgradeAccount", "Upgrade account");
    
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

#pragma mark - UITableViewDataSource

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return self.pricing.products / 2;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    ProductTableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"productCell" forIndexPath:indexPath];
    
    if (indexPath.row <= self.megaAccountType && !self.megaAccountType == MEGAAccountTypeFree && !(self.megaAccountType == 4)) {
        cell.contentView.backgroundColor = [UIColor colorWithRed:237/255.0f green:237/255.0f blue:237/255.0f alpha:0.5f];
        [cell setUserInteractionEnabled:NO];
    }
    
    // 4 is a mega account type lite
    if (self.megaAccountType == 4 && indexPath.row == 0) {
        cell.backgroundColor = [UIColor colorWithRed:237/255.0f green:237/255.0f blue:237/255.0f alpha:1.0f];
        [cell setUserInteractionEnabled:NO];
    }
    
    switch ([self.pricing proLevelAtProductIndex:indexPath.row * 2]) {
        case MEGAAccountTypeProI:
            [cell.productImageView setImage:[UIImage imageNamed:@"pro1"]];
            [cell.productNameLabel setText:@"Pro I"];
            
            break;
            
        case MEGAAccountTypeProII:
            [cell.productImageView setImage:[UIImage imageNamed:@"pro2"]];
            [cell.productNameLabel setText:@"Pro II"];
            
            break;
            
        case MEGAAccountTypeProIII:
            [cell.productImageView setImage:[UIImage imageNamed:@"pro3"]];
            [cell.productNameLabel setText:@"Pro III"];
            
            break;
            
        default:
            [cell.productImageView setImage:[UIImage imageNamed:@"prolite"]];
            [cell.productNameLabel setText:@"Lite"];
            
            break;
    }
    
    [cell.productStorageLabel setText:[NSString stringWithFormat:NSLocalizedString(@"productSpace", "Space %@"), [NSByteCountFormatter stringFromByteCount:([self.pricing storageGBAtProductIndex:indexPath.row * 2] * TOBYTES) countStyle:NSByteCountFormatterCountStyleMemory]]];
    [cell.productBandwidthLabel setText:[NSString stringWithFormat:NSLocalizedString(@"productBandwidth", "Bandwidth %@"), [NSByteCountFormatter stringFromByteCount:([self.pricing transferGBAtProductIndex:indexPath.row * 2] * TOBYTES) countStyle:NSByteCountFormatterCountStyleMemory]]];
    
    [cell.productPriceLabel setText:[NSString stringWithFormat:NSLocalizedString(@"productPricePerMonth", "%.2f %@ per month"), (float)[self.pricing amountAtProductIndex:indexPath.row * 2] / 100, [self.pricing currencyAtProductIndex:indexPath.row]]];
    
    return cell;
}

#pragma mark - UITableViewDelegate

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    self.monthlyPrice = [NSString stringWithFormat:NSLocalizedString(@"productMonthlyPrice", "Monthly (%.2f %@)"), (float)[self.pricing amountAtProductIndex:indexPath.row * 2] / 100, [self.pricing currencyAtProductIndex:indexPath.row]];
    self.yearlyPrice = [NSString stringWithFormat:NSLocalizedString(@"productYearlyPrice", "Yearly (%.2f %@)"), (float)[self.pricing amountAtProductIndex:indexPath.row * 2 + 1] / 100, [self.pricing currencyAtProductIndex:indexPath.row]];
    
    UIActionSheet *actionSheet = [[UIActionSheet alloc] initWithTitle:NSLocalizedString(@"chooseDuration", "Choose duration")
                                                             delegate:self
                                                    cancelButtonTitle:NSLocalizedString(@"cancel", "Cancel")
                                               destructiveButtonTitle:nil
                                                    otherButtonTitles:self.yearlyPrice, self.monthlyPrice, nil];
    [actionSheet showInView:self.view];
    
    [self.tableView deselectRowAtIndexPath:indexPath animated:YES];
}

- (void)actionSheet:(UIActionSheet *)actionSheet clickedButtonAtIndex:(NSInteger)buttonIndex {
    
}


@end
