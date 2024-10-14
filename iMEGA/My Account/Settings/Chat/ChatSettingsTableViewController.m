#import "ChatSettingsTableViewController.h"

#import "UIScrollView+EmptyDataSet.h"

#import "Helper.h"
#import "MEGAGetAttrUserRequestDelegate.h"
#import "MEGAReachabilityManager.h"
#import "MEGA-Swift.h"
#import "NSString+MNZCategory.h"

#import "ChatStatusTableViewController.h"
#import "ChatVideoUploadQuality.h"
#import "UIView+MNZCategory.h"
#import "MEGA-Swift.h"
#import "ChatImageUploadQuality.h"

@import MEGAL10nObjc;

typedef NS_ENUM(NSInteger, ChatSettingsSection) {
    ChatSettingsSectionStatus = 0,
    ChatSettingsSectionNotification,
    ChatSettingsSectionRichPreview,
    ChatSettingsSectionImageQuality,
    ChatSettingsSectionVideoQuality
};

typedef NS_ENUM(NSInteger, ChatSettingsNotificationRow) {
    ChatSettingsNotificationRowChatNotification = 0,
    ChatSettingsNotificationRowDND
};

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

@property (weak, nonatomic) IBOutlet UILabel *chatNotificationsLabel;
@property (weak, nonatomic) IBOutlet UISwitch *chatNotificationsSwitch;

@property (nonatomic) GlobalDNDNotificationControl *globalDNDNotificationControl;

@property (weak, nonatomic) IBOutlet UILabel *imageQualityLabel;
@property (weak, nonatomic) IBOutlet UILabel *imageQualityRightDetailLabel;

@property (nonatomic) NSArray<NSNumber *> *sections;
@property (nonatomic) NSArray<NSNumber *> *notificationSectionRows;


@end

@implementation ChatSettingsTableViewController

#pragma mark - Lifecycle

- (void)viewDidLoad {
    [super viewDidLoad];
    
    self.sections = @[@(ChatSettingsSectionStatus),
                      @(ChatSettingsSectionNotification),
                      @(ChatSettingsSectionRichPreview),
                      @(ChatSettingsSectionImageQuality),
                      @(ChatSettingsSectionVideoQuality)];
    self.notificationSectionRows = @[@(ChatSettingsNotificationRowChatNotification),
                                     @(ChatSettingsNotificationRowDND)];
    
    NSString *title = LocalizedString(@"chat", @"Chat section header");
    self.navigationItem.title = title;
    [self setMenuCapableBackButtonWithMenuTitle:title];
    
    self.statusLabel.text = LocalizedString(@"status", @"Title that refers to the status of the chat (Either Online or Offline)");
    
    self.richPreviewsLabel.text = LocalizedString(@"richUrlPreviews", @"Title used in settings that enables the generation of link previews in the chat");
    
    self.imageQualityLabel.text = LocalizedString(@"Image Quality", @"Label used near to the option selected to encode the images uploaded to a chat (Automatic, High, Optimised)");
    
    self.videoQualityLabel.text = LocalizedString(@"videoQuality", @"Title that refers to the status of the chat (Either Online or Offline)");
    
    self.doNotDisturbLabel.text = LocalizedString(@"Do Not Disturb", @"");

    self.chatNotificationsLabel.text = LocalizedString(@"Chat Notifications", @"Title that refers to disabling the chat notifications forever.");
    
    self.richPreviewsSwitch.on = [NSUserDefaults.standardUserDefaults boolForKey:@"richLinks"];
    
    MEGAGetAttrUserRequestDelegate *delegate = [[MEGAGetAttrUserRequestDelegate alloc] initWithCompletion:^(MEGARequest *request) {
        [NSUserDefaults.standardUserDefaults setBool:request.flag forKey:@"richLinks"];
        self.richPreviewsSwitch.on = request.flag;
    }];
    [MEGASdk.shared isRichPreviewsEnabledWithDelegate:delegate];
    
    self.doNotDisturbSwitch.enabled = NO;
    self.chatNotificationsSwitch.enabled = NO;
    self.globalDNDNotificationControl = [GlobalDNDNotificationControl.alloc initWithDelegate:self];
    
    [self setupColors];
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(internetConnectionChanged) name:kReachabilityChangedNotification object:nil];
    
    [MEGAChatSdk.shared addChatDelegate:self];
    
    [self onlineStatus];
    
    [self imageQualityString];
    [self videoQualityString];
    
    [self setUIElementsEnabled:MEGAReachabilityManager.isReachable];
    
    [self.tableView reloadData];
}

- (void)viewWillDisappear:(BOOL)animated {
    [super viewWillDisappear:animated];
    
    [[NSNotificationCenter defaultCenter] removeObserver:self name:kReachabilityChangedNotification object:nil];
    
    [MEGAChatSdk.shared removeChatDelegate:self];
}

#pragma mark - IBActions

- (IBAction)richPreviewsValueChanged:(UISwitch *)sender {
    [MEGASdk.shared enableRichPreviews:sender.isOn];
}

- (IBAction)dndSwitchValueChanged:(UISwitch *)sender {
    if (sender.isOn) {
        [self.globalDNDNotificationControl turnOnDNDWithIsChatTypeMeeting:NO sender:sender];
    } else {
        [self.globalDNDNotificationControl turnOffDND];
    }
}

- (IBAction)notificationSwitchValueChanged:(UISwitch *)sender {
    if (sender.isOn) {
        [self.globalDNDNotificationControl turnOffDND];
    } else {
        [self.globalDNDNotificationControl turnOffChatNotification];
    }
}

#pragma mark - Private

- (void)setupColors {
    self.statusRightDetailLabel.textColor = self.imageQualityRightDetailLabel.textColor = self.videoQualityRightDetailLabel.textColor = UIColor.secondaryLabelColor;
    
    self.tableView.separatorColor = [UIColor mnz_separator];
    self.tableView.backgroundColor = [UIColor pageBackgroundColor];
}

- (void)internetConnectionChanged {
    [self setUIElementsEnabled:MEGAReachabilityManager.isReachable];
}

- (void)setUIElementsEnabled:(BOOL)boolValue {
    self.statusLabel.enabled = self.statusRightDetailLabel.enabled = boolValue;
    self.richPreviewsLabel.enabled = self.richPreviewsSwitch.enabled = boolValue;
}

- (void)onlineStatus {
    MEGAChatPresenceConfig *presenceConfig = [MEGAChatSdk.shared presenceConfig];
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
            imageQualityString = LocalizedString(@"media.quality.automatic", @"Indicating that the image quality will be determine by MEGA.");
            break;
            
        case ChatImageUploadQualityOriginal:
            imageQualityString = LocalizedString(@"media.quality.original", @"Indicating that the image quality will be the same.");
            break;
            
        case ChatImageUploadQualityOptimised:
            imageQualityString = LocalizedString(@"media.quality.optimised", @"Indicating that the image will be optimised.");
            break;
            
        default:
            break;
    }
    
    self.imageQualityRightDetailLabel.text = imageQualityString;
}

- (void)videoQualityString {
    NSString *videoQualityString;
    NSUserDefaults *sharedUserDefaults = [NSUserDefaults.alloc initWithSuiteName:MEGAGroupIdentifier];
    ChatVideoUploadQuality videoQuality = [[sharedUserDefaults objectForKey:@"ChatVideoQuality"] unsignedIntegerValue];
    if (!videoQuality) {
        [sharedUserDefaults setObject:@(ChatVideoUploadQualityMedium) forKey:@"ChatVideoQuality"];
        videoQuality = ChatVideoUploadQualityMedium;
    }
    
    switch (videoQuality) {
        case ChatVideoUploadQualityLow:
            videoQualityString = LocalizedString(@"media.quality.low", @"Low");
            break;
            
        case ChatVideoUploadQualityMedium:
            videoQualityString = LocalizedString(@"media.quality.medium", @"Medium");
            break;
            
        case ChatVideoUploadQualityHigh:
            videoQualityString = LocalizedString(@"media.quality.high", @"High");
            break;
            
        case ChatVideoUploadQualityOriginal:
            videoQualityString = LocalizedString(@"media.quality.original", @"Original");
            break;
            
        default:
            break;
    }
    
    _videoQualityRightDetailLabel.text = videoQualityString;
}

#pragma mark - UITableViewDataSource

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return self.sections.count;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    if (self.sections[section].intValue == ChatSettingsSectionNotification) {
        return self.notificationSectionRows.count;
    }
    
    return 1;
}

- (NSString *)tableView:(UITableView *)tableView titleForFooterInSection:(NSInteger)section {
    NSString *footerTitle;
    
    switch (self.sections[section].intValue) {
        case ChatSettingsSectionNotification:
            if (!self.globalDNDNotificationControl.isForeverOptionEnabled) {
                footerTitle = self.globalDNDNotificationControl.timeRemainingToDeactiveDND;
            }
            break;
            
        case ChatSettingsSectionRichPreview:
            footerTitle = LocalizedString(@"richPreviewsFooter", @"Used in the \"rich previews\", when the user first tries to send an url - we ask them before we generate previews for that URL, since we need to send them unencrypted to our servers.");
            break;
            
        case ChatSettingsSectionImageQuality:
        {
            ChatImageUploadQuality imageQuality = [NSUserDefaults.standardUserDefaults integerForKey:@"chatImageQuality"];
            switch (imageQuality) {
                case ChatImageUploadQualityAuto:
                    footerTitle = LocalizedString(@"Send smaller size images through cellular networks and original size images through wifi", @"Description of Automatic Image Quality option");
                    break;
                    
                case ChatImageUploadQualityOriginal:
                    footerTitle = LocalizedString(@"Send original size, increased quality images", @"Description of Original Image Quality option");
                    break;
                    
                case ChatImageUploadQualityOptimised:
                    footerTitle = LocalizedString(@"Send smaller size images optimised for lower data consumption", @"Description of Optimised Image Quality option");
                    break;
                    
                default:
                    break;
            }
        }
            break;
            
        case ChatSettingsSectionVideoQuality:
            footerTitle = LocalizedString(@"qualityOfVideosUploadedToAChat", @"Footer text to explain the meaning of the functionaly 'Video quality' for videos uploaded to a chat.");
            break;
            
        default:
            break;
    }
    
    return footerTitle;
}

#pragma mark - UITableViewDelegate

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {
    CGFloat rowHeight = tableView.rowHeight;
    switch (self.sections[indexPath.section].intValue) {
        case ChatSettingsSectionNotification:
            switch (indexPath.row) {
                case ChatSettingsNotificationRowDND:
                    if (!self.chatNotificationsSwitch.on) {
                        return 0;
                    }
                    break;
                    
                default:
                    break;
            }
            break;
            
        default:
            break;
    }
    
    return rowHeight;
}

- (void)tableView:(UITableView *)tableView willDisplayCell:(UITableViewCell *)cell forRowAtIndexPath:(NSIndexPath *)indexPath {
    cell.backgroundColor = [UIColor pageBackgroundColor];

    if (indexPath.section == ChatSettingsSectionNotification) {
        switch (indexPath.row) {
            case ChatSettingsNotificationRowChatNotification:
                [self.globalDNDNotificationControl configureWithNotificationSwitch:self.chatNotificationsSwitch];
                break;
                
            case ChatSettingsNotificationRowDND:
                [self.globalDNDNotificationControl configureWithDndSwitch:self.doNotDisturbSwitch];
                break;
                
            default:
                break;
        }
    }
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {    
    if (indexPath.section == ChatSettingsSectionStatus && !self.isInvalidStatus) {
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
            break;
        }
            
        default:
            break;
    }
}

@end
