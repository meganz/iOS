#import "TransfersViewController.h"

#import <Photos/Photos.h>

#import "SVProgressHUD.h"
#import "UIScrollView+EmptyDataSet.h"

#import "NSString+MNZCategory.h"

#import "Helper.h"
#import "MEGASdkManager.h"
#import "MEGAReachabilityManager.h"
#import "MEGAGetThumbnailRequestDelegate.h"
#import "MEGATransferList+MNZCategory.h"
#import "MEGAStore.h"

#import "TransferTableViewCell.h"

@interface TransfersViewController () <UITableViewDelegate, UITableViewDataSource, DZNEmptyDataSetSource, DZNEmptyDataSetDelegate, MEGARequestDelegate, MEGATransferDelegate, TransferTableViewCellDelegate>

@property (weak, nonatomic) IBOutlet UIBarButtonItem *pauseBarButtonItem;
@property (weak, nonatomic) IBOutlet UIBarButtonItem *resumeBarButtonItem;
@property (weak, nonatomic) IBOutlet UIBarButtonItem *cancelBarButtonItem;

@property (weak, nonatomic) IBOutlet UISegmentedControl *transfersSegmentedControl;
@property (weak, nonatomic) IBOutlet UITableView *tableView;

@property (strong, nonatomic) NSMutableArray *transfers;

@property (strong, nonatomic) NSMutableArray<MOUploadTransfer *> *uploadTransfersQueued;

@property (nonatomic, getter=areTransfersPaused) BOOL transfersPaused;

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
    
    self.tableView.tableFooterView = [[UIView alloc] initWithFrame:CGRectZero];
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(internetConnectionChanged) name:kReachabilityChangedNotification object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(handleCoreDataChangeNotification:) name:NSManagedObjectContextObjectsDidChangeNotification object:nil];
    
    self.navigationItem.title = AMLocalizedString(@"transfers", @"Transfers");
    
    [self setNavigationBarButtonItemsEnabled:[MEGAReachabilityManager isReachable]];
    
    [[MEGASdkManager sharedMEGASdk] addMEGATransferDelegate:self];
    [[MEGASdkManager sharedMEGASdkFolder] addMEGATransferDelegate:self];
    [[MEGAReachabilityManager sharedManager] retryPendingConnections];
    [[MEGASdkManager sharedMEGASdkFolder] retryPendingConnections];
    
    if ([[NSUserDefaults standardUserDefaults] boolForKey:@"TransfersPaused"]) {
        self.transfersPaused = YES;
        self.navigationItem.rightBarButtonItems = @[self.cancelBarButtonItem, self.resumeBarButtonItem];
    } else {
        self.transfersPaused = NO;
        self.navigationItem.rightBarButtonItems = @[self.cancelBarButtonItem, self.pauseBarButtonItem];
    }
    
    if (!self.areTransfersPaused) {
        [self reloadView];
    }
}

- (void)viewWillDisappear:(BOOL)animated {
    [super viewWillDisappear:animated];
    
    [[NSNotificationCenter defaultCenter] removeObserver:self name:kReachabilityChangedNotification object:nil];
    [[NSNotificationCenter defaultCenter] removeObserver:self name:NSManagedObjectContextObjectsDidChangeNotification object:nil];

    [[MEGASdkManager sharedMEGASdk] removeMEGATransferDelegate:self];
    [[MEGASdkManager sharedMEGASdkFolder] removeMEGATransferDelegate:self];
    
    [self cleanTransfersList];
}

- (UIInterfaceOrientationMask)supportedInterfaceOrientations {
    return UIInterfaceOrientationMaskAll;
}

- (void)viewWillTransitionToSize:(CGSize)size withTransitionCoordinator:(id<UIViewControllerTransitionCoordinator>)coordinator {
    [super viewWillTransitionToSize:size withTransitionCoordinator:coordinator];
    
    [coordinator animateAlongsideTransition:^(id<UIViewControllerTransitionCoordinatorContext> context) {
        [self.tableView reloadEmptyDataSet];
    } completion:nil];
}

#pragma mark - UITableViewDataSource

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    TransferTableViewCell *cell = [self.tableView dequeueReusableCellWithIdentifier:@"transferCell" forIndexPath:indexPath];

    switch (indexPath.section) {
        case 0: {
            MEGATransfer *transfer = [self.transfers objectAtIndex:indexPath.row];
            [cell configureCellForTransfer:transfer delegate:self];
            break;
        }
            
        case 1: {
            MOUploadTransfer *uploadTransfer = [self.uploadTransfersQueued objectAtIndex:indexPath.row];
            [cell configureCellForQueuedTransfer:uploadTransfer delegate:self];
            break;
        }
    }
    
    return cell;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    switch (section) {
        case 0:
            return self.transfers.count;

        case 1:
            return self.uploadTransfersQueued.count;
            
        default:
            return 0;
    }
}

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    NSInteger numberOfSections = 0;
    switch (self.transfersSegmentedControl.selectedSegmentIndex) {
        case UISegmentedControlNoSegment:
        case 0: //All
        case 2: //Uploads
            numberOfSections = 2;
            break;
            
        case 1: //Downloads
            numberOfSections = 1;
            break;
    }
    
    return numberOfSections;
}

#pragma mark - Private

- (void)reloadView {
    [self cleanTransfersList];
    
    if (self.areTransfersPaused) {
        [self.tableView reloadData];
    } else {
        self.transfers = [NSMutableArray new];
        
        switch (self.transfersSegmentedControl.selectedSegmentIndex) {
            case UISegmentedControlNoSegment:
            case 0:
                [self getAllTransfers];
                break;
                
            case 1:
                [self getDownloadTransfers];
                break;
                
            case 2:
                [self getUploadTransfers];
                break;
        }
        
        [self sortTransfers];
        [self.tableView reloadData];
    }
}

- (void)getAllTransfers {
    MEGATransferList *transferList = [[MEGASdkManager sharedMEGASdk] transfers];
    if (transferList.size.integerValue) {
        [self.transfers addObjectsFromArray:transferList.mnz_transfersArrayFromTranferList];
    }
    
    transferList = [[MEGASdkManager sharedMEGASdkFolder] transfers];
    if (transferList.size.integerValue) {
        [self.transfers addObjectsFromArray:transferList.mnz_transfersArrayFromTranferList];
    }
    
    [self getQueuedUploadTransfers];
}

- (void)getDownloadTransfers {
    MEGATransferList *downloadTransferList = [[MEGASdkManager sharedMEGASdk] downloadTransfers];
    if (downloadTransferList.size.integerValue) {
        [self.transfers addObjectsFromArray:downloadTransferList.mnz_transfersArrayFromTranferList];
    }
    
    downloadTransferList = [[MEGASdkManager sharedMEGASdkFolder] downloadTransfers];
    if (downloadTransferList.size.integerValue) {
        [self.transfers addObjectsFromArray:downloadTransferList.mnz_transfersArrayFromTranferList];
    }
}

- (void)getUploadTransfers {
    MEGATransferList *uploadTransferList = [[MEGASdkManager sharedMEGASdk] uploadTransfers];
    if (uploadTransferList.size.integerValue) {
        [self.transfers addObjectsFromArray:uploadTransferList.mnz_transfersArrayFromTranferList];
    }
    
    uploadTransferList = [[MEGASdkManager sharedMEGASdkFolder] uploadTransfers];
    if (uploadTransferList.size.integerValue) {
        [self.transfers addObjectsFromArray:uploadTransferList.mnz_transfersArrayFromTranferList];
    }
    
    [self getQueuedUploadTransfers];
}

- (void)sortTransfers {
    NSMutableArray *completingTransfers = [NSMutableArray new];
    NSMutableArray *activeTransfers = [NSMutableArray new];
    NSMutableArray *queuedTransfers = [NSMutableArray new];
    NSMutableArray *inactiveTransfers = [NSMutableArray new];
    
    NSArray *tempTransfersArray = [NSArray arrayWithArray:self.transfers.copy];
    for (MEGATransfer *transfer in tempTransfersArray) {
        switch (transfer.state) {
            case MEGATransferStateQueued:
                [queuedTransfers addObject:transfer];
                break;
                
            case MEGATransferStateActive:
                [activeTransfers addObject:transfer];
                break;
                
            case MEGATransferStateCompleting:
                [completingTransfers addObject:transfer];
                break;
                
            default:
                [inactiveTransfers addObject:transfer];
                break;
        }
    }
    
    [self.transfers removeAllObjects];
    [self.transfers addObjectsFromArray:completingTransfers];
    [self.transfers addObjectsFromArray:activeTransfers];
    [self.transfers addObjectsFromArray:queuedTransfers];
    [self.transfers addObjectsFromArray:inactiveTransfers];
}

- (void)getQueuedUploadTransfers {
    self.uploadTransfersQueued = [[NSMutableArray alloc] initWithArray:[[MEGAStore shareInstance] fetchUploadTransfers]];
}

- (void)cleanTransfersList {
    [self.transfers removeAllObjects];
    [self.uploadTransfersQueued removeAllObjects];
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
    
    if (direction == 1) {
        [[MEGAStore shareInstance] removeAllUploadTransfers];
    }
}

- (NSIndexPath *)indexPathForTransfer:(MEGATransfer *)transfer {
    for (int i = 0; i < self.transfers.count; i++) {
        MEGATransfer *tempTransfer = [self.transfers objectAtIndex:i];
        if (transfer.tag ==  tempTransfer.tag) {
            return [NSIndexPath indexPathForRow:i inSection:0];
        }
    }
    
    return nil;
}

- (NSIndexPath *)indexPathForUploadTransferQueuedWithLocalIdentifier:(NSString *)localIdentifier {
    for (int i = 0; i < self.uploadTransfersQueued.count; i++) {
        MOUploadTransfer *tempUploadTransfer = [self.uploadTransfersQueued objectAtIndex:i];
        NSString *tempLocalIndentifier = tempUploadTransfer.localIdentifier;
        if ([localIdentifier isEqualToString:tempLocalIndentifier]) {
            return [NSIndexPath indexPathForRow:i inSection:1];
        }
    }
    
    return nil;
}

- (void)internetConnectionChanged {
    BOOL boolValue = [MEGAReachabilityManager isReachable];
    [self setNavigationBarButtonItemsEnabled:boolValue];
    
    [self reloadView];
}

- (void)setNavigationBarButtonItemsEnabled:(BOOL)boolValue {
    self.pauseBarButtonItem.enabled = boolValue;
    self.cancelBarButtonItem.enabled = boolValue;
}

- (void)handleCoreDataChangeNotification:(NSNotification *)notification {
    for (NSManagedObject *managedObject in [notification.userInfo objectForKey:NSDeletedObjectsKey]) {
        if ([managedObject isKindOfClass:MOUploadTransfer.class]) {
            MOUploadTransfer *uploadTransfer = (MOUploadTransfer *)managedObject;
            [self deleteUploadQueuedTransferWithLocalIdentifier:uploadTransfer.localIdentifier];
        }
    }
}

- (void)deleteUploadQueuedTransferWithLocalIdentifier:(NSString *)localIdentifier {
    NSIndexPath *indexPath = [self indexPathForUploadTransferQueuedWithLocalIdentifier:localIdentifier];
    if (indexPath) {
        [self.tableView beginUpdates];
        [self.tableView deleteRowsAtIndexPaths:@[indexPath] withRowAnimation:UITableViewRowAnimationAutomatic];
        [self.uploadTransfersQueued removeObjectAtIndex:indexPath.row];
        [self.tableView endUpdates];
    }
}

- (void)deleteUploadTransfer:(MEGATransfer *)transfer {
    NSIndexPath *indexPath = [self indexPathForTransfer:transfer];
    if (indexPath) {
        [self.tableView beginUpdates];
        [self.tableView deleteRowsAtIndexPaths:@[indexPath] withRowAnimation:UITableViewRowAnimationAutomatic];
        [self.transfers removeObjectAtIndex:indexPath.row];
        [self.tableView endUpdates];
    }
}

- (NSInteger)numberOfActiveTransfers {
    NSInteger numberOfActiveTransfers = 0;
    for (MEGATransfer *transfer in self.transfers) {
        if (transfer.state == MEGATransferStateActive) {
            numberOfActiveTransfers += 1;
        }
    }
    
    return numberOfActiveTransfers;
}

- (NSInteger)numberOfQueuedTransfers {
    NSInteger numberOfQueuedTransfers = 0;
    for (MEGATransfer *transfer in self.transfers) {
        if (transfer.state == MEGATransferStateQueued) {
            numberOfQueuedTransfers += 1;
        }
    }
    
    return numberOfQueuedTransfers;
}

- (NSInteger)numberOfPausedTransfers {
    NSInteger numberOfPausedTransfers = 0;
    for (MEGATransfer *transfer in self.transfers) {
        if (transfer.state == MEGATransferStatePaused) {
            numberOfPausedTransfers += 1;
        }
    }
    
    return numberOfPausedTransfers;
}

#pragma mark - IBActions

- (IBAction)transfersTypeSegmentedControlValueChanged:(UISegmentedControl *)sender {
    if (!self.areTransfersPaused) {
        [self reloadView];
    }
}

- (IBAction)pauseTransfersAction:(UIBarButtonItem *)sender {
    self.navigationItem.rightBarButtonItems = @[self.cancelBarButtonItem, self.resumeBarButtonItem];
    [[MEGASdkManager sharedMEGASdk] pauseTransfers:YES delegate:self];
    [[MEGASdkManager sharedMEGASdkFolder] pauseTransfers:YES delegate:self];
}

- (IBAction)resumeTransfersAction:(UIBarButtonItem *)sender {
    self.navigationItem.rightBarButtonItems = @[self.cancelBarButtonItem, self.pauseBarButtonItem];
    [[MEGASdkManager sharedMEGASdk] pauseTransfers:NO delegate:self];
    [[MEGASdkManager sharedMEGASdkFolder] pauseTransfers:NO delegate:self];
}

- (IBAction)cancelTransfersAction:(UIBarButtonItem *)sender {
    if ((self.transfers.count == 0) && (self.uploadTransfersQueued.count == 0)) {
        return;
    }
    
    NSString *transfersTypeString;
    switch (self.transfersSegmentedControl.selectedSegmentIndex) {
        case UISegmentedControlNoSegment:
        case 0: { //All
            transfersTypeString = AMLocalizedString(@"allInUppercaseTransfers", @"ALL transfers");
            break;
        }
            
        case 1: { //Downloads
            transfersTypeString = AMLocalizedString(@"downloadInUppercaseTransfers", @"DOWNLOAD transfers");
            break;
        }
            
        case 2: { //Uploads
            transfersTypeString = AMLocalizedString(@"uploadInUppercaseTransfers", @"UPLOAD transfers");
            break;
        }
    }
    
    UIAlertController *cancelTransfersAlert = [UIAlertController alertControllerWithTitle:AMLocalizedString(@"cancelTransfersTitle", @"Cancel transfers") message:[NSString stringWithFormat:AMLocalizedString(@"cancelTransfersText", @"Do you want to cancel %@?"), transfersTypeString] preferredStyle:UIAlertControllerStyleAlert];
    [cancelTransfersAlert addAction:[UIAlertAction actionWithTitle:AMLocalizedString(@"cancel", @"Button title to cancel something") style:UIAlertActionStyleCancel handler:nil]];
    
    [cancelTransfersAlert addAction:[UIAlertAction actionWithTitle:AMLocalizedString(@"ok", nil) style:UIAlertActionStyleDefault handler:^(UIAlertAction *action) {
        switch (self.transfersSegmentedControl.selectedSegmentIndex) {
            case UISegmentedControlNoSegment:
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
        
        [self reloadView];
    }]];
    
    [self presentViewController:cancelTransfersAlert animated:YES completion:nil];
}

#pragma mark - DZNEmptyDataSetSource

- (NSAttributedString *)titleForEmptyDataSet:(UIScrollView *)scrollView {
    NSString *text;
    if ([MEGAReachabilityManager isReachable]) {
        if (self.areTransfersPaused) {
            text = AMLocalizedString(@"transfersEmptyState_titlePaused", nil);
        } else {
            switch (self.transfersSegmentedControl.selectedSegmentIndex) {
                case UISegmentedControlNoSegment:
                case 0: //All
                    text = AMLocalizedString(@"transfersEmptyState_titleAll", @"Title shown when the there's no transfers and they aren't paused");
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
    
    return [[NSAttributedString alloc] initWithString:text attributes:[Helper titleAttributesForEmptyState]];
}

- (UIImage *)imageForEmptyDataSet:(UIScrollView *)scrollView {
    UIImage *image;
    if ([MEGAReachabilityManager isReachable]) {
        if (self.areTransfersPaused) {
            image = [UIImage imageNamed:@"pausedTransfersEmptyState"];
        } else {
            switch (self.transfersSegmentedControl.selectedSegmentIndex) {
                case UISegmentedControlNoSegment:
                case 0: //All
                    image = [UIImage imageNamed:@"transfersEmptyState"];
                    break;
                    
                case 1: //Downloads
                    image = [UIImage imageNamed:@"downloadsEmptyState"];
                    break;
                    
                case 2: //Uploads
                    image = [UIImage imageNamed:@"uploadsEmptyState"];
                    break;
            }
        }
    } else {
        image = [UIImage imageNamed:@"noInternetEmptyState"];
    }
    return image;
}

- (UIColor *)backgroundColorForEmptyDataSet:(UIScrollView *)scrollView {
    return UIColor.whiteColor;
}

- (CGFloat)spaceHeightForEmptyDataSet:(UIScrollView *)scrollView {
    return [Helper spaceHeightForEmptyState];
}

#pragma mark - MEGARequestDelegate

- (void)onRequestFinish:(MEGASdk *)api request:(MEGARequest *)request error:(MEGAError *)error {
    if (error.type) {
        return;
    }
    
    switch ([request type]) {
        case MEGARequestTypePauseTransfers: {
            [[NSUserDefaults standardUserDefaults] setBool:request.flag forKey:@"TransfersPaused"];
            self.transfersPaused = request.flag;
            [self reloadView];
            break;
        }
            
        case MEGARequestTypeCancelTransfers: {
            [self reloadView];
            [SVProgressHUD showImage:[UIImage imageNamed:@"hudMinus"] status:AMLocalizedString(@"transfersCancelled", nil)];
            break;
        }
            
        default:
            break;
    }
}

#pragma mark - MEGATransferDelegate

- (void)onTransferStart:(MEGASdk *)api transfer:(MEGATransfer *)transfer {
    if (transfer.type == MEGATransferTypeUpload) {
        if ([transfer.appData containsString:@">localIdentifier"]) {
            NSString *localIdentifier = [transfer.appData mnz_stringBetweenString:@">localIdentifier=" andString:@""];
            NSIndexPath *oldIndexPath = [self indexPathForUploadTransferQueuedWithLocalIdentifier:localIdentifier];
            if (oldIndexPath) {
                [self.tableView beginUpdates];
                
                NSInteger newTransferIndex = [self numberOfActiveTransfers];
                [self.transfers insertObject:transfer atIndex:newTransferIndex];
                
                TransferTableViewCell *cell = (TransferTableViewCell *)[self.tableView cellForRowAtIndexPath:oldIndexPath];
                [cell reconfigureCellWithTransfer:transfer];
                
                NSIndexPath *newIndexPath = [NSIndexPath indexPathForRow:newTransferIndex inSection:0];
                [self.tableView moveRowAtIndexPath:oldIndexPath toIndexPath:newIndexPath];
                [self.uploadTransfersQueued removeObjectAtIndex:oldIndexPath.row];
                [[MEGAStore shareInstance] deleteUploadTransferWithLocalIdentifier:localIdentifier];
                [self.tableView endUpdates];
            }
        } else {
            [self.tableView beginUpdates];
            NSInteger newTransferIndex = [self numberOfActiveTransfers];
            [self.transfers insertObject:transfer atIndex:newTransferIndex];
            NSIndexPath *newIndexPath = [NSIndexPath indexPathForRow:newTransferIndex inSection:0];
            [self.tableView insertRowsAtIndexPaths:@[newIndexPath] withRowAnimation:UITableViewRowAnimationAutomatic];
            [self.tableView endUpdates];
        }
    } else if (transfer.type == MEGATransferTypeDownload) {
        NSIndexPath *indexPath = [self indexPathForTransfer:transfer];
        [self.transfers replaceObjectAtIndex:indexPath.row withObject:transfer];
    }
}

- (void)onTransferUpdate:(MEGASdk *)api transfer:(MEGATransfer *)transfer {
    NSIndexPath *indexPath = [self indexPathForTransfer:transfer];
    if (indexPath) {
        TransferTableViewCell *cell = (TransferTableViewCell *)[self.tableView cellForRowAtIndexPath:indexPath];
        if (transfer.state == MEGATransferStateActive) {
            [cell reloadThumbnailImage];
            [cell updatePercentAndSpeedLabelsForTransfer:transfer];
        } else if (transfer.state == MEGATransferStateCompleting) {
            [cell configureCellWithTransferState:transfer.state];
        }
    }
}

- (void)onTransferFinish:(MEGASdk *)api transfer:(MEGATransfer *)transfer error:(MEGAError *)error {
    if (transfer.isStreamingTransfer) {
        return;
    }
    
    if (error.type) {
        if (error.type == MEGAErrorTypeApiEIncomplete) {
            [SVProgressHUD showImage:[UIImage imageNamed:@"hudMinus"] status:AMLocalizedString(@"transferCancelled", nil)];
        }
    }
    
    [self deleteUploadTransfer:transfer];
}

#pragma mark - TransferTableViewCellDelegate

- (void)pauseTransfer:(MEGATransfer *)transfer {
    NSIndexPath *oldIndexPath = [self indexPathForTransfer:transfer];
    [self.transfers replaceObjectAtIndex:oldIndexPath.row withObject:transfer];
    
    [self sortTransfers];
    [self.tableView reloadSections:[NSIndexSet indexSetWithIndex:0] withRowAnimation:UITableViewRowAnimationAutomatic];
}

- (void)cancelQueuedUploadTransfer:(NSString *)localIdentifier {
    NSIndexPath *indexPath = [self indexPathForUploadTransferQueuedWithLocalIdentifier:localIdentifier];
    if (localIdentifier && indexPath) {
        [SVProgressHUD showImage:[UIImage imageNamed:@"hudMinus"] status:AMLocalizedString(@"transferCancelled", nil)];

        [self.tableView beginUpdates];
        [self.tableView deleteRowsAtIndexPaths:@[indexPath] withRowAnimation:UITableViewRowAnimationAutomatic];
        [self.uploadTransfersQueued removeObjectAtIndex:indexPath.row];
        [[MEGAStore shareInstance] deleteUploadTransferWithLocalIdentifier:localIdentifier];
        [self.tableView endUpdates];
    }
}

@end
