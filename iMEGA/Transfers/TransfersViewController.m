/**
 * @file TransfersViewController.m
 * @brief View controller that shows the transfers associated with the logged user.
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
#import "UIScrollView+EmptyDataSet.h"

#import "MEGASdkManager.h"
#import "Helper.h"

#import "TransfersViewController.h"
#import "TransferTableViewCell.h"

@interface TransfersViewController () <UINavigationControllerDelegate, UITableViewDelegate, UITableViewDataSource, UIAlertViewDelegate, DZNEmptyDataSetSource, DZNEmptyDataSetDelegate, MEGARequestDelegate, MEGATransferDelegate>

@property (strong, nonatomic) IBOutlet UIBarButtonItem *pauseBarButtonItem;
@property (strong, nonatomic) IBOutlet UIBarButtonItem *resumeBarButtonItem;
@property (strong, nonatomic) IBOutlet UIBarButtonItem *cancelBarButtonItem;

@property (weak, nonatomic) IBOutlet UISegmentedControl *transfersSegmentedControl;
@property (weak, nonatomic) IBOutlet UITableView *tableView;

@property (nonatomic, strong) NSMutableDictionary *allActiveTransfersMutableDictionary;
@property (nonatomic, strong) NSMutableDictionary *allQueuedTransfersMutableDictionary;

@property (nonatomic, strong) NSMutableDictionary *downloadActiveTransfersMutableDictionary;
@property (nonatomic, strong) NSMutableDictionary *downloadQueuedTransfersMutableDictionary;

@property (nonatomic, strong) NSMutableDictionary *uploadActiveTransfersMutableDictionary;
@property (nonatomic, strong) NSMutableDictionary *uploadQueuedTransfersMutableDictionary;

@property (nonatomic, strong) NSMutableDictionary *allTransfersIndexPathMutableDictionary;
@property (nonatomic, strong) NSMutableDictionary *downloadTransfersIndexPathMutableDictionary;
@property (nonatomic, strong) NSMutableDictionary *uploadTransfersIndexPathMutableDictionary;

@end

@implementation TransfersViewController

#pragma mark - Lifecycle

- (void)viewDidLoad {
    [super viewDidLoad];
    
    self.tableView.emptyDataSetSource = self;
    self.tableView.emptyDataSetDelegate = self;
    
    [self.transfersSegmentedControl setTitle:NSLocalizedString(@"all", @"All") forSegmentAtIndex:0];
    [self.transfersSegmentedControl setTitle:NSLocalizedString(@"downloads", @"Downloads") forSegmentAtIndex:1];
    [self.transfersSegmentedControl setTitle:NSLocalizedString(@"uploads", @"Uploads") forSegmentAtIndex:2];
    
    self.allActiveTransfersMutableDictionary = [[NSMutableDictionary alloc] init];
    self.allQueuedTransfersMutableDictionary = [[NSMutableDictionary alloc] init];
    
    self.allTransfersIndexPathMutableDictionary = [[NSMutableDictionary alloc] init];
    self.downloadTransfersIndexPathMutableDictionary = [[NSMutableDictionary alloc] init];
    self.uploadTransfersIndexPathMutableDictionary = [[NSMutableDictionary alloc] init];
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    
    [self.navigationItem setTitle:NSLocalizedString(@"transfers", @"Transfers")];
    
    [[MEGASdkManager sharedMEGASdk] addMEGATransferDelegate:self];
    [[MEGASdkManager sharedMEGASdkFolder] addMEGATransferDelegate:self];
    [[MEGASdkManager sharedMEGASdk] retryPendingConnections];
    [[MEGASdkManager sharedMEGASdkFolder] retryPendingConnections];
    
    if ([[NSUserDefaults standardUserDefaults] boolForKey:@"TransfersPaused"]) {
        [self.navigationItem setRightBarButtonItems:@[self.resumeBarButtonItem, self.cancelBarButtonItem] animated:YES];
    } else {
        [self.navigationItem setRightBarButtonItems:@[self.pauseBarButtonItem, self.cancelBarButtonItem] animated:YES];
    }
    
    [self cleanTransfersList];
    [self transfersList];
    [self.tableView reloadData];
}

- (void)viewWillDisappear:(BOOL)animated {
    [super viewWillDisappear:animated];
    
    [[MEGASdkManager sharedMEGASdk] removeMEGATransferDelegate:self];
    [[MEGASdkManager sharedMEGASdkFolder] removeMEGATransferDelegate:self];
    
    [self cleanTransfersList];
}

- (void)dealloc {
    self.tableView.emptyDataSetSource = nil;
    self.tableView.emptyDataSetDelegate = nil;
}

#pragma mark - UITableViewDataSource

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    
    TransferTableViewCell *cell = [self.tableView dequeueReusableCellWithIdentifier:@"transferCell" forIndexPath:indexPath];
    
    MEGATransfer *transfer;
    if ([indexPath section] == 0) { //ACTIVE TRANSFERS
        switch (self.transfersSegmentedControl.selectedSegmentIndex) {
            case 0: { //All
                transfer = [[self.allActiveTransfersMutableDictionary allValues] objectAtIndex:indexPath.row];
                if ([transfer type] == MEGATransferTypeDownload) {
                    [self.allTransfersIndexPathMutableDictionary setObject:indexPath forKey:[self keyForTransfer:transfer]];
                    [cell.arrowImageView setImage:[Helper downloadTransferImage]];
                } else {
                    [self.allTransfersIndexPathMutableDictionary setObject:indexPath forKey:[NSNumber numberWithInteger:transfer.tag]];
                    [cell.arrowImageView setImage:[Helper uploadTransferImage]];
                }
                break;
            }
                
            case 1: { //Downloads
                transfer = [[self.downloadActiveTransfersMutableDictionary allValues] objectAtIndex:indexPath.row];
                [self.downloadTransfersIndexPathMutableDictionary setObject:indexPath forKey:[self keyForTransfer:transfer]];
                [cell.arrowImageView setImage:[Helper downloadTransferImage]];
                break;
            }
                
            case 2: { //Uploads
                transfer = [[self.uploadActiveTransfersMutableDictionary allValues] objectAtIndex:indexPath.row];
                [self.uploadTransfersIndexPathMutableDictionary setObject:indexPath forKey:[NSNumber numberWithInteger:transfer.tag]];
                [cell.arrowImageView setImage:[Helper uploadTransferImage]];
                break;
            }
        }
    } else { //QUEUED TRANSFERS
        switch (self.transfersSegmentedControl.selectedSegmentIndex) {
            case 0: { //All
                transfer = [[self.allQueuedTransfersMutableDictionary allValues] objectAtIndex:indexPath.row];
                if ([transfer type] == MEGATransferTypeDownload) {
                    [self.allTransfersIndexPathMutableDictionary setObject:indexPath forKey:[self keyForTransfer:transfer]];
                    [cell.arrowImageView setImage:[Helper downloadTransferImage]];
                } else {
                    [self.allTransfersIndexPathMutableDictionary setObject:indexPath forKey:[NSNumber numberWithInteger:transfer.tag]];
                    [cell.arrowImageView setImage:[Helper uploadTransferImage]];
                }
                break;
            }
                
            case 1: { //Downloads
                transfer = [[self.downloadQueuedTransfersMutableDictionary allValues] objectAtIndex:indexPath.row];
                [self.downloadTransfersIndexPathMutableDictionary setObject:indexPath forKey:[self keyForTransfer:transfer]];
                [cell.arrowImageView setImage:[Helper downloadTransferImage]];
                break;
            }
                
            case 2: { //Uploads
                transfer = [[self.uploadQueuedTransfersMutableDictionary allValues] objectAtIndex:indexPath.row];
                [self.uploadTransfersIndexPathMutableDictionary setObject:indexPath forKey:[NSNumber numberWithInteger:transfer.tag]];
                [cell.arrowImageView setImage:[Helper uploadTransferImage]];
                break;
            }
        }
        [cell.infoLabel setText:[NSString stringWithFormat:NSLocalizedString(@"queued", @"Queued")]];
    }
    
    NSString *fileName = [transfer fileName];
    NSString *nameString;
    if ([transfer type] == MEGATransferTypeDownload) {
        NSArray *itemNameComponentsArray = [fileName componentsSeparatedByString:@"_"];
        NSString *handleString = [itemNameComponentsArray objectAtIndex:0];
        if ([itemNameComponentsArray count] > 2) {
            nameString = [fileName substringFromIndex:(handleString.length + 1)];
        } else  {
            nameString = [itemNameComponentsArray objectAtIndex:1];
        }
    } else if ([transfer type] == MEGATransferTypeUpload) {
        nameString = fileName;
    }
    [cell.nameLabel setText:[[MEGASdkManager sharedMEGASdk] localToName:nameString]];
    
    [cell setTransferTag:transfer.tag];
    
    return cell;
}

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return 2;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    NSInteger numberOfRows = 0;
    switch (self.transfersSegmentedControl.selectedSegmentIndex) {
        case 0: { //All
            if (section == 0) {
                numberOfRows = [self.allActiveTransfersMutableDictionary count];
            } else {
                numberOfRows = [self.allQueuedTransfersMutableDictionary count];
            }
            break;
        }
            
        case 1:  { //Downloads
            if (section == 0) {
                numberOfRows = [self.downloadActiveTransfersMutableDictionary count];
            } else {
                numberOfRows = [self.downloadQueuedTransfersMutableDictionary count];
            }
            break;
        }
            
        case 2: { //Uploads
            if (section == 0) {
                numberOfRows = [self.uploadActiveTransfersMutableDictionary count];
            } else {
                numberOfRows = [self.uploadQueuedTransfersMutableDictionary count];
            }
            break;
        }
    }
    return numberOfRows;
}

- (NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section {
    NSString *titleForHeader;
    if ([self.tableView.dataSource tableView:tableView numberOfRowsInSection:section] == 0) {
        titleForHeader = nil;
    } else {
        if (section == 0) {
            titleForHeader = NSLocalizedString(@"activeTransfers", @"Active transfers");
        } else {
            titleForHeader = NSLocalizedString(@"queuedTransfers", @"Queued transfers");
        }
    }
    
    return titleForHeader;
}

#pragma mark - UITableViewDelegate

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    [tableView deselectRowAtIndexPath:indexPath animated:YES];
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {
    if (([[[UIDevice currentDevice] systemVersion] compare:@"8.0" options:NSNumericSearch] == NSOrderedAscending)) {
        return 44.0;
    }
    else {
        return UITableViewAutomaticDimension;
    }
}

- (CGFloat)tableView:(UITableView *)tableView estimatedHeightForRowAtIndexPath:(NSIndexPath *)indexPath {
    if (([[[UIDevice currentDevice] systemVersion] compare:@"8.0" options:NSNumericSearch] == NSOrderedAscending)) {
        return 44.0;
    }
    else {
        return UITableViewAutomaticDimension;
    }
}

#pragma mark - UIAlertViewDelegate

- (void)alertView:(UIAlertView *)alertView clickedButtonAtIndex:(NSInteger)buttonIndex {
    if ((alertView.tag == 0) && (buttonIndex == 1)) {
        switch (self.transfersSegmentedControl.selectedSegmentIndex) {
            case 0: { //All
                [self cancelTransfersForDirection:0];
                [self cancelTransfersForDirection:1];
                break;
            }
                
            case 1: { //Downloads
                [self cancelTransfersForDirection:0];
                break;
            }
                
            case 2: { //Uploads
                [self cancelTransfersForDirection:1];
                break;
            }
        }
        [self.tableView reloadData];
    }
}

#pragma mark - Private methods

- (void)transfersList {
    MEGATransferList *transferList = [[MEGASdkManager sharedMEGASdk] transfers];
    if ([transferList.size integerValue] != 0) {
        [self clasifyTransfers:transferList];
    }
    
    transferList = [[MEGASdkManager sharedMEGASdkFolder] transfers];
    if ([transferList.size integerValue] != 0) {
        [self clasifyTransfers:transferList];
    }
}

- (void)clasifyTransfers:(MEGATransferList *)transferList {
    NSInteger transferListSize = [transferList.size integerValue];
    for (NSInteger i = 0; i < transferListSize; i++) {
        MEGATransfer *transfer = [transferList transferAtIndex:i];
        if ([transfer type] == MEGATransferTypeDownload) {
            [self.allQueuedTransfersMutableDictionary setObject:transfer forKey:[self keyForTransfer:transfer]];
        } else {
            [self.allQueuedTransfersMutableDictionary setObject:transfer forKey:[NSNumber numberWithInteger:transfer.tag]];
        }
    }
}

- (void)addNewTransfer:(MEGATransfer *)transfer {
    if ([transfer type] == MEGATransferTypeDownload) {
        NSString *key = [self keyForTransfer:transfer];
        [self.allQueuedTransfersMutableDictionary setObject:transfer forKey:key];
        
        if (self.transfersSegmentedControl.selectedSegmentIndex == 1) {
            [self.downloadQueuedTransfersMutableDictionary setObject:transfer forKey:key];
        }
    } else {
        NSNumber *key = [NSNumber numberWithInteger:transfer.tag];
        [self.allQueuedTransfersMutableDictionary setObject:transfer forKey:key];
        
        if (self.transfersSegmentedControl.selectedSegmentIndex == 2) {
            [self.uploadQueuedTransfersMutableDictionary setObject:transfer forKey:key];
        }
    }
}

- (void)cleanTransfersList {
    [self.allActiveTransfersMutableDictionary removeAllObjects];
    [self.allQueuedTransfersMutableDictionary removeAllObjects];
    
    [self.allTransfersIndexPathMutableDictionary removeAllObjects];
    [self.downloadTransfersIndexPathMutableDictionary removeAllObjects];
    [self.uploadTransfersIndexPathMutableDictionary removeAllObjects];
    
    if (self.transfersSegmentedControl.selectedSegmentIndex == 1) {
        [self.downloadActiveTransfersMutableDictionary removeAllObjects];
        [self.downloadQueuedTransfersMutableDictionary removeAllObjects];
    } else if (self.transfersSegmentedControl.selectedSegmentIndex == 2) {
        [self.uploadActiveTransfersMutableDictionary removeAllObjects];
        [self.uploadQueuedTransfersMutableDictionary removeAllObjects];
    }
}

- (void)transfersForDirection:(NSInteger)direction {
    if (direction) {
        self.uploadActiveTransfersMutableDictionary = [[NSMutableDictionary alloc] init];
        NSEnumerator *enumerator = [self.allActiveTransfersMutableDictionary objectEnumerator];
        MEGATransfer *transfer;
        while ((transfer = [enumerator nextObject])) {
            if ([transfer type] == MEGATransferTypeUpload) {
                [self.uploadActiveTransfersMutableDictionary setObject:transfer forKey:[NSNumber numberWithInteger:transfer.tag]];
            }
        }
        
        self.uploadQueuedTransfersMutableDictionary = [[NSMutableDictionary alloc] init];
        enumerator = [self.allQueuedTransfersMutableDictionary objectEnumerator];
        while ((transfer = [enumerator nextObject])) {
            if ([transfer type] == MEGATransferTypeUpload) {
                [self.uploadQueuedTransfersMutableDictionary setObject:transfer forKey:[NSNumber numberWithInteger:transfer.tag]];
            }
        }
    } else {
        self.downloadActiveTransfersMutableDictionary = [[NSMutableDictionary alloc] init];
        NSEnumerator *enumerator = [self.allActiveTransfersMutableDictionary objectEnumerator];
        MEGATransfer *transfer;
        while ((transfer = [enumerator nextObject])) {
            if ([transfer type] == MEGATransferTypeDownload) {
                [self.downloadActiveTransfersMutableDictionary setObject:transfer forKey:[self keyForTransfer:transfer]];
            }
        }
        
        self.downloadQueuedTransfersMutableDictionary = [[NSMutableDictionary alloc] init];
        enumerator = [self.allQueuedTransfersMutableDictionary objectEnumerator];
        while ((transfer = [enumerator nextObject])) {
            if ([transfer type] == MEGATransferTypeDownload) {
                [self.downloadQueuedTransfersMutableDictionary setObject:transfer forKey:[self keyForTransfer:transfer]];
            }
        }
    }
}

- (NSString *)keyForTransfer:(MEGATransfer *)transfer {
    return [NSString stringWithFormat:@"%ld_%@", (long)[transfer tag], [NSString stringWithString:[MEGASdk base64HandleForHandle:transfer.nodeHandle] ]];
}

- (void)setActiveTransfer:(MEGATransfer *)transfer {
    if ([transfer type] == MEGATransferTypeDownload) {
        NSString *key = [self keyForTransfer:transfer];
        [self.allQueuedTransfersMutableDictionary removeObjectForKey:key];
        [self.allActiveTransfersMutableDictionary setObject:transfer forKey:key];
        
        if (self.transfersSegmentedControl.selectedSegmentIndex == 1) {
            [self.downloadQueuedTransfersMutableDictionary removeObjectForKey:key];
            [self.downloadActiveTransfersMutableDictionary setObject:transfer forKey:key];
        }
    } else {
        NSNumber *key = [NSNumber numberWithInteger:transfer.tag];
        [self.allQueuedTransfersMutableDictionary removeObjectForKey:key];
        [self.allActiveTransfersMutableDictionary setObject:transfer forKey:key];
        
        if (self.transfersSegmentedControl.selectedSegmentIndex == 2) {
            [self.uploadQueuedTransfersMutableDictionary removeObjectForKey:key];
            [self.uploadActiveTransfersMutableDictionary setObject:transfer forKey:key];
        }
    }
}

- (void)removeActiveTransfer:(MEGATransfer *)transfer {
    if ([transfer type] == MEGATransferTypeDownload) {
        NSString *key = [self keyForTransfer:transfer];
        [self.allActiveTransfersMutableDictionary removeObjectForKey:key];
        if (self.transfersSegmentedControl.selectedSegmentIndex == 1) {
            [self.downloadActiveTransfersMutableDictionary removeObjectForKey:key];
        }
        
        [self.allTransfersIndexPathMutableDictionary removeObjectForKey:key];
        [self.downloadTransfersIndexPathMutableDictionary removeObjectForKey:key];
    } else {
        NSNumber *key = [NSNumber numberWithInteger:transfer.tag];
        [self.allActiveTransfersMutableDictionary removeObjectForKey:key];
        if (self.transfersSegmentedControl.selectedSegmentIndex == 2) {
            [self.uploadActiveTransfersMutableDictionary removeObjectForKey:key];
        }
        
        [self.allTransfersIndexPathMutableDictionary removeObjectForKey:key];
        [self.uploadTransfersIndexPathMutableDictionary removeObjectForKey:key];
    }
}

- (void)pauseOrResumeTransfers:(BOOL)pauseOrResume {
    [[MEGASdkManager sharedMEGASdk] pauseTransfers:pauseOrResume delegate:self];
    [[MEGASdkManager sharedMEGASdkFolder] pauseTransfers:pauseOrResume delegate:self];
}

- (void)cancelTransfersForDirection:(NSInteger)direction {
    MEGATransferList *transferList = [[MEGASdkManager sharedMEGASdk] transfers];
    if ([transferList.size integerValue] != 0) {
        [[MEGASdkManager sharedMEGASdk] cancelTransfersForDirection:direction delegate:self];
    }
    
    transferList = [[MEGASdkManager sharedMEGASdkFolder] transfers];
    if ([transferList.size integerValue] != 0) {
        [[MEGASdkManager sharedMEGASdkFolder] cancelTransfersForDirection:direction delegate:self];
    }
}

#pragma mark - IBActions

- (IBAction)transfersTypeSegmentedControlValueChanged:(UISegmentedControl *)sender {
    switch (self.transfersSegmentedControl.selectedSegmentIndex) {
        case 0: { //All
            [self.downloadActiveTransfersMutableDictionary removeAllObjects];
            [self.downloadQueuedTransfersMutableDictionary removeAllObjects];
            [self.uploadActiveTransfersMutableDictionary removeAllObjects];
            [self.uploadQueuedTransfersMutableDictionary removeAllObjects];
            break;
        }
            
        case 1: { //Downloads
            [self transfersForDirection:0];
            break;
        }
    
        case 2: { //Uploads
            [self transfersForDirection:1];
            break;
        }
    }
    [self.tableView reloadData];
}

- (IBAction)pauseTransfersAction:(UIBarButtonItem *)sender {
    [self pauseOrResumeTransfers:YES];
    [self.navigationItem setRightBarButtonItems:@[self.resumeBarButtonItem, self.cancelBarButtonItem] animated:NO];
}

- (IBAction)resumeTransfersAction:(UIBarButtonItem *)sender {
    [self pauseOrResumeTransfers:NO];
    [self.navigationItem setRightBarButtonItems:@[self.pauseBarButtonItem, self.cancelBarButtonItem] animated:NO];
}

- (IBAction)cancelTransfersAction:(UIBarButtonItem *)sender {
    NSString *transfersTypeString;
    switch (self.transfersSegmentedControl.selectedSegmentIndex) {
        case 0: { //All
            if ((self.allActiveTransfersMutableDictionary.count == 0) && (self.allQueuedTransfersMutableDictionary.count == 0)) {
                return;
            }
            transfersTypeString = NSLocalizedString(@"allInUppercaseTransfers", @"ALL transfers");
            break;
        }
            
        case 1: { //Downloads
            if ((self.downloadActiveTransfersMutableDictionary.count == 0) && (self.downloadQueuedTransfersMutableDictionary.count == 0)) {
                return;
            }
            transfersTypeString = NSLocalizedString(@"downloadInUppercaseTransfers", @"DOWNLOAD transfers");
            break;
        }
            
        case 2: { //Uploads
            if ((self.uploadActiveTransfersMutableDictionary.count == 0) && (self.uploadQueuedTransfersMutableDictionary.count == 0)) {
                return;
            }
            transfersTypeString = NSLocalizedString(@"uploadInUppercaseTransfers", @"UPLOAD transfers");
            break;
        }
    }
    
    UIAlertView *alertView = [[UIAlertView alloc] initWithTitle:NSLocalizedString(@"cancelTransfersTitle", @"Cancel transfers")
                                                        message:[NSString stringWithFormat:NSLocalizedString(@"cancelTransfersText", @"Do you want to cancel %@?"), transfersTypeString]
                                                       delegate:self
                                              cancelButtonTitle:NSLocalizedString(@"cancel", @"Cancel")
                                              otherButtonTitles:NSLocalizedString(@"ok", @"OK"), nil];
    [alertView setTag:0];
    [alertView show];
}

#pragma mark - DZNEmptyDataSetSource

- (NSAttributedString *)titleForEmptyDataSet:(UIScrollView *)scrollView {
    
    NSString *text;
    switch (self.transfersSegmentedControl.selectedSegmentIndex) {
        case 0: //All
            text = NSLocalizedString(@"transfersEmptyState_titleAll", @"No active transfers");
            break;
            
        case 1: //Downloads
            text = NSLocalizedString(@"transfersEmptyState_titleDownload", @"No active download transfers");
            break;
            
        case 2: //Uploads
            text = NSLocalizedString(@"transfersEmptyState_titleUpload", @"No active upload transfers");
            break;
    }
    
    NSDictionary *attributes = @{NSFontAttributeName: [UIFont boldSystemFontOfSize:18.0],
                                 NSForegroundColorAttributeName: [UIColor darkGrayColor]};
    
    return [[NSAttributedString alloc] initWithString:text attributes:attributes];
}

- (NSAttributedString *)descriptionForEmptyDataSet:(UIScrollView *)scrollView {
    
    NSString *text;
    switch (self.transfersSegmentedControl.selectedSegmentIndex) {
        case 0: //All
            text = NSLocalizedString(@"transfersEmptyState_textAll",  @"You don't have any pending transfers.");
            break;
            
        case 1: //Downloads
            text = NSLocalizedString(@"transfersEmptyState_textDownload",  @"You don't have any pending download transfers.");
            break;
            
        case 2: //Uploads
            text = NSLocalizedString(@"transfersEmptyState_textUpload",  @"You don't have any pending upload transfers.");
            break;
    }
    
    NSMutableParagraphStyle *paragraph = [NSMutableParagraphStyle new];
    paragraph.lineBreakMode = NSLineBreakByWordWrapping;
    paragraph.alignment = NSTextAlignmentCenter;
    
    NSDictionary *attributes = @{NSFontAttributeName: [UIFont systemFontOfSize:14.0],
                                 NSForegroundColorAttributeName: [UIColor lightGrayColor],
                                 NSParagraphStyleAttributeName: paragraph};
    
    return [[NSAttributedString alloc] initWithString:text attributes:attributes];
}

- (UIImage *)imageForEmptyDataSet:(UIScrollView *)scrollView {
    return [UIImage imageNamed:@"emptyTransfers"];
}

- (UIColor *)backgroundColorForEmptyDataSet:(UIScrollView *)scrollView {
    return [UIColor whiteColor];
}

#pragma mark - MEGARequestDelegate

- (void)onRequestStart:(MEGASdk *)api request:(MEGARequest *)request {
}

- (void)onRequestFinish:(MEGASdk *)api request:(MEGARequest *)request error:(MEGAError *)error {
    if ([error type]) {
        return;
    }
    
    switch ([request type]) {
        case MEGARequestTypePauseTransfers: {
            if ([request flag]) {
                [SVProgressHUD showSuccessWithStatus:[NSString stringWithFormat:NSLocalizedString(@"transfersPaused", @"Transfers paused")]];
            } else {
                [SVProgressHUD showSuccessWithStatus:[NSString stringWithFormat:NSLocalizedString(@"transfersResumed", @"Transfers resumed")]];
            }
            [[NSUserDefaults standardUserDefaults] setBool:[request flag] forKey:@"TransfersPaused"];
            break;
        }
            
        case MEGARequestTypeCancelTransfers: {
            [self cleanTransfersList];
            [self.tableView reloadData];
            [SVProgressHUD showSuccessWithStatus:[NSString stringWithFormat:NSLocalizedString(@"transfersCanceled", @"Transfers canceled")]];
            break;
        }
            
        default:
            break;
    }
}

- (void)onRequestTemporaryError:(MEGASdk *)api request:(MEGARequest *)request error:(MEGAError *)error {
}

#pragma mark - MEGATransferDelegate

- (void)onTransferStart:(MEGASdk *)api transfer:(MEGATransfer *)transfer {
    [self addNewTransfer:transfer];
    [self.tableView reloadData];
}

- (void)onTransferUpdate:(MEGASdk *)api transfer:(MEGATransfer *)transfer {
    
    if ([transfer type] == MEGATransferTypeDownload) {
        NSString *key = [self keyForTransfer:transfer];
        if (([self.allActiveTransfersMutableDictionary objectForKey:key] == nil) && ([self.allQueuedTransfersMutableDictionary objectForKey:key] != nil)) {
            [self setActiveTransfer:transfer];
            [self.tableView reloadData];
        }
    } else {
        NSNumber *key = [NSNumber numberWithInteger:transfer.tag];
        if (([self.allActiveTransfersMutableDictionary objectForKey:key] == nil) && ([self.allQueuedTransfersMutableDictionary objectForKey:key] != nil)) {
            [self setActiveTransfer:transfer];
            [self.tableView reloadData];
        }
    }
    
    NSIndexPath *indexPath;
    switch (self.transfersSegmentedControl.selectedSegmentIndex) {
        case 0: { //All
            if ([transfer type] == MEGATransferTypeDownload) {
                indexPath = [self.allTransfersIndexPathMutableDictionary objectForKey:[self keyForTransfer:transfer]];
            } else {
                indexPath = [self.allTransfersIndexPathMutableDictionary objectForKey:[NSNumber numberWithInteger:transfer.tag]];
            }
            break;
        }
            
        case 1: { //Downloads
            if ([transfer type] == MEGATransferTypeUpload) {
                return;
            }
            indexPath = [self.downloadTransfersIndexPathMutableDictionary objectForKey:[self keyForTransfer:transfer]];
            break;
        }
            
        case 2: { //Uploads
            if ([transfer type] == MEGATransferTypeDownload) {
                return;
            }
            indexPath = [self.uploadTransfersIndexPathMutableDictionary objectForKey:[NSNumber numberWithInteger:transfer.tag]];
            break;
        }
    }
    if (indexPath != nil) {
        float percentage = ([[transfer transferredBytes] floatValue] / [[transfer totalBytes] floatValue] * 100);
        NSString *percentageCompleted = [NSString stringWithFormat:@"%.f%%", percentage];
        NSString *speed = [NSString stringWithFormat:@"%@/s", [NSByteCountFormatter stringFromByteCount:[[transfer speed] longLongValue]  countStyle:NSByteCountFormatterCountStyleMemory]];
        
        TransferTableViewCell *cell = (TransferTableViewCell *)[self.tableView cellForRowAtIndexPath:indexPath];
        [cell.infoLabel setText:[NSString stringWithFormat:@"%@ • %@", percentageCompleted, speed]];
    }
}

- (void)onTransferFinish:(MEGASdk *)api transfer:(MEGATransfer *)transfer error:(MEGAError *)error {
    if ([error type]) {
        if ([error type] == MEGAErrorTypeApiEIncomplete) {
            [SVProgressHUD showSuccessWithStatus:[NSString stringWithFormat:NSLocalizedString(@"transferCanceled", @"Transfer canceled")]];
            [self removeActiveTransfer:transfer];
            [self.tableView reloadData];
        }
        return;
    }
    
    [self removeActiveTransfer:transfer];
    [self.tableView reloadData];
}

- (void)onTransferTemporaryError:(MEGASdk *)api transfer:(MEGATransfer *)transfer error:(MEGAError *)error {
}

@end
