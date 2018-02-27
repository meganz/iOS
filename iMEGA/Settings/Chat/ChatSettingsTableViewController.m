#import "ChatSettingsTableViewController.h"

#import "UIScrollView+EmptyDataSet.h"
#import "SVProgressHUD.h"

#import "Helper.h"
#import "MEGAReachabilityManager.h"
#import "MEGALogger.h"
#import "MEGASdkManager.h"
#import "NSString+MNZCategory.h"

#import "ChatStatusTableViewController.h"
#import "ChatVideoQualityTableViewController.h"
#import "ChatVideoUploadQuality.h"

@interface ChatSettingsTableViewController () <DZNEmptyDataSetSource, DZNEmptyDataSetDelegate, MEGARequestDelegate, MEGAChatDelegate, MEGAChatRequestDelegate>

@property (weak, nonatomic) IBOutlet UILabel *chatLabel;
@property (weak, nonatomic) IBOutlet UISwitch *chatSwitch;

@property (weak, nonatomic) IBOutlet UILabel *videoQualityLabel;
@property (weak, nonatomic) IBOutlet UILabel *videoQualityRightDetailLabel;

@property (weak, nonatomic) IBOutlet UILabel *statusLabel;
@property (weak, nonatomic) IBOutlet UILabel *statusRightDetailLabel;
@property (nonatomic, getter=isInvalidStatus) BOOL invalidStatus;

@property (weak, nonatomic) IBOutlet UILabel *useMobileDataLabel;
@property (weak, nonatomic) IBOutlet UISwitch *useMobileDataSwitch;

@end

@implementation ChatSettingsTableViewController

#pragma mark - Lifecycle

- (void)viewDidLoad {
    [super viewDidLoad];
    
    self.tableView.emptyDataSetSource = self;
    self.tableView.emptyDataSetDelegate = self;
    
    self.navigationItem.title = AMLocalizedString(@"chat", @"Chat section header");
    
    self.chatLabel.text = AMLocalizedString(@"chat", @"Chat section header");
    
    self.statusLabel.text = AMLocalizedString(@"status", @"Title that refers to the status of the chat (Either Online or Offline)");
    
    self.useMobileDataLabel.text = AMLocalizedString(@"useMobileData", @"Title next to a switch button (On-Off) to allow using mobile data (Roaming) for a feature.");
    
    self.videoQualityLabel.text = AMLocalizedString(@"videoQuality", @"Title that refers to the status of the chat (Either Online or Offline)");
        
    BOOL isChatEnabled = ([[NSUserDefaults standardUserDefaults] boolForKey:@"IsChatEnabled"]) ? YES : NO;
    [self.chatSwitch setOn:isChatEnabled animated:YES];
    if (isChatEnabled) {
        BOOL isMobileDataEnabledForChat = [[NSUserDefaults standardUserDefaults] boolForKey:@"IsMobileDataEnabledForChat"];
        [self.useMobileDataSwitch setOn:isMobileDataEnabledForChat animated:YES];
    } else {
        [[NSUserDefaults standardUserDefaults] setBool:NO forKey:@"IsMobileDataEnabledForChat"];
        [[NSUserDefaults standardUserDefaults] synchronize];
        [self.useMobileDataSwitch setOn:NO animated:YES];
    }
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(internetConnectionChanged) name:kReachabilityChangedNotification object:nil];
    
    [[MEGASdkManager sharedMEGAChatSdk] addChatDelegate:self];
    
    [self onlineStatus];
    
    [self videoQualityString];
    
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
        [[MEGALogger sharedLogger] enableChatlogs];
        
        if ([MEGASdkManager sharedMEGAChatSdk] == nil) {
            [MEGASdkManager createSharedMEGAChatSdk];
        }
        
        NSString *session = [[MEGASdkManager sharedMEGASdk] dumpSession];
        MEGAChatInit chatInit = [[MEGASdkManager sharedMEGAChatSdk] initKarereWithSid:session];
        switch (chatInit) {
            case MEGAChatInitNoCache: {
                [[MEGASdkManager sharedMEGASdk] fetchNodes];
                [[NSUserDefaults standardUserDefaults] setBool:YES forKey:@"IsChatEnabled"];
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
        [[MEGALogger sharedLogger] enableSDKlogs];
    }
}

- (IBAction)useMobileDataValueChanged:(UISwitch *)sender {
    MEGALogInfo(@"Chat - Mobile Data: %@", (sender.isOn ? @"ON" : @"OFF"));
    
    [[NSUserDefaults standardUserDefaults] setBool:sender.isOn forKey:@"IsMobileDataEnabledForChat"];
    [[NSUserDefaults standardUserDefaults] synchronize];
}

#pragma mark - Private

- (void)internetConnectionChanged {
    [self.tableView reloadData];
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
        //TODO: Enable "Use Mobile Data" section when possible
        numberOfSections = 3;
    }
    
    return numberOfSections;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    NSInteger numberOfRows = 0;
    if ([MEGAReachabilityManager isReachable]) {
        numberOfRows = 1;
    }
    
    return numberOfRows;
}

- (NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section {
    NSString *titleForHeader;
    if (section == 3) {
        titleForHeader = AMLocalizedString(@"voiceAndVideoCalls", @"Section title of a button where you can enable mobile data for voice and video calls.");
    }
    return titleForHeader;
}

- (NSString *)tableView:(UITableView *)tableView titleForFooterInSection:(NSInteger)section {
    NSString *titleForFooter;
    if (section == 1) {
        titleForFooter = AMLocalizedString(@"qualityOfVideosUploadedToAChat", @"Footer text to explain the meaning of the functionaly 'Video quality' for videos uploaded to a chat.");
    }
    return titleForFooter;
}

#pragma mark - UITableViewDelegate

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    if ([indexPath isEqual:[NSIndexPath indexPathForRow:0 inSection:1]]) {
        ChatVideoQualityTableViewController *chatVideoQualityVC = [[UIStoryboard storyboardWithName:@"Settings" bundle:nil] instantiateViewControllerWithIdentifier:@"ChatVideoQualityTableViewControllerID"];
        [self.navigationController pushViewController:chatVideoQualityVC animated:YES];
    }
    
    if ([indexPath isEqual:[NSIndexPath indexPathForRow:0 inSection:2]] && !self.isInvalidStatus) {
        ChatStatusTableViewController *chatStatusTVC = [[UIStoryboard storyboardWithName:@"Settings" bundle:nil] instantiateViewControllerWithIdentifier:@"ChatStatusTableViewControllerID"];
        [self.navigationController pushViewController:chatStatusTVC animated:YES];
    }
}

#pragma mark - DZNEmptyDataSetSource

- (NSAttributedString *)titleForEmptyDataSet:(UIScrollView *)scrollView {
    NSString *text = @"";
    if (![MEGAReachabilityManager isReachable]) {
        text = AMLocalizedString(@"noInternetConnection",  @"Text shown on the app when you don't have connection to the internet or when you have lost it");
    }
    
    NSDictionary *attributes = @{NSFontAttributeName:[UIFont mnz_SFUIRegularWithSize:18.0f], NSForegroundColorAttributeName:[UIColor mnz_gray999999]};
    
    return [[NSAttributedString alloc] initWithString:text attributes:attributes];
}

- (UIImage *)imageForEmptyDataSet:(UIScrollView *)scrollView {
    if (![MEGAReachabilityManager isReachable]) {
        return [UIImage imageNamed:@"noInternetConnection"];
    }
    
    return nil;
}

- (CGFloat)verticalOffsetForEmptyDataSet:(UIScrollView *)scrollView {
    return [Helper verticalOffsetForEmptyStateWithNavigationBarSize:self.navigationController.navigationBar.frame.size searchBarActive:NO];
}

- (CGFloat)spaceHeightForEmptyDataSet:(UIScrollView *)scrollView {
    return [Helper spaceHeightForEmptyState];
}

#pragma mark - MEGAChatDelegate

- (void)onChatPresenceConfigUpdate:(MEGAChatSdk *)api presenceConfig:(MEGAChatPresenceConfig *)presenceConfig {
    if (presenceConfig.isPending) {
        return;
    }
    
    [self onlineStatus];
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
