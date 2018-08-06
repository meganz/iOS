#import "TransfersViewController.h"

#import "SVProgressHUD.h"
#import "UIScrollView+EmptyDataSet.h"

#import "MEGASdkManager.h"
#import "MEGAReachabilityManager.h"
#import "Helper.h"
#import "MEGAGetThumbnailRequestDelegate.h"

#import "TransferTableViewCell.h"

#import "MEGAStore.h"
#import <Photos/Photos.h>

@interface TransfersViewController () <UINavigationControllerDelegate, UITableViewDelegate, UITableViewDataSource, DZNEmptyDataSetSource, DZNEmptyDataSetDelegate, MEGARequestDelegate, MEGATransferDelegate, TransferTableViewCellDelegate> {
    BOOL areTransfersPaused;
}

@property (weak, nonatomic) IBOutlet UIBarButtonItem *pauseBarButtonItem;
@property (weak, nonatomic) IBOutlet UIBarButtonItem *resumeBarButtonItem;
@property (weak, nonatomic) IBOutlet UIBarButtonItem *cancelBarButtonItem;

@property (weak, nonatomic) IBOutlet UISegmentedControl *transfersSegmentedControl;
@property (weak, nonatomic) IBOutlet UITableView *tableView;

@property (strong, nonatomic) NSMutableDictionary *transfersMutableDictionary;
@property (strong, nonatomic) NSMutableArray *transfers;

@property (nonatomic) PHFetchResult *uploadTransfersQueued;

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
    
    self.transfersMutableDictionary = [[NSMutableDictionary alloc] init];
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(internetConnectionChanged) name:kReachabilityChangedNotification object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(handleCoreDataChangeNotification:) name:NSManagedObjectContextObjectsDidChangeNotification object:nil];
    
    self.navigationItem.title = AMLocalizedString(@"transfers", @"Transfers");
    
    [self setNavigationBarButtonItemsEnabled:[MEGAReachabilityManager isReachable]];
    
    [[MEGASdkManager sharedMEGASdk] addMEGATransferDelegate:self];
    [[MEGASdkManager sharedMEGASdkFolder] addMEGATransferDelegate:self];
    [[MEGASdkManager sharedMEGASdk] retryPendingConnections];
    [[MEGASdkManager sharedMEGASdkFolder] retryPendingConnections];
    
    if ([[NSUserDefaults standardUserDefaults] boolForKey:@"TransfersPaused"]) {
        areTransfersPaused = YES;
        self.navigationItem.rightBarButtonItems = @[self.cancelBarButtonItem, self.resumeBarButtonItem];
    } else {
        areTransfersPaused = NO;
        self.navigationItem.rightBarButtonItems = @[self.cancelBarButtonItem, self.pauseBarButtonItem];
    }
    
    if (!areTransfersPaused) {
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
    
    TransferTableViewCell *cell;

    switch (indexPath.section) {
        case 0: {
            MEGATransfer *transfer = [self.transfers objectAtIndex:indexPath.row];
            switch (transfer.state) {
                case MEGATransferStateActive:
                    cell = [self.tableView dequeueReusableCellWithIdentifier:@"activeTransferCell" forIndexPath:indexPath];
                    break;
                    
                default:
                    cell = [self.tableView dequeueReusableCellWithIdentifier:@"transferCell" forIndexPath:indexPath];
                    break;
            }
            [cell configureCellForTransfer:transfer delegate:self];
            break;
        }
            
        case 1: {
            PHAsset *asset = [self.uploadTransfersQueued objectAtIndex:indexPath.row];
            cell = [self.tableView dequeueReusableCellWithIdentifier:@"transferCell" forIndexPath:indexPath];
            [cell configureCellForAsset:asset delegate:self];
            break;
        }
            
        default:
            break;
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
    if (self.uploadTransfersQueued.count) {
        return 2;
    } else {
        return 1;
    }
}

#pragma mark - UITableViewDelegate

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    [tableView deselectRowAtIndexPath:indexPath animated:YES];
}

#pragma mark - Private

- (void)reloadView {
    
    [self.transfersMutableDictionary removeAllObjects];
    self.transfers = [NSMutableArray new];

    switch (self.transfersSegmentedControl.selectedSegmentIndex) {
        case 0:
            [self getAllTransfers];
            break;
            
        case 1:
            [self getDownloadTransfers];
            break;
            
        case 2:
            [self getUploadTransfers];
            break;
            
        default:
            [self getAllTransfers];
            break;
    }
    
    [self sortTransfers];
}

- (void)getAllTransfers {
    [self getQueuedUploadTransfers];

    MEGATransferList *transferList = [[MEGASdkManager sharedMEGASdk] transfers];
    if ([transferList.size integerValue] != 0) {
        [self mergeTransfers:transferList];
    }
    
    transferList = [[MEGASdkManager sharedMEGASdkFolder] transfers];
    if ([transferList.size integerValue] != 0) {
        [self mergeTransfers:transferList];
    }
}

- (void)getDownloadTransfers {
    self.uploadTransfersQueued = nil;

    MEGATransferList *transferList = [[MEGASdkManager sharedMEGASdk] downloadTransfers];
    if ([transferList.size integerValue] != 0) {
        [self mergeTransfers:transferList];
    }
    
    transferList = [[MEGASdkManager sharedMEGASdkFolder] downloadTransfers];
    if ([transferList.size integerValue] != 0) {
        [self mergeTransfers:transferList];
    }
}

- (void)getUploadTransfers {
    [self getQueuedUploadTransfers];

    MEGATransferList *transferList = [[MEGASdkManager sharedMEGASdk] uploadTransfers];
    if ([transferList.size integerValue] != 0) {
        [self mergeTransfers:transferList];
    }
    
    transferList = [[MEGASdkManager sharedMEGASdkFolder] uploadTransfers];
    if ([transferList.size integerValue] != 0) {
        [self mergeTransfers:transferList];
    }
}

- (void)mergeTransfers:(MEGATransferList *)transferList {
    NSInteger transferListSize = [transferList.size integerValue];
    for (NSInteger i = 0; i < transferListSize; i++) {
        MEGATransfer *transfer = [transferList transferAtIndex:i];
        if (transfer.type == MEGATransferTypeDownload) {
            [self.transfersMutableDictionary setObject:transfer forKey:[self keyForTransfer:transfer]];
        } else {
            [self.transfersMutableDictionary setObject:transfer forKey:[NSNumber numberWithInteger:transfer.tag]];
        }
    }
}

- (void)sortTransfers {
    NSMutableArray *activeTransfers = [NSMutableArray new];
    NSMutableArray *inactiveTransfers = [NSMutableArray new];
    
    for (MEGATransfer *transfer in self.transfersMutableDictionary.allValues) {
        
        switch (transfer.state) {
                
            case MEGATransferStateActive:
                [activeTransfers addObject:transfer];
                break;
                
            default:
                [inactiveTransfers addObject:transfer];
                break;
        }
    }
    
    [self.transfers addObjectsFromArray:activeTransfers];
    [self.transfers addObjectsFromArray:inactiveTransfers];
    
    [self.tableView reloadData];
}

- (void)getQueuedUploadTransfers {
    NSArray *uploadTransfers = [[MEGAStore shareInstance] fetchUploadTransfers];
    NSMutableArray *localIdentifiers = [NSMutableArray new];
    for (MOUploadTransfer *uploadTransfer in uploadTransfers) {
        [localIdentifiers addObject:uploadTransfer.localIdentifier];
    }
    self.uploadTransfersQueued = [PHAsset fetchAssetsWithLocalIdentifiers:localIdentifiers options:nil];
}

- (void)cleanTransfersList {
    [self.transfersMutableDictionary removeAllObjects];
    [self.transfers removeAllObjects];
    self.uploadTransfersQueued = nil;
}

- (NSString *)keyForTransfer:(MEGATransfer *)transfer {
    return [NSString stringWithFormat:@"%ld_%@", (long)[transfer tag], [NSString stringWithString:[MEGASdk base64HandleForHandle:transfer.nodeHandle] ]];
}

- (void)removeTransfer:(MEGATransfer *)transfer {
    MEGATransfer *tempTransfer = [self.transfersMutableDictionary objectForKey:[self keyForTransfer:transfer]];
    if (tempTransfer) {
        [self.transfers removeObject:tempTransfer];
        [self.transfersMutableDictionary removeObjectForKey:[self keyForTransfer:transfer]];
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
    
    if (direction == 1) {
        [[MEGAStore shareInstance] removeAllUploadTransfers];
    }
}

- (NSIndexPath *)indexPathForTransfer:(MEGATransfer *)transfer {
    for (int i = 0; i < self.transfers.count; i++) {
        if ([[self.transfers objectAtIndex:i] isKindOfClass:MEGATransfer.class]) {
            if (transfer.tag == [[self.transfers objectAtIndex:i] tag]) {
                return [NSIndexPath indexPathForRow:i inSection:0];
            }
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
            dispatch_async(dispatch_get_main_queue(), ^{
                [self reloadView];
            });
        }
    }
}

#pragma mark - IBActions

- (IBAction)transfersTypeSegmentedControlValueChanged:(UISegmentedControl *)sender {
    if (!areTransfersPaused) {
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
    if (self.transfersMutableDictionary.count == 0 && self.uploadTransfersQueued.count == 0) {
        return;
    }
    NSString *transfersTypeString;
    switch (self.transfersSegmentedControl.selectedSegmentIndex) {
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
            case 0: { //All
                [self cancelTransfersForDirection:0];
                [self cancelTransfersForDirection:1];
                self.uploadTransfersQueued = nil;
                break;
            }
                
            case 1: { //Downloads
                [self cancelTransfersForDirection:0];
                break;
            }
                
            case 2: { //Uploads
                [self cancelTransfersForDirection:1];
                self.uploadTransfersQueued = nil;
                break;
            }
        }
        [self.tableView reloadData];
    }]];
    
    [self presentViewController:cancelTransfersAlert animated:YES completion:nil];
}

#pragma mark - DZNEmptyDataSetSource

- (NSAttributedString *)titleForEmptyDataSet:(UIScrollView *)scrollView {
    NSString *text;
    if ([MEGAReachabilityManager isReachable]) {
        if (areTransfersPaused) {
            text = AMLocalizedString(@"transfersEmptyState_titlePaused", nil);
        } else {
            switch (self.transfersSegmentedControl.selectedSegmentIndex) {
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
        if (areTransfersPaused) {
            image = [UIImage imageNamed:@"pausedTransfersEmptyState"];
        } else {
            switch (self.transfersSegmentedControl.selectedSegmentIndex) {
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
            areTransfersPaused = request.flag;
            if (areTransfersPaused) {
                [self cleanTransfersList];
                [self.tableView reloadData];
            } else {
                [self reloadView];
            }
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
    [self reloadView];
}

- (void)onTransferUpdate:(MEGASdk *)api transfer:(MEGATransfer *)transfer {
    
    NSIndexPath *indexPath = [self indexPathForTransfer:transfer];
    
    if (indexPath) {
        [self.transfers replaceObjectAtIndex:indexPath.row withObject:transfer];
    } else {
        return;
    }
    
    if (transfer.state == MEGATransferStateActive) {
        TransferTableViewCell *cell = (TransferTableViewCell *)[self.tableView cellForRowAtIndexPath:indexPath];
        if ([cell.reuseIdentifier isEqualToString:@"activeTransferCell"]) {
            [cell updatePercentAndSpeedLabelsForTransfer:transfer];
        }
    } else if (transfer.state == MEGATransferStateCompleting) {
        [self.tableView reloadRowsAtIndexPaths:@[indexPath] withRowAnimation:UITableViewRowAnimationNone];
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
    [self reloadView];
}

#pragma mark - TransferTableViewCellDelegate

- (void)pauseTransferCell:(TransferTableViewCell *)cell {
    [self reloadView];
}

@end
