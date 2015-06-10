/**
 * @file LanguageTableViewController.m
 * @brief View controller that allow change the app language on the fly
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

#import "LanguageTableViewController.h"

@interface LanguageTableViewController () {
    NSArray *languages;
    NSArray *codes;
    NSString *selected;
}

@end

@implementation LanguageTableViewController

#pragma mark - Lifecycle

- (void)viewDidLoad {
    [super viewDidLoad];
    
    NSString *lang = [[LocalizationSystem sharedLocalSystem] getLanguage];
    if (lang) {
        selected = lang;
    } else {
        selected = nil;
    }
    
    codes = [NSArray arrayWithObjects:@"en", @"es", nil];
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    
    self.navigationItem.title = AMLocalizedString(@"applicationLanguageLabel", nil);
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
    return codes.count;
}


- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"languageCell" forIndexPath:indexPath];
    
    NSString *code = codes[indexPath.row];
    cell.textLabel.text = AMLocalizedString(code, nil);
    
    cell.accessoryType = UITableViewCellAccessoryNone;
    
    if (selected) {
        if ([selected isEqualToString:code]) {
            cell.accessoryType = UITableViewCellAccessoryCheckmark;
        }
    }
    return cell;
    
}

#pragma mark - UITableViewDelegate

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    if (indexPath.row>=codes.count) {
        return;
    }
    
    selected = codes[indexPath.row];
    [[LocalizationSystem sharedLocalSystem] setLanguage:selected];
    
    [self.tableView reloadData];
    
    [self viewWillAppear:YES];
    
    [tableView deselectRowAtIndexPath:indexPath animated:YES];
}


@end
