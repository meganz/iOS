#import "QRSettingsTableViewController.h"

#import "SVProgressHUD.h"

#import "MEGAContactLinkCreateRequestDelegate.h"
#import "MEGAGetAttrUserRequestDelegate.h"
#import "MEGASetAttrUserRequestDelegate.h"
#import "MEGA-Swift.h"

@import MEGAL10nObjc;

@interface QRSettingsTableViewController ()

@property (nonatomic) MEGAGetAttrUserRequestDelegate *getContactLinksOptionDelegate;

@end

@implementation QRSettingsTableViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    self.navigationItem.title = LocalizedString(@"qrCode", @"QR Code label, used in Settings as title. String as short as possible");
    self.autoAcceptLabel.text = LocalizedString(@"autoAccept", @"Label for the setting that allow users to automatically add contacts when they scan his/her QR code. String as short as possible.");
    self.resetQRCodeLabel.text = LocalizedString(@"resetQrCode", @"Action to reset the current valid QR code of the user");
    self.closeBarButtonItem.title = LocalizedString(@"close", @"");
    
    self.getContactLinksOptionDelegate = [[MEGAGetAttrUserRequestDelegate alloc] initWithCompletion:^(MEGARequest *request) {
        self.autoAcceptSwitch.on = request.flag;
    } error:^(MEGARequest *request, MEGAError *error) {
        self.autoAcceptSwitch.on = error.type == MEGAErrorTypeApiENoent;
    }];
    [MEGASdk.shared getContactLinksOptionWithDelegate:self.getContactLinksOptionDelegate];
    
    [self setupColors];
}

#pragma mark - UITableViewDataSource

- (NSString *)tableView:(UITableView *)tableView titleForFooterInSection:(NSInteger)section {
    NSString *footer = @"";
    switch (section) {
        case 0:
            footer = LocalizedString(@"autoAcceptFooter", @"Footer that explains the way Auto-Accept works for QR codes");
            break;
            
        case 1:
            footer = LocalizedString(@"resetQrCodeFooter", @"Footer that explains what would happen if the user resets his/her QR code");
            break;
            
        default:
            break;
    }
    return footer;
}

#pragma mark - UITableViewDelegate

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    if (indexPath.section==1 && indexPath.row == 0) {
        MEGAContactLinkCreateRequestDelegate *delegate = [[MEGAContactLinkCreateRequestDelegate alloc] initWithCompletion:^(MEGARequest *request) {
            [SVProgressHUD showSuccessWithStatus:LocalizedString(@"resetQrCodeFooter", @"Footer that explains what would happen if the user resets his/her QR code")];
        }];

        [MEGASdk.shared contactLinkCreateRenew:YES delegate:delegate];
    }
    [tableView deselectRowAtIndexPath:indexPath animated:YES];
}

- (void)tableView:(UITableView *)tableView willDisplayFooterView:(UIView *)view forSection:(NSInteger)section {
    if ([view isKindOfClass:[UITableViewHeaderFooterView class]]) {
        UITableViewHeaderFooterView *footerView = (UITableViewHeaderFooterView *)view;
        footerView.textLabel.textColor = UIColor.mnz_secondaryTextColor;
    }
}

#pragma mark - IBActions

- (IBAction)autoAcceptSwitchDidChange:(UISwitch *)sender {
    MEGASetAttrUserRequestDelegate *delegate = [[MEGASetAttrUserRequestDelegate alloc] initWithCompletion:^() {
        [MEGASdk.shared getContactLinksOptionWithDelegate:self.getContactLinksOptionDelegate];
    }];
    [MEGASdk.shared setContactLinksOptionDisable:sender.isOn delegate:delegate];
}

- (IBAction)didTapCloseButton:(UIBarButtonItem *)sender {
    [self dismissViewControllerAnimated:YES completion:nil];
}

@end
