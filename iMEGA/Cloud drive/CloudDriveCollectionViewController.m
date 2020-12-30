
#import "CloudDriveCollectionViewController.h"

#import "NSString+MNZCategory.h"

#import "MEGANode+MNZCategory.h"

#import "MEGAReachabilityManager.h"
#import "MEGASdkManager.h"

#import "CloudDriveViewController.h"
#import "NodeCollectionViewCell.h"

@interface CloudDriveCollectionViewController () <UICollectionViewDataSource, UICollectionViewDelegate>

@property (weak, nonatomic) IBOutlet UIView *searchView;
@property (weak, nonatomic) IBOutlet NSLayoutConstraint *searchViewTopConstraint;

@end

@implementation CloudDriveCollectionViewController

#pragma mark - Lifecycle

- (void)viewDidLoad {
    [super viewDidLoad];

    [self.searchView addSubview:self.cloudDrive.searchController.searchBar];
    self.cloudDrive.searchController.searchBar.autoresizingMask = UIViewAutoresizingFlexibleWidth;
}

#pragma mark - UICollectionViewDataSource

- (NSInteger)collectionView:(UICollectionView *)collectionView numberOfItemsInSection:(NSInteger)section {
    NSInteger numberOfRows = 0;
    if ([MEGAReachabilityManager isReachable]) {
        if (self.cloudDrive.searchController.searchBar.text.length >= kMinimumLettersToStartTheSearch) {
            numberOfRows = self.cloudDrive.searchNodesArray.count;
        } else {
            numberOfRows = self.cloudDrive.nodes.size.integerValue;
        }
    }
    return numberOfRows;
}

- (UICollectionViewCell *)collectionView:(UICollectionView *)collectionView cellForItemAtIndexPath:(NSIndexPath *)indexPath {
    MEGANode *node = [self.cloudDrive nodeAtIndexPath:indexPath];

    NodeCollectionViewCell *cell = [self.collectionView dequeueReusableCellWithReuseIdentifier:@"NodeCollectionID" forIndexPath:indexPath];
    [cell configureCellForNode:node];
    
    return cell;
}

- (void)collectionView:(UICollectionView *)collectionView willDisplayCell:(UICollectionViewCell *)cell forItemAtIndexPath:(NSIndexPath *)indexPath {
    MEGANode *node = [self.cloudDrive nodeAtIndexPath:indexPath];
    
    NodeCollectionViewCell *nodeCell = (NodeCollectionViewCell *)cell;
    
    if (self.collectionView.allowsMultipleSelection) {
        nodeCell.selectImageView.hidden = NO;
        BOOL selected = NO;
        for (MEGANode *tempNode in self.cloudDrive.selectedNodesArray) {
            if (tempNode.handle == node.handle) {
                selected = YES;
                [self.collectionView selectItemAtIndexPath:indexPath animated:NO scrollPosition:UICollectionViewScrollPositionNone];
            }
        }
        [nodeCell selectCell:selected];
    } else {
        nodeCell.selectImageView.hidden = YES;
    }
}

#pragma mark - UICollectionViewDelegate

- (void)collectionView:(UICollectionView *)collectionView didSelectItemAtIndexPath:(NSIndexPath *)indexPath {
    MEGANode *node = [self.cloudDrive nodeAtIndexPath:indexPath];
    if (node == nil) {
        return;
    }
    
    if (collectionView.allowsMultipleSelection) {
        [self.cloudDrive.selectedNodesArray addObject:node];
        
        [self.cloudDrive updateNavigationBarTitle];
        
        [self.cloudDrive toolbarActionsForNodeArray:self.cloudDrive.selectedNodesArray];
        
        [self.cloudDrive setToolbarActionsEnabled:YES];
        
        self.cloudDrive.allNodesSelected = (self.cloudDrive.selectedNodesArray.count == self.cloudDrive.nodes.size.integerValue);
        
        NodeCollectionViewCell *cell = (NodeCollectionViewCell *)[self.collectionView cellForItemAtIndexPath:indexPath];
        [cell selectCell:YES];
        
        return;
    }
    
    [self.cloudDrive didSelectNode:node];
}

- (void)collectionView:(UICollectionView *)collectionView didDeselectItemAtIndexPath:(NSIndexPath *)indexPath {
    if (indexPath.row > self.cloudDrive.nodes.size.integerValue) {
        return;
    }
    
    if (collectionView.allowsMultipleSelection) {
        MEGANode *node = [self.cloudDrive.nodes nodeAtIndex:indexPath.row];

        NSMutableArray *tempArray = [self.cloudDrive.selectedNodesArray copy];
        for (MEGANode *tempNode in tempArray) {
            if (tempNode.handle == node.handle) {
                [self.cloudDrive.selectedNodesArray removeObject:tempNode];
            }
        }
        
        [self.cloudDrive updateNavigationBarTitle];
        
        [self.cloudDrive toolbarActionsForNodeArray:self.cloudDrive.selectedNodesArray];
        
        if (self.cloudDrive.selectedNodesArray.count == 0) {
            [self.cloudDrive setToolbarActionsEnabled:NO];
        } else {
            if ([[MEGASdkManager sharedMEGASdk] isNodeInRubbish:node]) {
                [self.cloudDrive setToolbarActionsEnabled:YES];
            }
        }
        
        self.cloudDrive.allNodesSelected = NO;
        
        NodeCollectionViewCell *cell = (NodeCollectionViewCell *)[self.collectionView cellForItemAtIndexPath:indexPath];
        [cell selectCell:NO];
    }
}

#pragma mark - UIScrolViewDelegate

- (void)scrollViewDidScroll:(UIScrollView *)scrollView {
    //keep the search view next to collection view offset when scroll and adjust collection insets to the offset simulating that the search bar is embed into the collection
    self.searchViewTopConstraint.constant = - scrollView.contentOffset.y - 50;
    self.collectionView.contentInset = UIEdgeInsetsMake(MAX(0, MIN(-scrollView.contentOffset.y, 50)), 0, 0, 0);
    
    if (self.cloudDrive.searchController.isActive) {
        [self.cloudDrive.searchController.searchBar resignFirstResponder];
    }
}

- (void)scrollViewDidEndDragging:(UIScrollView *)scrollView willDecelerate:(BOOL)decelerate {
    if (scrollView.contentOffset.y > -50 && scrollView.contentOffset.y < 0) { //Search bar is partially visible when end dragging
        if ([scrollView.panGestureRecognizer velocityInView:scrollView].y < 0) { //Hide search bar if scrolling up
            [UIView animateWithDuration:.2 delay:0 options:UIViewAnimationOptionCurveLinear animations:^{
                self.searchViewTopConstraint.constant = -50;
                self.collectionView.contentOffset = CGPointZero;
                self.collectionView.contentInset = UIEdgeInsetsZero;
                [self.view layoutIfNeeded];
            } completion:nil];
        } else { //Show search bar if scrolling down
            [UIView animateWithDuration:.2 animations:^{
                self.collectionView.contentInset = UIEdgeInsetsMake(50, 0, 0, 0);
                self.searchViewTopConstraint.constant = 0;
                self.collectionView.contentOffset = CGPointMake(0, -50);
                [self.view layoutIfNeeded];
            }];
        }
    }
}

#pragma mark - Actions

- (IBAction)infoTouchUpInside:(UIButton *)sender {
    if (self.collectionView.allowsMultipleSelection) {
        return;
    }
    
    CGPoint buttonPosition = [sender convertPoint:CGPointZero toView:self.collectionView];
    NSIndexPath *indexPath = [self.collectionView indexPathForItemAtPoint:buttonPosition];
    
    MEGANode *node = [self.cloudDrive nodeAtIndexPath:indexPath];
    if (node == nil) {
        return;
    }
    
    [self.cloudDrive showCustomActionsForNode:node sender:sender];
}

#pragma mark - Public

- (void)setCollectionViewEditing:(BOOL)editing animated:(BOOL)animated {
    self.collectionView.allowsMultipleSelection = editing;
    [self.cloudDrive setViewEditing:editing];
    
    for (NodeCollectionViewCell *cell in [self.collectionView visibleCells]) {
        cell.selectImageView.hidden = !editing;
        cell.selectImageView.image = [UIImage imageNamed:@"checkBoxUnselected"];
    }
}

- (void)collectionViewSelectIndexPath:(NSIndexPath *)indexPath {
    [self collectionView:self.collectionView didSelectItemAtIndexPath:indexPath];
}

- (void)resetSearchBarPosition {
    self.collectionView.contentInset = UIEdgeInsetsZero;
}

@end
