
#import "MNZActionViewController.h"
#import "Helper.h"
#import "MEGASdkManager.h"
#import "MEGAStore.h"

#define kCollectionViewHeaderHeight 80
#define kCollectionViewCellHeight 60
#define kCollectionViewMaxHeight [[UIScreen mainScreen] bounds].size.height - 84

@interface MegaActionNode : NSObject

@property (strong, nonatomic) NSString *title;
@property (strong, nonatomic) NSString *iconName;
@property (nonatomic, copy) void (^actionBlock)(void);

@end

@implementation MegaActionNode

@end

@interface MNZActionViewController () <UICollectionViewDelegate, UICollectionViewDataSource>

@property (weak, nonatomic) IBOutlet UICollectionView *collectionView;
@property (weak, nonatomic) IBOutlet NSLayoutConstraint *collectionViewHeight;
@property (strong, nonatomic) NSArray<MegaActionNode *> *actions;

@property (nonatomic) MEGAShareType accessType;

@end

@implementation MNZActionViewController

#pragma mark Lifecycle

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
    
    self.accessType = [[MEGASdkManager sharedMEGASdk] accessLevelForNode:self.node];

    self.actions = [self getActions];
    [self redrawCollectionView];

}

#pragma mark Layout

- (void)viewWillTransitionToSize:(CGSize)size withTransitionCoordinator:(id<UIViewControllerTransitionCoordinator>)coordinator {
    [super viewWillTransitionToSize:size withTransitionCoordinator:coordinator];
    
    [coordinator animateAlongsideTransition:^(id<UIViewControllerTransitionCoordinatorContext> context) {
        [self redrawCollectionView];
    } completion:nil];
}

#pragma mark CollectionView DataSource

- (NSInteger)collectionView:(UICollectionView *)collectionView numberOfItemsInSection:(NSInteger)section {
    
    return self.actions.count;
}

- (UICollectionViewCell *)collectionView:(UICollectionView *)collectionView cellForItemAtIndexPath:(NSIndexPath *)indexPath {
    MegaActionNode *action = [self.actions objectAtIndex:indexPath.row];
    UICollectionViewCell *cell = [self.collectionView dequeueReusableCellWithReuseIdentifier:@"actionCell" forIndexPath:indexPath];
    UILabel *title = [cell viewWithTag:1];
    title.text = action.title;
    UIImageView *imageView = [cell viewWithTag:100];
    [imageView setImage:[UIImage imageNamed:action.iconName]];
    
    return cell;
}

- (UICollectionReusableView *)collectionView:(UICollectionView *)collectionView viewForSupplementaryElementOfKind:(NSString *)kind atIndexPath:(NSIndexPath *)indexPath {
    
    UICollectionReusableView *header = [self.collectionView dequeueReusableSupplementaryViewOfKind:kind withReuseIdentifier:@"actionHeader" forIndexPath:indexPath];
    
    UILabel *title = [header viewWithTag:1];
    title.text = self.node.name;
    UILabel *info = [header viewWithTag:2];
    info.text = [Helper sizeAndDateForNode:self.node api:[MEGASdkManager sharedMEGASdk]];

    UIImageView *imageView = [header viewWithTag:100];
    if ([self.node type] == MEGANodeTypeFile) {
        if ([self.node hasThumbnail]) {
            [Helper thumbnailForNode:self.node api:[MEGASdkManager sharedMEGASdk] cell:header];
        } else {
            [imageView setImage:[Helper imageForNode:self.node]];
        }
    } else if ([self.node type] == MEGANodeTypeFolder) {
        [imageView setImage:[Helper imageForNode:self.node]];
        info.text = [Helper filesAndFoldersInFolderNode:self.node api:[MEGASdkManager sharedMEGASdk]];
    }
    
    return header;
}

#pragma mark CollectionView Delegate

- (void)collectionView:(UICollectionView *)collectionView didSelectItemAtIndexPath:(NSIndexPath *)indexPath {
    [self.actions objectAtIndex:indexPath.row].actionBlock();
}

#pragma mark Private

- (void)redrawCollectionView {
    float collectionMaxHeight = kCollectionViewHeaderHeight + kCollectionViewCellHeight*[self.collectionView numberOfItemsInSection:0];
    float screenHeight = kCollectionViewMaxHeight;
    
    if (collectionMaxHeight > screenHeight) {
        self.collectionViewHeight.constant = kCollectionViewMaxHeight;
    } else {
        self.collectionViewHeight.constant = collectionMaxHeight;
    }
}

#pragma mark MegaActions

- (NSArray<MegaActionNode *>*)getActions {
    NSMutableArray *actions = [NSMutableArray new];
    
    switch (self.accessType) {
        case MEGAShareTypeAccessRead:
        case MEGAShareTypeAccessReadWrite: {
            [actions addObject:[self actionDownload]];
            [actions addObject:[self actionFileInfo]];
            [actions addObject:[self actionCopy]];
            if (self.isIncomingShareChildView) {
                [actions addObject:[self actionLeaveSharing]];
            }
            break;
        }
            
        case MEGAShareTypeAccessFull:
            [actions addObject:[self actionDownload]];
            [actions addObject:[self actionFileInfo]];
            [actions addObject:[self actionCopy]];
            [actions addObject:[self actionRename]];
            if (self.isIncomingShareChildView) {
                [actions addObject:[self actionLeaveSharing]];
            }
            break;
            
        case MEGAShareTypeAccessOwner:
            if (self.displayMode == DisplayModeCloudDrive || self.displayMode == DisplayModeRubbishBin) {
                [actions addObject:[self actionShare]];
                [actions addObject:[self actionDownload]];
                [actions addObject:[self actionFileInfo]];
                [actions addObject:[self actionCopy]];
                [actions addObject:[self actionMove]];
                [actions addObject:[self actionRename]];
                if (self.node.publicLink) {
                    [actions addObject:[self actionRemoveLink]];
                }
                if (self.isIncomingShareChildView) {
                    [actions addObject:[self actionLeaveSharing]];
                }
                if (self.displayMode == DisplayModeCloudDrive) {
                    [actions addObject:[self actionMoveToRubbishBin]];
                } else if (self.displayMode == DisplayModeRubbishBin) {
                    [actions addObject:[self actionRemove]];
                }
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
    
    return actions;
}

- (MegaActionNode *)actionShare {
    MegaActionNode *action = [[MegaActionNode alloc] init];
    action.title = @"Localizar Share";
    action.iconName = @"shareGray";
    [action setActionBlock:^{
        NSLog(@"share pulsada");
    }];
    return action;
}

- (MegaActionNode *)actionDownload {
    MegaActionNode *action = [[MegaActionNode alloc] init];
    if ([[Helper downloadingNodes] objectForKey:self.node.base64Handle] != nil) {
        action.iconName = @"download";
        action.title = AMLocalizedString(@"queued", @"Text shown when one file has been selected to be downloaded but it's on the queue to be downloaded, it's pending for download");
    } else {
        MOOfflineNode *offlineNode = [[MEGAStore shareInstance] offlineNodeWithNode:self.node api:[MEGASdkManager sharedMEGASdk]];
        if (offlineNode != nil) {
            action.iconName = @"downloaded";
            action.title = AMLocalizedString(@"savedForOffline", @"List option shown on the details of a file or folder");
        } else {
            action.iconName = @"download";
            action.title = AMLocalizedString(@"saveForOffline", @"List option shown on the details of a file or folder");
        }
    }
    return action;
}

- (MegaActionNode *)actionFileInfo {
    MegaActionNode *action = [[MegaActionNode alloc] init];
    action.title = @"Localizar File Info";
    action.iconName = @"nodeInfo";
    return action;
}

- (MegaActionNode *)actionRename {
    MegaActionNode *action = [[MegaActionNode alloc] init];
    action.title = AMLocalizedString(@"rename", @"Title for the action that allows you to rename a file or folder");
    action.iconName = @"rename";
    return action;
}

- (MegaActionNode *)actionCopy {
    MegaActionNode *action = [[MegaActionNode alloc] init];
    action.title = AMLocalizedString(@"copy", @"List option shown on the details of a file or folder");
    action.iconName = @"copy";
    return action;
}

- (MegaActionNode *)actionMove {
    MegaActionNode *action = [[MegaActionNode alloc] init];
    action.title = AMLocalizedString(@"move", @"Title for the action that allows you to move a file or folder");
    action.iconName = @"move";
    return action;
}

- (MegaActionNode *)actionMoveToRubbishBin {
    MegaActionNode *action = [[MegaActionNode alloc] init];
    action.title = AMLocalizedString(@"moveToTheRubbishBin", @"Title for the action that allows you to 'Move to the Rubbish Bin' files or folders");
    action.iconName = @"rubbishBin";
    return action;
}

- (MegaActionNode *)actionRemove {
    MegaActionNode *action = [[MegaActionNode alloc] init];
    action.title = AMLocalizedString(@"remove", @"Title for the action that allows to remove a file or folder");
    action.iconName = @"remove";
    return action;
}

- (MegaActionNode *)actionLeaveSharing {
    MegaActionNode *action = [[MegaActionNode alloc] init];
    action.title = AMLocalizedString(@"leaveFolder", @"Button title of the action that allows to leave a shared folder");
    action.iconName = @"leaveShare";
    return action;
}

- (MegaActionNode *)actionRemoveLink {
    MegaActionNode *action = [[MegaActionNode alloc] init];
    action.title = AMLocalizedString(@"removeLink", @"Message shown when there is an active link that can be removed or disabled");
    action.iconName = @"removeLink";
    return action;
}

- (MegaActionNode *)actionRemoveSharing {
    MegaActionNode *action = [[MegaActionNode alloc] init];
    action.title = AMLocalizedString(@"removeSharing", @"Alert title shown on the Shared Items section when you want to remove 1 share");
    action.iconName = @"removeShare";
    return action;
}

#pragma mark IBActions

- (IBAction)tapCancel:(id)sender {
    [self dismissViewControllerAnimated:YES completion:nil];
}

@end
