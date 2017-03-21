#import "ChatSettingsTableViewController.h"

#import "UIScrollView+EmptyDataSet.h"
#import "SVProgressHUD.h"

#import "Helper.h"
#import "MEGAReachabilityManager.h"
#import "MEGALogger.h"
#import "MEGASdkManager.h"
#import "NSString+MNZCategory.h"

#import "ChatStatusTableViewController.h"

@interface ChatSettingsTableViewController () <DZNEmptyDataSetSource, DZNEmptyDataSetDelegate, MEGARequestDelegate, MEGAChatDelegate, MEGAChatRequestDelegate>

@property (weak, nonatomic) IBOutlet UILabel *chatLabel;
@property (weak, nonatomic) IBOutlet UISwitch *chatSwitch;

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
        [self enableChatWithSession];
    } else {
        [[MEGASdkManager sharedMEGAChatSdk] logoutWithDelegate:self];
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
    if ([MEGAReachabilityManager isReachable]) {
        [self.tableView reloadSections:[NSIndexSet indexSetWithIndex:1] withRowAnimation:UITableViewRowAnimationNone];
    }
}

- (void)enableChatWithSession {
    if ([[NSUserDefaults standardUserDefaults] boolForKey:@"logging"]) {
        [[MEGALogger sharedLogger] useChatSDKLogger];
    }
    
    if ([MEGASdkManager sharedMEGAChatSdk] == nil) {
        [MEGASdkManager createSharedMEGAChatSdk];
    }
    
    NSString *session = [[MEGASdkManager sharedMEGASdk] dumpSession];
    MEGAChatInit chatInit = [[MEGASdkManager sharedMEGAChatSdk] initKarereWithSid:session];
    switch (chatInit) {
        case MEGAChatInitNoCache: {
            [SVProgressHUD setDefaultMaskType:SVProgressHUDMaskTypeClear];
            [SVProgressHUD show];
            [[MEGASdkManager sharedMEGASdk] fetchNodesWithDelegate:self];
            break;
        }
        
        default: {
            MEGALogError(@"Init Karere with session failed");
            UIAlertController *alertController = [UIAlertController alertControllerWithTitle:AMLocalizedString(@"error", nil) message:@"Error initializing the chat" preferredStyle:UIAlertControllerStyleAlert];
            [alertController addAction:[UIAlertAction actionWithTitle:AMLocalizedString(@"ok", nil) style:UIAlertActionStyleCancel handler:^(UIAlertAction *action) {
            }]];
            [[MEGASdkManager sharedMEGAChatSdk] logoutWithDelegate:self];
            [self presentViewController:alertController animated:YES completion:nil];
            break;
        }
    }
}

#pragma mark - UITableViewDataSource

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    NSInteger numberOfSections = 1;
    if ([[NSUserDefaults standardUserDefaults] boolForKey:@"IsChatEnabled"]) {
        //TODO: Enable "Use Mobile Data" section when possible
        numberOfSections = 2;
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
    if (section == 2) {
        titleForHeader = AMLocalizedString(@"voiceAndVideoCalls", @"Section title of a button where you can enable mobile data for voice and video calls.");
    }
    return titleForHeader;
}

#pragma mark - UITableViewDelegate

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    if ([indexPath isEqual:[NSIndexPath indexPathForRow:0 inSection:1]] && !self.isInvalidStatus) {
        ChatStatusTableViewController *chatStatusTVC = [[UIStoryboard storyboardWithName:@"Settings" bundle:nil] instantiateViewControllerWithIdentifier:@"ChatStatusTableViewControllerID"];
        [self.navigationController pushViewController:chatStatusTVC animated:YES];
    }
}

#pragma mark - DZNEmptyDataSetSource

- (NSAttributedString *)titleForEmptyDataSet:(UIScrollView *)scrollView {
    NSString *text;
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


#pragma mark - MEGARequestDelegate

- (void)onRequestFinish:(MEGASdk *)api request:(MEGARequest *)request error:(MEGAError *)error {
    if ([error type]) return;
    
    if ([request type] == MEGARequestTypeFetchNodes) {
        [[MEGASdkManager sharedMEGAChatSdk] connectWithDelegate:self];
    }
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
        case MEGAChatRequestTypeConnect: {
            [SVProgressHUD setDefaultMaskType:SVProgressHUDMaskTypeNone];
            [SVProgressHUD dismiss];
            
            if (error.type) return;
            
            [self.tableView reloadData];
            break;
        }
            
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
