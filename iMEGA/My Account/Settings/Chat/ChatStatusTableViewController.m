#import "ChatStatusTableViewController.h"

#import "SVProgressHUD.h"
#import "UIScrollView+EmptyDataSet.h"

#import "EmptyStateView.h"
#import "MEGAReachabilityManager.h"
#import "MEGA-Swift.h"

@import MEGAL10nObjc;

@interface ChatStatusTableViewController () <UITextFieldDelegate, DZNEmptyDataSetSource, DZNEmptyDataSetDelegate, MEGAChatDelegate>

@property (weak, nonatomic) IBOutlet UILabel *onlineLabel;
@property (weak, nonatomic) IBOutlet UILabel *awayLabel;
@property (weak, nonatomic) IBOutlet UILabel *busyLabel;
@property (weak, nonatomic) IBOutlet UILabel *offlineLabel;

@property (weak, nonatomic) IBOutlet UILabel *autoAwayLabel;
@property (weak, nonatomic) IBOutlet UISwitch *autoAwaySwitch;

@property (weak, nonatomic) IBOutlet UILabel *statusPersistenceLabel;
@property (weak, nonatomic) IBOutlet UISwitch *statusPersistenceSwitch;

@property (weak, nonatomic) IBOutlet UILabel *lastActiveLabel;
@property (weak, nonatomic) IBOutlet UISwitch *lastActiveSwitch;

@end

@implementation ChatStatusTableViewController

#pragma mark - Lifecycle

- (void)viewDidLoad {
    [super viewDidLoad];
    
    self.tableView.emptyDataSetSource = self;
    self.tableView.emptyDataSetDelegate = self;
    
    self.navigationItem.title = LocalizedString(@"status", @"Title that refers to the status of the chat (Either Online or Offline)");
    
    [self.tableView registerNib:[UINib nibWithNibName:@"SelectableTableViewCell" bundle:nil] forCellReuseIdentifier:@"SelectableTableViewCellID"];
    
    self.onlineLabel.text = LocalizedString(@"online", @"");
    self.awayLabel.text = LocalizedString(@"away", @"");
    self.busyLabel.text = LocalizedString(@"busy", @"");
    self.offlineLabel.text = LocalizedString(@"offline", @"Title of the Offline section");
    self.lastActiveLabel.text = LocalizedString(@"settings.calls.status.showLastSeen.title", @"");

    self.autoAwayLabel.text = LocalizedString(@"autoAway", @"");
    
    self.statusPersistenceLabel.text = LocalizedString(@"statusPersistence", @"");
    [self.autoAwayTimeSaveButton setTitle:LocalizedString(@"save", @"Button title to 'Save' the selected option") forState:UIControlStateNormal];
    
    [self setupColors];
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(internetConnectionChanged) name:kReachabilityChangedNotification object:nil];
    
    [MEGAChatSdk.shared addChatDelegate:self];
    
    self.presenceConfig = [MEGAChatSdk.shared presenceConfig];
    [self updateUIWithPresenceConfig];
    
    self.autoAwayTimeoutInMinutes = (NSInteger)(self.presenceConfig.autoAwayTimeout / 60);
}

- (void)viewWillDisappear:(BOOL)animated {
    [super viewWillDisappear:animated];
    
    [[NSNotificationCenter defaultCenter] removeObserver:self name:kReachabilityChangedNotification object:nil];
    
    [MEGAChatSdk.shared removeChatDelegate:self];
}

#pragma mark - Private

- (void)setupColors {
    self.tableView.backgroundColor = [self defaultBackgroundColor];
    
    self.onlineLabel.textColor = [self primaryTextColor];
    self.awayLabel.textColor = [self primaryTextColor];
    self.busyLabel.textColor = [self primaryTextColor];
    self.offlineLabel.textColor = [self primaryTextColor];
    self.autoAwayLabel.textColor = [self primaryTextColor];
    self.statusPersistenceLabel.textColor = [self primaryTextColor];
    self.lastActiveLabel.textColor = [self primaryTextColor];
    
    self.timeoutAutoAwayLabel.textColor = [self secondayTextColor];
    [self.autoAwayTimeSaveButton setTitleColor:[self secondayTextColor] forState:UIControlStateNormal];
    [self.autoAwayTimeSaveButton setTitleColor:[self disabledTextColor] forState:UIControlStateDisabled];
    
    self.autoAwaySwitch.tintColor = [self switchTintColor];
    self.statusPersistenceSwitch.tintColor = [self switchTintColor];
    self.lastActiveSwitch.tintColor = [self switchTintColor];
    
    self.tableView.separatorColor = [UIColor borderStrong];
}

- (void)internetConnectionChanged {
    [self.tableView reloadData];
}

- (void)updateUIWithPresenceConfig {
    [self deselectRowWithPreviousStatus];
    
    [self updateCurrentIndexPathForOnlineStatus];
    
    self.autoAwaySwitch.on = self.presenceConfig.isAutoAwayEnabled;
    self.timeoutAutoAwayCell.hidden = !self.presenceConfig.isAutoAwayEnabled && self.isSelectingTimeout;
    [self updateAutoAwayTimeTitle];
    self.statusPersistenceSwitch.on = self.presenceConfig.isPersist;
    
    self.lastActiveSwitch.on = self.presenceConfig.isLastGreenVisible;
    
    [self.tableView reloadData];
}

- (void)deselectRowWithPreviousStatus {
    if (self.currentStatusIndexPath) {
        SelectableTableViewCell *cell = [self.tableView cellForRowAtIndexPath:self.currentStatusIndexPath];
        cell.redCheckmarkImageView.hidden = YES;
    }
}

- (void)updateCurrentIndexPathForOnlineStatus {
    NSIndexPath *presenceIndexPath;
    switch (self.presenceConfig.onlineStatus) {
        case MEGAChatStatusOffline:
            presenceIndexPath = [NSIndexPath indexPathForRow:3 inSection:0];
            break;
            
        case MEGAChatStatusAway:
            presenceIndexPath = [NSIndexPath indexPathForRow:1 inSection:0];
            break;
            
        case MEGAChatStatusOnline:
            presenceIndexPath = [NSIndexPath indexPathForRow:0 inSection:0];
            break;
            
        case MEGAChatStatusBusy:
            presenceIndexPath = [NSIndexPath indexPathForRow:2 inSection:0];
            break;
            
        case MEGAChatStatusInvalid:
            break;
    }
    self.currentStatusIndexPath = presenceIndexPath;
    
    SelectableTableViewCell *cell = [self.tableView cellForRowAtIndexPath:self.currentStatusIndexPath];
    cell.redCheckmarkImageView.hidden = NO;
}

- (void)setPresenceAutoAway:(BOOL)boolValue {
    self.isSelectingTimeout = NO;
    [SVProgressHUD setDefaultMaskType:SVProgressHUDMaskTypeClear];
    [SVProgressHUD show];
    
    [MEGAChatSdk.shared setPresenceAutoaway:boolValue timeout:(self.autoAwayTimeoutInMinutes * 60)];
}

#pragma mark - IBActions

- (IBAction)autoAwayValueChanged:(UISwitch *)sender {
    [self setPresenceAutoAway:sender.on];
}

- (IBAction)autoAwayTimeSaveButtonTouchUpInside:(UIButton *)sender {
    [self saveAutoAwayTime];
}

- (IBAction)statusPersistenceValueChanged:(UISwitch *)sender {
    [SVProgressHUD setDefaultMaskType:SVProgressHUDMaskTypeClear];
    [SVProgressHUD show];
    
    [MEGAChatSdk.shared setPresencePersist:sender.on];
}

- (IBAction)lastGreenValueChanged:(UISwitch *)sender {
    [SVProgressHUD setDefaultMaskType:SVProgressHUDMaskTypeClear];
    [SVProgressHUD show];
    
    [MEGAChatSdk.shared setLastGreenVisible:sender.on];
}

#pragma mark - UITableViewDataSource

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    NSInteger numberOfSections = 0;
    if ([MEGAReachabilityManager isReachable]) {
        MEGAChatStatus onlineStatus = self.presenceConfig.onlineStatus;
        if (onlineStatus == MEGAChatStatusOnline) {
            if (self.presenceConfig.isPersist) {
                numberOfSections = 3; //If Status Persistence is active = No autoaway
            } else {
                numberOfSections = 4;
            }
        } else if (onlineStatus == MEGAChatStatusOffline) {
            numberOfSections = 2; //No autoaway nor persist
        } else {
            numberOfSections = 3; //No autoaway
        }
    }
    
    return numberOfSections;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    switch (section) {
        case 0:
            return 4;
            break;
            
        case 1:
        case 2:
            return 1;
            break;
            
        case 3:
            if (self.presenceConfig.isAutoAwayEnabled) {
                if (self.isSelectingTimeout) {
                    return 4;
                } else {
                    return 2;
                }
            } else {
                return 1;
            }
            break;
            
        case 4:
            return 2;
            break;
            
        default:
            return 1;
            break;
    }
}

- (NSString *)tableView:(UITableView *)tableView titleForFooterInSection:(NSInteger)section {
    NSString *titleForFooter;
    switch (section) {
        case 0:
            titleForFooter = nil;
            break;
            
        case 1:
            titleForFooter = LocalizedString(@"Allow your contacts to see the last time you were active on MEGA.", @"Footer text to explain the meaning of the functionaly 'Last seen' of your chat status.");
            break;
            
        case 2:
            titleForFooter = LocalizedString(@"maintainMyChosenStatusAppearance", @"Footer text to explain the meaning of the functionaly 'Auto-away' of your chat status.");
            break;
            
        case 3:
            if (self.presenceConfig.isAutoAwayEnabled && !self.isSelectingTimeout) {
                titleForFooter = LocalizedString(@"autoAway.footerDescription", @"Footer text to explain the meaning of the functionaly Auto-away of your chat status.");
                titleForFooter = [titleForFooter stringByReplacingOccurrencesOfString:@"[X]" withString:[self formatHoursAndMinutes]];
            }
            break;
    }
    
    return titleForFooter;
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {
    if (indexPath.section == 3 && self.isSelectingTimeout && indexPath.item == 1) {
        return 0;
    }
    
    return UITableViewAutomaticDimension;
}

#pragma mark - UITableViewDelegate

- (void)tableView:(UITableView *)tableView willDisplayCell:(UITableViewCell *)cell forRowAtIndexPath:(NSIndexPath *)indexPath {
    cell.backgroundColor = [UIColor pageBackgroundColor];
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    [self.tableView deselectRowAtIndexPath:indexPath animated:YES];
    
    if (self.currentStatusIndexPath == indexPath) {
        return;
    }

    if (indexPath.section == 0) {
        [SVProgressHUD setDefaultMaskType:SVProgressHUDMaskTypeClear];
        [SVProgressHUD show];
        
        switch (indexPath.row) {
            case 0: //Online
                [MEGAChatSdk.shared setOnlineStatus:MEGAChatStatusOnline];
                break;
                
            case 1: //Away
                [MEGAChatSdk.shared setOnlineStatus:MEGAChatStatusAway];
                break
                ;
            case 2: //Busy
                [MEGAChatSdk.shared setOnlineStatus:MEGAChatStatusBusy];
                break;
                
            case 3: //Offline
                [MEGAChatSdk.shared setOnlineStatus:MEGAChatStatusOffline];
                break;
        }
    } else if (indexPath.section == 3 && indexPath.row == 1 && !self.isSelectingTimeout) { //Auto-away - Number of
        self.isSelectingTimeout = YES;
        [self configurePickerValues];
        [tableView reloadData];
    }
}

- (CGFloat)tableView:(UITableView *)tableView heightForFooterInSection:(NSInteger)section {
    if (section == 3 && self.isSelectingTimeout) {
        return 0;
    } else {
        return UITableViewAutomaticDimension;
    }
}

#pragma mark - DZNEmptyDataSetSource

- (nullable UIView *)customViewForEmptyDataSet:(UIScrollView *)scrollView {
    EmptyStateView *emptyStateView = [EmptyStateView.alloc initWithImage:[self imageForEmptyState] title:[self titleForEmptyState] description:[self descriptionForEmptyState] buttonTitle:[self buttonTitleForEmptyState]];
    [emptyStateView.button addTarget:self action:@selector(buttonTouchUpInsideEmptyState) forControlEvents:UIControlEventTouchUpInside];
    
    return emptyStateView;
}

#pragma mark - Empty State

- (NSString *)titleForEmptyState {
    NSString *text = @"";
    if (![MEGAReachabilityManager isReachable]) {
        text = LocalizedString(@"noInternetConnection",  @"Text shown on the app when you don't have connection to the internet or when you have lost it");
    }
    
    return text;
}

- (NSString *)descriptionForEmptyState {
    NSString *text = @"";
    if (!MEGAReachabilityManager.isReachable && !MEGAReachabilityManager.sharedManager.isMobileDataEnabled) {
        text = LocalizedString(@"Mobile Data is turned off", @"Information shown when the user has disabled the 'Mobile Data' setting for MEGA in the iOS Settings.");
    }
    
    return text;
}

- (UIImage *)imageForEmptyState {
    if (![MEGAReachabilityManager isReachable]) {
        return [UIImage megaImageWithNamed:@"noInternetEmptyState"];
    }
    
    return nil;
}

- (NSString *)buttonTitleForEmptyState {
    NSString *text = @"";
    if (!MEGAReachabilityManager.isReachable && !MEGAReachabilityManager.sharedManager.isMobileDataEnabled) {
        text = LocalizedString(@"Turn Mobile Data on", @"Button title to go to the iOS Settings to enable 'Mobile Data' for the MEGA app.");
    }
    
    return text;
}

- (void)buttonTouchUpInsideEmptyState {
    if (!MEGAReachabilityManager.isReachable && !MEGAReachabilityManager.sharedManager.isMobileDataEnabled) {
        [UIApplication.sharedApplication openURL:[NSURL URLWithString:UIApplicationOpenSettingsURLString] options:@{} completionHandler:nil];
    }
}

#pragma mark - MEGAChatDelegate

- (void)onChatPresenceConfigUpdate:(MEGAChatSdk *)api presenceConfig:(MEGAChatPresenceConfig *)presenceConfig {
    if (presenceConfig.isPending) {
        return;
    }
    
    [SVProgressHUD setDefaultMaskType:SVProgressHUDMaskTypeNone];
    [SVProgressHUD dismiss];
    
    self.presenceConfig = presenceConfig;
    
    [self updateUIWithPresenceConfig];
}

@end
