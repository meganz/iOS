
#import "GetLinkTableViewController.h"

#import "SVProgressHUD.h"

#import "Helper.h"
#import "MEGASDKManager.h"

@interface GetLinkTableViewController () <MEGARequestDelegate>

@property (nonatomic) NSMutableArray *fullLinks;
@property (nonatomic) NSMutableArray *links;
@property (nonatomic) NSMutableArray *keys;

@property (nonatomic) NSMutableArray *selectedArray;
@property (nonatomic) NSIndexPath *selectedIndexPath;

@property (nonatomic) BOOL isFree;
@property (nonatomic) NSUInteger pending;

@property (weak, nonatomic) IBOutlet UILabel *textToCopy;
@property (weak, nonatomic) IBOutlet UISwitch *expireSwitch;
@property (weak, nonatomic) IBOutlet UIDatePicker *expireDatePicker;

@property (weak, nonatomic) IBOutlet UILabel *linkWithoutKeyLabel;
@property (weak, nonatomic) IBOutlet UILabel *decryptionKeyLabel;
@property (weak, nonatomic) IBOutlet UILabel *linkWithKeyLabel;
@property (weak, nonatomic) IBOutlet UIButton *pasteboardCopyButton;
@property (weak, nonatomic) IBOutlet UILabel *expireDateLabel;

@end

@implementation GetLinkTableViewController

#pragma mark - Lifecycle

- (void)viewDidLoad {
    [super viewDidLoad];
    
    self.fullLinks = [NSMutableArray new];
    self.links = [NSMutableArray new];
    self.keys = [NSMutableArray new];
    
    self.selectedArray = self.fullLinks;
    self.selectedIndexPath = [NSIndexPath indexPathForRow:2 inSection:0];
    
    self.isFree = NO;
    NSDate *tomorrow = [NSDate dateWithTimeInterval:(24*60*60) sinceDate:[NSDate date]];
    self.expireDatePicker.minimumDate = tomorrow;
    [self.expireDatePicker setLocale:[NSLocale localeWithLocaleIdentifier:[[LocalizationSystem sharedLocalSystem] getLanguage]]];
    
    [[MEGASdkManager sharedMEGASdk] getAccountDetailsWithDelegate:self];

    self.pending = self.nodesToExport.count;
    for (MEGANode *node in self.nodesToExport) {
        [[MEGASdkManager sharedMEGASdk] exportNode:node delegate:self];
    }
    
    self.linkWithoutKeyLabel.text = AMLocalizedString(@"linkWithoutKey", @"This is button text on the Get Link dialog. This lets the user get a public file/folder link without the decryption key e.g. https://mega.nz/#!Qo12lSpT.");
    self.decryptionKeyLabel.text = AMLocalizedString(@"decryptionKey", nil);
    self.linkWithKeyLabel.text = AMLocalizedString(@"linkWithKey", @"This is button text on the Get Link dialog. This lets the user get a public file/folder link with the decryption key e.g. https://mega.nz/#!Qo12lSpT!3uv6GhJhAWWH46fcMN2KGRtxc_QSLthcwvAdaA_TjCE.");
    [self.pasteboardCopyButton setTitle:AMLocalizedString(@"copy", nil) forState:UIControlStateNormal];
    self.expireDateLabel.text = AMLocalizedString(@"expiryDate", @"A label in the Get Link dialog which allows the user to set an expiry date on their public link.");
}

#pragma mark - Private

- (void)updateTextToCopy {
    self.textToCopy.text = [self.selectedArray componentsJoinedByString:@" "];
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
            [[MEGASdkManager sharedMEGASdk] exportNode:node expireTime:self.expireDatePicker.date delegate:self];
        } else {
            [[MEGASdkManager sharedMEGASdk] exportNode:node delegate:self];
        }
    }
}

- (IBAction)expireDateChanged:(UIDatePicker *)sender {
    self.pending = self.nodesToExport.count;
    for (MEGANode *node in self.nodesToExport) {
        [[MEGASdkManager sharedMEGASdk] exportNode:node expireTime:self.expireDatePicker.date delegate:self];
    }
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
        [self updateTextToCopy];
        [tableView cellForRowAtIndexPath:self.selectedIndexPath].accessoryType = UITableViewCellAccessoryNone;
        [tableView cellForRowAtIndexPath:indexPath].accessoryType = UITableViewCellAccessoryCheckmark;
        self.selectedIndexPath = indexPath;
    }
    [tableView deselectRowAtIndexPath:indexPath animated:YES];
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {
    CGFloat heightForRow = 44.0;
    if (self.isFree && indexPath.section == 2) {
        return 0.0f;
    }
    if (indexPath.section == 2 && indexPath.row == 1) {
        return self.expireSwitch.isOn ? 162.0f : 0.0f;
    }
    return heightForRow;
}

-(NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section {
    NSString *title = @"";
    switch (section) {
        case 0:
            title = AMLocalizedString(@"export", @"Title for the Export section of the get link view");
            break;
            
        case 2:
            title = self.isFree ? @"" : AMLocalizedString(@"options", nil);
            break;

        default:
            break;
    }
    return title;
}

#pragma mark - MEGARequestDelegate

- (void)onRequestStart:(MEGASdk *)api request:(MEGARequest *)request {
    if ([request type] == MEGARequestTypeExport && [request access]) {
        NSString *status = self.pending > 1 ? AMLocalizedString(@"generatingLinks", nil) : AMLocalizedString(@"generatingLink", nil);
        [SVProgressHUD showWithStatus:status];
    }
}

- (void)onRequestFinish:(MEGASdk *)api request:(MEGARequest *)request error:(MEGAError *)error {
    if ([error type]) {
        [SVProgressHUD showErrorWithStatus:error.name];
        return;
    }
    
    switch ([request type]) {
        case MEGARequestTypeExport: {
            if ([request access]) {
                NSString *fullLink = [request link];
                
                NSArray *components = [fullLink componentsSeparatedByString:@"!"];
                NSString *link = [NSString stringWithFormat:@"%@!%@", components[0], components[1]];
                NSString *key = components[2];
                
                [self.fullLinks addObject:fullLink];
                [self.links addObject:link];
                [self.keys addObject:key];
                
                [self updateTextToCopy];
                if (--self.pending==0) {
                    [SVProgressHUD dismiss];
                }
            }
            break;
        }
            
        case MEGARequestTypeAccountDetails: {
            self.isFree = [[request megaAccountDetails] type] == MEGAAccountTypeFree;
            [self.tableView reloadData];
        }
            
        default:
            break;
    }
}

@end
