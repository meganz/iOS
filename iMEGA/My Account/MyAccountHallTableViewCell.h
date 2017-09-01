
@interface MyAccountHallTableViewCell : UITableViewCell

@property (weak, nonatomic) IBOutlet UILabel *sectionLabel;
@property (weak, nonatomic) IBOutlet UIImageView *iconImageView;
@property (weak, nonatomic) IBOutlet UIView *lineView;

@property (weak, nonatomic) IBOutlet UIView *pendingView;
@property (weak, nonatomic) IBOutlet UILabel *pendingLabel;

@property (weak, nonatomic) IBOutlet UIView *separatorLineView;

@end
