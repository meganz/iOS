
#import "QRSettingsTableViewController.h"

#import "SVProgressHUD.h"

#import "MEGASdkManager.h"

@interface QRSettingsTableViewController () <MEGARequestDelegate>

@property (weak, nonatomic) IBOutlet UIBarButtonItem *closeBarButtonItem;

@property (weak, nonatomic) IBOutlet UILabel *autoAcceptLabel;
@property (weak, nonatomic) IBOutlet UILabel *resetQRCodeLabel;
@property (weak, nonatomic) IBOutlet UISwitch *autoAcceptSwitch;

@end

@implementation QRSettingsTableViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    self.navigationItem.title = AMLocalizedString(@"qrCode", @"QR Code label, used in Settings as title. String as short as possible");
    self.autoAcceptLabel.text = AMLocalizedString(@"autoAccept", @"Label for the setting that allow users to automatically add contacts when they scan his/her QR code. String as short as possible.");
    self.resetQRCodeLabel.text = AMLocalizedString(@"resetQrCode", @"Action to reset the current valid QR code of the user");
    self.closeBarButtonItem.title = AMLocalizedString(@"close", nil);
    
    [[MEGASdkManager sharedMEGASdk] getContactLinksOptionWithDelegate:self];
}

#pragma mark - UITableViewDataSource

- (NSString *)tableView:(UITableView *)tableView titleForFooterInSection:(NSInteger)section {
    NSString *footer = @"";
    switch (section) {
        case 0:
            footer = AMLocalizedString(@"autoAcceptFooter", @"Footer that explains the way Auto-Accept works for QR codes");
            break;
            
        case 1:
            footer = AMLocalizedString(@"resetQrCodeFooter", @"Footer that explains what would happen if the user resets his/her QR code");
            break;
            
        default:
            break;
    }
    return footer;
}

#pragma mark - UITableViewDelegate

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    if (indexPath.section==1 && indexPath.row == 0) {
        // TODO: Delete the handle parameter as it is going to be useless
        [[MEGASdkManager sharedMEGASdk] contactLinkDeleteWithHandle:0 delegate:self];
    }
    [tableView deselectRowAtIndexPath:indexPath animated:YES];
}

#pragma mark - IBActions

- (IBAction)autoAcceptSwitchDidChange:(UISwitch *)sender {
    [[MEGASdkManager sharedMEGASdk] setContactLinksOptionDisable:!sender.isOn delegate:self];
}

- (IBAction)didTapCloseButton:(UIBarButtonItem *)sender {
    [self dismissViewControllerAnimated:YES completion:nil];
}

#pragma mark - MEGARequestDelegate

- (void)onRequestFinish:(MEGASdk *)api request:(MEGARequest *)request error:(MEGAError *)error {
    if (!error.type) {
        switch (request.type) {
            case MEGARequestTypeContactLinkDelete:
                [SVProgressHUD showSuccessWithStatus:AMLocalizedString(@"resetQrCodeFooter", @"Footer that explains what would happen if the user resets his/her QR code")];
                break;
                
            case MEGARequestTypeGetAttrUser:
                self.autoAcceptSwitch.on = request.flag;
                break;
                
            default:
                break;
        }
    }
}

@end
