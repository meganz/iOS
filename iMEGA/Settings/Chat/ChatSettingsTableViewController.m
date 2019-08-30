#import "ChatSettingsTableViewController.h"

#import "UIScrollView+EmptyDataSet.h"

#import "Helper.h"
#import "MEGAGetAttrUserRequestDelegate.h"
#import "MEGAReachabilityManager.h"
#import "MEGASdkManager.h"
#import "NSString+MNZCategory.h"

#import "ChatStatusTableViewController.h"
#import "ChatVideoUploadQuality.h"

@interface ChatSettingsTableViewController () <MEGARequestDelegate, MEGAChatDelegate, MEGAChatRequestDelegate>

@property (weak, nonatomic) IBOutlet UILabel *chatLabel;
@property (weak, nonatomic) IBOutlet UISwitch *chatSwitch;

@property (weak, nonatomic) IBOutlet UILabel *videoQualityLabel;
@property (weak, nonatomic) IBOutlet UILabel *videoQualityRightDetailLabel;

@property (weak, nonatomic) IBOutlet UILabel *statusLabel;
@property (weak, nonatomic) IBOutlet UILabel *statusRightDetailLabel;
@property (nonatomic, getter=isInvalidStatus) BOOL invalidStatus;

@property (weak, nonatomic) IBOutlet UILabel *richPreviewsLabel;
@property (weak, nonatomic) IBOutlet UISwitch *richPreviewsSwitch;

@end

@implementation ChatSettingsTableViewController

#pragma mark - Lifecycle

- (void)viewDidLoad {
    [super viewDidLoad];
    
    self.navigationItem.title = AMLocalizedString(@"chat", @"Chat section header");
    
    self.chatLabel.text = AMLocalizedString(@"chat", @"Chat section header");
    
    self.statusLabel.text = AMLocalizedString(@"status", @"Title that refers to the status of the chat (Either Online or Offline)");
    
    self.richPreviewsLabel.text = AMLocalizedString(@"richUrlPreviews", @"Title used in settings that enables the generation of link previews in the chat");
    
    self.videoQualityLabel.text = AMLocalizedString(@"videoQuality", @"Title that refers to the status of the chat (Either Online or Offline)");
        
    BOOL isChatEnabled = [NSUserDefaults.standardUserDefaults boolForKey:@"IsChatEnabled"];
    [self.chatSwitch setOn:isChatEnabled animated:YES];
    
    self.richPreviewsSwitch.on = [NSUserDefaults.standardUserDefaults boolForKey:@"richLinks"];
    
    MEGAGetAttrUserRequestDelegate *delegate = [[MEGAGetAttrUserRequestDelegate alloc] initWithCompletion:^(MEGARequest *request) {
        [NSUserDefaults.standardUserDefaults setBool:request.flag forKey:@"richLinks"];
        self.richPreviewsSwitch.on = request.flag;
    }];
    [[MEGASdkManager sharedMEGASdk] isRichPreviewsEnabledWithDelegate:delegate];
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(internetConnectionChanged) name:kReachabilityChangedNotification object:nil];
    
    [[MEGASdkManager sharedMEGAChatSdk] addChatDelegate:self];
    
    [self onlineStatus];
    
    [self videoQualityString];
    
    [self setUIElementsEnabled:MEGAReachabilityManager.isReachable];
    
    [self.tableView reloadData];
}

- (void)viewWillDisappear:(BOOL)animated {
    [super viewWillDisappear:animated];
    
    [[NSNotificationCenter defaultCenter] removeObserver:self name:kReachabilityChangedNotification object:nil];
    
    [[MEGASdkManager sharedMEGAChatSdk] removeChatDelegate:self];
}

#pragma mark - IBActions

- (IBAction)chatValueChanged:(UISwitch *)sender {
    MEGALogInfo(@"Chat: %@", (sender.isOn ? @"ON" : @"OFF"));
    if (sender.isOn) {
        if ([MEGASdkManager sharedMEGAChatSdk] == nil) {
            [MEGASdkManager createSharedMEGAChatSdk];
        }
        
        NSString *session = [[MEGASdkManager sharedMEGASdk] dumpSession];
        MEGAChatInit chatInit = [[MEGASdkManager sharedMEGAChatSdk] initKarereWithSid:session];
        switch (chatInit) {
            case MEGAChatInitNoCache: {
                [[MEGASdkManager sharedMEGAChatSdk] addChatDelegate:self];
                [[MEGASdkManager sharedMEGASdk] fetchNodes];
                [[NSUserDefaults standardUserDefaults] setBool:YES forKey:@"IsChatEnabled"];
                [[NSUserDefaults.alloc initWithSuiteName:MEGAGroupIdentifier] setBool:YES forKey:@"IsChatEnabled"];
                [MEGAReachabilityManager sharedManager].chatRoomListState = MEGAChatRoomListStateInProgress;
                [[NSUserDefaults standardUserDefaults] synchronize];
                break;
            }
                
            default: {
                MEGALogError(@"Init Karere with session failed");
                NSString *message = [NSString stringWithFormat:@"Error (%ld) initializing the chat", (long)chatInit];
                UIAlertController *alertController = [UIAlertController alertControllerWithTitle:AMLocalizedString(@"error", nil) message:message preferredStyle:UIAlertControllerStyleAlert];
                [alertController addAction:[UIAlertAction actionWithTitle:AMLocalizedString(@"ok", nil) style:UIAlertActionStyleCancel handler:nil]];
                [[MEGASdkManager sharedMEGAChatSdk] logoutWithDelegate:self];
                [self presentViewController:alertController animated:YES completion:nil];
                sender.on = NO;
                break;
            }
        }
    } else {
        self.invalidStatus = YES;
        [[MEGASdkManager sharedMEGAChatSdk] logoutWithDelegate:self];
        [[NSUserDefaults standardUserDefaults] setBool:NO forKey:@"IsChatEnabled"];
        [[NSUserDefaults.alloc initWithSuiteName:MEGAGroupIdentifier] setBool:NO forKey:@"IsChatEnabled"];
    }
}

- (IBAction)richPreviewsValueChanged:(UISwitch *)sender {
    [[MEGASdkManager sharedMEGASdk] enableRichPreviews:sender.isOn];
}

#pragma mark - Private

- (void)internetConnectionChanged {
    [self setUIElementsEnabled:MEGAReachabilityManager.isReachable];
}

- (void)setUIElementsEnabled:(BOOL)boolValue {
    self.chatLabel.enabled = self.chatSwitch.enabled = boolValue;
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

- (void)videoQualityString {
    NSNumber *videoQualityNumber = [[NSUserDefaults standardUserDefaults] objectForKey:@"ChatVideoQuality"];
    ChatVideoUploadQuality videoQuality;
    NSString *videoQualityString;
    if (videoQualityNumber) {
        videoQuality = videoQualityNumber.unsignedIntegerValue;
    } else {
        [[NSUserDefaults standardUserDefaults] setObject:@(ChatVideoUploadQualityMedium) forKey:@"ChatVideoQuality"];
        [[NSUserDefaults standardUserDefaults] synchronize];
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
    NSInteger numberOfSections = 1;
    if ([[NSUserDefaults standardUserDefaults] boolForKey:@"IsChatEnabled"]) {
        numberOfSections = 4;
    }
    
    return numberOfSections;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return 1;
}

- (NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section {
    NSString *titleForHeader;
    if (section == 4) {
        titleForHeader = AMLocalizedString(@"voiceAndVideoCalls", @"Section title of a button where you can enable mobile data for voice and video calls.");
    }
    
    return titleForHeader;
}

- (NSString *)tableView:(UITableView *)tableView titleForFooterInSection:(NSInteger)section {
    NSString *footerTitle;
    if (section == 2) {
        footerTitle = AMLocalizedString(@"richPreviewsFooter", @"Used in the \"rich previews\", when the user first tries to send an url - we ask them before we generate previews for that URL, since we need to send them unencrypted to our servers.");
    }
    if (section == 3) {
        footerTitle = AMLocalizedString(@"qualityOfVideosUploadedToAChat", @"Footer text to explain the meaning of the functionaly 'Video quality' for videos uploaded to a chat.");
    }
    return footerTitle;
}

#pragma mark - UITableViewDelegate

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {    
    if ([indexPath isEqual:[NSIndexPath indexPathForRow:0 inSection:1]] && !self.isInvalidStatus) {
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
