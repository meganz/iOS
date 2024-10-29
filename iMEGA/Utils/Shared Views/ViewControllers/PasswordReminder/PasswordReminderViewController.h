#import <UIKit/UIKit.h>

@class PasswordReminderViewModel;
@interface PasswordReminderViewController : UIViewController

@property (weak, nonatomic) IBOutlet UILabel *titleLabel;
@property (weak, nonatomic) IBOutlet UILabel *descriptionLabel;
@property (weak, nonatomic) IBOutlet UILabel *switchInfoLabel;
@property (weak, nonatomic) IBOutlet UIButton *testPasswordButton;
@property (weak, nonatomic) IBOutlet UIButton *backupKeyButton;
@property (weak, nonatomic) IBOutlet UIButton *dismissButton;

@property (weak, nonatomic) IBOutlet UIView *doNotShowMeAgainView;
@property (weak, nonatomic) IBOutlet UIView *doNotShowMeAgainTopSeparatorView;
@property (weak, nonatomic) IBOutlet UISwitch *dontShowAgainSwitch;
@property (weak, nonatomic) IBOutlet UIView *doNotShowMeAgainBottomSeparatorView;

@property (weak, nonatomic) IBOutlet UIView *alphaView;
@property (weak, nonatomic) IBOutlet UIImageView *keyImageView;

@property (weak, nonatomic) IBOutlet UIView *backgroundView;

@property (assign, getter=isLoggingOut) BOOL logout;
@property (nonatomic, strong) PasswordReminderViewModel *viewModel;

@end
