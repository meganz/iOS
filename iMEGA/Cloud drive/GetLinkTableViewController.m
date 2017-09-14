
#import "GetLinkTableViewController.h"

#import "SVProgressHUD.h"

#import "Helper.h"
#import "MEGAExportRequestDelegate.h"
#import "MEGAPasswordLinkRequestDelegate.h"
#import "MEGASdk+MNZCategory.h"
#import "MEGASDKManager.h"

@interface GetLinkTableViewController () <UITextFieldDelegate>

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
@property (weak, nonatomic) IBOutlet UIBarButtonItem *shareBarButtonItem;

@property (weak, nonatomic) IBOutlet UILabel *textToCopy;
@property (weak, nonatomic) IBOutlet UISwitch *expireSwitch;
@property (weak, nonatomic) IBOutlet UISwitch *passwordSwitch;
@property (weak, nonatomic) IBOutlet UIDatePicker *expireDatePicker;

@property (weak, nonatomic) IBOutlet UILabel *linkWithoutKeyLabel;
@property (weak, nonatomic) IBOutlet UILabel *decryptionKeyLabel;
@property (weak, nonatomic) IBOutlet UILabel *linkWithKeyLabel;
@property (weak, nonatomic) IBOutlet UIButton *pasteboardCopyButton;
@property (weak, nonatomic) IBOutlet UILabel *expireDateLabel;
@property (weak, nonatomic) IBOutlet UILabel *expireDateSetLabel;
@property (weak, nonatomic) IBOutlet UIButton *expireDateSetSaveButton;

@property (weak, nonatomic) IBOutlet UILabel *passwordProtectionLabel;

@property (weak, nonatomic) IBOutlet UITextField *enterPasswordTextField;
@property (weak, nonatomic) IBOutlet UITextField *confirmPasswordTextField;

@property (nonatomic) MEGAExportRequestDelegate *exportDelegate;
@property (nonatomic) MEGAPasswordLinkRequestDelegate *passwordLinkDelegate;

@property (nonatomic) NSDateFormatter *dateFormatter;

@end

@implementation GetLinkTableViewController

#pragma mark - Lifecycle

- (void)viewDidLoad {
    [super viewDidLoad];
    
    [self setNavigationBarTitle];

    self.dateFormatter = [[NSDateFormatter alloc] init];
    self.dateFormatter.dateStyle = NSDateFormatterMediumStyle;
    self.dateFormatter.timeStyle = NSDateFormatterNoStyle;
    NSString *currentLanguageID = [[LocalizationSystem sharedLocalSystem] getLanguage];
    NSLocale *locale = [[NSLocale alloc] initWithLocaleIdentifier:currentLanguageID];
    self.dateFormatter.locale = locale;

    self.exportDelegate = [[MEGAExportRequestDelegate alloc] initWithCompletion:^(MEGARequest *request) {
        NSString *fullLink = [request link];
        
        NSArray *components = [fullLink componentsSeparatedByString:@"!"];
        NSString *link = [NSString stringWithFormat:@"%@!%@", components[0], components[1]];
        NSString *key = components[2];
        
        [self.fullLinks addObject:fullLink];
        [self.links addObject:link];
        [self.keys addObject:key];
        
        [self updateUI];
        
        if (--self.pending==0) {
            [SVProgressHUD dismiss];
        }
    } multipleLinks:self.nodesToExport.count > 1];
    
    self.passwordLinkDelegate = [[MEGAPasswordLinkRequestDelegate alloc] initWithCompletion:^(MEGARequest *request) {
        [self.encryptedLinks addObject:request.text];
        [self updateUI];
        
        if (--self.pending==0) {
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
        [[MEGASdkManager sharedMEGASdk] exportNode:node delegate:self.exportDelegate];
    }
    
    self.doneBarButtonItem.title = AMLocalizedString(@"done", @"");
    self.shareBarButtonItem.title = AMLocalizedString(@"share", @"Button title which, if tapped, will trigger the action of sharing with the contact or contacts selected");
    
    self.linkWithoutKeyLabel.text = AMLocalizedString(@"linkWithoutKey", @"This is button text on the Get Link dialog. This lets the user get a public file/folder link without the decryption key e.g. https://mega.nz/#!Qo12lSpT.");
    self.decryptionKeyLabel.text = AMLocalizedString(@"decryptionKey", nil);
    self.linkWithKeyLabel.text = AMLocalizedString(@"linkWithKey", @"This is button text on the Get Link dialog. This lets the user get a public file/folder link with the decryption key e.g. https://mega.nz/#!Qo12lSpT!3uv6GhJhAWWH46fcMN2KGRtxc_QSLthcwvAdaA_TjCE.");
    [self.pasteboardCopyButton setTitle:AMLocalizedString(@"copy", nil) forState:UIControlStateNormal];
    self.expireDateLabel.text = AMLocalizedString(@"setExpiryDate", @"A label in the Get Link dialog which allows the user to set an expiry date on their public link.");
    [self.expireDateSetSaveButton setTitle:AMLocalizedString(@"save", @"Button title to 'Save' the selected option") forState:UIControlStateNormal];
    
    self.passwordProtectionLabel.text = AMLocalizedString(@"setPasswordProtection", @"This is a title label on the Export Link dialog. The title covers the section where the user can password protect a public link.");
    
    [self checkExpirationTime];
}

#pragma mark - Private

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
        title = areExportedNodes ? AMLocalizedString(@"updateLinks", @"A right click context menu item. This will let the user update multiple public links with additional information. For example the public links can now be updated with an expiry time.") : AMLocalizedString(@"getLinks", @"Title shown under the action that allows you to get several links to files and/or folders");
    } else {
        title = areExportedNodes ? AMLocalizedString(@"updateLink", @"A right click context menu item. This will let the user update a public link with additional information. For example the public link can now be updated with an expiry time.") : AMLocalizedString(@"getLink", @"Title shown under the action that allows you to get a link to file or folder");
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
    uint64_t expirationTime = 0;
    uint64_t earlierExpirationTime = 0;
    for (MEGANode *node in self.nodesToExport) {
        if (earlierExpirationTime > node.expirationTime) {
            earlierExpirationTime = node.expirationTime;
        }
    }
    expirationTime = earlierExpirationTime;
    
    if (expirationTime == 0) {
        self.expireSwitch.on = NO;
    } else {
        self.expireSwitch.on = YES;
        self.expireDateSetLabel.hidden = NO;
        NSDate *date = [[NSDate alloc] initWithTimeIntervalSince1970:expirationTime];
        self.expireDateSetLabel.text = [self.dateFormatter stringFromDate:date];
    }
}

- (void)showDatePicker {
    [self.tableView beginUpdates];
    
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

#pragma mark - IBActions

- (IBAction)copyTapped:(UIButton *)sender {
    UIPasteboard *pasteboard = [UIPasteboard generalPasteboard];
    [pasteboard setString:self.textToCopy.text];
    NSString *status = self.selectedArray.count > 1 ? AMLocalizedString(@"linksCopied", @"Message shown when the links have been copied to the pasteboard") : AMLocalizedString(@"linkCopied", @"Message shown when the link has been copied to the pasteboard");
    [SVProgressHUD showSuccessWithStatus:status];
}

- (IBAction)doneTapped:(UIBarButtonItem *)sender {
    [self dismissViewControllerAnimated:YES completion:nil];
}

- (IBAction)expireSwitchChanged:(UISwitch *)sender {
    self.expireDateSetLabel.hidden = !sender.isOn;
    self.expireDateSetSaveButton.hidden = !sender.isOn;
    
    if (sender.isOn) {
        self.expireDateSetLabel.text = [self.dateFormatter stringFromDate:self.expireDatePicker.date];
        [self showDatePicker];
    } else {
        [self hideDatePicker];
    }
    
    [self.tableView reloadData];
}

- (IBAction)expireDateChanged:(UIDatePicker *)sender {
    self.expireDateSetLabel.text = [self.dateFormatter stringFromDate:sender.date];
    
    self.expireDateSetSaveButton.enabled = YES;
    self.expireDateSetSaveButton.hidden = NO;
}

- (IBAction)passwordProtectionSwitchChanged:(UISwitch *)sender {
    if (sender.isOn) {
        self.encryptedLinks = [NSMutableArray new];
        self.selectedArray = self.encryptedLinks;
        [self.tableView cellForRowAtIndexPath:self.selectedIndexPath].accessoryType = UITableViewCellAccessoryNone;
        [self.tableView cellForRowAtIndexPath:self.linkWithKeyIndexPath].accessoryType = UITableViewCellAccessoryCheckmark;
        self.selectedIndexPath = self.linkWithKeyIndexPath;
    } else {
        self.selectedArray = self.fullLinks;
        self.enterPasswordTextField.text = @"";
        self.confirmPasswordTextField.text = @"";
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
    self.pending = self.nodesToExport.count;
    for (MEGANode *node in self.nodesToExport) {
        [[MEGASdkManager sharedMEGASdk] exportNode:node expireTime:self.expireDatePicker.date delegate:self.exportDelegate];
    }
    
    self.expireDateSetSaveButton.enabled = NO;
    self.expireDateSetSaveButton.hidden = YES;
    
    [self hideDatePicker];
}

#pragma mark - TableViewDelegate

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    if (indexPath.section == 0) {
        switch (indexPath.row) {
            case 0:
                self.selectedArray = self.links;
                break;
                
            case 1:
                self.selectedArray = self.keys;
                break;
                
            case 2:
                self.selectedArray = self.fullLinks;
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
            } else if (indexPath.row == 1 || indexPath.row == 2) {
                heightForRow = self.passwordSwitch.isOn ? 44.0f : 0.0f;
            }
            break;
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

- (BOOL)textField:(UITextField *)textField shouldChangeCharactersInRange:(NSRange)range replacementString:(NSString *)string {
    NSString *password = [textField.text stringByReplacingCharactersInRange:range withString:string];

    switch (textField.tag) {
        case 0:
            if ([password compare:self.confirmPasswordTextField.text] == NSOrderedSame) {
                [self encryptLinks:password];
            }
            break;
            
        case 1:
            if ([password compare:self.enterPasswordTextField.text] == NSOrderedSame) {
                [self encryptLinks:password];
            }
            break;
            
        default:
            break;
    }
    
    return YES;
}

- (BOOL)textFieldShouldReturn:(UITextField *)textField {
    switch (textField.tag) {
        case 0:
            [self.confirmPasswordTextField becomeFirstResponder];
            break;
            
        case 1:
            if ([self.enterPasswordTextField.text compare:self.confirmPasswordTextField.text] != NSOrderedSame) {
                [SVProgressHUD showErrorWithStatus:AMLocalizedString(@"passwordsDoNotMatch", @"Error text shown when you have not written the same password")];
            }
            [self.confirmPasswordTextField resignFirstResponder];
            break;
            
        default:
            break;
    }
    
    return YES;
}

@end
