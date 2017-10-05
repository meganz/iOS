
#import "InviteFriendsViewController.h"

#import <AddressBookUI/AddressBookUI.h>
#import <ContactsUI/ContactsUI.h>

#import "VENTokenField.h"

#import "MEGAInviteContactRequestDelegate.h"
#import "MEGAReachabilityManager.h"
#import "MEGASdkManager.h"
#import "NSString+MNZCategory.h"
#import "UIColor+MNZCategory.h"

#import "HelpModalViewController.h"

@interface InviteFriendsViewController () <ABPeoplePickerNavigationControllerDelegate, CNContactPickerDelegate, VENTokenFieldDataSource, VENTokenFieldDelegate>

@property (weak, nonatomic) IBOutlet UIScrollView *scrollView;

@property (weak, nonatomic) IBOutlet UIView *inviteYourFriendsView;
@property (weak, nonatomic) IBOutlet UILabel *inviteYourFriendsTitleLabel;
@property (weak, nonatomic) IBOutlet UILabel *inviteYourFriendsSubtitleLabel;

@property (weak, nonatomic) IBOutlet UILabel *inviteYourFriendsExplanationLabel;

@property (weak, nonatomic) IBOutlet VENTokenField *tokenField;
@property (weak, nonatomic) IBOutlet NSLayoutConstraint *tokenFieldHeightLayoutConstraint;
@property (weak, nonatomic) IBOutlet UIButton *addContactsButton;

@property (weak, nonatomic) IBOutlet UILabel *inviteButtonUpperLabel;
@property (weak, nonatomic) IBOutlet UIButton *inviteButton;

@property (weak, nonatomic) IBOutlet UIButton *howItWorksButton;

@property (nonatomic, strong) NSMutableArray *tokens;

@end

@implementation InviteFriendsViewController

#pragma mark - Lifecycle

- (void)viewDidLoad {
    [super viewDidLoad];
    
    self.navigationItem.title = AMLocalizedString(@"inviteYourFriends", @"Indicating text for when 'you invite your friends'");
    
    self.inviteYourFriendsTitleLabel.text = AMLocalizedString(@"inviteYourFriends", @"Indicating text for when 'you invite your friends'");
    self.inviteYourFriendsSubtitleLabel.text = AMLocalizedString(@"inviteFriendsAndGetForEachReferral", @"Subtitle shown under the label 'Invite your friends' explaining the reward you will get after each referral");
    
    self.inviteYourFriendsExplanationLabel.text = AMLocalizedString(@"inviteYourFriendsExplanation", @"Text shown to explain how and where you can invite friends");
    
    self.tokens = [NSMutableArray array];
    self.tokenField.dataSource = self;
    self.tokenField.delegate = self;
    [self customizeTokenField];
    
    self.inviteButtonUpperLabel.text = @"";
    [self.inviteButton setTitle:AMLocalizedString(@"invite", @"A button on a dialog which invites a contact to join MEGA.") forState:UIControlStateNormal];
    
    [self.howItWorksButton setTitle:AMLocalizedString(@"howItWorks", @"") forState:UIControlStateNormal];
}

- (void)viewWillTransitionToSize:(CGSize)size withTransitionCoordinator:(id<UIViewControllerTransitionCoordinator>)coordinator {
    [super viewWillTransitionToSize:size withTransitionCoordinator:coordinator];
    
    [coordinator animateAlongsideTransition:^(id<UIViewControllerTransitionCoordinatorContext> context) {
        [self.tokenField reloadData];
        self.tokenFieldHeightLayoutConstraint.constant = self.tokenField.frame.size.height;
    } completion:nil];
}

#pragma mark - Private

- (void)customizeTokenField {
    self.tokenFieldHeightLayoutConstraint.constant = 30.0f;
    
    self.tokenField.maxHeight = 500.0f;
    self.tokenField.verticalInset = 11.0f;
    self.tokenField.horizontalInset = 11.0f;
    self.tokenField.tokenPadding = 10.0f;
    self.tokenField.minInputWidth = (self.tokenField.frame.size.width / 2);
    
    self.tokenField.inputTextFieldKeyboardType = UIKeyboardTypeEmailAddress;
    
    self.tokenField.toLabelText = @"";
    self.tokenField.inputTextFieldTextColor = [UIColor mnz_black333333];
    self.tokenField.inputTextFieldFont = [UIFont mnz_SFUIRegularWithSize:17.0f];
    
    self.tokenField.tokenFont = [UIFont mnz_SFUIRegularWithSize:17.0f];
    self.tokenField.tokenHighlightedTextColor = [UIColor mnz_black333333];
    self.tokenField.tokenHighlightedBackgroundColor = [UIColor mnz_grayEEEEEE];
    
    self.tokenField.delimiters = @[@","];
    self.tokenField.placeholderText = AMLocalizedString(@"insertYourFriendsEmails", @"");
    [self.tokenField setColorScheme:[UIColor mnz_redD90007]];
}

- (void)addEmailToTokenList:(NSString *)email {
    [self.tokens addObject:email];
    [self.tokenField reloadData];
    self.tokenFieldHeightLayoutConstraint.constant = self.tokenField.frame.size.height;
    
    [self cleanErrors];
    
    self.inviteButton.backgroundColor = [UIColor mnz_redF0373A];
}

- (void)cleanErrors {
    self.inviteButtonUpperLabel.text = @"";
    self.inviteButtonUpperLabel.textColor = [UIColor mnz_gray999999];
}

#pragma mark - IBActions

- (IBAction)addContactsTouchUpInside:(UIButton *)sender {
    if (self.presentedViewController != nil) {
        [self.presentedViewController dismissViewControllerAnimated:NO completion:nil];
    }
    
    if ([[UIDevice currentDevice] systemVersionLessThanVersion:@"9.0"]) {
        ABPeoplePickerNavigationController *contactsPickerNC = [[ABPeoplePickerNavigationController alloc] init];
        contactsPickerNC.predicateForEnablingPerson = [NSPredicate predicateWithFormat:@"emailAddresses.@count > 0"];
        contactsPickerNC.predicateForSelectionOfProperty = [NSPredicate predicateWithFormat:@"(key == 'emailAddresses')"];
        contactsPickerNC.peoplePickerDelegate = self;
        [self presentViewController:contactsPickerNC animated:YES completion:nil];
    } else {
        CNContactPickerViewController *contactsPickerViewController = [[CNContactPickerViewController alloc] init];
        contactsPickerViewController.predicateForEnablingContact = [NSPredicate predicateWithFormat:@"emailAddresses.@count > 0"];
        contactsPickerViewController.predicateForSelectionOfProperty = [NSPredicate predicateWithFormat:@"(key == 'emailAddresses')"];
        contactsPickerViewController.delegate = self;
        [self presentViewController:contactsPickerViewController animated:YES completion:nil];
    }
}

- (IBAction)inviteTouchUpInside:(UIButton *)sender {
    if ([MEGAReachabilityManager isReachableHUDIfNot]) {
        if (self.tokens.count != 0) {
            MEGAInviteContactRequestDelegate *inviteContactRequestDelegate = [[MEGAInviteContactRequestDelegate alloc] initWithNumberOfRequests:self.tokens.count];
            for (NSString *email in self.tokens) {
                [[MEGASdkManager sharedMEGASdk] inviteContactWithEmail:email message:@"" action:MEGAInviteActionAdd delegate:inviteContactRequestDelegate];
            }
        }
    }
    
    [self.tokenField resignFirstResponder];
}

- (IBAction)howItWorksTouchUpInside:(UIButton *)sender {
    HelpModalViewController *helpModalVC = [[HelpModalViewController alloc] init];
    helpModalVC.modalPresentationStyle = UIModalPresentationCustom;
    helpModalVC.viewTitle = AMLocalizedString(@"howItWorks", @"");
    helpModalVC.firstParagraph = [AMLocalizedString(@"howItWorksMain", @"")  mnz_removeWebclientFormatters];
    helpModalVC.secondParagraph = AMLocalizedString(@"howItWorksSecondary", @"");
    helpModalVC.thirdParagraph = AMLocalizedString(@"howItWorksTertiary", @"A message which is shown once someone has invited a friend as part of the achievements program.");
    
    [self presentViewController:helpModalVC animated:YES completion:nil];
}

#pragma mark - ABPeoplePickerNavigationControllerDelegate
  
- (void)peoplePickerNavigationController:(ABPeoplePickerNavigationController *)peoplePicker didSelectPerson:(ABRecordRef)person {
    NSString *email = nil;
    ABMultiValueRef emails = ABRecordCopyValue(person, kABPersonEmailProperty);
    if (ABMultiValueGetCount(emails) > 0) {
        email = (__bridge_transfer NSString *)
        ABMultiValueCopyValueAtIndex(emails, 0);
    }
    
    if (email) {
        [self addEmailToTokenList:email];
    } else {
        UIAlertController *contactHasNoEmailAlertController = [UIAlertController alertControllerWithTitle:AMLocalizedString(@"contactWithoutEmail", @"Alert title shown when you add a contact from your device and the selected one doesn't have an email.") message:nil preferredStyle:UIAlertControllerStyleAlert];
        
        [contactHasNoEmailAlertController addAction:[UIAlertAction actionWithTitle:AMLocalizedString(@"ok", nil) style:UIAlertActionStyleCancel handler:nil]];
        
        [self presentViewController:contactHasNoEmailAlertController animated:YES completion:nil];
    }
    
    if (emails) {
        CFRelease(emails);
    }
}

#pragma mark - CNContactPickerDelegate

- (void)contactPicker:(CNContactPickerViewController *)picker didSelectContactProperties:(NSArray<CNContactProperty*> *)contactProperties {
    if (contactProperties.count != 0) {
        for (CNContactProperty *contactProperty in contactProperties) {
            [self.tokens addObject:contactProperty.value];
        }
        
        [self.tokenField reloadData];
        self.tokenFieldHeightLayoutConstraint.constant = self.tokenField.frame.size.height;
        
        self.inviteButton.backgroundColor = [UIColor mnz_redF0373A];
        
        [self cleanErrors];
    }
}

#pragma mark - VENTokenFieldDelegate

- (void)tokenField:(VENTokenField *)tokenField didEnterText:(NSString *)text {
    if (text.length == 0 || text.mnz_isEmpty) {
        return;
    }
    
    if (text.mnz_isValidEmail) {               
        self.tokenField.inputTextFieldTextColor = [UIColor mnz_black333333];
        
        self.inviteButtonUpperLabel.text = @"";
        self.inviteButtonUpperLabel.textColor = [UIColor mnz_gray999999];
        
        [self addEmailToTokenList:text];
    } else {
        self.tokenField.inputTextFieldTextColor = [UIColor mnz_redD90007];
        
        self.inviteButtonUpperLabel.text = AMLocalizedString(@"theEmailAddressFormatIsInvalid", @"Add contacts and share dialog error message when user try to add wrong email address");
        self.inviteButtonUpperLabel.textColor = [UIColor mnz_redD90007];
    }
}

- (void)tokenField:(VENTokenField *)tokenField didDeleteTokenAtIndex:(NSUInteger)index {
    [self.tokens removeObjectAtIndex:index];
    [self.tokenField reloadData];
    self.tokenFieldHeightLayoutConstraint.constant = tokenField.frame.size.height;
    
    [self cleanErrors];
    
    if (self.tokens.count == 0) {
        self.inviteButton.backgroundColor = [UIColor mnz_grayCCCCCC];
    }
}

#pragma mark - VENTokenFieldDataSource

- (NSString *)tokenField:(VENTokenField *)tokenField titleForTokenAtIndex:(NSUInteger)index {
    return self.tokens[index];
}

- (NSUInteger)numberOfTokensInTokenField:(VENTokenField *)tokenField {
    return self.tokens.count;
}

- (UIColor *)tokenField:(VENTokenField *)tokenField colorSchemeForTokenAtIndex:(NSUInteger)index {
    return [UIColor mnz_black333333];
}

@end
