#import "ChangeNameViewController.h"

#import "MEGANavigationController.h"
#import "MEGAReachabilityManager.h"
#import "MEGASdkManager.h"
#import "MEGAStore.h"

#import "SVProgressHUD.h"

@interface ChangeNameViewController () <UITextFieldDelegate, MEGARequestDelegate>

@property (strong, nonatomic) IBOutlet UIBarButtonItem *cancelBarButtonItem;

@property (weak, nonatomic) IBOutlet UITextField *firstNameTextField;
@property (weak, nonatomic) IBOutlet UITextField *lastNameTextField;

@property (weak, nonatomic) IBOutlet UIButton *saveButton;

@property (strong, nonatomic) NSString *firstName;
@property (strong, nonatomic) NSString *lastName;

@end

@implementation ChangeNameViewController

#pragma mark - Lifecycle

- (void)viewDidLoad {
    [super viewDidLoad];
    
    self.cancelBarButtonItem.title = AMLocalizedString(@"cancel", @"Button title to cancel something");
    self.navigationItem.title = AMLocalizedString(@"changeName", @"Button title that allows the user change his name");
    
    MOUser *moUser = [[MEGAStore shareInstance] fetchUserWithUserHandle:[[[MEGASdkManager sharedMEGASdk] myUser] handle]];
    self.firstName = moUser.firstname;
    self.lastName = moUser.lastname;
    
    self.firstName ? (self.firstNameTextField.text = self.firstName) : (self.firstNameTextField.placeholder = AMLocalizedString(@"firstName", @"Hint text for the first name (Placeholder)"));
    self.lastName ? (self.lastNameTextField.text = self.lastName) : (self.lastNameTextField.placeholder = AMLocalizedString(@"lastName", @"Hint text for the last name (Placeholder)"));
    
    [self.saveButton setTitle:AMLocalizedString(@"save", @"Button title to 'Save' the selected option") forState:UIControlStateNormal];
}

#pragma mark - Private

- (BOOL)validateNameForm {
    if ([self isStringEmpty:self.firstNameTextField.text]) {
        [SVProgressHUD showErrorWithStatus:AMLocalizedString(@"nameInvalidFormat", @"Enter a valid name")];
        [self.firstNameTextField becomeFirstResponder];
        return NO;
    }
    
    return YES;
}

- (BOOL)isStringEmpty:(NSString *)string {
    return ![[string stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]] length];
}


- (BOOL)hasNameBeenEdited:(NSString *)name inTextFieldForTag:(NSInteger)tag {
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

- (IBAction)cancelAction:(UIBarButtonItem *)sender {
    [self dismissViewControllerAnimated:YES completion:nil];
}

- (IBAction)saveTouchUpInside:(UIButton *)sender {
    if ([MEGAReachabilityManager isReachableHUDIfNot]) {
        if ([self validateNameForm]) {
            self.saveButton.enabled = NO;
            
            if (![self.firstNameTextField.text isEqualToString:self.firstName]) {
                [[MEGASdkManager sharedMEGASdk] setUserAttributeType:MEGAUserAttributeFirstname value:self.firstNameTextField.text delegate:self];
            }
            if (![self.lastNameTextField.text isEqualToString:self.lastName]) {
                [[MEGASdkManager sharedMEGASdk] setUserAttributeType:MEGAUserAttributeLastname value:self.lastNameTextField.text delegate:self];
            }
        }
    } else {
        self.saveButton.enabled = YES;
    }
}

#pragma mark - UITextFieldDelegate

- (BOOL)textField:(UITextField *)textField shouldChangeCharactersInRange:(NSRange)range replacementString:(NSString *)string {
    NSString *text = [textField.text stringByReplacingCharactersInRange:range withString:string];
    BOOL shouldSaveButtonColorBeDisabled = NO;
    switch (textField.tag) {
        case 0: { //FirstNameTextField
            if ([self isStringEmpty:text]) {
                shouldSaveButtonColorBeDisabled = YES;
            } else if ([self hasNameBeenEdited:text inTextFieldForTag:textField.tag]) {
                shouldSaveButtonColorBeDisabled = NO;
            }
            break;
        }
            
        case 1: { //LastNameTextField
            BOOL hasLastNameBeenEdited = [self hasNameBeenEdited:text inTextFieldForTag:textField.tag];
            if (hasLastNameBeenEdited) {
                shouldSaveButtonColorBeDisabled = NO;
            } else {
                BOOL hasFirstNameBeenModified = [self hasNameBeenEdited:self.firstNameTextField.text inTextFieldForTag:self.firstNameTextField.tag];
                BOOL isFirstNameEmpty = [self isStringEmpty:self.firstNameTextField.text];
                shouldSaveButtonColorBeDisabled = (hasFirstNameBeenModified && !isFirstNameEmpty) ? NO: YES;
            }
            break;
        }
    }
    self.saveButton.backgroundColor = shouldSaveButtonColorBeDisabled ? [UIColor mnz_grayCCCCCC] : [UIColor mnz_redFF4C52];
    
    return YES;
}

- (BOOL)textFieldShouldClear:(UITextField *)textField {
    BOOL shouldSaveButtonColorBeDisabled = NO;
    switch (textField.tag) {
        case 0: { //FirstNameTextField
            shouldSaveButtonColorBeDisabled = YES;
            break;
        }
            
        case 1: { //LastNameTextField
            BOOL hasLastNameBeenEdited = [self hasNameBeenEdited:@"" inTextFieldForTag:textField.tag];
            if (hasLastNameBeenEdited) {
                shouldSaveButtonColorBeDisabled = NO;
            } else {
                BOOL hasFirstNameBeenEdited = [self hasNameBeenEdited:self.firstNameTextField.text inTextFieldForTag:self.firstNameTextField.tag];
                BOOL isFirstNameEmpty = [self isStringEmpty:self.firstNameTextField.text];
                shouldSaveButtonColorBeDisabled = (hasFirstNameBeenEdited && !isFirstNameEmpty) ? NO : YES;
            }
            break;
        }
    }
    self.saveButton.backgroundColor = shouldSaveButtonColorBeDisabled ? [UIColor mnz_grayCCCCCC] : [UIColor mnz_redFF4C52];
    
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
                [SVProgressHUD showErrorWithStatus:error.name];
                return;
            }
            
            if (request.paramType == MEGAUserAttributeFirstname) {
                self.firstName = request.text;
            } else if (request.paramType == MEGAUserAttributeLastname) {
                self.lastName = request.text;
            }
            
            [self.firstNameTextField resignFirstResponder];
            [self.lastNameTextField resignFirstResponder];
            
            [SVProgressHUD showSuccessWithStatus:AMLocalizedString(@"youHaveSuccessfullyChangedYourProfile", @"Success message when changing profile information.")];
            [self dismissViewControllerAnimated:YES completion:nil];
            break;
        }
            
        default:
            break;
    }
}

@end
