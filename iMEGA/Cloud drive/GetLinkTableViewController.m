
#import "GetLinkTableViewController.h"

#import "SVProgressHUD.h"

#import "Helper.h"
#import "MEGAExportRequestDelegate.h"
#import "MEGAPasswordLinkRequestDelegate.h"
#import "MEGASdk+MNZCategory.h"
#import "MEGASDKManager.h"
#import "MEGA-Swift.h"
#import "NSDate+MNZCategory.h"
#import "NSString+MNZCategory.h"
#import "PasswordStrengthIndicatorView.h"
#import "PasswordView.h"

@interface GetLinkTableViewController () <UITextFieldDelegate, UIAdaptivePresentationControllerDelegate>

@property (nonatomic) NSMutableArray *fullLinks;
@property (nonatomic) NSMutableArray *links;
@property (nonatomic) NSMutableArray *keys;
@property (nonatomic) NSMutableArray *encryptedLinks;

@property (nonatomic) NSMutableArray *selectedArray;
@property (nonatomic) NSIndexPath *selectedIndexPath;
@property (nonatomic) NSIndexPath *linkWithKeyIndexPath;

@property (nonatomic) BOOL isFree;
@property (nonatomic) NSUInteger pending;

@property (weak, nonatomic) IBOutlet UIBarButtonItem *doneBarButtonItem;

@property (weak, nonatomic) IBOutlet UILabel *textToCopy;
@property (weak, nonatomic) IBOutlet UISwitch *expireSwitch;
@property (weak, nonatomic) IBOutlet UISwitch *passwordSwitch;
@property (weak, nonatomic) IBOutlet UIDatePicker *expireDatePicker;

@property (weak, nonatomic) IBOutlet UILabel *linkWithoutKeyLabel;
@property (weak, nonatomic) IBOutlet UILabel *decryptionKeyLabel;
@property (weak, nonatomic) IBOutlet UILabel *linkWithKeyLabel;
@property (weak, nonatomic) IBOutlet UILabel *expireDateLabel;
@property (weak, nonatomic) IBOutlet UILabel *expireDateSetLabel;
@property (weak, nonatomic) IBOutlet UIButton *expireDateSetSaveButton;

@property (weak, nonatomic) IBOutlet UILabel *passwordProtectionLabel;
@property (weak, nonatomic) IBOutlet PasswordView *passwordView;
@property (weak, nonatomic) IBOutlet PasswordStrengthIndicatorView *passwordStrengthIndicatorView;
@property (weak, nonatomic) IBOutlet PasswordView *confirmPasswordView;
@property (weak, nonatomic) IBOutlet UILabel *encryptWithPasswordLabel;

@property (weak, nonatomic) IBOutlet UIBarButtonItem *toolbarCopyLinkBarButtonItem;
@property (weak, nonatomic) IBOutlet UIBarButtonItem *shareBarButtonItem;

@property (nonatomic) MEGAExportRequestDelegate *exportDelegate;
@property (nonatomic) MEGAPasswordLinkRequestDelegate *passwordLinkDelegate;

@property (nonatomic) NSString *currentPassword;
@property (nonatomic) NSDate *currentExpiryDate;

@end

@implementation GetLinkTableViewController

#pragma mark - Lifecycle

- (void)viewDidLoad {
    [super viewDidLoad];
    
    [self setNavigationBarTitle];
    
    [self checkExpirationTime];
    
    self.exportDelegate = [[MEGAExportRequestDelegate alloc] initWithCompletion:^(MEGARequest *request) {
        [self processLink:request.link];
    } multipleLinks:self.nodesToExport.count > 1];
    
    if (MEGASdkManager.sharedMEGASdk.businessStatus == BusinessStatusExpired) {
        self.tableView.userInteractionEnabled = self.toolbarCopyLinkBarButtonItem.enabled = self.shareBarButtonItem.enabled = NO;
    }
    
    self.passwordLinkDelegate = [[MEGAPasswordLinkRequestDelegate alloc] initWithCompletion:^(MEGARequest *request) {
        [self.encryptedLinks addObject:request.text];
        [self updateUI];
        
        if (--self.pending==0) {
            self.passwordView.passwordTextField.enabled = self.confirmPasswordView.passwordTextField.enabled = NO;
            [self.tableView cellForRowAtIndexPath:[NSIndexPath indexPathForRow:0 inSection:4]].userInteractionEnabled = NO;
            self.encryptWithPasswordLabel.text = AMLocalizedString(@"encrypted", @"The button text on the Export Link dialog to indicate that the link has been encrypted successfully.");
            self.encryptWithPasswordLabel.textColor = UIColor.systemGreenColor;
            [SVProgressHUD dismiss];
        }
    } multipleLinks:self.nodesToExport.count > 1];
    
    self.fullLinks = [NSMutableArray new];
    self.links = [NSMutableArray new];
    self.keys = [NSMutableArray new];

    self.selectedArray = self.fullLinks;
    self.linkWithKeyIndexPath = [NSIndexPath indexPathForRow:2 inSection:0];
    self.selectedIndexPath = self.linkWithKeyIndexPath;

    self.isFree = NO;
    NSDate *tomorrow = [NSDate dateWithTimeInterval:(24*60*60) sinceDate:[NSDate date]];
    self.expireDatePicker.minimumDate = tomorrow;
    [self.expireDatePicker setLocale:[NSLocale localeWithLocaleIdentifier:[[LocalizationSystem sharedLocalSystem] getLanguage]]];
    
    self.isFree = ![[MEGASdkManager sharedMEGASdk] mnz_isProAccount];
    if (self.isFree) {
        self.expireDateLabel.enabled = self.expireSwitch.enabled = NO;
        self.passwordProtectionLabel.enabled = self.passwordSwitch.enabled = NO;
    }

    self.pending = self.nodesToExport.count;
    for (MEGANode *node in self.nodesToExport) {
        if (node.isExported) {
            [self processLink:node.publicLink];
        } else {
            [MEGASdkManager.sharedMEGASdk exportNode:node delegate:self.exportDelegate];
        }
    }
    
    self.doneBarButtonItem.title = AMLocalizedString(@"done", @"");
    
    self.linkWithoutKeyLabel.text = AMLocalizedString(@"linkWithoutKey", @"This is button text on the Get Link dialog. This lets the user get a public file/folder link without the decryption key e.g. https://mega.nz/#!Qo12lSpT.");
    self.decryptionKeyLabel.text = AMLocalizedString(@"decryptionKey", nil);
    self.linkWithKeyLabel.text = AMLocalizedString(@"linkWithKey", @"This is button text on the Get Link dialog. This lets the user get a public file/folder link with the decryption key e.g. https://mega.nz/#!Qo12lSpT!3uv6GhJhAWWH46fcMN2KGRtxc_QSLthcwvAdaA_TjCE.");
    self.expireDateLabel.text = AMLocalizedString(@"setExpiryDate", @"A label in the Get Link dialog which allows the user to set an expiry date on their public link.");
    [self.expireDateSetSaveButton setTitle:AMLocalizedString(@"save", @"Button title to 'Save' the selected option") forState:UIControlStateNormal];
    
    self.passwordProtectionLabel.text = AMLocalizedString(@"setPasswordProtection", @"This is a title label on the Export Link dialog. The title covers the section where the user can password protect a public link.");
    self.passwordView.passwordTextField.returnKeyType = UIReturnKeyNext;
    self.passwordView.passwordTextField.delegate = self;
    self.confirmPasswordView.passwordTextField.delegate = self;
    self.encryptWithPasswordLabel.text = AMLocalizedString(@"encrypt", @"The text of a button. This button will encrypt a link with a password.");
    
    self.shareBarButtonItem.title = AMLocalizedString(@"share", @"Button title which, if tapped, will trigger the action of sharing with the contact or contacts selected");
    self.toolbarCopyLinkBarButtonItem.title = AMLocalizedString(@"copyLink", @"Title for a button to copy the link to the clipboard");
    
    self.navigationController.presentationController.delegate = self;
}

- (void)traitCollectionDidChange:(UITraitCollection *)previousTraitCollection {
    [super traitCollectionDidChange:previousTraitCollection];
    
    if (@available(iOS 13.0, *)) {
        if ([self.traitCollection hasDifferentColorAppearanceComparedToTraitCollection:previousTraitCollection]) {
            [self updateAppearance];
            
            [self.tableView reloadData];
        }
    }
}

#pragma mark - Private

- (void)updateAppearance {
    self.view.backgroundColor = [UIColor mnz_backgroundGroupedElevated:self.traitCollection];
}

- (void)setNavigationBarTitle {
    BOOL areExportedNodes = YES;
    for (MEGANode *node in self.nodesToExport) {
        if (!node.isExported) {
            areExportedNodes = NO;
            break;
        }
    }
    
    NSString *title;
    if (self.nodesToExport.count > 1) {
        title = areExportedNodes ? AMLocalizedString(@"manageLinks", @"A menu item in the right click context menu in the Cloud Drive. This menu item will take the user to a dialog where they can manage the public folder/file links which they currently have selected.") : AMLocalizedString(@"getLinks", @"Title shown under the action that allows you to get several links to files and/or folders");
    } else {
        title = areExportedNodes ? AMLocalizedString(@"manageLink", @"Item menu option upon right click on one or multiple files.") : AMLocalizedString(@"getLink", @"Title shown under the action that allows you to get a link to file or folder");
    }
    self.navigationItem.title = title;
}

- (void)updateUI {
    self.textToCopy.text = [self.selectedArray componentsJoinedByString:@" "];
    [self.tableView reloadData];
}

- (void)encryptLinks:(NSString *)password {
    self.pending = self.fullLinks.count;
    for (NSString *link in self.fullLinks) {
        [[MEGASdkManager sharedMEGASdk] encryptLinkWithPassword:link password:password delegate:self.passwordLinkDelegate];
    }
}

- (void)checkExpirationTime {
    uint64_t earliestExpirationTime = UINT64_MAX;
    for (MEGANode *node in self.nodesToExport) {
        if (node.expirationTime <= 0) {
            continue;
        }
        if (earliestExpirationTime > node.expirationTime) {
            earliestExpirationTime = node.expirationTime;
        }
    }
    
    if (earliestExpirationTime == UINT64_MAX) {
        self.expireSwitch.on = NO;
    } else {
        self.expireSwitch.on = YES;
        self.expireDateSetLabel.hidden = NO;
        self.currentExpiryDate = [NSDate.alloc initWithTimeIntervalSince1970:earliestExpirationTime];
        self.expireDateSetLabel.text = self.currentExpiryDate.mnz_formattedDateMediumStyle;
    }
}

- (void)showDatePicker {
    [self.tableView beginUpdates];
    
    if (self.currentExpiryDate != self.expireDatePicker.date) {
        self.expireDateSetLabel.text = self.expireDatePicker.date.mnz_formattedDateMediumStyle;
        self.expireDateSetSaveButton.enabled = YES;
        self.expireDateSetSaveButton.hidden = NO;
    }
    
    self.expireDatePicker.hidden = NO;
    self.expireDatePicker.alpha = 0.0f;
    [UIView animateWithDuration:0.25 animations:^{
        self.expireDatePicker.alpha = 1.0f;
    }];
    
    [self.tableView endUpdates];
}

- (void)hideDatePicker {
    [self.tableView beginUpdates];
    
    self.expireDatePicker.hidden = YES;
    [UIView animateWithDuration:0.25 animations:^{
        self.expireDatePicker.alpha = 0.0f;
    }];
    
    [self.tableView endUpdates];
}

- (BOOL)validatePassword {
    if (self.passwordView.passwordTextField.text.mnz_isEmpty) {
        [self.passwordView setErrorState:YES withText:AMLocalizedString(@"passwordInvalidFormat", @"Message shown when the user enters a wrong password")];
        return NO;
    } else if ([MEGASdkManager.sharedMEGASdk passwordStrength:self.passwordView.passwordTextField.text] == PasswordStrengthVeryWeak) {
        [self.passwordView setErrorState:YES withText:AMLocalizedString(@"pleaseStrengthenYourPassword", nil)];
        return NO;
    } else {
        [self.passwordView setErrorState:NO withText:AMLocalizedString(@"passwordPlaceholder", @"Hint text to suggest that the user has to write his password")];
        return YES;
    }
}

- (BOOL)validateConfirmPassword {
    if ([self.confirmPasswordView.passwordTextField.text isEqualToString:self.passwordView.passwordTextField.text]) {
        [self.confirmPasswordView setErrorState:NO withText:AMLocalizedString(@"confirmPassword", @"Hint text where the user have to re-write the new password to confirm it")];
        return YES;
    } else {
        [self.confirmPasswordView setErrorState:YES withText:AMLocalizedString(@"passwordsDoNotMatch", @"Error text shown when you have not written the same password")];
        return NO;
    }
}

- (void)processLink:(NSString *)fullLink {
    NSArray *components;
    NSString *link;
    NSString *key;
    
    if ([fullLink containsString:@"file"] || [fullLink containsString:@"folder"]) {//New format file/folder links
        components = [fullLink componentsSeparatedByString:@"#"];
        link = components[0];
        key = components[1];
    } else {
        components = [fullLink componentsSeparatedByString:@"!"];
        link = [NSString stringWithFormat:@"%@!%@", components.firstObject, components[1]];
        key = components[2];
    }
    
    [self.fullLinks addObject:fullLink];
    [self.links addObject:link];
    [self.keys addObject:key];
    
    [self updateUI];
    
    if (--self.pending==0) {
        [SVProgressHUD dismiss];
    }
}

#pragma mark - IBActions

- (IBAction)doneTapped:(UIBarButtonItem *)sender {
    [self dismissViewControllerAnimated:YES completion:nil];
}

- (IBAction)expireSwitchChanged:(UISwitch *)sender {
    self.expireDateSetLabel.hidden = !sender.isOn;
    self.expireDateSetSaveButton.hidden = !sender.isOn;
    self.expireDateSetSaveButton.enabled = sender.isOn;
    
    if (sender.isOn) {
        self.expireDateSetLabel.text = self.expireDatePicker.date.mnz_formattedDateMediumStyle;
        [self showDatePicker];
    } else {
        [self.fullLinks removeAllObjects];
        [self.links removeAllObjects];
        [self.keys removeAllObjects];
        self.pending = self.nodesToExport.count;
        for (MEGANode *node in self.nodesToExport) {
            [MEGASdkManager.sharedMEGASdk exportNode:node expireTime:[NSDate dateWithTimeIntervalSince1970:0] delegate:self.exportDelegate];
        }
        
        self.currentExpiryDate = [NSDate dateWithTimeIntervalSince1970:0];
        
        [self hideDatePicker];
    }
    
    [self.tableView reloadData];
}

- (IBAction)expireDateChanged:(UIDatePicker *)sender {
    self.expireDateSetLabel.text = sender.date.mnz_formattedDateMediumStyle;
    
    self.expireDateSetSaveButton.enabled = (self.links.count > 1) ? YES : !(sender.date == self.currentExpiryDate);
    self.expireDateSetSaveButton.hidden = (self.links.count > 1) ? NO : (sender.date == self.currentExpiryDate);
}

- (IBAction)passwordProtectionSwitchChanged:(UISwitch *)sender {
    [self tableView:self.tableView didSelectRowAtIndexPath:[NSIndexPath indexPathForRow:2 inSection:0]];
    [self.tableView cellForRowAtIndexPath:[NSIndexPath indexPathForRow:0 inSection:0]].userInteractionEnabled = [self.tableView cellForRowAtIndexPath:[NSIndexPath indexPathForRow:1 inSection:0]].userInteractionEnabled = [self.tableView cellForRowAtIndexPath:[NSIndexPath indexPathForRow:2 inSection:0]].userInteractionEnabled = !sender.isOn;
    self.linkWithoutKeyLabel.enabled = self.decryptionKeyLabel.enabled = self.linkWithKeyLabel.enabled = !sender.isOn;
    
    self.passwordView.passwordTextField.enabled = self.confirmPasswordView.passwordTextField.enabled = sender.isOn;
    [self.tableView cellForRowAtIndexPath:[NSIndexPath indexPathForRow:0 inSection:4]].userInteractionEnabled = sender.isOn;
    
    if (sender.isOn) {
        self.encryptWithPasswordLabel.text = AMLocalizedString(@"encrypt", @"The text of a button. This button will encrypt a link with a password.");
        self.encryptWithPasswordLabel.textColor = [UIColor mnz_blueForTraitCollection:self.traitCollection];
        
        self.encryptedLinks = [NSMutableArray new];
        self.selectedArray = self.encryptedLinks;
        [self.tableView cellForRowAtIndexPath:self.selectedIndexPath].accessoryType = UITableViewCellAccessoryNone;
        [self.tableView cellForRowAtIndexPath:self.linkWithKeyIndexPath].accessoryType = UITableViewCellAccessoryCheckmark;
        self.selectedIndexPath = self.linkWithKeyIndexPath;
        [self.passwordStrengthIndicatorView updateViewWithPasswordStrength:[MEGASdkManager.sharedMEGASdk passwordStrength:self.passwordView.passwordTextField.text]];
    } else {
        self.selectedArray = self.fullLinks;
        self.passwordView.passwordTextField.text = @"";
        self.confirmPasswordView.passwordTextField.text = @"";
        self.currentPassword = @"";
        [self.passwordView setErrorState:NO withText:AMLocalizedString(@"passwordPlaceholder", @"Hint text to suggest that the user has to write his password")];
        [self.confirmPasswordView setErrorState:NO withText:AMLocalizedString(@"confirmPassword", @"Hint text where the user have to re-write the new password to confirm it")];
    }
    [self updateUI];
}

- (IBAction)shareAction:(UIBarButtonItem *)sender {
    UIActivityViewController *activityVC = [[UIActivityViewController alloc] initWithActivityItems:@[self.textToCopy.text] applicationActivities:nil];
    [activityVC setExcludedActivityTypes:@[UIActivityTypePrint, UIActivityTypeAssignToContact, UIActivityTypeSaveToCameraRoll, UIActivityTypeAddToReadingList, UIActivityTypeAirDrop]];
    [activityVC.popoverPresentationController setBarButtonItem:sender];
    
    [self presentViewController:activityVC animated:YES completion:nil];
}

- (IBAction)expireDateSaveButtonTouchUpInside:(UIButton *)sender {
    if ((self.links.count == 1) && (self.expireDatePicker.date == self.currentExpiryDate)) {
        return;
    }
    
    [self.fullLinks removeAllObjects];
    [self.links removeAllObjects];
    [self.keys removeAllObjects];
    self.pending = self.nodesToExport.count;
    for (MEGANode *node in self.nodesToExport) {
        [MEGASdkManager.sharedMEGASdk exportNode:node expireTime:self.expireDatePicker.date delegate:self.exportDelegate];
    }
    
    self.expireDateSetSaveButton.enabled = NO;
    self.expireDateSetSaveButton.hidden = YES;
    
    [self hideDatePicker];
}

- (IBAction)copyLinkTapped:(UIBarButtonItem *)sender {
    if (self.textToCopy.text.length > 0) {
        UIPasteboard *pasteboard = UIPasteboard.generalPasteboard;
        pasteboard.string = self.textToCopy.text;
        
        NSString *status;
        if (self.selectedIndexPath == [NSIndexPath indexPathForRow:1 inSection:0]) {
            status = AMLocalizedString(@"copiedToTheClipboard", @"Text of the button after the links were copied to the clipboard");
        } else {
            status = (self.selectedArray.count > 1) ? AMLocalizedString(@"linksCopied", @"Message shown when the links have been copied to the pasteboard") : AMLocalizedString(@"linkCopied", @"Message shown when the link has been copied to the pasteboard");
        }
        [SVProgressHUD showSuccessWithStatus:status];
    } else if (self.passwordSwitch.isOn) {
        [SVProgressHUD showErrorWithStatus:AMLocalizedString(@"passwordInvalidFormat", @"Enter a valid password")];
        [self.passwordView.passwordTextField becomeFirstResponder];
    }
}

#pragma mark - UITableViewDelegate

- (void)tableView:(UITableView *)tableView willDisplayCell:(UITableViewCell *)cell forRowAtIndexPath:(NSIndexPath *)indexPath {
    cell.backgroundColor = [UIColor mnz_secondaryBackgroundGroupedElevated:self.traitCollection];
    cell.tintColor = [UIColor mnz_primaryGrayForTraitCollection:self.traitCollection];
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    if (indexPath.section == 0) {
        switch (indexPath.row) {
            case 0:
                self.selectedArray = self.links;
                self.toolbarCopyLinkBarButtonItem.title = AMLocalizedString(@"copyLink", @"Title for a button to copy the link to the clipboard");
                break;
                
            case 1:
                self.selectedArray = self.keys;
                self.toolbarCopyLinkBarButtonItem.title = AMLocalizedString(@"copyKey", @"Title for a button that copies the key of the link to the clipboard");
                break;
                
            case 2:
                self.selectedArray = self.fullLinks;
                self.toolbarCopyLinkBarButtonItem.title = AMLocalizedString(@"copyLink", @"Title for a button to copy the link to the clipboard");
                break;
                
            default:
                break;
        }
        [self updateUI];
        [tableView cellForRowAtIndexPath:self.selectedIndexPath].accessoryType = UITableViewCellAccessoryNone;
        [tableView cellForRowAtIndexPath:indexPath].accessoryType = UITableViewCellAccessoryCheckmark;
        self.selectedIndexPath = indexPath;
    } else if (indexPath.section == 2) {
        if (indexPath.row == 1) {
            self.expireDatePicker.hidden ? [self showDatePicker] : [self hideDatePicker];
        }
    } else if (indexPath.section == 4) {
        if (![self validatePassword] || ![self validateConfirmPassword]) {
            return;
        }
        [self encryptLinks:self.passwordView.passwordTextField.text];
    }

    [tableView deselectRowAtIndexPath:indexPath animated:YES];
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {
    CGFloat heightForRow = 0.0f;
    switch (indexPath.section) {
        case 0:
        case 1:
            heightForRow = 44.0f;
            break;
            
        case 2: {
            if (indexPath.row == 0) {
                heightForRow = 44.0f;
            } else if (indexPath.row == 1) {
                heightForRow = self.expireSwitch.isOn ? 44.0f : 0.0f;
            } else if (indexPath.row == 2) {
                heightForRow = (self.expireSwitch.isOn && !self.expireDatePicker.hidden) ? 162.0f : 0.0f;
            }
            break;
        }
            
        case 3: {
            if (indexPath.row == 0) {
                heightForRow = 44.0f;
            } else if (indexPath.row == 1 || indexPath.row == 3) {
                heightForRow = self.passwordSwitch.isOn ? 60.0f : 0.0f;
            } else if (indexPath.row == 2) {
                heightForRow = self.passwordSwitch.isOn && self.currentPassword.length > 0 ? 112.0f : 0.0f;
            }
            break;
        }
            
        case 4: {
            heightForRow = self.passwordSwitch.isOn ? 44.0f : 0.0f;
        }
    }
    
    return heightForRow;
}

- (NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section {
    NSString *title = @"";
    switch (section) {
        case 2: {
            NSString *options = [AMLocalizedString(@"options", @"Header to explain that 'Upload videos', 'Use cellular connection' and 'Only when charging' are options of the Camera Uploads") stringByAppendingString:@" "];
            title = self.isFree ? [options stringByAppendingString:AMLocalizedString(@"proOnly", @"An alert dialog for the Get Link feature")] : options;
            break;
        }

        default:
            break;
    }
    
    return title;
}

#pragma mark - UITextFieldDelegate

- (void)textFieldDidBeginEditing:(UITextField *)textField {
    if (self.passwordView.passwordTextField == textField) {
        self.passwordView.toggleSecureButton.hidden = NO;
    } else {
        self.confirmPasswordView.toggleSecureButton.hidden = NO;
    }
}

- (void)textFieldDidEndEditing:(UITextField *)textField {
    if (self.passwordView.passwordTextField == textField) {
        self.passwordView.passwordTextField.secureTextEntry = YES;
        [self.passwordView configureSecureTextEntry];
        [self validatePassword];
    } else {
        self.confirmPasswordView.passwordTextField.secureTextEntry = YES;
        [self.confirmPasswordView configureSecureTextEntry];
        [self validateConfirmPassword];
    }
}

- (BOOL)textField:(UITextField *)textField shouldChangeCharactersInRange:(NSRange)range replacementString:(NSString *)string {
    self.currentPassword = [textField.text stringByReplacingCharactersInRange:range withString:string];
    
    if (self.passwordView.passwordTextField == textField) {
        [self.passwordView setErrorState:NO withText:AMLocalizedString(@"passwordPlaceholder", @"Hint text to suggest that the user has to write his password")];
        [self.tableView beginUpdates];
        [self.passwordStrengthIndicatorView updateViewWithPasswordStrength:[MEGASdkManager.sharedMEGASdk passwordStrength:self.currentPassword]];
        [self.tableView endUpdates];
        [self.tableView scrollToRowAtIndexPath:[NSIndexPath indexPathForRow:2 inSection:3] atScrollPosition:UITableViewScrollPositionTop animated:YES];
    } else {
        [self.confirmPasswordView setErrorState:NO withText:AMLocalizedString(@"confirmPassword", @"Hint text where the user have to re-write the new password to confirm it")];
    }
    
    return YES;
}

- (BOOL)textFieldShouldReturn:(UITextField *)textField {
    if (self.passwordView.passwordTextField == textField) {
        [self.confirmPasswordView.passwordTextField becomeFirstResponder];
    } else {
        [self.confirmPasswordView.passwordTextField resignFirstResponder];
    }
    
    return YES;
}

#pragma mark - UIAdaptivePresentationControllerDelegate

- (BOOL)presentationControllerShouldDismiss:(UIPresentationController *)presentationController {
    return NO;
}

- (void)presentationControllerDidAttemptToDismiss:(UIPresentationController *)presentationController {
    UIAlertController *confirmDismissAlert = [UIAlertController.alloc discardChangesFromBarButton:self.doneBarButtonItem withConfirmAction:^{
        [self dismissViewControllerAnimated:YES completion:nil];
    }];
    [self presentViewController:confirmDismissAlert animated:YES completion:nil];
}

@end
