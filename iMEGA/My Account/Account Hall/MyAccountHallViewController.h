NS_ASSUME_NONNULL_BEGIN

@class MyAccountHallViewModel, MEGALabel;

@interface MyAccountHallViewController : UIViewController

@property (weak, nonatomic) IBOutlet UITableView *tableView;
@property (weak, nonatomic) IBOutlet UILabel *accountTypeLabel;
@property (weak, nonatomic) IBOutlet UIImageView *avatarImageView;
@property (weak, nonatomic) IBOutlet UIView *tableFooterView;
@property (weak, nonatomic) IBOutlet UILabel *tableFooterLabel;
@property (weak, nonatomic) IBOutlet MEGALabel *nameLabel;

@property (weak, nonatomic) IBOutlet UIView *profileView;
@property (weak, nonatomic) IBOutlet UILabel *viewAndEditProfileLabel;
@property (weak, nonatomic) IBOutlet UIButton *viewAndEditProfileButton;
@property (weak, nonatomic) IBOutlet UIImageView *viewAndEditProfileImageView;
@property (nonatomic) IBOutlet NSLayoutConstraint *nameLabelCenterVerticalConstraint;

@property (nonatomic, strong) MyAccountHallViewModel *viewModel;

@end

NS_ASSUME_NONNULL_END
