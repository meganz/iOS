#import "ChatSettingsTableViewController.h"

#import "MEGASdkManager.h"

#import "ChatStatusTableViewController.h"

@interface ChatSettingsTableViewController ()

@property (weak, nonatomic) IBOutlet UILabel *chatLabel;
@property (weak, nonatomic) IBOutlet UISwitch *chatSwitch;

@property (weak, nonatomic) IBOutlet UILabel *statusLabel;
@property (weak, nonatomic) IBOutlet UILabel *statusRightDetailLabel;

@property (weak, nonatomic) IBOutlet UILabel *useMobileDataLabel;
@property (weak, nonatomic) IBOutlet UISwitch *useMobileDataSwitch;

@end

@implementation ChatSettingsTableViewController

#pragma mark - Lifecycle

- (void)viewDidLoad {
    [super viewDidLoad];
    
    self.navigationItem.title = AMLocalizedString(@"chat", @"Chat section header");
    
    self.chatLabel.text = AMLocalizedString(@"chat", @"Chat section header");
    
    self.statusLabel.text = AMLocalizedString(@"status", @"Title that refers to the status of the chat (Either Online or Offline)");
    
    self.useMobileDataLabel.text = AMLocalizedString(@"useMobileData", @"Title next to a switch button (On-Off) to allow using mobile data (Roaming) for a feature.");
    
    BOOL isChatEnabled = [[NSUserDefaults standardUserDefaults] boolForKey:@"IsChatEnabled"];
    if (isChatEnabled) {
        [self.chatSwitch setOn:YES animated:YES];
        
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
    
    [self onlineStatus];
}

#pragma mark - IBActions

- (IBAction)chatValueChanged:(UISwitch *)sender {
    MEGALogInfo(@"Chat: %@", (sender.isOn ? @"ON" : @"OFF"));
    
    //TODO: Disable/enable chat
    
    [[NSUserDefaults standardUserDefaults] setBool:sender.isOn forKey:@"IsChatEnabled"];
    [[NSUserDefaults standardUserDefaults] synchronize];
    
    [self.tableView reloadData];
}

- (IBAction)useMobileDataValueChanged:(UISwitch *)sender {
    MEGALogInfo(@"Chat - Mobile Data: %@", (sender.isOn ? @"ON" : @"OFF"));
    
    [[NSUserDefaults standardUserDefaults] setBool:sender.isOn forKey:@"IsMobileDataEnabledForChat"];
    [[NSUserDefaults standardUserDefaults] synchronize];
}

#pragma mark - Private

- (void)onlineStatus {
    NSString *onlineStatus;
    switch ([[MEGASdkManager sharedMEGAChatSdk] onlineStatus]) {
        case MEGAChatStatusOffline:
            onlineStatus = AMLocalizedString(@"offline", @"Title of the Offline section");
            break;
            
        case MEGAChatStatusOnline:
            onlineStatus = AMLocalizedString(@"online", nil);
            break;
            
        default:
            break;
    }
    self.statusRightDetailLabel.text = onlineStatus;
}

#pragma mark - UITableViewDataSource

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    NSInteger numberOfSections = 1;
    if ([[NSUserDefaults standardUserDefaults] boolForKey:@"IsChatEnabled"]) {
        numberOfSections = 3;
    }
    
    return numberOfSections;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return 1;
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
    if ([indexPath isEqual:[NSIndexPath indexPathForRow:0 inSection:1]]) {
        ChatStatusTableViewController *chatStatusTVC = [[UIStoryboard storyboardWithName:@"Settings" bundle:nil] instantiateViewControllerWithIdentifier:@"ChatStatusTableViewControllerID"];
        [self.navigationController pushViewController:chatStatusTVC animated:YES];
    }
}

@end
