#import "MasterKeyViewController.h"

#import "MEGAReachabilityManager.h"
#import "MEGA-Swift.h"

#import "Helper.h"

#import "NSURL+MNZCategory.h"

@interface MasterKeyViewController ()
@end

@implementation MasterKeyViewController

#pragma mark - Lifecycle

- (void)viewDidLoad {
    [super viewDidLoad];
    
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
