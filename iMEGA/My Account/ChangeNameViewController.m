#import "ChangeNameViewController.h"

#import "SVProgressHUD.h"

#import "MEGANavigationController.h"
#import "MEGAReachabilityManager.h"
#import "MEGASdkManager.h"
#import "MEGAStore.h"
#import "MEGA-Swift.h"
#import "NSString+MNZCategory.h"

@interface ChangeNameViewController () <UITextFieldDelegate, MEGARequestDelegate, UIAdaptivePresentationControllerDelegate>

@property (weak, nonatomic) IBOutlet UIView *firstNameView;
@property (weak, nonatomic) IBOutlet UIView *firstNameTopSeparatorView;
@property (weak, nonatomic) IBOutlet UILabel *firstNameLabel;
@property (weak, nonatomic) IBOutlet UITextField *firstNameTextField;
@property (weak, nonatomic) IBOutlet UIView *firstNameBottomSeparatorView;

@property (weak, nonatomic) IBOutlet UIView *lastNameView;
@property (weak, nonatomic) IBOutlet UILabel *lastNameLabel;
@property (weak, nonatomic) IBOutlet UITextField *lastNameTextField;
@property (weak, nonatomic) IBOutlet UIView *lastNameBottomSeparatorView;

@property (weak, nonatomic) IBOutlet UIBarButtonItem *cancelBarButtonItem;
@property (weak, nonatomic) IBOutlet UIBarButtonItem *saveButton;

@property (strong, nonatomic) NSString *firstName;
@property (strong, nonatomic) NSString *lastName;

@end

@implementation ChangeNameViewController

#pragma mark - Lifecycle

- (void)viewDidLoad {
    [super viewDidLoad];
    
    self.navigationItem.title = AMLocalizedString(@"changeName", @"Button title that allows the user change his name");
    
    MOUser *moUser = [[MEGAStore shareInstance] fetchUserWithUserHandle:[[[MEGASdkManager sharedMEGASdk] myUser] handle]];
    self.firstName = moUser.firstname;
    self.lastName = moUser.lastname;
    
    self.firstName ? (self.firstNameTextField.text = self.firstName) : (self.firstNameTextField.placeholder = AMLocalizedString(@"firstName", @"Hint text for the first name (Placeholder)"));
    self.lastName ? (self.lastNameTextField.text = self.lastName) : (self.lastNameTextField.placeholder = AMLocalizedString(@"lastName", @"Hint text for the last name (Placeholder)"));
    
    self.firstNameTextField.textContentType = UITextContentTypeGivenName;
    self.lastNameTextField.textContentType = UITextContentTypeFamilyName;
    
    self.cancelBarButtonItem.title = AMLocalizedString(@"cancel", @"Button title to cancel something");
    [self.saveButton setTitle:AMLocalizedString(@"save", @"Button title to 'Save' the selected option")];
    [self.saveButton setTitleTextAttributes:@{NSFontAttributeName:[UIFont systemFontOfSize:17.0f weight:UIFontWeightMedium]} forState:UIControlStateNormal];
    
    [self updateAppearance];
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    
    self.navigationController.presentationController.delegate = self;
}

- (void)traitCollectionDidChange:(UITraitCollection *)previousTraitCollection {
    [super traitCollectionDidChange:previousTraitCollection];
    
    if (@available(iOS 13.0, *)) {
        if ([self.traitCollection hasDifferentColorAppearanceComparedToTraitCollection:previousTraitCollection]) {
            [self updateAppearance];
        }
    }
}

#pragma mark - Private

- (void)updateAppearance {
    self.view.backgroundColor = [UIColor mnz_backgroundGroupedElevated:self.traitCollection];
    
    self.firstNameView.backgroundColor = self.lastNameView.backgroundColor = [UIColor mnz_secondaryBackgroundGroupedElevated:self.traitCollection];
    self.firstNameLabel.textColor = self.lastNameLabel.textColor = [UIColor mnz_secondaryGrayForTraitCollection:self.traitCollection];
    
    self.firstNameTopSeparatorView.backgroundColor = self.firstNameBottomSeparatorView.backgroundColor = self.lastNameBottomSeparatorView.backgroundColor = [UIColor mnz_separatorForTraitCollection:self.traitCollection];
}

- (BOOL)validateNameForm {
    self.firstNameTextField.text = self.firstNameTextField.text.mnz_removeWhitespacesAndNewlinesFromBothEnds;
    self.lastNameTextField.text = self.lastNameTextField.text.mnz_removeWhitespacesAndNewlinesFromBothEnds;
    
    if (self.firstNameTextField.text.mnz_isEmpty) {
        [SVProgressHUD showErrorWithStatus:AMLocalizedString(@"nameInvalidFormat", @"Enter a valid name")];
        [self.firstNameTextField becomeFirstResponder];
        return NO;
    }
    
    return YES;
}

- (BOOL)hasNameBeenEdited:(NSString *)name inTextFieldForTag:(NSInteger)tag {
    name = name.mnz_removeWhitespacesAndNewlinesFromBothEnds;
    
    BOOL hasNameBeenEdited = NO;
    switch (tag) {
        case 0: {
            if (![self.firstName isEqualToString:name]) {
                hasNameBeenEdited = YES;
            }
            break;
        }
            
        case 1: {
            if (![self.lastName isEqualToString:name]) {
                hasNameBeenEdited = YES;
            }
            break;
        }
    }
    
    return hasNameBeenEdited;
}

#pragma mark - IBActions

- (IBAction)cancelTouchUpInside:(UIBarButtonItem *)sender {
    [self.firstNameTextField resignFirstResponder];
    [self.lastNameTextField resignFirstResponder];
    
    [self dismissViewControllerAnimated:YES completion:nil];
}

- (IBAction)saveTouchUpInside:(UIBarButtonItem *)sender {
    [self.firstNameTextField resignFirstResponder];
    [self.lastNameTextField resignFirstResponder];
    
    if ([MEGAReachabilityManager isReachableHUDIfNot]) {
        if ([self validateNameForm]) {
            self.saveButton.enabled = NO;
            
            if ([self hasNameBeenEdited:self.firstNameTextField.text inTextFieldForTag:self.firstNameTextField.tag]) {
                [[MEGASdkManager sharedMEGASdk] setUserAttributeType:MEGAUserAttributeFirstname value:self.firstNameTextField.text delegate:self];
            }
            if ([self hasNameBeenEdited:self.lastNameTextField.text inTextFieldForTag:self.lastNameTextField.tag]) {
                [[MEGASdkManager sharedMEGASdk] setUserAttributeType:MEGAUserAttributeLastname value:self.lastNameTextField.text delegate:self];
            }
        }
    } else {
        self.saveButton.enabled = YES;
    }
}

#pragma mark - UITextFieldDelegate

- (void)textFieldDidEndEditing:(UITextField *)textField {
    switch (textField.tag) {
        case 0:
        case 1: {
            textField.text = textField.text.mnz_removeWhitespacesAndNewlinesFromBothEnds;
            break;
        }
    }
}

- (BOOL)textField:(UITextField *)textField shouldChangeCharactersInRange:(NSRange)range replacementString:(NSString *)string {
    NSString *text = [textField.text stringByReplacingCharactersInRange:range withString:string];
    
    BOOL shouldSaveButtonBeEnabled = YES;
    switch (textField.tag) {
        case 0: { //FirstNameTextField
            shouldSaveButtonBeEnabled = text.mnz_isEmpty ? NO : [self hasNameBeenEdited:text inTextFieldForTag:textField.tag];
            break;
        }
            
        case 1: { //LastNameTextField
            BOOL hasLastNameBeenEdited = [self hasNameBeenEdited:text inTextFieldForTag:textField.tag];
            if (hasLastNameBeenEdited && !self.firstNameTextField.text.mnz_isEmpty) {
                shouldSaveButtonBeEnabled = YES;
            } else {
                BOOL hasFirstNameBeenModified = [self hasNameBeenEdited:self.firstNameTextField.text inTextFieldForTag:self.firstNameTextField.tag];
                shouldSaveButtonBeEnabled = hasFirstNameBeenModified;
            }
        }
    }
    
    self.saveButton.enabled = shouldSaveButtonBeEnabled;
    
    return YES;
}

- (BOOL)textFieldShouldReturn:(UITextField *)textField {
    switch ([textField tag]) {
        case 0: //FirstNameTextField
            [self.lastNameTextField becomeFirstResponder];
            break;
            
        case 1: //LastNameTextField
            [self saveTouchUpInside:self.saveButton];
            break;
            
        default:
            break;
    }
    
    return YES;
}

#pragma mark - UIAdaptivePresentationControllerDelegate

- (BOOL)presentationControllerShouldDismiss:(UIPresentationController *)presentationController {
    return !self.saveButton.enabled;
}

- (void)presentationControllerDidAttemptToDismiss:(UIPresentationController *)presentationController {
    UIAlertController *confirmDismissAlert = [UIAlertController.alloc discardChangesFromBarButton:self.cancelBarButtonItem withConfirmAction:^{
        [self dismissViewControllerAnimated:YES completion:nil];
    }];
    [self presentViewController:confirmDismissAlert animated:YES completion:nil];
}

#pragma mark - MEGARequestDelegate

- (void)onRequestStart:(MEGASdk *)api request:(MEGARequest *)request {
    if ([request type] == MEGARequestTypeSetAttrUser) {
        [SVProgressHUD show];
    }
}

- (void)onRequestFinish:(MEGASdk *)api request:(MEGARequest *)request error:(MEGAError *)error {
    switch (request.type) {
        case MEGARequestTypeSetAttrUser: {
            if ([error type]) {
                [SVProgressHUD showErrorWithStatus:AMLocalizedString(error.name, nil)];
                return;
            }
            
            [SVProgressHUD showSuccessWithStatus:AMLocalizedString(@"youHaveSuccessfullyChangedYourProfile", @"Success message when changing profile information.")];
            [self dismissViewControllerAnimated:YES completion:nil];
            break;
        }
            
        default:
            break;
    }
}

@end
