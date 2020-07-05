#import "ChatSettingsTableViewController.h"

#import "UIScrollView+EmptyDataSet.h"

#import "Helper.h"
#import "MEGAGetAttrUserRequestDelegate.h"
#import "MEGAReachabilityManager.h"
#import "MEGASdkManager.h"
#import "MEGA-Swift.h"
#import "NSString+MNZCategory.h"

#import "ChatStatusTableViewController.h"
#import "ChatVideoUploadQuality.h"
#import "UIView+MNZCategory.h"
#import "MEGA-Swift.h"
#import "ChatImageUploadQuality.h"

@interface ChatSettingsTableViewController () <MEGARequestDelegate, MEGAChatDelegate, MEGAChatRequestDelegate, PushNotificationControlProtocol>

@property (weak, nonatomic) IBOutlet UILabel *videoQualityLabel;
@property (weak, nonatomic) IBOutlet UILabel *videoQualityRightDetailLabel;

@property (weak, nonatomic) IBOutlet UILabel *statusLabel;
@property (weak, nonatomic) IBOutlet UILabel *statusRightDetailLabel;
@property (nonatomic, getter=isInvalidStatus) BOOL invalidStatus;

@property (weak, nonatomic) IBOutlet UILabel *richPreviewsLabel;
@property (weak, nonatomic) IBOutlet UISwitch *richPreviewsSwitch;

@property (weak, nonatomic) IBOutlet UILabel *doNotDisturbLabel;
@property (weak, nonatomic) IBOutlet UISwitch *doNotDisturbSwitch;

@property (nonatomic) GlobalDNDNotificationControl *globalDNDNotificationControl;

@property (weak, nonatomic) IBOutlet UILabel *imageQualityLabel;
@property (weak, nonatomic) IBOutlet UILabel *imageQualityRightDetailLabel;

@end

@implementation ChatSettingsTableViewController

#pragma mark - Lifecycle

- (void)viewDidLoad {
    [super viewDidLoad];
    
    self.navigationItem.title = AMLocalizedString(@"chat", @"Chat section header");
    
    self.statusLabel.text = AMLocalizedString(@"status", @"Title that refers to the status of the chat (Either Online or Offline)");
    
    self.richPreviewsLabel.text = AMLocalizedString(@"richUrlPreviews", @"Title used in settings that enables the generation of link previews in the chat");
    
    self.imageQualityLabel.text = AMLocalizedString(@"Image quality", @"Label used near to the option selected to encode the images uploaded to a chat (Automatic, High, Optimised)");
    
    self.videoQualityLabel.text = AMLocalizedString(@"videoQuality", @"Title that refers to the status of the chat (Either Online or Offline)");
    
    self.doNotDisturbLabel.text = AMLocalizedString(@"Do Not Disturb", nil);
    
    self.richPreviewsSwitch.on = [NSUserDefaults.standardUserDefaults boolForKey:@"richLinks"];
    
    MEGAGetAttrUserRequestDelegate *delegate = [[MEGAGetAttrUserRequestDelegate alloc] initWithCompletion:^(MEGARequest *request) {
        [NSUserDefaults.standardUserDefaults setBool:request.flag forKey:@"richLinks"];
        self.richPreviewsSwitch.on = request.flag;
    }];
    [[MEGASdkManager sharedMEGASdk] isRichPreviewsEnabledWithDelegate:delegate];
    
    self.doNotDisturbSwitch.enabled = NO;
    self.globalDNDNotificationControl = [GlobalDNDNotificationControl.alloc initWithDelegate:self];
    
    [self updateAppearance];
}

- (void)pushNotificationSettingsLoaded {
    self.doNotDisturbSwitch.enabled = self.globalDNDNotificationControl.isNotificationSettingsLoaded;
    self.doNotDisturbSwitch.on = self.globalDNDNotificationControl.isGlobalDNDEnabled;
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(internetConnectionChanged) name:kReachabilityChangedNotification object:nil];
    
    [[MEGASdkManager sharedMEGAChatSdk] addChatDelegate:self];
    
    [self onlineStatus];
    
    [self imageQualityString];
    [self videoQualityString];
    
    [self setUIElementsEnabled:MEGAReachabilityManager.isReachable];
    
    [self.tableView reloadData];
}

- (void)viewWillDisappear:(BOOL)animated {
    [super viewWillDisappear:animated];
    
    [[NSNotificationCenter defaultCenter] removeObserver:self name:kReachabilityChangedNotification object:nil];
    
    [[MEGASdkManager sharedMEGAChatSdk] removeChatDelegate:self];
}

- (void)traitCollectionDidChange:(UITraitCollection *)previousTraitCollection {
    [super traitCollectionDidChange:previousTraitCollection];
    
    if (@available(iOS 13.0, *)) {
        if ([self.traitCollection hasDifferentColorAppearanceComparedToTraitCollection:previousTraitCollection]) {
            [self updateAppearance];
        }
    }
}

#pragma mark - IBActions

- (IBAction)richPreviewsValueChanged:(UISwitch *)sender {
    [[MEGASdkManager sharedMEGASdk] enableRichPreviews:sender.isOn];
}

- (IBAction)dndSwitchValueChanged:(UISwitch *)sender {
    if (sender.isOn == YES) {
        [self.globalDNDNotificationControl turnOnDND:sender];
    } else {
        [self.globalDNDNotificationControl turnOffDND];
    }
}

#pragma mark - Private

- (void)updateAppearance {
    self.statusRightDetailLabel.textColor = self.imageQualityRightDetailLabel.textColor = self.videoQualityRightDetailLabel.textColor = UIColor.mnz_secondaryLabel;
    
    self.tableView.separatorColor = [UIColor mnz_separatorForTraitCollection:self.traitCollection];
    self.tableView.backgroundColor = [UIColor mnz_backgroundGroupedForTraitCollection:self.traitCollection];
    
    [self.tableView reloadData];
}

- (void)internetConnectionChanged {
    [self setUIElementsEnabled:MEGAReachabilityManager.isReachable];
}

- (void)setUIElementsEnabled:(BOOL)boolValue {
    self.statusLabel.enabled = self.statusRightDetailLabel.enabled = boolValue;
    self.richPreviewsLabel.enabled = self.richPreviewsSwitch.enabled = boolValue;
}

- (void)onlineStatus {
    MEGAChatPresenceConfig *presenceConfig = [[MEGASdkManager sharedMEGAChatSdk] presenceConfig];
    NSString *onlineStatus = [NSString chatStatusString:presenceConfig.onlineStatus];
    if (onlineStatus) {
        self.invalidStatus = NO;
        self.statusLabel.enabled = self.statusRightDetailLabel.enabled = YES;
    } else {
        self.invalidStatus = YES;
        self.statusLabel.enabled = self.statusRightDetailLabel.enabled = NO;
    }
    
    self.statusRightDetailLabel.text = onlineStatus;
}

- (void)imageQualityString {
    ChatImageUploadQuality imageQuality = [NSUserDefaults.standardUserDefaults integerForKey:@"chatImageQuality"];
    NSString *imageQualityString;
    switch (imageQuality) {
        case ChatImageUploadQualityAuto:
            imageQualityString = AMLocalizedString(@"Automatic", @"Text for some option property indicating the user the action will be determine automatically by MEGA. For example: Image Quality option for chats");
            break;
            
        case ChatImageUploadQualityHigh:
            imageQualityString = AMLocalizedString(@"high", @"Property associated with something higher than the usual or average size, number, value, or amount. For example: video quality.");
            break;
            
        case ChatImageUploadQualityOptimised:
            imageQualityString = AMLocalizedString(@"Optimised", @"Text for some option property indicating the user the action to perform will be optimised. For example: Image Quality reduction option for chats");
            break;
            
        default:
            break;
    }
    
    self.imageQualityRightDetailLabel.text = imageQualityString;
}

- (void)videoQualityString {
    NSNumber *videoQualityNumber = [[NSUserDefaults standardUserDefaults] objectForKey:@"ChatVideoQuality"];
    ChatVideoUploadQuality videoQuality;
    NSString *videoQualityString;
    if (videoQualityNumber) {
        videoQuality = videoQualityNumber.unsignedIntegerValue;
    } else {
        [[NSUserDefaults standardUserDefaults] setObject:@(ChatVideoUploadQualityMedium) forKey:@"ChatVideoQuality"];
        videoQuality = ChatVideoUploadQualityMedium;
    }
    
    switch (videoQuality) {
        case ChatVideoUploadQualityLow:
            videoQualityString = AMLocalizedString(@"low", @"Low");
            break;
            
        case ChatVideoUploadQualityMedium:
            videoQualityString = AMLocalizedString(@"medium", @"Medium");
            break;
            
        case ChatVideoUploadQualityHigh:
            videoQualityString = AMLocalizedString(@"high", @"High");
            break;
            
        case ChatVideoUploadQualityOriginal:
            videoQualityString = AMLocalizedString(@"original", @"Original");
            break;
            
        default:
            break;
    }
    
    _videoQualityRightDetailLabel.text = videoQualityString;
}

#pragma mark - UITableViewDataSource

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return 5;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return 1;
}

- (NSString *)tableView:(UITableView *)tableView titleForFooterInSection:(NSInteger)section {
    NSString *footerTitle;
    
    switch (section) {
        case 1:
            footerTitle = self.globalDNDNotificationControl.timeRemainingToDeactiveDND;
            break;
            
        case 2:
            footerTitle = AMLocalizedString(@"richPreviewsFooter", @"Used in the \"rich previews\", when the user first tries to send an url - we ask them before we generate previews for that URL, since we need to send them unencrypted to our servers.");
            break;
            
        case 3:
        {
            ChatImageUploadQuality imageQuality = [NSUserDefaults.standardUserDefaults integerForKey:@"chatImageQuality"];
            switch (imageQuality) {
                case ChatImageUploadQualityAuto:
                    footerTitle = AMLocalizedString(@"Send smaller size images through cellular networks and original size images through wifi", @"Description of Automatic Image Quality option");
                    break;
                    
                case ChatImageUploadQualityHigh:
                    footerTitle = AMLocalizedString(@"Send original size, increased quality images", @"Description of High Image Quality option");
                    break;
                    
                case ChatImageUploadQualityOptimised:
                    footerTitle = AMLocalizedString(@"Send smaller size images optimised for lower data consumption", @"Description of Optimised Image Quality option");
                    break;
                    
                default:
                    break;
            }
        }
            break;
            
        case 4:
            footerTitle = AMLocalizedString(@"qualityOfVideosUploadedToAChat", @"Footer text to explain the meaning of the functionaly 'Video quality' for videos uploaded to a chat.");
            break;
            
        default:
            break;
    }
    
    return footerTitle;
}

#pragma mark - UITableViewDelegate

- (void)tableView:(UITableView *)tableView willDisplayCell:(UITableViewCell *)cell forRowAtIndexPath:(NSIndexPath *)indexPath {
    cell.backgroundColor = [UIColor mnz_secondaryBackgroundGrouped:self.traitCollection];

    if (indexPath.section == 1 && indexPath.row == 0) {
        [self.globalDNDNotificationControl configureWithDndSwitch:self.doNotDisturbSwitch];
    }
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {    
    if ([indexPath isEqual:[NSIndexPath indexPathForRow:0 inSection:0]] && !self.isInvalidStatus) {
        ChatStatusTableViewController *chatStatusTVC = [[UIStoryboard storyboardWithName:@"ChatSettings" bundle:nil] instantiateViewControllerWithIdentifier:@"ChatStatusTableViewControllerID"];
        [self.navigationController pushViewController:chatStatusTVC animated:YES];
    }
}

#pragma mark - MEGAChatDelegate

- (void)onChatPresenceConfigUpdate:(MEGAChatSdk *)api presenceConfig:(MEGAChatPresenceConfig *)presenceConfig {
    if (presenceConfig.isPending) {
        return;
    }
    
    [self onlineStatus];
    [self.tableView reloadData];
}

#pragma mark - MEGAChatRequestDelegate

- (void)onChatRequestFinish:(MEGAChatSdk *)api request:(MEGAChatRequest *)request error:(MEGAChatError *)error {
    switch (request.type) {
        case MEGAChatRequestTypeLogout: {
            if (error.type) return;
            
            [self.tableView reloadData];
            [MEGAReachabilityManager sharedManager].chatRoomListState = MEGAChatRoomListStateOffline;
            break;
        }
            
        default:
            break;
    }
}

@end
