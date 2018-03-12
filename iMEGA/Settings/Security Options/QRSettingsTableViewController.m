
#import "QRSettingsTableViewController.h"

#import "SVProgressHUD.h"

#import "MEGAContactLinkCreateRequestDelegate.h"
#import "MEGAGetAttrUserRequestDelegate.h"
#import "MEGASetAttrUserRequestDelegate.h"
#import "MEGASdkManager.h"

@interface QRSettingsTableViewController ()

@property (weak, nonatomic) IBOutlet UIBarButtonItem *closeBarButtonItem;

@property (weak, nonatomic) IBOutlet UILabel *autoAcceptLabel;
@property (weak, nonatomic) IBOutlet UILabel *resetQRCodeLabel;
@property (weak, nonatomic) IBOutlet UISwitch *autoAcceptSwitch;

@property (nonatomic) MEGAGetAttrUserRequestDelegate *getContactLinksOptionDelegate;

@end

@implementation QRSettingsTableViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    self.navigationItem.title = AMLocalizedString(@"qrCode", @"QR Code label, used in Settings as title. String as short as possible");
    self.autoAcceptLabel.text = AMLocalizedString(@"autoAccept", @"Label for the setting that allow users to automatically add contacts when they scan his/her QR code. String as short as possible.");
    self.resetQRCodeLabel.text = AMLocalizedString(@"resetQrCode", @"Action to reset the current valid QR code of the user");
    self.closeBarButtonItem.title = AMLocalizedString(@"close", nil);
    
    self.getContactLinksOptionDelegate = [[MEGAGetAttrUserRequestDelegate alloc] initWithCompletion:^(MEGARequest *request) {
        self.autoAcceptSwitch.on = request.flag;
    }];
    [[MEGASdkManager sharedMEGASdk] getContactLinksOptionWithDelegate:self.getContactLinksOptionDelegate];
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
        MEGAContactLinkCreateRequestDelegate *delegate = [[MEGAContactLinkCreateRequestDelegate alloc] initWithCompletion:^(MEGARequest *request) {
            [SVProgressHUD showSuccessWithStatus:AMLocalizedString(@"resetQrCodeFooter", @"Footer that explains what would happen if the user resets his/her QR code")];
        }];

        [[MEGASdkManager sharedMEGASdk] contactLinkCreateRenew:YES delegate:delegate];
    }
    [tableView deselectRowAtIndexPath:indexPath animated:YES];
}

#pragma mark - IBActions

- (IBAction)autoAcceptSwitchDidChange:(UISwitch *)sender {
    MEGASetAttrUserRequestDelegate *delegate = [[MEGASetAttrUserRequestDelegate alloc] initWithCompletion:^(MEGARequest *request) {
        [[MEGASdkManager sharedMEGASdk] getContactLinksOptionWithDelegate:self.getContactLinksOptionDelegate];
    }];
    [[MEGASdkManager sharedMEGASdk] setContactLinksOptionDisable:!sender.isOn delegate:delegate];
}

- (IBAction)didTapCloseButton:(UIBarButtonItem *)sender {
    [self dismissViewControllerAnimated:YES completion:nil];
}

@end
