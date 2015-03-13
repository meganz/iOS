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

@interface AboutTableViewController ()

@property (weak, nonatomic) IBOutlet UILabel *privacyPolicyLabel;
@property (weak, nonatomic) IBOutlet UILabel *termsOfServicesLabel;
@end

@implementation AboutTableViewController

#pragma mark - Lifecycle

- (void)viewDidLoad {
    [super viewDidLoad];
    
    [self.privacyPolicyLabel setText:NSLocalizedString(@"privacyPolicyLabel", nil)];
    [self.termsOfServicesLabel setText:NSLocalizedString(@"termsOfServicesLabel", nil)];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

#pragma mark - Table view data source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return 4;
}

@end
