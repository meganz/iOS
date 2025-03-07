@interface MyAccountHallTableViewCell : UITableViewCell

@property (weak, nonatomic) IBOutlet UILabel *sectionLabel;
@property (weak, nonatomic) IBOutlet UILabel *detailLabel;
@property (weak, nonatomic) IBOutlet UIActivityIndicatorView *activityIndicatorView;
@property (weak, nonatomic) IBOutlet UIImageView *iconImageView;

@property (strong, nonatomic) IBOutlet NSLayoutConstraint *pendingViewSpacingConstraint;
@property (weak, nonatomic) IBOutlet UIView *pendingView;
@property (weak, nonatomic) IBOutlet UILabel *pendingLabel;
@property (weak, nonatomic) IBOutlet UIView *promoView;
@property (weak, nonatomic) IBOutlet UILabel *promoLabel;

@property (weak, nonatomic) IBOutlet UILabel *storageLabel;
@property (weak, nonatomic) IBOutlet UILabel *transferLabel;
@property (weak, nonatomic) IBOutlet UILabel *storageUsedLabel;
@property (weak, nonatomic) IBOutlet UILabel *transferUsedLabel;

@end
