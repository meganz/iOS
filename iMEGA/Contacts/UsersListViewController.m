
#import "UsersListViewController.h"
#import "UserCollectionViewCell.h"
#import "MEGAUser+MNZCategory.h"
#import "UIImageView+MNZCategory.h"

@interface UsersListViewController () <UICollectionViewDataSource>

@property (weak, nonatomic) IBOutlet UICollectionView *collectionView;

@property (strong, nonatomic) NSMutableArray<MEGAUser *> *users;

@end

@implementation UsersListViewController

#pragma mark - Lifecycle

- (void)viewDidLoad {
    [super viewDidLoad];

    self.users = [NSMutableArray new];
}

#pragma mark - Public

- (void)addUser:(MEGAUser *)user {
    [self.collectionView performBatchUpdates:^{
        [self.users addObject:user];
        [self.collectionView insertItemsAtIndexPaths:@[[NSIndexPath indexPathForRow:self.users.count-1 inSection:0]]];
    } completion:^(BOOL finished) {
        [self.collectionView scrollToItemAtIndexPath:[NSIndexPath indexPathForRow:self.users.count-1 inSection:0] atScrollPosition:UICollectionViewScrollPositionRight animated:YES];
    }];
}

- (void)removeUser:(MEGAUser *)user {
    [self.collectionView performBatchUpdates:^{
        [self.collectionView deleteItemsAtIndexPaths:@[[self indexPathForUser:user]]];
        [self.users removeObject:user];
    } completion:nil];
}

#pragma mark - Actions

- (IBAction)removeUserAction:(UIButton *)sender {
    NSIndexPath *indexPath = [self.collectionView indexPathForItemAtPoint:[sender convertPoint:CGPointZero toView:self.collectionView]];
    MEGAUser *user = [self.users objectAtIndex:indexPath.row];
    if ([self.userListDelegate respondsToSelector:@selector(removeSelectedUser:)]) {
        [self.userListDelegate removeSelectedUser:user];
    }
    [self removeUser:user];
}

#pragma mark - Private

- (NSIndexPath *)indexPathForUser:(MEGAUser *)user {
    return [NSIndexPath indexPathForRow:[self.users indexOfObject:user] inSection:0];
}

#pragma mark - CollectionViewDataSource

- (NSInteger)collectionView:(UICollectionView *)collectionView numberOfItemsInSection:(NSInteger)section {
    return self.users.count;
}

- (UICollectionViewCell *)collectionView:(UICollectionView *)collectionView cellForItemAtIndexPath:(NSIndexPath *)indexPath {
    MEGAUser *user = [self.users objectAtIndex:indexPath.row];
    UserCollectionViewCell *userCell = [self.collectionView dequeueReusableCellWithReuseIdentifier:@"UserCollectionViewCellID" forIndexPath:indexPath];
    userCell.nameLabel.text = user.mnz_firstName;
    [userCell.avatarImageView mnz_setImageForUserHandle:user.handle];
    return userCell;
}

@end
