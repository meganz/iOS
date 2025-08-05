#import "ChangeNameViewController.h"

#import "SVProgressHUD.h"

#import "MEGANavigationController.h"
#import "MEGAReachabilityManager.h"
#import "MEGAStore.h"
#import "MEGA-Swift.h"
#import "NSString+MNZCategory.h"
@import MEGAAppSDKRepo;

#import "LocalizationHelper.h"

@interface ChangeNameViewController () <UITextFieldDelegate, MEGARequestDelegate, UIAdaptivePresentationControllerDelegate>

@property (weak, nonatomic) IBOutlet UIView *firstNameView;
@property (weak, nonatomic) IBOutlet UIView *firstNameTopSeparatorView;
@property (weak, nonatomic) IBOutlet UILabel *firstNameLabel;

@property (weak, nonatomic) IBOutlet UIView *firstNameBottomSeparatorView;

@property (weak, nonatomic) IBOutlet UIView *lastNameView;
@property (weak, nonatomic) IBOutlet UILabel *lastNameLabel;
@property (weak, nonatomic) IBOutlet UIView *lastNameBottomSeparatorView;

@property (weak, nonatomic) IBOutlet UIBarButtonItem *cancelBarButtonItem;

@end

@implementation ChangeNameViewController

#pragma mark - Lifecycle

- (void)viewDidLoad {
    [super viewDidLoad];
    
    self.navigationItem.title = LocalizedString(@"changeName", @"Button title that allows the user change his name");
    
    MOUser *moUser = [[MEGAStore shareInstance] fetchUserWithUserHandle:MEGASdk.currentUserHandle.unsignedLongLongValue];
    self.firstName = moUser.firstname;
    self.lastName = moUser.lastname;
    
    self.firstName ? (self.firstNameTextField.text = self.firstName) : (self.firstNameTextField.placeholder = LocalizedString(@"firstName", @"Hint text for the first name (Placeholder)"));
    self.lastName ? (self.lastNameTextField.text = self.lastName) : (self.lastNameTextField.placeholder = LocalizedString(@"lastName", @"Hint text for the last name (Placeholder)"));
    
    self.firstNameTextField.textContentType = UITextContentTypeGivenName;
    self.lastNameTextField.textContentType = UITextContentTypeFamilyName;
    
    self.cancelBarButtonItem.title = LocalizedString(@"cancel", @"Button title to cancel something");
    [self.saveButton setTitle:LocalizedString(@"save", @"Button title to 'Save' the selected option")];
    [self.saveButton setTitleTextAttributes:@{NSFontAttributeName:[UIFont mnz_preferredFontWithStyle:UIFontTextStyleBody weight:UIFontWeightMedium]} forState:UIControlStateNormal];
    
    self.firstNameLabel.text = LocalizedString(@"firstName", @"Hint text for the first name (Placeholder)");
    self.lastNameLabel.text = LocalizedString(@"lastName", @"Hint text for the first name (Placeholder)");
    
    [self setupColors];
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    
    self.navigationController.presentationController.delegate = self;
}

#pragma mark - Private

- (void)setupColors {
    self.view.backgroundColor = [self defaultBackgroundColor];
    self.firstNameView.backgroundColor = self.lastNameView.backgroundColor = [self defaultBackgroundColor];
    self.firstNameLabel.textColor = self.lastNameLabel.textColor = [self primaryTextcolor];
    self.firstNameTopSeparatorView.backgroundColor = self.firstNameBottomSeparatorView.backgroundColor = self.lastNameBottomSeparatorView.backgroundColor = [UIColor borderStrong];
}

#pragma mark - IBActions

- (IBAction)cancelTouchUpInside:(UIBarButtonItem *)sender {
    [self.firstNameTextField resignFirstResponder];
    [self.lastNameTextField resignFirstResponder];
    
    [self dismissViewControllerAnimated:YES completion:nil];
}

- (IBAction)saveTouchUpInside:(UIBarButtonItem *)sender {
    [self validateAndSaveUpdatedName];
}

#pragma mark - UIAdaptivePresentationControllerDelegate

- (BOOL)presentationControllerShouldDismiss:(UIPresentationController *)presentationController {
    return !self.saveButton.enabled;
}

- (void)presentationControllerDidAttemptToDismiss:(UIPresentationController *)presentationController {
    if (self.cancelBarButtonItem == nil) {
        return;
    }
    
    UIAlertController *confirmDismissAlert = [UIAlertController.alloc discardChangesFromBarButton:self.cancelBarButtonItem withConfirmAction:^{
        [self dismissViewControllerAnimated:YES completion:nil];
    }];
    [self presentViewController:confirmDismissAlert animated:YES completion:nil];
}

@end
