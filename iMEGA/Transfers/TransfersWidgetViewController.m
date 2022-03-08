#import "TransfersWidgetViewController.h"
#import "CopyrightWarningViewController.h"
#import "CloudDriveViewController.h"
#import "MEGAPhotoBrowserViewController.h"
#import <Photos/Photos.h>

#import "SVProgressHUD.h"
#import "UIScrollView+EmptyDataSet.h"
#import "UIApplication+MNZCategory.h"

#import "NSString+MNZCategory.h"
#import "MEGANode+MNZCategory.h"
#import "MEGASdk+MNZCategory.h"

#import "Helper.h"
#import "MEGASdkManager.h"
#import "MEGAReachabilityManager.h"
#import "MEGAGetThumbnailRequestDelegate.h"
#import "MEGATransfer+MNZCategory.h"
#import "MEGATransferList+MNZCategory.h"
#import "MEGAStore.h"
#import "TransfersWidgetSelected.h"
#import "UITableView+MNZCategory.h"
#import "MEGANode+MNZCategory.h"

#import "TransferTableViewCell.h"
#import "NodeTableViewCell.h"
#import "MEGANavigationController.h"
#import "MEGA-Swift.h"

@interface TransfersWidgetViewController () <UITableViewDelegate, UITableViewDataSource, DZNEmptyDataSetSource, DZNEmptyDataSetDelegate, MEGARequestDelegate, MEGATransferDelegate, TransferTableViewCellDelegate, TransferActionViewControllerDelegate>

@property (weak, nonatomic) IBOutlet UIView *selectorView;
@property (weak, nonatomic) IBOutlet UIBarButtonItem *pauseBarButtonItem;
@property (weak, nonatomic) IBOutlet UIBarButtonItem *resumeBarButtonItem;
@property (weak, nonatomic) IBOutlet UIBarButtonItem *cancelBarButtonItem;
@property (strong, nonatomic) UIBarButtonItem *editBarButtonItem;

@property (weak, nonatomic) IBOutlet UIButton *inProgressButton;
@property (weak, nonatomic) IBOutlet UIView *allLineView;
@property (weak, nonatomic) IBOutlet UIButton *completedButton;
@property (weak, nonatomic) IBOutlet UIView *completedLineView;
@property (weak, nonatomic) IBOutlet UITableView *tableView;
@property (weak, nonatomic) IBOutlet NSLayoutConstraint *toolbarBottomConstraint;
@property (weak, nonatomic) IBOutlet UIToolbar *toolbar;
@property (strong, nonatomic) IBOutlet UIBarButtonItem *clearAllButton;

@property (strong, nonatomic) TransferUseCaseHelper *transfersUseCaseHelper;
@property (strong, nonatomic) NSMutableArray<MEGATransfer *> *transfers;
@property (strong, nonatomic) NSMutableArray<NSString *> *uploadTransfersQueued;
@property (strong, nonatomic) NSMutableArray<MEGATransfer *> *completedTransfers;
@property (strong, nonatomic) NSMutableArray<MEGATransfer *> *selectedTransfers;

@property (nonatomic, getter=areTransfersPaused) BOOL transfersPaused;
@property (nonatomic) TransfersWidgetSelected transfersSelected;

@end

@implementation TransfersWidgetViewController

static TransfersWidgetViewController* instance = nil;

#pragma mark - Lifecycle

+ (instancetype)sharedTransferViewController {
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        instance = [[UIStoryboard storyboardWithName:@"Transfers" bundle:nil] instantiateViewControllerWithIdentifier:@"TransfersWidgetViewControllerID"];
    });
    return instance;
}


- (void)viewDidLoad {
    [super viewDidLoad];

    self.uploadTransfersQueued = NSMutableArray.new;
    self.selectedTransfers = NSMutableArray.new;
    self.transfersUseCaseHelper = [[TransferUseCaseHelper alloc] init];
    
    self.tableView.emptyDataSetSource = self;
    self.tableView.emptyDataSetDelegate = self;
    
    self.editBarButtonItem = [UIBarButtonItem.alloc initWithTitle:NSLocalizedString(@"edit", @"Caption of a button to edit the files that are selected") style:UIBarButtonItemStylePlain target:self action:@selector(switchEdit)];
    self.navigationItem.rightBarButtonItems = @[self.editBarButtonItem];

    [self.inProgressButton setTitle:NSLocalizedString(@"In Progress", @"Title of one of the filters in the Transfers section. In this case In Progress transfers") forState:UIControlStateNormal];
    [self.completedButton setTitle:NSLocalizedString(@"Completed",@"Title of one of the filters in the Transfers section. In this case Completed transfers") forState:UIControlStateNormal];
    [self.clearAllButton setTitle:self.tableView.isEditing ? NSLocalizedString(@"Clear Selected", @"tool bar title used in transfer widget, allow user to clear the selected items in the list") : NSLocalizedString(@"Clear All", @"tool bar title used in transfer widget, allow user to clear all items in the list")];
    
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(internetConnectionChanged) name:kReachabilityChangedNotification object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(handleCoreDataChangeNotification:) name:NSManagedObjectContextObjectsDidChangeNotification object:nil];
    [NSNotificationCenter.defaultCenter addObserver:self selector:@selector(didReceiveTransferOverQuotaNotification:) name:MEGATransferOverQuotaNotification object:nil];

    [[MEGASdkManager sharedMEGASdk] addMEGATransferDelegate:self];
    [[MEGASdkManager sharedMEGASdkFolder] addMEGATransferDelegate:self];
    [[MEGASdkManager sharedMEGASdk] addMEGARequestDelegate:self];
    [[MEGAReachabilityManager sharedManager] retryPendingConnections];
    [[MEGASdkManager sharedMEGASdkFolder] retryPendingConnections];
    
    [self reloadView];
    
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    
    self.navigationItem.title = NSLocalizedString(@"transfers", @"Transfers");
        
    [self setNavigationBarButtonItemsEnabled:[MEGAReachabilityManager isReachable]];
    
    if ([[NSUserDefaults standardUserDefaults] boolForKey:@"TransfersPaused"]) {
        self.transfersPaused = YES;
    } else {
        self.transfersPaused = NO;
    }

    self.progressView.hidden = YES;
    [self reloadView];
    
}

- (void)viewWillDisappear:(BOOL)animated {
    [super viewWillDisappear:animated];
    [self.progressView showWidgetIfNeeded];
}

- (void)viewDidDisappear:(BOOL)animated {
    [super viewDidDisappear:animated];
    if (self.tableView.isEditing) {
        [self switchEdit];
    }
}

- (void)traitCollectionDidChange:(UITraitCollection *)previousTraitCollection {
    [super traitCollectionDidChange:previousTraitCollection];
    
    if ([self.traitCollection hasDifferentColorAppearanceComparedToTraitCollection:previousTraitCollection]) {
        [self reloadView];
        [AppearanceManager forceToolbarUpdate:self.toolbar traitCollection:self.traitCollection];
    }
}

- (void)updateSelector {
    self.inProgressButton.backgroundColor = self.completedButton.backgroundColor = [UIColor mnz_mainBarsForTraitCollection:self.traitCollection];
    
    [self.inProgressButton setTitleColor:[UIColor mnz_primaryGrayForTraitCollection:(self.traitCollection)] forState:UIControlStateNormal];
    [self.inProgressButton setTitleColor:[UIColor mnz_redForTraitCollection:self.traitCollection] forState:UIControlStateSelected];
    self.allLineView.backgroundColor = self.inProgressButton.selected ? [UIColor mnz_redForTraitCollection:self.traitCollection] : nil;
    
    [self.completedButton setTitleColor:[UIColor mnz_primaryGrayForTraitCollection:(self.traitCollection)] forState:UIControlStateNormal];
    [self.completedButton setTitleColor:[UIColor mnz_redForTraitCollection:self.traitCollection] forState:UIControlStateSelected];
    self.completedLineView.backgroundColor = self.completedButton.selected ? [UIColor mnz_redForTraitCollection:self.traitCollection] : nil;
    
    switch (self.transfersSelected) {
        case TransfersWidgetSelectedAll:
            [self.clearAllButton setTitle:self.areTransfersPaused ? NSLocalizedString(@"Resume All", @"tool bar title used in transfer widget, allow user to resume all transfers in the list") : NSLocalizedString(@"Pause All", @"tool bar title used in transfer widget, allow user to Pause all transfers in the list")];
            self.clearAllButton.enabled = true;
            break;
            
        case TransfersWidgetSelectedCompleted:
            [self.clearAllButton setTitle:self.tableView.isEditing ? NSLocalizedString(@"Clear Selected", @"tool bar title used in transfer widget, allow user to clear the selected items in the list") : NSLocalizedString(@"Clear All", @"tool bar title used in transfer widget, allow user to clear all items in the list")];
            break;
    }
}

- (void)updateViewState {
    switch (self.transfersSelected) {
        case TransfersWidgetSelectedAll: {
            BOOL ongoingTransfers = self.transfers.count > 0;
            self.editBarButtonItem.enabled = ongoingTransfers;
            self.toolbar.hidden = !ongoingTransfers;
            break;
        }
            
        case TransfersWidgetSelectedCompleted: {
            BOOL completedTransfers = self.completedTransfers.count > 0;
            self.editBarButtonItem.enabled = completedTransfers;
            self.toolbar.hidden = !completedTransfers;
            self.clearAllButton.enabled = !self.tableView.isEditing || completedTransfers;
            break;
        }
    }
}

- (void)dealloc {
    [NSNotificationCenter.defaultCenter removeObserver:self name:kReachabilityChangedNotification object:nil];
    [NSNotificationCenter.defaultCenter removeObserver:self name:NSManagedObjectContextObjectsDidChangeNotification object:nil];
    [NSNotificationCenter.defaultCenter removeObserver:self name:MEGATransferOverQuotaNotification object:nil];

    [MEGASdkManager.sharedMEGASdk removeMEGATransferDelegate:self];
    [MEGASdkManager.sharedMEGASdkFolder removeMEGATransferDelegate:self];
}

- (void)viewWillTransitionToSize:(CGSize)size withTransitionCoordinator:(id<UIViewControllerTransitionCoordinator>)coordinator {
    [super viewWillTransitionToSize:size withTransitionCoordinator:coordinator];
    
    [coordinator animateAlongsideTransition:^(id<UIViewControllerTransitionCoordinatorContext> context) {
        [self.tableView reloadEmptyDataSet];
    } completion:nil];
}

- (void)showCustomActionsForTransfer:(MEGATransfer *)transfer sender:(UIView *)sender {
    MEGANode *node = transfer.node;

    switch (transfer.state) {
        case MEGATransferStateComplete:
        {
            TransferActionViewController *actionController = [TransferActionViewController.alloc initWithNode:node delegate:self displayMode:transfer.publicNode ? DisplayModePublicLinkTransfers : DisplayModeTransfers isIncoming:NO sender:sender];
            actionController.transfer = transfer;
            if ([[UIDevice currentDevice] iPadDevice]) {
                actionController.modalPresentationStyle = UIModalPresentationPopover;
                actionController.popoverPresentationController.delegate = actionController;
                actionController.popoverPresentationController.sourceView = sender;
                actionController.popoverPresentationController.sourceRect = CGRectMake(0, 0, sender.frame.size.width/2, sender.frame.size.height/2);
            } else {
                actionController.modalPresentationStyle = UIModalPresentationOverFullScreen;
            }
            [self presentViewController:actionController animated:YES completion:nil];
        }
            break;
            
        default:
        {
            
            TransferActionViewController *actionController = [TransferActionViewController.alloc initWithNode:node delegate:self displayMode:DisplayModeTransfersFailed isIncoming:NO sender:sender];
            actionController.transfer = transfer;

            if ([[UIDevice currentDevice] iPadDevice]) {
                actionController.modalPresentationStyle = UIModalPresentationPopover;
                actionController.popoverPresentationController.delegate = actionController;
                actionController.popoverPresentationController.sourceView = sender;
                actionController.popoverPresentationController.sourceRect = CGRectMake(0, 0, sender.frame.size.width/2, sender.frame.size.height/2);
            } else {
                actionController.modalPresentationStyle = UIModalPresentationOverFullScreen;
            }
            
            [self presentViewController:actionController animated:YES completion:nil];
            
        }
            
            break;
    }

}

#pragma mark - UITableViewDataSource

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    
    if (self.inProgressButton.selected) {
        
        TransferTableViewCell *cell = [self.tableView dequeueReusableCellWithIdentifier:@"transferCell" forIndexPath:indexPath];
        
        switch (indexPath.section) {
            case 0: {
                MEGATransfer *transfer = [self.transfers objectOrNilAtIndex:indexPath.row];
                [cell configureCellForTransfer:transfer overquota:[TransfersWidgetViewController sharedTransferViewController].progressView.overquota delegate:self];
                break;
            }
                
            case 1: {
                NSString *uploadTransferLocalIdentifier = [self.uploadTransfersQueued objectOrNilAtIndex:indexPath.row];
                [cell configureCellForQueuedTransfer:uploadTransferLocalIdentifier delegate:self];
                break;
            }
        }
        
        return cell;
        
    } else {
        
        MEGATransfer *transfer = [self.completedTransfers objectOrNilAtIndex:indexPath.row];
        
        MEGANode *node = transfer.node;
        
        if (transfer.state == MEGATransferStateComplete) {
            NodeTableViewCell *cell = [self.tableView dequeueReusableCellWithIdentifier:@"nodeCell" forIndexPath:indexPath];
            cell.selectedBackgroundView = UIView.new;
            [cell configureCellForNode:node api:[MEGASdkManager sharedMEGASdk]];
            return cell;

        } else {
            TransferTableViewCell *cell = [self.tableView dequeueReusableCellWithIdentifier:@"transferCell" forIndexPath:indexPath];
            cell.selectedBackgroundView = UIView.new;

            [cell configureCellForTransfer:transfer delegate:self];
            return cell;
        }
    }
}

- (NSString *)tableView:(UITableView *)tableView titleForDeleteConfirmationButtonForRowAtIndexPath:(NSIndexPath *)indexPath {
    return NSLocalizedString(@"clear", @"Button title to clear something");
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    NSInteger numberOfRows = 0;
    if (MEGAReachabilityManager.isReachable) {
        switch (section) {
            case 0:
                if (self.inProgressButton.selected) {
                    numberOfRows = self.transfers.count;
                } else {
                    numberOfRows = self.completedTransfers.count;
                }
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

- (void)tableView:(UITableView *)tableView didDeselectRowAtIndexPath:(NSIndexPath *)indexPath {
    if (self.completedButton.selected) {
        MEGATransfer *transfer = [self.completedTransfers objectOrNilAtIndex:indexPath.row];
        [self.selectedTransfers removeObject:transfer];
        if (self.selectedTransfers.count == 0) {
            self.clearAllButton.enabled = false;
        }
    }
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    if (self.completedButton.selected) {
        
        MEGATransfer *transfer = [self.completedTransfers objectOrNilAtIndex:indexPath.row];
        if (transfer == nil) return;
        
        if (tableView.isEditing) {
            [self.selectedTransfers addObject:transfer];
            self.clearAllButton.enabled = true;
            return;
        }
        
        if (transfer.state == MEGATransferStateComplete) {
            MEGANode *node = transfer.node;
            if (node.name.mnz_isVisualMediaPathExtension) {
                [self showNode:node];
            } else {
                [node mnz_openNodeInNavigationController:self.navigationController folderLink:NO fileLink:nil];
            }
        } else {
            UITableViewCell *cell = [tableView cellForRowAtIndexPath:indexPath];
            [self showCustomActionsForTransfer:transfer sender:cell];
        }

    }
    [tableView deselectRowAtIndexPath:indexPath animated:YES];
}

- (UITableViewCellEditingStyle)tableView:(UITableView *)tableView editingStyleForRowAtIndexPath:(NSIndexPath *)indexPath {
    if (self.completedButton.selected) {
        return self.tableView.isEditing ? UITableViewCellEditingStyleDelete | UITableViewCellEditingStyleInsert : UITableViewCellEditingStyleDelete;
    } else {
        return UITableViewCellEditingStyleDelete;
    }
}

- (BOOL)tableView:(UITableView *)tableView canMoveRowAtIndexPath:(NSIndexPath *)indexPath {
    if (self.completedButton.selected) {
        return NO;
    } else if (indexPath.section == 1) {
        return NO;
    } else {
        return YES;
    }
}

- (NSIndexPath *)tableView:(UITableView *)tableView targetIndexPathForMoveFromRowAtIndexPath:(NSIndexPath *)sourceIndexPath toProposedIndexPath:(NSIndexPath *)proposedDestinationIndexPath {
    
    if (sourceIndexPath.section != proposedDestinationIndexPath.section) {
        return sourceIndexPath;
    }
    
    return proposedDestinationIndexPath;
}

- (void)tableView:(UITableView *)tableView moveRowAtIndexPath:(NSIndexPath *)fromIndexPath toIndexPath:(NSIndexPath *)toIndexPath {
    MEGATransfer *selectedTransfer = [self.transfers objectOrNilAtIndex:fromIndexPath.row];
    
    BOOL isDemoted = fromIndexPath.row < toIndexPath.row;
    
    if (isDemoted) {
        if (toIndexPath.row + 1 < self.transfers.count) {
            [MEGASdkManager.sharedMEGASdk moveTransferBefore:selectedTransfer prevTransfer:({
                MEGATransfer *prevTransfer = [self.transfers objectOrNilAtIndex:toIndexPath.row + 1];
                prevTransfer;
                
            })];
        } else {
            [MEGASdkManager.sharedMEGASdk moveTransferToLast:selectedTransfer];
        }
    } else {
        [MEGASdkManager.sharedMEGASdk moveTransferBefore:selectedTransfer prevTransfer:({
            MEGATransfer *prevTransfer = [self.transfers objectOrNilAtIndex:toIndexPath.row];
            prevTransfer;
            
        })];
    }
    
    [self.transfers removeObjectAtIndex:fromIndexPath.row];
    [self.transfers insertObject:selectedTransfer atIndex:toIndexPath.row];
    
    [self.tableView reloadData];
}

- (BOOL)tableView:(UITableView *)tableView canEditRowAtIndexPath:(NSIndexPath *)indexPath {
    if (self.inProgressButton.selected) {
        return tableView.isEditing;
    }
    return YES;
}

- (void)tableView:(UITableView *)tableView commitEditingStyle:(UITableViewCellEditingStyle)editingStyle forRowAtIndexPath:(NSIndexPath *)indexPath {
    if (editingStyle == UITableViewCellEditingStyleDelete) {
        if (self.inProgressButton.selected) {
            TransferTableViewCell *cell = (TransferTableViewCell *)[self.tableView cellForRowAtIndexPath:indexPath];
            [cell cancelTransfer:nil];
        } else {
            [self removeFromCompletedTransfers:self.completedTransfers[indexPath.row]];
            [self.tableView reloadData];
        }
    }
}


- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    NSInteger numberOfSections = 0;
    if (MEGAReachabilityManager.isReachable) {
        switch (self.transfersSelected) {
            case TransfersWidgetSelectedAll:
                numberOfSections = 2;
                break;
                
            case TransfersWidgetSelectedCompleted:
                numberOfSections = 1;
                break;
        }
    }
    
    return numberOfSections;
}

#pragma mark - Private

- (void)reloadView {
    
    [self getAllTransfers];
    [self updateSelector];
    [self updateViewState];
    [self.tableView reloadData];
}

- (void)getAllTransfers {
    self.transfers = [[NSMutableArray alloc] initWithArray:[self.transfersUseCaseHelper transfers]];
    
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

- (void)removeFromCompletedTransfers:(MEGATransfer *)transfer {
    [[MEGASdkManager.sharedMEGASdk completedTransfers] removeObject:transfer];
}

- (void)removeSelectedTransfers {
    [[MEGASdkManager.sharedMEGASdk completedTransfers] removeObjectsInArray:self.selectedTransfers];
}

- (void)removeAllCompletedTransfers {
    [[MEGASdkManager.sharedMEGASdk completedTransfers] removeAllObjects];
}

- (NSIndexPath *)indexPathForPendingTransfer:(MEGATransfer *)transfer {
    for (int i = 0; i < self.transfers.count; i++) {
        MEGATransfer *tempTransfer = self.transfers[i];
        
        if (transfer.tag ==  tempTransfer.tag) {
            return [NSIndexPath indexPathForRow:i inSection:0];
        }
    }
    
    return nil;
}

- (NSIndexPath *)indexPathForUploadTransferQueuedWithLocalIdentifier:(NSString *)localIdentifier {
    for (int i = 0; i < self.uploadTransfersQueued.count; i++) {
        NSString *tempLocalIndentifier = [self.uploadTransfersQueued objectOrNilAtIndex:i];
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
            dispatch_async(dispatch_get_main_queue(), ^{
                [self reloadView];
            });
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
        [self.uploadTransfersQueued removeObjectAtIndex:indexPath.row];
        dispatch_async(dispatch_get_main_queue(), ^{
            [self.tableView reloadData];
        });
    }
}

- (void)deleteUploadingTransfer:(MEGATransfer *)transfer {
    
    NSIndexPath *indexPath = [self indexPathForPendingTransfer:transfer];
    
    if (self.inProgressButton.selected) {
        if (indexPath) {
            [self.transfers removeObjectAtIndex:indexPath.row];
            [self.tableView reloadData];
            if (self.transfers.count == 0) {
                [self.progressView configureData];
            }
            
        }
    } else {
        [self.tableView debounce:@selector(reloadData) delay:0.1];
        self.toolbar.hidden = NO;
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

- (void)didReceiveTransferOverQuotaNotification:(NSNotification *)notification {
    MEGALogDebug(@"[Transfer Widget] transfer over quota notification %@", notification.userInfo);
    [self reloadView];
}

#pragma mark - IBActions

- (IBAction)selectTransfersTouchUpInside:(UIButton *)sender {
    if (sender.tag == self.transfersSelected) {
        return;
    }
    
    self.transfersSelected = sender.tag;
    
    switch (self.transfersSelected) {
        default:
        case TransfersWidgetSelectedAll:
            self.completedButton.selected = NO;
            self.inProgressButton.selected = YES;
            [self.clearAllButton setTitle:self.areTransfersPaused ? NSLocalizedString(@"Resume All", @"tool bar title used in transfer widget, allow user to resume all transfers in the list") : NSLocalizedString(@"Pause All", @"tool bar title used in transfer widget, allow user to Pause all transfers in the list")];
            break;
            
        case TransfersWidgetSelectedCompleted:
            self.inProgressButton.selected = NO;
            self.completedButton.selected = YES;
            [self.clearAllButton setTitle:self.tableView.isEditing ? NSLocalizedString(@"Clear Selected", @"tool bar title used in transfer widget, allow user to clear the selected items in the list") : NSLocalizedString(@"Clear All", @"tool bar title used in transfer widget, allow user to clear all items in the list")];
            break;
            
    }
    
    
    [self reloadView];
}


- (IBAction)clearAll:(id)sender {
    switch (self.transfersSelected) {
        case TransfersWidgetSelectedAll:
            if (self.areTransfersPaused) {
                [self resumeTransfersAction:sender];
            } else {
                [self pauseTransfersAction:sender];
            }
            break;
        case TransfersWidgetSelectedCompleted:
            if (self.tableView.isEditing) {
                [self removeSelectedTransfers];
                [self.selectedTransfers removeAllObjects];
            } else {
                [self removeAllCompletedTransfers];
            }
            [self switchEdit];
            
            if (self.transfers.count == 0) {
                [self.progressView dismissWidget];
            }
            break;
        default:
            break;
    }

}

- (IBAction)infoTouchUpInside:(UIButton *)sender {
    if (self.tableView.isEditing) {
        return;
    }
    
    CGPoint buttonPosition = [sender convertPoint:CGPointZero toView:self.tableView];
    NSIndexPath *indexPath = [self.tableView indexPathForRowAtPoint:buttonPosition];
    MEGATransfer *transfer = [self.completedTransfers objectOrNilAtIndex:indexPath.row];
    
    [self showCustomActionsForTransfer:transfer sender:sender];
}

- (IBAction)pauseTransfersAction:(UIBarButtonItem *)sender {
    [[MEGASdkManager sharedMEGASdk] pauseTransfers:YES delegate:self];
    [[MEGASdkManager sharedMEGASdkFolder] pauseTransfers:YES delegate:self];
}

- (IBAction)resumeTransfersAction:(UIBarButtonItem *)sender {
    [[MEGASdkManager sharedMEGASdk] pauseTransfers:NO delegate:self];
    [[MEGASdkManager sharedMEGASdkFolder] pauseTransfers:NO delegate:self];
}

- (IBAction)cancelTransfersAction:(UIBarButtonItem *)sender {
    if ((self.transfers.count == 0) && (self.uploadTransfersQueued.count == 0)) {
        return;
    }
    NSString *transfersTypeString = NSLocalizedString(@"allInUppercaseTransfers", @"ALL transfers");
    
    UIAlertController *cancelTransfersAlert = [UIAlertController alertControllerWithTitle:NSLocalizedString(@"cancelTransfersTitle", @"Cancel transfers") message:[NSString stringWithFormat:NSLocalizedString(@"cancelTransfersText", @"Do you want to cancel %@?"), transfersTypeString] preferredStyle:UIAlertControllerStyleAlert];
    [cancelTransfersAlert addAction:[UIAlertAction actionWithTitle:NSLocalizedString(@"cancel", @"Button title to cancel something") style:UIAlertActionStyleCancel handler:nil]];
    [cancelTransfersAlert addAction:[UIAlertAction actionWithTitle:NSLocalizedString(@"ok", nil) style:UIAlertActionStyleDefault handler:^(UIAlertAction *action) {
        [self cancelTransfersForDirection:0];
        [self cancelTransfersForDirection:1];
        
        [self switchEdit];
    }]];
    
    [self presentViewController:cancelTransfersAlert animated:YES completion:nil];
}

#pragma mark - DZNEmptyDataSetSource

- (nullable UIView *)customViewForEmptyDataSet:(UIScrollView *)scrollView {
    EmptyStateView *emptyStateView = [EmptyStateView.alloc initWithImage:[self imageForEmptyState] title:[self titleForEmptyState] description:@"" buttonTitle:@""];    
    return emptyStateView;
}

#pragma mark - Empty State

- (NSString *)titleForEmptyState {
    NSString *text;
    switch (self.transfersSelected) {
        case TransfersWidgetSelectedAll:
            if (self.areTransfersPaused) {
                text = NSLocalizedString(@"transfersEmptyState_titlePaused", nil);
            } else {
                text = NSLocalizedString(@"transfersEmptyState_titleAll", @"Title shown when the there's no transfers and they aren't paused");
            }
            break;
        case TransfersWidgetSelectedCompleted:
            text = NSLocalizedString(@"transfersEmptyState_titleAll", @"Title shown when the there's no transfers and they aren't paused");
            break;
    }
  
    return text;
}

- (UIImage *)imageForEmptyState {
    UIImage *image;
    switch (self.transfersSelected) {
        case TransfersWidgetSelectedAll:
            if (self.areTransfersPaused) {
                image = [UIImage imageNamed:@"pausedTransfersEmptyState"];
            } else {
                image = [UIImage imageNamed:@"transfersEmptyState"];
            }
            break;
        case TransfersWidgetSelectedCompleted:
            image = [UIImage imageNamed:@"transfersEmptyState"];
            break;
    }
    return image;
}

#pragma mark - MEGARequestDelegate

- (void)onRequestFinish:(MEGASdk *)api request:(MEGARequest *)request error:(MEGAError *)error {
    if (error.type) {
        return;
    }
    
    switch ([request type]) {
        case MEGARequestTypeLogout: {
            [self removeAllCompletedTransfers];
            [self reloadView];
            break;
        }
            
        case MEGARequestTypePauseTransfers: {
            [[NSUserDefaults standardUserDefaults] setBool:request.flag forKey:@"TransfersPaused"];
            self.transfersPaused = request.flag;
            [self reloadView];
            break;
        }
            
        case MEGARequestTypeCancelTransfers: {
            [self reloadView];
            [SVProgressHUD showImage:[UIImage imageNamed:@"hudMinus"] status:NSLocalizedString(@"transfersCancelled", nil)];
            break;
        }
            
        default:
            break;
    }
}

#pragma mark - getters

- (NSMutableArray *)transfers {
    if (!_transfers) {
        _transfers = [[NSMutableArray alloc] initWithArray:[self.transfersUseCaseHelper transfers]];
    }
    return _transfers;
}

- (NSMutableArray *)completedTransfers {
    _completedTransfers = [[NSMutableArray alloc] initWithArray:[self.transfersUseCaseHelper completedTransfers]];
    return _completedTransfers;
}

#pragma mark - MEGATransferDelegate

- (void)onTransferStart:(MEGASdk *)api transfer:(MEGATransfer *)transfer {
    switch (self.transfersSelected) {
        case TransfersWidgetSelectedAll:
            break;
            
        case TransfersWidgetSelectedCompleted:
            if (transfer.type == MEGATransferTypeUpload) return;
            break;
            
    }
    [self.transfers addObject:transfer];

    if (transfer.type == MEGATransferTypeUpload) {
        [self reloadView];
    } else if (transfer.type == MEGATransferTypeDownload) {
        NSIndexPath *indexPath = [self indexPathForPendingTransfer:transfer];
        if (indexPath) {
            [self.transfers replaceObjectAtIndex:indexPath.row withObject:transfer];
        }
    }
}

- (void)onTransferUpdate:(MEGASdk *)api transfer:(MEGATransfer *)transfer {
    NSIndexPath *indexPath = [self indexPathForPendingTransfer:transfer];
    if (indexPath && self.inProgressButton.isSelected) {
        TransferTableViewCell *cell = (TransferTableViewCell *)[self.tableView cellForRowAtIndexPath:indexPath];
        if ([[self.tableView indexPathsForVisibleRows] containsObject:indexPath] && [cell isKindOfClass:TransferTableViewCell.class]) {
            if (transfer.state == MEGATransferStateActive && !self.areTransfersPaused) {
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
        [SVProgressHUD showImage:[UIImage imageNamed:@"hudMinus"] status:NSLocalizedString(@"transferCancelled", nil)];
    }
    
    [self deleteUploadingTransfer:transfer];
}

#pragma mark - TransferTableViewCellDelegate

- (void)pauseTransfer:(MEGATransfer *)transfer {
    NSIndexPath *oldIndexPath = [self indexPathForPendingTransfer:transfer];
    if (!transfer) {
        return;
    }
    [self.transfers replaceObjectAtIndex:oldIndexPath.row withObject:transfer];
    
    [self.tableView reloadData];
}

- (void)cancelQueuedUploadTransfer:(NSString *)localIdentifier {
    NSIndexPath *indexPath = [self indexPathForUploadTransferQueuedWithLocalIdentifier:localIdentifier];
    if (localIdentifier && indexPath) {
        [SVProgressHUD showImage:[UIImage imageNamed:@"hudMinus"] status:NSLocalizedString(@"transferCancelled", nil)];
        
        [self.uploadTransfersQueued removeObjectAtIndex:indexPath.row];
        [[MEGAStore shareInstance] deleteUploadTransferWithLocalIdentifier:localIdentifier];
        [self.tableView reloadData];
    }
}

#pragma mark - TransferActionViewController

- (void)transferAction:(NodeActionViewController *)nodeAction didSelect:(MegaNodeActionType)action for:(MEGATransfer *)transfer from:(id)sender {
    MEGANode *node = transfer.node;
    if (!node && transfer.type == MEGATransferTypeDownload) {
        return;
    }
    
    switch (action) {

        case MegaNodeActionTypeShareLink:
        case MegaNodeActionTypeManageLink: {
            if (MEGAReachabilityManager.isReachableHUDIfNot && node != nil) {
                MEGANavigationController *getLinkNC = [GetLinkViewController instantiateWithNodes:@[node]];
                [self presentViewController:getLinkNC animated:YES completion:nil];
            }
            break;
        }
        case MegaNodeActionTypeViewInFolder: {

            MEGANode *parentNode = [[MEGASdkManager sharedMEGASdk] nodeForHandle:node.parentHandle];
            if (parentNode.isFolder) {
                [self openFolderNode:parentNode];
            }

            break;

        }
        case MegaNodeActionTypeRetry: {

            [MEGASdkManager.sharedMEGASdk retryTransfer:transfer];
            [self removeFromCompletedTransfers:transfer];
            [self.tableView reloadData];
            break;
        }
        case MegaNodeActionTypeClear: {
            __block MEGATransfer *selectedTransfer;
            [self.completedTransfers enumerateObjectsUsingBlock:^(MEGATransfer * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
                if (obj.nodeHandle == node.handle) {
                    selectedTransfer = obj;
                    *stop = YES;
                };
            }];
            [self removeFromCompletedTransfers:selectedTransfer];
            [self.tableView reloadData];
            break;

        }
        default:
            break;
    }

}

#pragma mark - Private


- (void)switchEdit {
    BOOL isEditing = self.completedTransfers.count > 0 ? !self.tableView.editing : false;
    [self.tableView setEditing:isEditing animated:YES];
    [self.editBarButtonItem setTitle:self.tableView.isEditing ? NSLocalizedString(@"done", @"") : NSLocalizedString(@"edit", @"Caption of a button to edit the files that are selected")];
    self.navigationItem.rightBarButtonItems = self.tableView.isEditing ? @[self.editBarButtonItem, self.cancelBarButtonItem] : @[self.editBarButtonItem];

    [self reloadView];
    if (self.tableView.isEditing) {
        [self pauseTransfersAction:nil];
    } else {
        [self resumeTransfersAction:nil];
    }
}

- (void)openFolderNode:(MEGANode *)node {
    CloudDriveViewController *cloudDriveVC = [[UIStoryboard storyboardWithName:@"Cloud" bundle:nil] instantiateViewControllerWithIdentifier:@"CloudDriveID"];
    cloudDriveVC.parentNode = node;
    
    [self.navigationController pushViewController:cloudDriveVC animated:YES];
}

- (void)showNode:(MEGANode *)node {
    [self.navigationController presentViewController:[self photoBrowserForMediaNode:node] animated:YES completion:nil];
}

- (MEGAPhotoBrowserViewController *)photoBrowserForMediaNode:(MEGANode *)node {
    MEGAPhotoBrowserViewController *photoBrowserVC = [MEGAPhotoBrowserViewController photoBrowserWithMediaNodes:@[node].mutableCopy api:[MEGASdkManager sharedMEGASdk] displayMode:DisplayModeTransfers presentingNode:node preferredIndex:0];
    
    return photoBrowserVC;
}

@end
