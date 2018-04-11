#import "CustomActionViewController.h"

#import "Helper.h"
#import "MEGASdkManager.h"
#import "MEGANode+MNZCategory.h"
#import "UIImageView+MNZCategory.h"

#define kCollectionViewHeaderHeight 80
#define kCollectionViewCellHeight 60
#define kCollectionViewMaxHeight [[UIScreen mainScreen] bounds].size.height - 84

@interface MegaActionNode : NSObject

@property (strong, nonatomic) NSString *title;
@property (strong, nonatomic) NSString *iconName;
@property (assign, nonatomic) MegaNodeActionType actionType;

@end

@implementation MegaActionNode

- (instancetype)initWithTitle:(NSString *)title iconName:(NSString*)iconName andActionType:(MegaNodeActionType)actionType {
    self = [super init];
    if (self) {
        _title = title;
        _iconName = iconName;
        _actionType = actionType;
    }
    
    return self;
}

@end

@interface CustomActionViewController () <UICollectionViewDelegate, UICollectionViewDataSource>

@property (weak, nonatomic) IBOutlet UIView *alphaView;
@property (weak, nonatomic) IBOutlet UICollectionView *collectionView;
@property (weak, nonatomic) IBOutlet NSLayoutConstraint *collectionViewHeight;
@property (weak, nonatomic) IBOutlet NSLayoutConstraint *collectionViewLeading;
@property (weak, nonatomic) IBOutlet NSLayoutConstraint *collectionViewTrailing;
@property (weak, nonatomic) IBOutlet NSLayoutConstraint *collectionViewBottom;
@property (weak, nonatomic) IBOutlet UIButton *cancelButton;
@property (strong, nonatomic) NSArray<MegaActionNode *> *actions;

@end

@implementation CustomActionViewController

#pragma mark - Lifecycle

- (void)viewDidLoad {
    [super viewDidLoad];
    
    [self registerCells];
    self.actions = [self getActions];
    [self configureView];
    [self redrawCollectionView];
}

- (void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];
    
    [self fadeInBackgroundCompletion:nil];
}

#pragma mark - Layout

- (void)configureView {
    [self.cancelButton setTitle:AMLocalizedString(@"cancel", @"Button title to cancel something") forState:UIControlStateNormal];
}

- (void)viewWillTransitionToSize:(CGSize)size withTransitionCoordinator:(id<UIViewControllerTransitionCoordinator>)coordinator {
    [super viewWillTransitionToSize:size withTransitionCoordinator:coordinator];
    
    [coordinator animateAlongsideTransition:^(id<UIViewControllerTransitionCoordinatorContext> context) {
        [self redrawCollectionView];
    } completion:nil];
}

#pragma mark - CollectionViewDataSource

- (NSInteger)collectionView:(UICollectionView *)collectionView numberOfItemsInSection:(NSInteger)section {
    
    return self.actions.count;
}

- (UICollectionViewCell *)collectionView:(UICollectionView *)collectionView cellForItemAtIndexPath:(NSIndexPath *)indexPath {
    MegaActionNode *action = [self.actions objectAtIndex:indexPath.row];
    UICollectionViewCell *cell = [self.collectionView dequeueReusableCellWithReuseIdentifier:@"actionCell" forIndexPath:indexPath];
    UILabel *title = [cell viewWithTag:1];
    title.text = action.title;
    UIImageView *imageView = [cell viewWithTag:100];
    imageView.image = [UIImage imageNamed:action.iconName];
    
    if (indexPath.row == self.actions.count-1) {
        UIView *separatorView = [cell viewWithTag:101];
        separatorView.hidden = YES;
    }
    return cell;
}

- (UICollectionReusableView *)collectionView:(UICollectionView *)collectionView viewForSupplementaryElementOfKind:(NSString *)kind atIndexPath:(NSIndexPath *)indexPath {
    
    UICollectionReusableView *header = [self.collectionView dequeueReusableSupplementaryViewOfKind:kind withReuseIdentifier:@"actionHeader" forIndexPath:indexPath];
    
    UILabel *title = [header viewWithTag:1];
    title.text = self.node.name;
    UILabel *info = [header viewWithTag:2];
    info.text = [Helper sizeAndDateForNode:self.node api:[MEGASdkManager sharedMEGASdk]];
    
    UIImageView *imageView = [header viewWithTag:100];
    if (self.node.isFile) {
        [imageView mnz_setThumbnailByNodeHandle:self.node.handle];
    } else if (self.node.isFolder) {
        imageView.image = [Helper imageForNode:self.node];
        info.text = [Helper filesAndFoldersInFolderNode:self.node api:[MEGASdkManager sharedMEGASdk]];
    }
    
    return header;
}

- (CGSize)collectionView:(UICollectionView *)collectionView layout:(UICollectionViewLayout *)collectionViewLayout sizeForItemAtIndexPath:(NSIndexPath *)indexPath {
    return CGSizeMake(self.collectionView.bounds.size.width, 60);
}

#pragma mark - CollectionViewDelegate

- (void)collectionView:(UICollectionView *)collectionView didSelectItemAtIndexPath:(NSIndexPath *)indexPath {
    [self fadeOutBackgroundCompletion:^{
        [self dismissViewControllerAnimated:YES completion:^{
            [self.actionDelegate performAction:[self.actions objectAtIndex:indexPath.row].actionType inNode:self.node fromSender:self.actionSender];
        }];
    }];
}

#pragma mark - Private

- (void)redrawCollectionView {
    float collectionMaxHeight = kCollectionViewHeaderHeight + kCollectionViewCellHeight * [self.collectionView numberOfItemsInSection:0];
    float screenHeight = kCollectionViewMaxHeight;
    
    if (collectionMaxHeight > screenHeight) {
        self.collectionViewHeight.constant = kCollectionViewMaxHeight;
    } else {
        self.collectionViewHeight.constant = collectionMaxHeight;
    }
}

- (void)fadeInBackgroundCompletion:(void (^ __nullable)(void))fadeInCompletion {
    [UIView animateWithDuration:.3 animations:^{
        self.alphaView.alpha = 0.5;
    } completion:^(BOOL finished) {
        if (fadeInCompletion && finished) {
            fadeInCompletion();
        }
    }];
}

- (void)fadeOutBackgroundCompletion:(void (^ __nullable)(void))fadeOutCompletion {
    [UIView animateWithDuration:.2 animations:^{
        self.alphaView.alpha = 0;
    } completion:^(BOOL finished) {
        if (fadeOutCompletion && finished) {
            fadeOutCompletion();
        }
    }];
}

- (void)registerCells {
    [self.collectionView registerNib:[UINib nibWithNibName:@"NodeActionCollectionViewCell" bundle:nil] forCellWithReuseIdentifier:@"actionCell"];
    [self.collectionView registerNib:[UINib nibWithNibName:@"NodeActionHeaderCollectionReusableView" bundle:nil] forSupplementaryViewOfKind:UICollectionElementKindSectionHeader withReuseIdentifier:@"actionHeader"];
}

#pragma mark MegaActions

- (NSArray<MegaActionNode *> *)getActions {
    MEGAShareType accessType = [[MEGASdkManager sharedMEGASdk] accessLevelForNode:self.node];
    
    NSMutableArray *actions = [NSMutableArray new];
    
    if (self.displayMode == DisplayModeFolderLink) {
        [actions addObject:[self actionImport]];
        [actions addObject:[self actionDownload]];
        if (self.node.isFile) {
            [actions addObject:[self actionOpen]];
        }
    } else if (self.displayMode == DisplayModeFileLink) {
        [actions addObject:[self actionImport]];
        [actions addObject:[self actionDownload]];
        [actions addObject:[self actionOpen]];
        [actions addObject:[self actionShare]];
    } else {
        switch (accessType) {
            case MEGAShareTypeAccessRead:
            case MEGAShareTypeAccessReadWrite: {
                [actions addObject:[self actionDownload]];
                if (self.displayMode != DisplayModeNodeVersions) {
                    if (self.displayMode != DisplayModeNodeInfo) {
                        [actions addObject:[self actionFileInfo]];
                    }
                    [actions addObject:[self actionCopy]];
                    if (self.isIncomingShareChildView) {
                        [actions addObject:[self actionLeaveSharing]];
                    }
                }
                break;
            }
                
            case MEGAShareTypeAccessFull:
                [actions addObject:[self actionDownload]];
                if (self.displayMode == DisplayModeNodeVersions) {
                    [actions addObject:[self actionRevertVersion]];
                    [actions addObject:[self actionRemove]];
                } else {
                    if (self.displayMode != DisplayModeNodeInfo) {
                        [actions addObject:[self actionFileInfo]];
                    }
                    [actions addObject:[self actionCopy]];
                    [actions addObject:[self actionRename]];
                    if (self.isIncomingShareChildView) {
                        [actions addObject:[self actionLeaveSharing]];
                    }
                }
                break;
                
            case MEGAShareTypeAccessOwner:
                if (self.displayMode == DisplayModeCloudDrive || self.displayMode == DisplayModeRubbishBin || self.displayMode == DisplayModeNodeInfo) {
                    [actions addObject:[self actionShare]];
                    [actions addObject:[self actionDownload]];
                    if (self.displayMode != DisplayModeNodeInfo) {
                        [actions addObject:[self actionFileInfo]];
                    }
                    [actions addObject:[self actionCopy]];
                    [actions addObject:[self actionMove]];
                    [actions addObject:[self actionRename]];
                    if (self.isIncomingShareChildView) {
                        [actions addObject:[self actionLeaveSharing]];
                    }
                    if (self.displayMode == DisplayModeCloudDrive) {
                        [actions addObject:[self actionMoveToRubbishBin]];
                    } else if (self.displayMode == DisplayModeRubbishBin) {
                        [actions addObject:[self actionRemove]];
                    }
                } else if (self.displayMode == DisplayModeNodeVersions) {
                    [actions addObject:[self actionDownload]];
                    [actions addObject:[self actionRevertVersion]];
                    [actions addObject:[self actionRemove]];
                } else {
                    [actions addObject:[self actionShare]];
                    [actions addObject:[self actionDownload]];
                    [actions addObject:[self actionFileInfo]];
                    [actions addObject:[self actionCopy]];
                    [actions addObject:[self actionRename]];
                    [actions addObject:[self actionRemoveSharing]];
                }
                break;
                
            default:
                break;
        }
    }
    
    if (self.excludedActions.count > 0) {
        NSMutableArray *actionsToRemove = [NSMutableArray new];
        for (MegaActionNode *action in actions) {
            if ([self.excludedActions containsObject:@(action.actionType)]) {
                [actionsToRemove addObject:action];
            }
        }
        [actions removeObjectsInArray:actionsToRemove];
    }
    
    return actions;
}

- (MegaActionNode *)actionShare {
    return [[MegaActionNode alloc] initWithTitle:AMLocalizedString(@"share", @"Button title which, if tapped, will trigger the action of sharing with the contact or contacts selected") iconName: @"share" andActionType:MegaNodeActionTypeShare];
}

- (MegaActionNode *)actionDownload {
    return [[MegaActionNode alloc] initWithTitle:AMLocalizedString(@"download", nil) iconName: @"offline" andActionType:MegaNodeActionTypeDownload];
}

- (MegaActionNode *)actionFileInfo {
    NSString *infoTitle = self.node.isFile ? AMLocalizedString(@"fileInfo", @"Label of the option menu. When clicking this button, the app shows the info of the file.") : AMLocalizedString(@"folderInfo", @"Label of the option menu. When clicking this button, the app shows the info of the folder.");
    return [[MegaActionNode alloc] initWithTitle:infoTitle iconName: @"info" andActionType:MegaNodeActionTypeFileInfo];
}

- (MegaActionNode *)actionRename {
    return [[MegaActionNode alloc] initWithTitle:AMLocalizedString(@"rename", @"Title for the action that allows you to rename a file or folder") iconName: @"rename_node" andActionType:MegaNodeActionTypeRename];
}

- (MegaActionNode *)actionCopy {
    return [[MegaActionNode alloc] initWithTitle:AMLocalizedString(@"copy", @"List option shown on the details of a file or folder") iconName: @"copy" andActionType:MegaNodeActionTypeCopy];
}

- (MegaActionNode *)actionMove {
    return [[MegaActionNode alloc] initWithTitle:AMLocalizedString(@"move", @"Title for the action that allows you to move a file or folder") iconName: @"move" andActionType:MegaNodeActionTypeMove];
}

- (MegaActionNode *)actionMoveToRubbishBin {
    return [[MegaActionNode alloc] initWithTitle:AMLocalizedString(@"moveToTheRubbishBin", @"Title for the action that allows you to 'Move to the Rubbish Bin' files or folders") iconName: @"rubbishBin" andActionType:MegaNodeActionTypeMoveToRubbishBin];
}

- (MegaActionNode *)actionRemove {
    return [[MegaActionNode alloc] initWithTitle:AMLocalizedString(@"remove", @"Title for the action that allows to remove a file or folder") iconName: @"remove" andActionType:MegaNodeActionTypeRemove];
}

- (MegaActionNode *)actionLeaveSharing {
    return [[MegaActionNode alloc] initWithTitle:AMLocalizedString(@"leaveFolder", @"Button title of the action that allows to leave a shared folder") iconName: @"leaveShare" andActionType:MegaNodeActionTypeLeaveSharing];
}

- (MegaActionNode *)actionRemoveLink {
    return [[MegaActionNode alloc] initWithTitle:AMLocalizedString(@"removeLink", @"Message shown when there is an active link that can be removed or disabled") iconName: @"removeLink" andActionType:MegaNodeActionTypeRemoveLink];
}

- (MegaActionNode *)actionRemoveSharing {
    return [[MegaActionNode alloc] initWithTitle:AMLocalizedString(@"removeSharing", @"Alert title shown on the Shared Items section when you want to remove 1 share") iconName: @"removeShare" andActionType:MegaNodeActionTypeRemoveSharing];
}

- (MegaActionNode *)actionImport {
    return [[MegaActionNode alloc] initWithTitle:AMLocalizedString(@"import", nil) iconName: @"infoImport" andActionType:MegaNodeActionTypeImport];
}

- (MegaActionNode *)actionOpen {
    return [[MegaActionNode alloc] initWithTitle:AMLocalizedString(@"openButton", nil) iconName: @"infoOpen" andActionType:MegaNodeActionTypeOpen];
}
        
- (MegaActionNode *)actionRevertVersion {
    return [[MegaActionNode alloc] initWithTitle:AMLocalizedString(@"revert", @"A button label which reverts a certain version of a file to be the current version of the selected file.") iconName: @"history" andActionType:MegaNodeActionTypeRevertVersion];
}

- (MegaActionNode *)actionRemoveVersion {
    return [[MegaActionNode alloc] initWithTitle:AMLocalizedString(@"delete", nil) iconName: @"remove" andActionType:MegaNodeActionTypeRemove];
}

#pragma mark - IBActions

- (IBAction)tapCancel:(id)sender {
    [self fadeOutBackgroundCompletion:^{
        [self dismissViewControllerAnimated:YES completion:nil];
    }];
}

- (IBAction)touchUpOutside:(id)sender {
    [self tapCancel:sender];
}

#pragma mark - PopOverDelegate

- (void)prepareForPopoverPresentation:(UIPopoverPresentationController *)popoverPresentationController {
    self.cancelButton.hidden = YES;
    self.collectionViewBottom.constant = 0;
    self.collectionViewLeading.constant = 0;
    self.collectionViewLeading.priority = 1000;
    self.collectionViewTrailing.constant = 0;
    self.collectionViewTrailing.priority = 1000;
    float collectionMaxHeight = kCollectionViewHeaderHeight + kCollectionViewCellHeight * [self getActions].count;
    self.preferredContentSize = CGSizeMake(self.collectionView.bounds.size.width, collectionMaxHeight);
}

@end

