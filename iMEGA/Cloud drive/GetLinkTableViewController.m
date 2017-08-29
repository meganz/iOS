
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

@property (weak, nonatomic) IBOutlet UILabel *textToCopy;
@property (weak, nonatomic) IBOutlet UISwitch *expireSwitch;
@property (weak, nonatomic) IBOutlet UISwitch *passwordSwitch;
@property (weak, nonatomic) IBOutlet UIDatePicker *expireDatePicker;

@property (weak, nonatomic) IBOutlet UILabel *linkWithoutKeyLabel;
@property (weak, nonatomic) IBOutlet UILabel *decryptionKeyLabel;
@property (weak, nonatomic) IBOutlet UILabel *linkWithKeyLabel;
@property (weak, nonatomic) IBOutlet UIButton *pasteboardCopyButton;
@property (weak, nonatomic) IBOutlet UILabel *expireDateLabel;
@property (weak, nonatomic) IBOutlet UILabel *passwordProtectionLabel;

@property (weak, nonatomic) IBOutlet UITextField *enterPasswordTextField;
@property (weak, nonatomic) IBOutlet UITextField *confirmPasswordTextField;

@property (nonatomic) MEGAExportRequestDelegate *exportDelegate;
@property (nonatomic) MEGAPasswordLinkRequestDelegate *passwordLinkDelegate;

@end

@implementation GetLinkTableViewController

#pragma mark - Lifecycle

- (void)viewDidLoad {
    [super viewDidLoad];
    
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

    self.pending = self.nodesToExport.count;
    for (MEGANode *node in self.nodesToExport) {
        [[MEGASdkManager sharedMEGASdk] exportNode:node delegate:self.exportDelegate];
    }
    
    self.linkWithoutKeyLabel.text = AMLocalizedString(@"linkWithoutKey", @"This is button text on the Get Link dialog. This lets the user get a public file/folder link without the decryption key e.g. https://mega.nz/#!Qo12lSpT.");
    self.decryptionKeyLabel.text = AMLocalizedString(@"decryptionKey", nil);
    self.linkWithKeyLabel.text = AMLocalizedString(@"linkWithKey", @"This is button text on the Get Link dialog. This lets the user get a public file/folder link with the decryption key e.g. https://mega.nz/#!Qo12lSpT!3uv6GhJhAWWH46fcMN2KGRtxc_QSLthcwvAdaA_TjCE.");
    [self.pasteboardCopyButton setTitle:AMLocalizedString(@"copy", nil) forState:UIControlStateNormal];
    self.expireDateLabel.text = AMLocalizedString(@"expiryDate", @"A label in the Get Link dialog which allows the user to set an expiry date on their public link.");
}

#pragma mark - Private

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
    [self.tableView reloadData];
    self.pending = self.nodesToExport.count;
    for (MEGANode *node in self.nodesToExport) {
        if (sender.isOn) {
            [[MEGASdkManager sharedMEGASdk] exportNode:node expireTime:self.expireDatePicker.date delegate:self.exportDelegate];
        } else {
            [[MEGASdkManager sharedMEGASdk] exportNode:node delegate:self.exportDelegate];
        }
    }
}

- (IBAction)expireDateChanged:(UIDatePicker *)sender {
    self.pending = self.nodesToExport.count;
    for (MEGANode *node in self.nodesToExport) {
        [[MEGASdkManager sharedMEGASdk] exportNode:node expireTime:self.expireDatePicker.date delegate:self.exportDelegate];
    }
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
    }
    [tableView deselectRowAtIndexPath:indexPath animated:YES];
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {
    CGFloat heightForRow = 44.0;
    if (self.isFree && indexPath.section >= 2) {
        return 0.0f;
    }
    if (indexPath.section == 2 && indexPath.row == 1) {
        return self.expireSwitch.isOn ? 162.0f : 0.0f;
    }
    if (!self.passwordSwitch.isOn && indexPath.section == 3 && indexPath.row >= 1) {
         return 0.0f;
    }
    if (self.passwordSwitch.isOn && indexPath.section == 0 && indexPath.row < 2) {
        return 0.0f;
    }
    return heightForRow;
}

- (NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section {
    NSString *title = @"";
    switch (section) {
        case 0:
            title = AMLocalizedString(@"export", @"Title for the Export section of the get link view");
            break;
            
        case 1:
            title = self.selectedArray.count > 1 ? AMLocalizedString(@"megaLinks", @"Title for the Link section of the get link view when there are more than one link") : [AMLocalizedString(@"megaLink", @"Title for the Link section of the get link view when there is only one link") stringByReplacingOccurrencesOfString:@":" withString:@""];
            break;
            
        case 2:
            title = self.isFree ? @"" : AMLocalizedString(@"options", nil);
            break;

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
            [self.confirmPasswordTextField resignFirstResponder];
            break;
            
        default:
            break;
    }
    
    return YES;
}

@end
