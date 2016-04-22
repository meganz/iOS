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
#import "MEGAReachabilityManager.h"
#import "Helper.h"
#import "NSMutableAttributedString+MNZCategory.h"

#import "TransfersViewController.h"
#import "TransferTableViewCell.h"

@interface TransfersViewController () <UINavigationControllerDelegate, UITableViewDelegate, UITableViewDataSource, UIAlertViewDelegate, DZNEmptyDataSetSource, DZNEmptyDataSetDelegate, MEGARequestDelegate, MEGATransferDelegate> {
    BOOL areTransfersPaused;
}

@property (strong, nonatomic) IBOutlet UIBarButtonItem *pauseBarButtonItem;
@property (strong, nonatomic) IBOutlet UIBarButtonItem *resumeBarButtonItem;
@property (strong, nonatomic) IBOutlet UIBarButtonItem *cancelBarButtonItem;
@property (strong, nonatomic) IBOutlet UIBarButtonItem *negativeSpaceBarButtonItem;

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
    
    [self.transfersSegmentedControl setTitle:AMLocalizedString(@"all", @"All") forSegmentAtIndex:0];
    [self.transfersSegmentedControl setTitle:AMLocalizedString(@"downloads", @"Downloads") forSegmentAtIndex:1];
    [self.transfersSegmentedControl setTitle:AMLocalizedString(@"uploads", @"Uploads") forSegmentAtIndex:2];
    
    self.allActiveTransfersMutableDictionary = [[NSMutableDictionary alloc] init];
    self.allQueuedTransfersMutableDictionary = [[NSMutableDictionary alloc] init];
    
    self.allTransfersIndexPathMutableDictionary = [[NSMutableDictionary alloc] init];
    self.downloadTransfersIndexPathMutableDictionary = [[NSMutableDictionary alloc] init];
    self.uploadTransfersIndexPathMutableDictionary = [[NSMutableDictionary alloc] init];
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(internetConnectionChanged) name:kReachabilityChangedNotification object:nil];
    
    [self.navigationItem setTitle:AMLocalizedString(@"transfers", @"Transfers")];
    
    [self setNavigationBarButtonItemsEnabled:[MEGAReachabilityManager isReachable]];
    
    [[MEGASdkManager sharedMEGASdk] addMEGATransferDelegate:self];
    [[MEGASdkManager sharedMEGASdkFolder] addMEGATransferDelegate:self];
    [[MEGASdkManager sharedMEGASdk] retryPendingConnections];
    [[MEGASdkManager sharedMEGASdkFolder] retryPendingConnections];
    
    self.negativeSpaceBarButtonItem = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemFixedSpace target:nil action:nil];
    if (([[UIDevice currentDevice] userInterfaceIdiom] == UIUserInterfaceIdiomPad)) {
        [self.negativeSpaceBarButtonItem setWidth:-5.0];
    } else {
        [self.negativeSpaceBarButtonItem setWidth:-1.0];
    }
    
    if ([[NSUserDefaults standardUserDefaults] boolForKey:@"TransfersPaused"]) {
        areTransfersPaused = YES;
        [self.navigationItem setRightBarButtonItems:@[self.negativeSpaceBarButtonItem, self.cancelBarButtonItem, self.resumeBarButtonItem] animated:YES];
    } else {
        areTransfersPaused = NO;
        [self.navigationItem setRightBarButtonItems:@[self.negativeSpaceBarButtonItem, self.cancelBarButtonItem, self.pauseBarButtonItem] animated:YES];
    }
    
    [self transfersList];
    
    if (self.transfersSegmentedControl.selectedSegmentIndex == 1) {
        [self transfersForDirection:0];
    } else if (self.transfersSegmentedControl.selectedSegmentIndex == 2) {
        [self transfersForDirection:1];
    }
    
    [self.tableView reloadData];
}

- (void)viewWillDisappear:(BOOL)animated {
    [super viewWillDisappear:animated];
    
    [[NSNotificationCenter defaultCenter] removeObserver:self name:kReachabilityChangedNotification object:nil];
    
    [[MEGASdkManager sharedMEGASdk] removeMEGATransferDelegate:self];
    [[MEGASdkManager sharedMEGASdkFolder] removeMEGATransferDelegate:self];
    
    [self cleanTransfersList];
}

- (UIInterfaceOrientationMask)supportedInterfaceOrientations {
    return UIInterfaceOrientationMaskPortrait;
}

- (UIInterfaceOrientation)preferredInterfaceOrientationForPresentation {
    return UIInterfaceOrientationPortrait;
}

#pragma mark - UITableViewDataSource

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    
    TransferTableViewCell *cell;
    
    MEGATransfer *transfer;
    if ([indexPath section] == 0) { //ACTIVE TRANSFERS
        cell = [self.tableView dequeueReusableCellWithIdentifier:@"activeTransferCell" forIndexPath:indexPath];
        if (cell == nil) {
            cell = [[TransferTableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:@"activeTransferCell"];
        }
        
        switch (self.transfersSegmentedControl.selectedSegmentIndex) {
            case 0: { //All
                NSArray *allActiveTransfersArray = [self.allActiveTransfersMutableDictionary allValues];
                NSUInteger count = allActiveTransfersArray.count;
                
                if (count == 0) {
                    break;
                }
                
                if (count > indexPath.row) {
                    transfer = [allActiveTransfersArray objectAtIndex:indexPath.row];
                    if ([transfer type] == MEGATransferTypeDownload) {
                        [self.allTransfersIndexPathMutableDictionary setObject:indexPath forKey:[self keyForTransfer:transfer]];
                    } else {
                        [self.allTransfersIndexPathMutableDictionary setObject:indexPath forKey:[NSNumber numberWithInteger:transfer.tag]];
                    }
                }
                
                break;
            }
                
            case 1: { //Downloads
                
                NSArray *downloadActiveTransfersArray = [self.downloadActiveTransfersMutableDictionary allValues];
                NSUInteger count = downloadActiveTransfersArray.count;
                
                if (count == 0) {
                    break;
                }
                
                if (count > indexPath.row) {
                    transfer = [downloadActiveTransfersArray objectAtIndex:indexPath.row];
                    [self.downloadTransfersIndexPathMutableDictionary setObject:indexPath forKey:[self keyForTransfer:transfer]];
                }
                
                break;
            }
                
            case 2: { //Uploads
                
                NSArray *uploadActiveTransfersArray = [self.uploadActiveTransfersMutableDictionary allValues];
                NSUInteger count = uploadActiveTransfersArray.count;
                if (count == 0) {
                    break;
                }
                
                if (count > indexPath.row) {
                    transfer = [uploadActiveTransfersArray objectAtIndex:indexPath.row];
                    [self.uploadTransfersIndexPathMutableDictionary setObject:indexPath forKey:[NSNumber numberWithInteger:transfer.tag]];
                }
                
                break;
            }
        }
        if ([transfer type] == MEGATransferTypeDownload) {
            [cell.arrowImageView setImage:[Helper downloadingTransferImage]];
            [cell.percentageLabel setTextColor:megaGreen];
        } else {
            [cell.arrowImageView setImage:[Helper uploadingTransferImage]];
            [cell.percentageLabel setTextColor:megaBlue];
        }
        
    } else { //QUEUED TRANSFERS
        cell = [self.tableView dequeueReusableCellWithIdentifier:@"transferCell" forIndexPath:indexPath];
        if (cell == nil) {
            cell = [[TransferTableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:@"transferCell"];
        }
        
        switch (self.transfersSegmentedControl.selectedSegmentIndex) {
            case 0: { //All
                NSArray *allQueuedTransfersArray = [self.allQueuedTransfersMutableDictionary allValues];
                NSUInteger count = allQueuedTransfersArray.count;
                
                if (count == 0) {
                    break;
                }
                
                if (count > indexPath.row) {
                    transfer = [allQueuedTransfersArray objectAtIndex:indexPath.row];
                    if ([transfer type] == MEGATransferTypeDownload) {
                        [self.allTransfersIndexPathMutableDictionary setObject:indexPath forKey:[self keyForTransfer:transfer]];
                    } else {
                        [self.allTransfersIndexPathMutableDictionary setObject:indexPath forKey:[NSNumber numberWithInteger:transfer.tag]];
                    }
                }
                
                break;
            }
                
            case 1: { //Downloads
                NSArray *downloadQueuedTransfersArray = [self.downloadQueuedTransfersMutableDictionary allValues];
                NSUInteger count = downloadQueuedTransfersArray.count;
               
                if (count == 0) {
                    break;
                }
                
                if (count > indexPath.row) {
                    transfer = [downloadQueuedTransfersArray objectAtIndex:indexPath.row];
                    [self.downloadTransfersIndexPathMutableDictionary setObject:indexPath forKey:[self keyForTransfer:transfer]];
                }
                
                break;
            }
                
            case 2: { //Uploads
                NSArray *uploadQueuedTransfersArray = [self.uploadQueuedTransfersMutableDictionary allValues];
                NSUInteger count = uploadQueuedTransfersArray.count;
                if (count == 0) {
                    break;
                }
                
                if (count > indexPath.row) {
                    transfer = [uploadQueuedTransfersArray objectAtIndex:indexPath.row];
                    [self.uploadTransfersIndexPathMutableDictionary setObject:indexPath forKey:[NSNumber numberWithInteger:transfer.tag]];
                }
                
                break;
            }
        }
        
        [cell.percentageLabel setText:AMLocalizedString(@"queued", @"Queued")];
        if ([transfer type] == MEGATransferTypeDownload) {
            [cell.arrowImageView setImage:[Helper downloadQueuedTransferImage]];
        } else {
            [cell.arrowImageView setImage:[Helper uploadQueuedTransferImage]];
        }
    }
    
    NSString *fileName = [transfer fileName];
    [cell.nameLabel setText:[[MEGASdkManager sharedMEGASdk] unescapeFsIncompatible:fileName]];
    [cell.iconImageView setImage:[Helper imageForExtension:fileName.pathExtension]];
    
    UIView *view = [[UIView alloc] init];
    [view setBackgroundColor:megaInfoGray];
    [cell setSelectedBackgroundView:view];
    
    [cell setSeparatorInset:UIEdgeInsetsMake(0.0, 60.0, 0.0, 0.0)];
    
    [cell setTransferTag:transfer.tag];
    
    return cell;
}

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return 2;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    NSInteger numberOfRows = 0;
    
    if ([MEGAReachabilityManager isReachable]) {
        if (!areTransfersPaused) {
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
        }
    }
    
    if (numberOfRows == 0) {
        [self.cancelBarButtonItem setEnabled:NO];
        [self.tableView setSeparatorStyle:UITableViewCellSeparatorStyleNone];
    } else {
        [self.cancelBarButtonItem setEnabled:YES];
        [self.tableView setSeparatorStyle:UITableViewCellSeparatorStyleSingleLine];
    }
    
    return numberOfRows;
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

- (void)removeTransfer:(MEGATransfer *)transfer {
    if ([transfer type] == MEGATransferTypeDownload) {
        NSString *key = [self keyForTransfer:transfer];
        [self.allActiveTransfersMutableDictionary removeObjectForKey:key];
        [self.allQueuedTransfersMutableDictionary removeObjectForKey:key];
        if (self.transfersSegmentedControl.selectedSegmentIndex == 1) {
            [self.downloadActiveTransfersMutableDictionary removeObjectForKey:key];
            [self.downloadQueuedTransfersMutableDictionary removeObjectForKey:key];
        }
        
        [self.allTransfersIndexPathMutableDictionary removeObjectForKey:key];
        [self.downloadTransfersIndexPathMutableDictionary removeObjectForKey:key];
    } else {
        NSNumber *key = [NSNumber numberWithInteger:transfer.tag];
        [self.allActiveTransfersMutableDictionary removeObjectForKey:key];
        [self.allQueuedTransfersMutableDictionary removeObjectForKey:key];
        if (self.transfersSegmentedControl.selectedSegmentIndex == 2) {
            [self.uploadActiveTransfersMutableDictionary removeObjectForKey:key];
            [self.uploadQueuedTransfersMutableDictionary removeObjectForKey:key];
        }
        
        [self.allTransfersIndexPathMutableDictionary removeObjectForKey:key];
        [self.uploadTransfersIndexPathMutableDictionary removeObjectForKey:key];
    }
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

- (NSIndexPath *)indexPathForTransfer:(MEGATransfer *)transfer {
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
                return nil;
            }
            indexPath = [self.downloadTransfersIndexPathMutableDictionary objectForKey:[self keyForTransfer:transfer]];
            break;
        }
            
        case 2: { //Uploads
            if ([transfer type] == MEGATransferTypeDownload) {
                return nil;
            }
            indexPath = [self.uploadTransfersIndexPathMutableDictionary objectForKey:[NSNumber numberWithInteger:transfer.tag]];
            break;
        }
    }
    return indexPath;
}

- (void)internetConnectionChanged {
    BOOL boolValue = [MEGAReachabilityManager isReachable];
    [self setNavigationBarButtonItemsEnabled:boolValue];
    
    [self.tableView reloadData];
}

- (void)setNavigationBarButtonItemsEnabled:(BOOL)boolValue {
    [self.pauseBarButtonItem setEnabled:boolValue];
    [self.cancelBarButtonItem setEnabled:boolValue];
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
    [self.navigationItem setRightBarButtonItems:@[self.negativeSpaceBarButtonItem, self.cancelBarButtonItem, self.resumeBarButtonItem] animated:NO];
    [[MEGASdkManager sharedMEGASdk] pauseTransfers:YES delegate:self];
    [[MEGASdkManager sharedMEGASdkFolder] pauseTransfers:YES delegate:self];
}

- (IBAction)resumeTransfersAction:(UIBarButtonItem *)sender {
    [self.navigationItem setRightBarButtonItems:@[self.negativeSpaceBarButtonItem, self.cancelBarButtonItem, self.pauseBarButtonItem] animated:NO];
    [[MEGASdkManager sharedMEGASdk] pauseTransfers:NO delegate:self];
    [[MEGASdkManager sharedMEGASdkFolder] pauseTransfers:NO delegate:self];
}

- (IBAction)cancelTransfersAction:(UIBarButtonItem *)sender {
    NSString *transfersTypeString;
    switch (self.transfersSegmentedControl.selectedSegmentIndex) {
        case 0: { //All
            if ((self.allActiveTransfersMutableDictionary.count == 0) && (self.allQueuedTransfersMutableDictionary.count == 0)) {
                return;
            }
            transfersTypeString = AMLocalizedString(@"allInUppercaseTransfers", @"ALL transfers");
            break;
        }
            
        case 1: { //Downloads
            if ((self.downloadActiveTransfersMutableDictionary.count == 0) && (self.downloadQueuedTransfersMutableDictionary.count == 0)) {
                return;
            }
            transfersTypeString = AMLocalizedString(@"downloadInUppercaseTransfers", @"DOWNLOAD transfers");
            break;
        }
            
        case 2: { //Uploads
            if ((self.uploadActiveTransfersMutableDictionary.count == 0) && (self.uploadQueuedTransfersMutableDictionary.count == 0)) {
                return;
            }
            transfersTypeString = AMLocalizedString(@"uploadInUppercaseTransfers", @"UPLOAD transfers");
            break;
        }
    }
    
    UIAlertView *alertView = [[UIAlertView alloc] initWithTitle:AMLocalizedString(@"cancelTransfersTitle", @"Cancel transfers")
                                                        message:[NSString stringWithFormat:AMLocalizedString(@"cancelTransfersText", @"Do you want to cancel %@?"), transfersTypeString]
                                                       delegate:self
                                              cancelButtonTitle:AMLocalizedString(@"cancel", nil)
                                              otherButtonTitles:AMLocalizedString(@"ok", nil), nil];
    [alertView setTag:0];
    [alertView show];
}

#pragma mark - DZNEmptyDataSetSource

- (NSAttributedString *)titleForEmptyDataSet:(UIScrollView *)scrollView {
    
    [self.tableView setSeparatorStyle:UITableViewCellSeparatorStyleNone];
    
    NSString *text;
    if ([MEGAReachabilityManager isReachable]) {
        if (areTransfersPaused) {
            return [NSMutableAttributedString mnz_darkenSectionTitleInString:AMLocalizedString(@"transfersEmptyState_titlePaused", nil) sectionTitle:AMLocalizedString(@"transfers", @"Title of the Transfers section")];
        } else {
            switch (self.transfersSegmentedControl.selectedSegmentIndex) {
                case 0: //All
                    return [NSMutableAttributedString mnz_darkenSectionTitleInString:AMLocalizedString(@"transfersEmptyState_titleAll", @"Title shown when the there's no transfers and they aren't paused") sectionTitle:AMLocalizedString(@"transfers", @"Title of the Transfers section")];
                    break;
                    
                case 1: //Downloads
                    text = AMLocalizedString(@"transfersEmptyState_titleDownload", @"No Download Transfers");
                    break;
                    
                case 2: //Uploads
                    text = AMLocalizedString(@"transfersEmptyState_titleUpload", @"No Uploads Transfers");
                    break;
            }
        }
    } else {
        text = AMLocalizedString(@"noInternetConnection",  @"No Internet Connection");
    }
    
    NSDictionary *attributes = @{NSFontAttributeName:[UIFont fontWithName:kFont size:18.0], NSForegroundColorAttributeName:megaGray};
    
    return [[NSAttributedString alloc] initWithString:text attributes:attributes];
}

- (UIImage *)imageForEmptyDataSet:(UIScrollView *)scrollView {
    UIImage *image;
    if ([MEGAReachabilityManager isReachable]) {
        if (areTransfersPaused) {
            image = [UIImage imageNamed:@"transfersPaused"];
        } else {
            switch (self.transfersSegmentedControl.selectedSegmentIndex) {
                case 0: //All
                    image = [UIImage imageNamed:@"emptyTransfers"];
                    break;
                    
                case 1: //Downloads
                    image = [UIImage imageNamed:@"emptyTransfersDownloads"];
                    break;
                    
                case 2: //Uploads
                    image = [UIImage imageNamed:@"emptyTransfersUploads"];
                    break;
            }
        }
    } else {
        image = [UIImage imageNamed:@"noInternetConnection"];
    }
    return image;
}

- (UIColor *)backgroundColorForEmptyDataSet:(UIScrollView *)scrollView {
    return [UIColor whiteColor];
}

- (CGFloat)spaceHeightForEmptyDataSet:(UIScrollView *)scrollView {
    return 40.0f;
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
            [[NSUserDefaults standardUserDefaults] setBool:[request flag] forKey:@"TransfersPaused"];
            areTransfersPaused = [request flag];
            [self.tableView reloadData];
            break;
        }
            
        case MEGARequestTypeCancelTransfers: {
            [self cleanTransfersList];
            [self.tableView reloadData];
            [SVProgressHUD showImage:[UIImage imageNamed:@"hudMinus"] status:AMLocalizedString(@"transfersCancelled", nil)];
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
    
    NSIndexPath *indexPath = [self indexPathForTransfer:transfer];
    if (indexPath != nil && ([indexPath section] == 0)) {
        float percentage = ([[transfer transferredBytes] floatValue] / [[transfer totalBytes] floatValue] * 100);
        NSString *percentageCompleted = [NSString stringWithFormat:@"%.f %%", percentage];
        NSString *speed = [NSString stringWithFormat:@"%@/s", [NSByteCountFormatter stringFromByteCount:[[transfer speed] longLongValue]  countStyle:NSByteCountFormatterCountStyleMemory]];
        
        TransferTableViewCell *cell = (TransferTableViewCell *)[self.tableView cellForRowAtIndexPath:indexPath];
        if ([transfer type] == MEGATransferTypeDownload) {
            [cell.arrowImageView setImage:[Helper downloadingTransferImage]];
            [cell.percentageLabel setTextColor:megaGreen];
        } else {
            [cell.arrowImageView setImage:[Helper uploadingTransferImage]];
            [cell.percentageLabel setTextColor:megaBlue];
        }
        [cell.percentageLabel setText:percentageCompleted];
        [cell.speedLabel setText:speed];
    }
}

- (void)onTransferFinish:(MEGASdk *)api transfer:(MEGATransfer *)transfer error:(MEGAError *)error {
    if (transfer.isStreamingTransfer) {
        return;
    }
    
    if ([error type]) {
        if ([error type] == MEGAErrorTypeApiEIncomplete) {
            [SVProgressHUD showImage:[UIImage imageNamed:@"hudMinus"] status:AMLocalizedString(@"transferCancelled", nil)];
            [self removeTransfer:transfer];
            [self.tableView reloadData];
        }
        return;
    }
    
    [self removeTransfer:transfer];
    [self.tableView reloadData];
}

- (void)onTransferTemporaryError:(MEGASdk *)api transfer:(MEGATransfer *)transfer error:(MEGAError *)error {
}

@end
