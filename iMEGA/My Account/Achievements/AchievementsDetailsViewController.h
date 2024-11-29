#import <UIKit/UIKit.h>

@interface AchievementsDetailsViewController : UIViewController

@property (nonatomic,copy)void (^ _Nullable onAchievementDetailsUpdated)(MEGAAchievementsDetails * _Nonnull achievementsDetails);

@property (nonatomic, nullable) MEGAAchievementsDetails *achievementsDetails;
@property (nonatomic, nullable) NSNumber* completedAchievementIndex;
@property (nonatomic) MEGAAchievement achievementClass;

@property (weak, nonatomic) IBOutlet UIView * _Nullable subtitleView;
@property (weak, nonatomic) IBOutlet UILabel * _Nullable subtitleLabel;
@property (weak, nonatomic) IBOutlet UILabel * _Nullable howItWorksLabel;
@property (weak, nonatomic) IBOutlet UILabel * _Nullable howItWorksExplanationLabel;
@property (weak, nonatomic) IBOutlet UIButton * _Nullable addPhoneNumberButton;
@property (weak, nonatomic) IBOutlet NSLayoutConstraint *scrollViewBottomSpacingConstraint;
@property (weak, nonatomic) IBOutlet NSLayoutConstraint *scrollViewBottonConstraint;

@end
