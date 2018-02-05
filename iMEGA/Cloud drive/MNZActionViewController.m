
#import "MNZActionViewController.h"
#import "Helper.h"
#import "MEGASdkManager.h"

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

- (NSArray<MegaActionNode *>*)getActions {
    NSMutableArray *actions = [NSMutableArray new];
    
    [actions addObject:[self actionShare]];
    [actions addObject:[self actionDownload]];
    
    return actions;
}

- (MegaActionNode *)actionShare {
    MegaActionNode *action = [[MegaActionNode alloc] init];
    action.title = @"Share";
    action.iconName = @"shareGray";
    [action setActionBlock:^{
        NSLog(@"share pulsada");
    }];
    return action;
}

- (MegaActionNode *)actionDownload {
    MegaActionNode *action = [[MegaActionNode alloc] init];
    action.title = @"Download";
    action.iconName = @"download";
    return action;
}

- (MegaActionNode *)actionFileInfo {
    MegaActionNode *action = [[MegaActionNode alloc] init];
    action.title = @"Download";
    action.iconName = @"download";
    return action;
}

- (MegaActionNode *)actionRename {
    MegaActionNode *action = [[MegaActionNode alloc] init];
    action.title = @"Download";
    action.iconName = @"download";
    return action;
}

- (MegaActionNode *)actionCopy {
    MegaActionNode *action = [[MegaActionNode alloc] init];
    action.title = @"Download";
    action.iconName = @"download";
    return action;
}

- (MegaActionNode *)actionMove {
    MegaActionNode *action = [[MegaActionNode alloc] init];
    action.title = @"Download";
    action.iconName = @"download";
    return action;
}

- (MegaActionNode *)actionMoveToRubbishBin {
    MegaActionNode *action = [[MegaActionNode alloc] init];
    action.title = @"Download";
    action.iconName = @"download";
    return action;
}

- (MegaActionNode *)actionRemove {
    MegaActionNode *action = [[MegaActionNode alloc] init];
    action.title = @"Download";
    action.iconName = @"download";
    return action;
}

#pragma mark Actions

- (IBAction)tapCancel:(id)sender {
    [self dismissViewControllerAnimated:YES completion:nil];
}

@end
