#import "MasterKeyViewController.h"

#import "MEGAReachabilityManager.h"
#import "MEGA-Swift.h"

#import "Helper.h"

#import "NSURL+MNZCategory.h"

@interface MasterKeyViewController ()

@property (weak, nonatomic) IBOutlet UIImageView *keyIllustrationImageView;

@end

@implementation MasterKeyViewController

#pragma mark - Lifecycle

- (void)viewDidLoad {
    [super viewDidLoad];
    
    self.keyIllustrationImageView.image = [UIImage megaImageWithNamed:@"key_illustration"];
    [self setupContent];
    [self setupColors];
    [self dispatchOnViewDidLoadAction];
}

#pragma mark - IBActions

- (IBAction)copyMasterKeyTouchUpInside:(UIButton *)sender {
    [self dispatchTapCopyAction];
}

- (IBAction)saveMasterKeyTouchUpInside:(UIButton *)sender {
    [self dispatchTapSaveAction];
}

- (IBAction)whyDoINeedARecoveryKeyTouchUpInside:(UIButton *)sender {
    [self dispatchTapWhyDoINeedARecoveryKeyAction];
}

@end
