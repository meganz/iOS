#import "TransfersViewController.h"

#import <Photos/Photos.h>

#import "SVProgressHUD.h"
#import "UIScrollView+EmptyDataSet.h"

#import "NSString+MNZCategory.h"

#import "Helper.h"
#import "MEGASdkManager.h"
#import "MEGAReachabilityManager.h"
#import "MEGAGetThumbnailRequestDelegate.h"
#import "MEGATransfer+MNZCategory.h"
#import "MEGATransferList+MNZCategory.h"
#import "MEGAStore.h"
#import "TransfersSelected.h"
#import "UITableView+MNZCategory.h"

#import "TransferTableViewCell.h"

@interface TransfersViewController () <UITableViewDelegate, UITableViewDataSource, DZNEmptyDataSetSource, DZNEmptyDataSetDelegate, MEGARequestDelegate, MEGATransferDelegate, TransferTableViewCellDelegate>

@property (weak, nonatomic) IBOutlet UIView *selectorView;
@property (weak, nonatomic) IBOutlet UIBarButtonItem *pauseBarButtonItem;
@property (weak, nonatomic) IBOutlet UIBarButtonItem *resumeBarButtonItem;
@property (weak, nonatomic) IBOutlet UIBarButtonItem *cancelBarButtonItem;

@property (weak, nonatomic) IBOutlet UIButton *allButton;
@property (weak, nonatomic) IBOutlet UIView *allLineView;
@property (weak, nonatomic) IBOutlet UIButton *downloadsButton;
@property (weak, nonatomic) IBOutlet UIView *downloadsLineView;
@property (weak, nonatomic) IBOutlet UIButton *uploadsButton;
@property (weak, nonatomic) IBOutlet UIView *uploadsLineView;
@property (weak, nonatomic) IBOutlet UITableView *tableView;

@property (strong, nonatomic) NSMutableArray<MEGATransfer *> *transfers;
@property (strong, nonatomic) NSMutableArray<NSString *> *uploadTransfersQueued;

@property (nonatomic, getter=areTransfersPaused) BOOL transfersPaused;

@property (nonatomic) TransfersSelected transfersSelected;

@end

@implementation TransfersViewController

#pragma mark - Lifecycle

- (void)viewDidLoad {
    [super viewDidLoad];
    
    self.transfers = NSMutableArray.new;
    self.uploadTransfersQueued = NSMutableArray.new;
    
    self.tableView.emptyDataSetSource = self;
    self.tableView.emptyDataSetDelegate = self;
    
    [self updateSelector];
    [self.allButton setTitle:AMLocalizedString(@"all", @"All") forState:UIControlStateNormal];
    [self.downloadsButton setTitle:AMLocalizedString(@"downloads", @"Downloads") forState:UIControlStateNormal];
    [self.uploadsButton setTitle:AMLocalizedString(@"uploads", @"Uploads") forState:UIControlStateNormal];
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    
    self.navigationItem.title = AMLocalizedString(@"transfers", @"Transfers");
    
    [self setNavigationBarButtonItemsEnabled:[MEGAReachabilityManager isReachable]];
    
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
    
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(internetConnectionChanged) name:kReachabilityChangedNotification object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(handleCoreDataChangeNotification:) name:NSManagedObjectContextObjectsDidChangeNotification object:nil];

    [[MEGASdkManager sharedMEGASdk] addMEGATransferDelegate:self];
    [[MEGASdkManager sharedMEGASdkFolder] addMEGATransferDelegate:self];
    [[MEGAReachabilityManager sharedManager] retryPendingConnections];
    [[MEGASdkManager sharedMEGASdkFolder] retryPendingConnections];
}

- (void)viewWillDisappear:(BOOL)animated {
    [super viewWillDisappear:animated];
    
    [[NSNotificationCenter defaultCenter] removeObserver:self name:kReachabilityChangedNotification object:nil];
    [[NSNotificationCenter defaultCenter] removeObserver:self name:NSManagedObjectContextObjectsDidChangeNotification object:nil];

    [[MEGASdkManager sharedMEGASdk] removeMEGATransferDelegate:self];
    [[MEGASdkManager sharedMEGASdkFolder] removeMEGATransferDelegate:self];
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

- (void)traitCollectionDidChange:(UITraitCollection *)previousTraitCollection {
    [super traitCollectionDidChange:previousTraitCollection];
    
    if (@available(iOS 13.0, *)) {
        if ([self.traitCollection hasDifferentColorAppearanceComparedToTraitCollection:previousTraitCollection]) {
            [self updateSelector];
        }
    }
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
            NSString *uploadTransferLocalIdentifier = [self.uploadTransfersQueued objectAtIndex:indexPath.row];
            [cell configureCellForQueuedTransfer:uploadTransferLocalIdentifier delegate:self];
            break;
        }
    }
    
    return cell;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    NSInteger numberOfRows = 0;
    if (MEGAReachabilityManager.isReachable) {
        switch (section) {
            case 0:
                numberOfRows = self.transfers.count;
                break;
                
            case 1:
                numberOfRows = self.uploadTransfersQueued.count;
                break;
                
            default:
                break;
        }
    }
    
    return numberOfRows;
}

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    NSInteger numberOfSections = 0;
    if (MEGAReachabilityManager.isReachable) {
        switch (self.transfersSelected) {
            case AllTransfersSelected:
            case UploadsTransfersSelected:
                numberOfSections = 2;
                break;
                
            case DownloadsTransfersSelected:
                numberOfSections = 1;
                break;
        }
    }
    
    return numberOfSections;
}

#pragma mark - Private

- (void)reloadView {
    if (self.areTransfersPaused) {
        [self cleanTransfersList];
    } else {
        switch (self.transfersSelected) {
            case AllTransfersSelected:
                [self getAllTransfers];
                break;
                
            case DownloadsTransfersSelected:
                [self getDownloadTransfers];
                break;
                
            case UploadsTransfersSelected:
                [self getUploadTransfers];
                break;
        }
        
        [self sortTransfers];
    }
    [self.tableView reloadData];
}

- (void)getAllTransfers {
    NSMutableArray *transfers = NSMutableArray.new;
    
    MEGATransferList *transferList = [[MEGASdkManager sharedMEGASdk] transfers];
    if (transferList.size.integerValue) {
        [transfers addObjectsFromArray:transferList.mnz_transfersArrayFromTranferList];
    }
    
    transferList = [[MEGASdkManager sharedMEGASdkFolder] transfers];
    if (transferList.size.integerValue) {
        [transfers addObjectsFromArray:transferList.mnz_transfersArrayFromTranferList];
    }
    
    self.transfers = transfers;
    
    [self getQueuedUploadTransfers];
}

- (void)getDownloadTransfers {
    NSMutableArray *transfers = NSMutableArray.new;
    
    MEGATransferList *downloadTransferList = [[MEGASdkManager sharedMEGASdk] downloadTransfers];
    if (downloadTransferList.size.integerValue) {
        [transfers addObjectsFromArray:downloadTransferList.mnz_transfersArrayFromTranferList];
    }
    
    downloadTransferList = [[MEGASdkManager sharedMEGASdkFolder] downloadTransfers];
    if (downloadTransferList.size.integerValue) {
        [transfers addObjectsFromArray:downloadTransferList.mnz_transfersArrayFromTranferList];
    }
    
    self.transfers = transfers;
}

- (void)getUploadTransfers {
    NSMutableArray *transfers = NSMutableArray.new;
    
    MEGATransferList *uploadTransferList = [[MEGASdkManager sharedMEGASdk] uploadTransfers];
    if (uploadTransferList.size.integerValue) {
        [transfers addObjectsFromArray:uploadTransferList.mnz_transfersArrayFromTranferList];
    }
    
    uploadTransferList = [[MEGASdkManager sharedMEGASdkFolder] uploadTransfers];
    if (uploadTransferList.size.integerValue) {
        [transfers addObjectsFromArray:uploadTransferList.mnz_transfersArrayFromTranferList];
    }
    
    self.transfers = transfers;
    
    [self getQueuedUploadTransfers];
}

- (void)sortTransfers {
    [self.transfers sortUsingComparator:^NSComparisonResult(MEGATransfer *transfer1, MEGATransfer *transfer2) {
        NSNumber *state1 = @([transfer1 mnz_orderByState]);
        NSNumber *state2 = @([transfer2 mnz_orderByState]);
        if ([state1 compare:state2] == NSOrderedSame) {
            return [@(transfer1.tag) compare:@(transfer2.tag)];
        } else {
            return [state1 compare:state2];
        }
    }];
}

- (void)getQueuedUploadTransfers {
    NSArray *tempUploadTransfersQueued = [[MEGAStore shareInstance] fetchUploadTransfers];
    
    NSMutableArray *uploadTransfersQueued = NSMutableArray.new;
    for (MOUploadTransfer *uploadQueuedTransfer in tempUploadTransfersQueued) {
        [uploadTransfersQueued addObject:uploadQueuedTransfer.localIdentifier];
    }
    
    self.uploadTransfersQueued = uploadTransfersQueued;
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
        NSString *tempLocalIndentifier = [self.uploadTransfersQueued objectAtIndex:i];
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
    for (NSManagedObject *managedObject in [notification.userInfo objectForKey:NSInvalidatedAllObjectsKey]) {
        if ([managedObject isKindOfClass:MOUploadTransfer.class]) {
            [self reloadView];
            return;
        }
    }
    
    for (NSManagedObject *managedObject in [notification.userInfo objectForKey:NSInvalidatedObjectsKey]) {
        if ([managedObject isKindOfClass:MOUploadTransfer.class]) {
            MOUploadTransfer *uploadTransfer = (MOUploadTransfer *)managedObject;
            NSString *coreDataLocalIdentifier = uploadTransfer.localIdentifier;
            [self manageCoreDataNotificationForLocalIdentifier:coreDataLocalIdentifier];
        }
    }
    
    for (NSManagedObject *managedObject in [notification.userInfo objectForKey:NSDeletedObjectsKey]) {
        if ([managedObject isKindOfClass:MOUploadTransfer.class]) {
            MOUploadTransfer *uploadTransfer = (MOUploadTransfer *)managedObject;
            NSString *coreDataLocalIdentifier = uploadTransfer.localIdentifier;
            [self manageCoreDataNotificationForLocalIdentifier:coreDataLocalIdentifier];
        }
    }
}

- (void)manageCoreDataNotificationForLocalIdentifier:(NSString *)localIdentifier {
    BOOL ignoreCoreDataNotification = NO;
    for (NSString *tempLocalIdentifier in [Helper uploadingNodes]) {
        if ([localIdentifier isEqualToString:tempLocalIdentifier]) {
            ignoreCoreDataNotification = YES;
            break;
        }
    }
    
    if (ignoreCoreDataNotification) {
        [[Helper uploadingNodes] removeObject:localIdentifier];
    } else {
        [self deleteUploadQueuedTransferWithLocalIdentifier:localIdentifier];
    }
}

- (void)deleteUploadQueuedTransferWithLocalIdentifier:(NSString *)localIdentifier {
    NSIndexPath *indexPath = [self indexPathForUploadTransferQueuedWithLocalIdentifier:localIdentifier];
    if (indexPath) {
        [self.tableView mnz_performBatchUpdates:^{
            [self.uploadTransfersQueued removeObjectAtIndex:indexPath.row];
            [self.tableView deleteRowsAtIndexPaths:@[indexPath] withRowAnimation:UITableViewRowAnimationAutomatic];
        } completion:nil];
    }
}

- (void)deleteUploadingTransfer:(MEGATransfer *)transfer {
    NSIndexPath *indexPath = [self indexPathForTransfer:transfer];
    if (indexPath) {
        [self.tableView mnz_performBatchUpdates:^{
            [self.transfers removeObjectAtIndex:indexPath.row];
            [self.tableView deleteRowsAtIndexPaths:@[indexPath] withRowAnimation:UITableViewRowAnimationAutomatic];
        } completion:nil];
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

- (void)updateSelector {
    self.selectorView.backgroundColor = [UIColor mnz_mainBarsColorForTraitCollection:self.traitCollection];
    
    [self.allButton setTitleColor:[UIColor mnz_primaryGrayForTraitCollection:(self.traitCollection)] forState:UIControlStateNormal];
    [self.allButton setTitleColor:[UIColor mnz_redMainForTraitCollection:self.traitCollection] forState:UIControlStateSelected];
    self.allLineView.backgroundColor = self.allButton.selected ? [UIColor mnz_redMainForTraitCollection:self.traitCollection] : UIColor.mnz_grayCCCCCC;
    
    [self.downloadsButton setTitleColor:[UIColor mnz_primaryGrayForTraitCollection:(self.traitCollection)] forState:UIControlStateNormal];
    [self.downloadsButton setTitleColor:[UIColor mnz_redMainForTraitCollection:self.traitCollection] forState:UIControlStateSelected];
    self.downloadsLineView.backgroundColor = self.downloadsButton.selected ? [UIColor mnz_redMainForTraitCollection:self.traitCollection] : UIColor.mnz_grayCCCCCC;
    
    [self.uploadsButton setTitleColor:[UIColor mnz_primaryGrayForTraitCollection:(self.traitCollection)] forState:UIControlStateNormal];
    [self.uploadsButton setTitleColor:[UIColor mnz_redMainForTraitCollection:self.traitCollection] forState:UIControlStateSelected];
    self.uploadsLineView.backgroundColor = self.uploadsButton.selected ? [UIColor mnz_redMainForTraitCollection:self.traitCollection] : UIColor.mnz_grayCCCCCC;
}

#pragma mark - IBActions

- (IBAction)selectTransfersTouchUpInside:(UIButton *)sender {
    if (sender.tag == self.transfersSelected) {
        return;
    }
    
    self.transfersSelected = sender.tag;
    
    switch (self.transfersSelected) {
        default:
        case AllTransfersSelected:
            self.downloadsButton.selected = self.uploadsButton.selected = NO;
            self.allButton.selected = YES;
            break;
           
        case DownloadsTransfersSelected:
            self.allButton.selected = self.uploadsButton.selected = NO;
            self.downloadsButton.selected = YES;
            break;
            
        case UploadsTransfersSelected:
            self.allButton.selected = self.downloadsButton.selected = NO;
            self.uploadsButton.selected = YES;
            break;
    }
    
    [self updateSelector];
    
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
    switch (self.transfersSelected) {
        case AllTransfersSelected:
            transfersTypeString = AMLocalizedString(@"allInUppercaseTransfers", @"ALL transfers");
            break;
            
        case DownloadsTransfersSelected:
            transfersTypeString = AMLocalizedString(@"downloadInUppercaseTransfers", @"DOWNLOAD transfers");
            break;
            
        case UploadsTransfersSelected:
            transfersTypeString = AMLocalizedString(@"uploadInUppercaseTransfers", @"UPLOAD transfers");
            break;
    }
    
    UIAlertController *cancelTransfersAlert = [UIAlertController alertControllerWithTitle:AMLocalizedString(@"cancelTransfersTitle", @"Cancel transfers") message:[NSString stringWithFormat:AMLocalizedString(@"cancelTransfersText", @"Do you want to cancel %@?"), transfersTypeString] preferredStyle:UIAlertControllerStyleAlert];
    [cancelTransfersAlert addAction:[UIAlertAction actionWithTitle:AMLocalizedString(@"cancel", @"Button title to cancel something") style:UIAlertActionStyleCancel handler:nil]];
    
    [cancelTransfersAlert addAction:[UIAlertAction actionWithTitle:AMLocalizedString(@"ok", nil) style:UIAlertActionStyleDefault handler:^(UIAlertAction *action) {
        switch (self.transfersSelected) {
            case AllTransfersSelected: {
                [self cancelTransfersForDirection:0];
                [self cancelTransfersForDirection:1];
                break;
            }
                
            case DownloadsTransfersSelected:
                [self cancelTransfersForDirection:0];
                break;
                
            case UploadsTransfersSelected:
                [self cancelTransfersForDirection:1];
                break;
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
            switch (self.transfersSelected) {
                case AllTransfersSelected:
                    text = AMLocalizedString(@"transfersEmptyState_titleAll", @"Title shown when the there's no transfers and they aren't paused");
                    break;
                    
                case DownloadsTransfersSelected:
                    text = AMLocalizedString(@"transfersEmptyState_titleDownload", @"No Download Transfers");
                    break;
                    
                case UploadsTransfersSelected:
                    text = AMLocalizedString(@"transfersEmptyState_titleUpload", @"No Uploads Transfers");
                    break;
            }
        }
    } else {
        text = AMLocalizedString(@"noInternetConnection",  @"No Internet Connection");
    }
    
    return [[NSAttributedString alloc] initWithString:text attributes:[Helper titleAttributesForEmptyState]];
}

- (nullable NSAttributedString *)descriptionForEmptyDataSet:(UIScrollView *)scrollView {
    NSString *text = @"";
    if (!MEGAReachabilityManager.isReachable && !MEGAReachabilityManager.sharedManager.isMobileDataEnabled) {
        text = AMLocalizedString(@"Mobile Data is turned off", @"Information shown when the user has disabled the 'Mobile Data' setting for MEGA in the iOS Settings.");
    }
    
    NSDictionary *attributes = @{NSFontAttributeName:[UIFont preferredFontForTextStyle:UIFontTextStyleFootnote], NSForegroundColorAttributeName:[UIColor mnz_primaryGrayForTraitCollection:self.traitCollection]};
    
    return [NSAttributedString.alloc initWithString:text attributes:attributes];
}

- (UIImage *)imageForEmptyDataSet:(UIScrollView *)scrollView {
    UIImage *image;
    if ([MEGAReachabilityManager isReachable]) {
        if (self.areTransfersPaused) {
            image = [UIImage imageNamed:@"pausedTransfersEmptyState"];
        } else {
            switch (self.transfersSelected) {
                case AllTransfersSelected:
                    image = [UIImage imageNamed:@"transfersEmptyState"];
                    break;
                    
                case DownloadsTransfersSelected:
                    image = [UIImage imageNamed:@"downloadsEmptyState"];
                    break;
                    
                case UploadsTransfersSelected:
                    image = [UIImage imageNamed:@"uploadsEmptyState"];
                    break;
            }
        }
    } else {
        image = [UIImage imageNamed:@"noInternetEmptyState"];
    }
    return image;
}

- (NSAttributedString *)buttonTitleForEmptyDataSet:(UIScrollView *)scrollView forState:(UIControlState)state {
    NSString *text = @"";
    if (!MEGAReachabilityManager.isReachable && !MEGAReachabilityManager.sharedManager.isMobileDataEnabled) {
        text = AMLocalizedString(@"Turn Mobile Data on", @"Button title to go to the iOS Settings to enable 'Mobile Data' for the MEGA app.");
    }
    
    return [NSAttributedString.alloc initWithString:text attributes:Helper.buttonTextAttributesForEmptyState];
}

- (UIImage *)buttonBackgroundImageForEmptyDataSet:(UIScrollView *)scrollView forState:(UIControlState)state {
    UIEdgeInsets capInsets = [Helper capInsetsForEmptyStateButton];
    UIEdgeInsets rectInsets = [Helper rectInsetsForEmptyStateButton];
    
    return [[[UIImage imageNamed:@"emptyStateButton"] resizableImageWithCapInsets:capInsets resizingMode:UIImageResizingModeStretch] imageWithAlignmentRectInsets:rectInsets];
}

- (UIColor *)backgroundColorForEmptyDataSet:(UIScrollView *)scrollView {
    return UIColor.whiteColor;
}

- (CGFloat)spaceHeightForEmptyDataSet:(UIScrollView *)scrollView {
    return [Helper spaceHeightForEmptyState];
}

#pragma mark - DZNEmptyDataSetDelegate

- (void)emptyDataSet:(UIScrollView *)scrollView didTapButton:(UIButton *)button {
    if (!MEGAReachabilityManager.isReachable && !MEGAReachabilityManager.sharedManager.isMobileDataEnabled) {
        [UIApplication.sharedApplication openURL:[NSURL URLWithString:UIApplicationOpenSettingsURLString] options:@{} completionHandler:nil];
    }
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
    switch (self.transfersSelected) {
        case AllTransfersSelected:
            break;
            
        case DownloadsTransfersSelected:
            if (transfer.type == MEGATransferTypeUpload) return;
            break;
            
        case UploadsTransfersSelected:
            if (transfer.type == MEGATransferTypeDownload) return;
            break;
    }
    
    if (transfer.type == MEGATransferTypeUpload) {
        if ([transfer.appData containsString:@">localIdentifier"]) {
            NSString *localIdentifier = [transfer.appData mnz_stringBetweenString:@">localIdentifier=" andString:@""];
            NSIndexPath *oldIndexPath = [self indexPathForUploadTransferQueuedWithLocalIdentifier:localIdentifier];
            if (oldIndexPath) {
                [self.tableView mnz_performBatchUpdates:^{
                    NSInteger newTransferIndex = [self numberOfActiveTransfers];
                    [self.transfers insertObject:transfer atIndex:newTransferIndex];
                    
                    TransferTableViewCell *cell = (TransferTableViewCell *)[self.tableView cellForRowAtIndexPath:oldIndexPath];
                    [cell reconfigureCellWithTransfer:transfer];
                                        
                    NSIndexPath *newIndexPath = [NSIndexPath indexPathForRow:newTransferIndex inSection:0];
                    [self.uploadTransfersQueued removeObjectAtIndex:oldIndexPath.row];
                    [self.tableView moveRowAtIndexPath:oldIndexPath toIndexPath:newIndexPath];
                } completion:nil];
            }
        } else {
            [self.tableView mnz_performBatchUpdates:^{
                NSInteger newTransferIndex = [self numberOfActiveTransfers];
                [self.transfers insertObject:transfer atIndex:newTransferIndex];
                NSIndexPath *newIndexPath = [NSIndexPath indexPathForRow:newTransferIndex inSection:0];
                [self.tableView insertRowsAtIndexPaths:@[newIndexPath] withRowAnimation:UITableViewRowAnimationAutomatic];
            } completion:nil];
        }
    } else if (transfer.type == MEGATransferTypeDownload) {
        NSIndexPath *indexPath = [self indexPathForTransfer:transfer];
        if (indexPath) {
            [self.transfers replaceObjectAtIndex:indexPath.row withObject:transfer];
        }
    }
}

- (void)onTransferUpdate:(MEGASdk *)api transfer:(MEGATransfer *)transfer {
    NSIndexPath *indexPath = [self indexPathForTransfer:transfer];
    if (indexPath) {
        if ([[self.tableView indexPathsForVisibleRows] containsObject:indexPath]) {
            TransferTableViewCell *cell = (TransferTableViewCell *)[self.tableView cellForRowAtIndexPath:indexPath];
            if (transfer.state == MEGATransferStateActive) {
                [cell reloadThumbnailImage];
                [cell updatePercentAndSpeedLabelsForTransfer:transfer];
            }
            [cell updateTransferIfNewState:transfer];
        }
        [self.transfers replaceObjectAtIndex:indexPath.row withObject:transfer];
    }
}

- (void)onTransferFinish:(MEGASdk *)api transfer:(MEGATransfer *)transfer error:(MEGAError *)error {
    if (transfer.isStreamingTransfer) {
        return;
    }
    
    if (error.type == MEGAErrorTypeApiEIncomplete) {
        [SVProgressHUD showImage:[UIImage imageNamed:@"hudMinus"] status:AMLocalizedString(@"transferCancelled", nil)];
    }
    
    [self deleteUploadingTransfer:transfer];
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
        
        [self.tableView mnz_performBatchUpdates:^{
            [self.uploadTransfersQueued removeObjectAtIndex:indexPath.row];
            [[MEGAStore shareInstance] deleteUploadTransferWithLocalIdentifier:localIdentifier];
            [self.tableView deleteRowsAtIndexPaths:@[indexPath] withRowAnimation:UITableViewRowAnimationAutomatic];
        } completion:nil];
    }
}

@end
