#import <UIKit/UIKit.h>

@class RecoveryKeyViewModel;
@interface MasterKeyViewController : UIViewController

@property (weak, nonatomic) IBOutlet UIView *illustrationView;
@property (weak, nonatomic) IBOutlet UIButton *carbonCopyMasterKeyButton;
@property (weak, nonatomic) IBOutlet UIButton *saveMasterKey;
@property (weak, nonatomic) IBOutlet UIButton *whyDoINeedARecoveryKeyButton;
@property (nonatomic, strong) RecoveryKeyViewModel *viewModel;
@end
