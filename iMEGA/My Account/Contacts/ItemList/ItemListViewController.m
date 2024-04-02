#import "ItemListViewController.h"
#import "ItemCollectionViewCell.h"
#import "UIImageView+MNZCategory.h"
#import "UIImage+GKContact.h"

#ifdef MNZ_SHARE_EXTENSION
#import "MEGAShare-Swift.h"
#elif MNZ_NOTIFICATION_EXTENSION
#import "MEGANotifications-Swift.h"
#elif MNZ_WIDGET_EXTENSION
#import "MEGAWidgetExtension-Swift.h"
#else
#import "MEGA-Swift.h"
#endif

@interface ItemListViewController () <UICollectionViewDataSource>

@property (weak, nonatomic) IBOutlet UICollectionView *collectionView;

@property (strong, nonatomic) NSMutableArray<ItemListModel *> *items;

@end

@implementation ItemListViewController

#pragma mark - Lifecycle

- (void)viewDidLoad {
    [super viewDidLoad];

    self.items = [NSMutableArray new];
}

#pragma mark - Public

- (void)addItem:(ItemListModel *)item {
    if ([self isNewItem:item]) {
        [self.collectionView performBatchUpdates:^{
            [self.items addObject:item];
            [self.collectionView insertItemsAtIndexPaths:@[[NSIndexPath indexPathForRow:self.items.count-1 inSection:0]]];
        } completion:^(BOOL finished) {
            if (self.items.count) {
                [self.collectionView scrollToItemAtIndexPath:[NSIndexPath indexPathForRow:self.items.count-1 inSection:0] atScrollPosition:UICollectionViewScrollPositionRight animated:YES];
            }
        }];
    }
}

- (void)removeItem:(ItemListModel *)item {
    NSIndexPath *indexPath = [self indexPathForItem:item];
    if (!indexPath) {
        NSAssert(NO, @"Unexpected, should have index for each item");
        return;
    }
    [self.collectionView performBatchUpdates:^{
        [self.collectionView deleteItemsAtIndexPaths:@[indexPath]];
        [self deleteItemFromList:item];
    } completion:nil];
}

#pragma mark - Actions

- (IBAction)removeUserAction:(UIButton *)sender {
    NSIndexPath *indexPath = [self.collectionView indexPathForItemAtPoint:[sender convertPoint:CGPointZero toView:self.collectionView]];
    id item = [self.items objectAtIndex:indexPath.row].model;
    if ([self.itemListDelegate respondsToSelector:@selector(removeSelectedItem:)]) {
        [self.itemListDelegate removeSelectedItem:item];
    }
    [self removeItem:[self.items objectAtIndex:indexPath.row]];
}

#pragma mark - Private

- (NSIndexPath *)indexPathForItem:(ItemListModel *)item {
    for (ItemListModel *itemInList in self.items) {
        if ([item isEqual:itemInList]) {
            return [NSIndexPath indexPathForRow:[self.items indexOfObject:itemInList] inSection:0];
        }
    }
    return nil;
}

- (void)deleteItemFromList:(ItemListModel *)item {
    ItemListModel *itemFound = nil;
    for (ItemListModel *itemInList in self.items) {
        if ([item isEqual:itemInList]) {
            itemFound = itemInList;
            break;
        }
    }
    if (itemFound) {
        [self.items removeObject:itemFound];
    }
}

- (BOOL)isNewItem:(ItemListModel *)item {
    for (ItemListModel *itemInList in self.items) {
        if ([item isEqual:itemInList]) {
            return NO;
        }
    }
    return YES;
}

#pragma mark - CollectionViewDataSource

- (NSInteger)collectionView:(UICollectionView *)collectionView numberOfItemsInSection:(NSInteger)section {
    return self.items.count;
}

- (UICollectionViewCell *)collectionView:(UICollectionView *)collectionView cellForItemAtIndexPath:(NSIndexPath *)indexPath {
    ItemCollectionViewCell *itemCell = [self.collectionView dequeueReusableCellWithReuseIdentifier:@"ItemCollectionViewCellID" forIndexPath:indexPath];
    ItemListModel *item = [self.items objectAtIndex:indexPath.row];

    [self setupCell:itemCell with:item];

    return itemCell;
}

@end
