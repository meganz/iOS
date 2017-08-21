#import "ChatStatusTableViewController.h"

#import "NSDate+DateTools.h"
#import "SVProgressHUD.h"
#import "UIScrollView+EmptyDataSet.h"

#import "Helper.h"
#import "MEGAReachabilityManager.h"
#import "MEGASdkManager.h"

#import "SelectableTableViewCell.h"

@interface ChatStatusTableViewController () <UITextFieldDelegate, DZNEmptyDataSetSource, DZNEmptyDataSetDelegate, MEGAChatDelegate>

@property (nonatomic) MEGAChatPresenceConfig *presenceConfig;
@property (weak, nonatomic) NSIndexPath *currentStatusIndexPath;

@property (weak, nonatomic) IBOutlet UILabel *onlineLabel;
@property (weak, nonatomic) IBOutlet UIImageView *onlineRedCheckmarkImageView;
@property (weak, nonatomic) IBOutlet UILabel *awayLabel;
@property (weak, nonatomic) IBOutlet UIImageView *awayRedCheckmarkImageView;
@property (weak, nonatomic) IBOutlet UILabel *busyLabel;
@property (weak, nonatomic) IBOutlet UIImageView *busyRedCheckmarkImageView;
@property (weak, nonatomic) IBOutlet UILabel *offlineLabel;
@property (weak, nonatomic) IBOutlet UIImageView *offlineRedCheckmarkImageView;

@property (weak, nonatomic) IBOutlet UILabel *autoAwayLabel;
@property (weak, nonatomic) IBOutlet UISwitch *autoAwaySwitch;
@property (weak, nonatomic) IBOutlet UITextField *autoAwayTimeTextField;
@property (weak, nonatomic) IBOutlet UIButton *autoAwayTimeSaveButton;
@property (nonatomic) NSInteger autoAwayTimeoutInMinutes;

@property (weak, nonatomic) IBOutlet UILabel *statusPersistenceLabel;
@property (weak, nonatomic) IBOutlet UISwitch *statusPersistenceSwitch;

@end

@implementation ChatStatusTableViewController

#pragma mark - Lifecycle

- (void)viewDidLoad {
    [super viewDidLoad];
    
    self.tableView.emptyDataSetSource = self;
    self.tableView.emptyDataSetDelegate = self;
    
    self.navigationItem.title = AMLocalizedString(@"status", @"Title that refers to the status of the chat (Either Online or Offline)");
    
    [self.tableView registerNib:[UINib nibWithNibName:@"SelectableTableViewCell" bundle:nil] forCellReuseIdentifier:@"SelectableTableViewCellID"];
    
    self.onlineLabel.text = AMLocalizedString(@"online", nil);
    self.awayLabel.text = AMLocalizedString(@"away", nil);
    self.busyLabel.text = AMLocalizedString(@"busy", nil);
    self.offlineLabel.text = AMLocalizedString(@"offline", @"Title of the Offline section");
    
    self.autoAwayLabel.text = AMLocalizedString(@"autoAway", nil);
    
    self.statusPersistenceLabel.text = AMLocalizedString(@"statusPersistence", nil);
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(internetConnectionChanged) name:kReachabilityChangedNotification object:nil];
    
    [[MEGASdkManager sharedMEGAChatSdk] addChatDelegate:self];
    
    self.presenceConfig = [[MEGASdkManager sharedMEGAChatSdk] presenceConfig];
    [self updateUIWithPresenceConfig];
    
    self.autoAwayTimeoutInMinutes = (self.presenceConfig.autoAwayTimeout / 60);
}

- (void)viewWillDisappear:(BOOL)animated {
    [super viewWillDisappear:animated];
    
    [[NSNotificationCenter defaultCenter] removeObserver:self name:kReachabilityChangedNotification object:nil];
    
    [[MEGASdkManager sharedMEGAChatSdk] removeChatDelegate:self];
}

#pragma mark - Private

- (void)internetConnectionChanged {
    [self.tableView reloadData];
}

- (void)updateUIWithPresenceConfig {
    [self deselectRowWithPreviousStatus];
    
    [self updateCurrentIndexPathForOnlineStatus];
    
    self.autoAwaySwitch.on = self.presenceConfig.isAutoAwayEnabled;
    [self updateAutoAwayTimeLabel];
    
    self.statusPersistenceSwitch.on = self.presenceConfig.isPersist;
    
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
    }
    self.currentStatusIndexPath = presenceIndexPath;
    
    SelectableTableViewCell *cell = [self.tableView cellForRowAtIndexPath:self.currentStatusIndexPath];
    cell.redCheckmarkImageView.hidden = NO;
}

- (void)setPresenceAutoAway:(BOOL)boolValue {
    [SVProgressHUD setDefaultMaskType:SVProgressHUDMaskTypeClear];
    [SVProgressHUD show];
    
    [[MEGASdkManager sharedMEGAChatSdk] setPresenceAutoaway:boolValue timeout:(self.autoAwayTimeoutInMinutes * 60)];
}

- (void)updateAutoAwayTimeLabel {
    NSString *xMinutes;
    if ((self.presenceConfig.autoAwayTimeout / 60) < 2) {
        xMinutes = AMLocalizedString(@"1Minute", nil);
        self.autoAwayTimeTextField.text = xMinutes;
    } else {
        xMinutes = AMLocalizedString(@"xMinutes", nil);
        self.autoAwayTimeTextField.text = [xMinutes stringByReplacingOccurrencesOfString:@"[X]" withString:[NSString stringWithFormat:@"%lld", (self.presenceConfig.autoAwayTimeout / 60)]];
    }
    
    self.autoAwayTimeSaveButton.hidden = YES;
}

#pragma mark - IBActions

- (IBAction)autoAwayValueChanged:(UISwitch *)sender {
    [self setPresenceAutoAway:sender.on];
}

- (IBAction)autoAwayTimeSaveButtonTouchUpInside:(UIButton *)sender {
    [self.autoAwayTimeTextField resignFirstResponder];
    self.autoAwayTimeSaveButton.enabled = NO;
    self.autoAwayTimeSaveButton.hidden = YES;
    
    self.autoAwayTimeoutInMinutes = self.autoAwayTimeTextField.text.intValue;
    
    [self setPresenceAutoAway:self.autoAwaySwitch.isOn];
}

- (IBAction)statusPersistenceValueChanged:(UISwitch *)sender {
    [SVProgressHUD setDefaultMaskType:SVProgressHUDMaskTypeClear];
    [SVProgressHUD show];
    
    [[MEGASdkManager sharedMEGAChatSdk] setPresencePersist:sender.on];
}

#pragma mark - UITableViewDataSource

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    NSInteger numberOfSections = 0;
    if ([MEGAReachabilityManager isReachable]) {
        MEGAChatStatus onlineStatus = self.presenceConfig.onlineStatus;
        if (onlineStatus == MEGAChatStatusOnline) {
            if (self.presenceConfig.isPersist) {
                numberOfSections = 2; //If Status Persistence is active = No autoaway
            } else {
                numberOfSections = 3;
            }
        } else if (onlineStatus == MEGAChatStatusOffline) {
            numberOfSections = 1; //No autoaway nor persist
        } else {
            numberOfSections =  2; //No autoaway
        }
    }
    
    return numberOfSections;
}

- (NSString *)tableView:(UITableView *)tableView titleForFooterInSection:(NSInteger)section {
    NSString *titleForFooter;
    switch (section) {
        case 0:
            titleForFooter = nil;
            break;
            
        case 1:
            titleForFooter = AMLocalizedString(@"maintainMyChosenStatusAppearance", @"Footer text to explain the meaning of the functionaly 'Auto-away' of your chat status.");
            break;
            
        case 2:
            if (self.presenceConfig.autoAwayTimeout < 2) {
                titleForFooter = AMLocalizedString(@"showMeAwayAfterXMinutesOfInactivity", @"Footer text to explain the meaning of the functionaly Auto-away of your chat status.");
                titleForFooter = [titleForFooter stringByReplacingOccurrencesOfString:@"[X]" withString:[NSString stringWithFormat:@"%lld", (self.presenceConfig.autoAwayTimeout / 60)]];
            } else {
                titleForFooter = AMLocalizedString(@"showMeAwayAfter1MinuteOfInactivity", @"Footer text to explain the meaning of the functionaly Auto-away of your chat status.");
            }
            break;
    }
    
    return titleForFooter;
}

#pragma mark - UITableViewDelegate

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    [self.tableView deselectRowAtIndexPath:indexPath animated:YES];
    
    if (self.autoAwayTimeTextField.isEditing) {
        [self.autoAwayTimeTextField resignFirstResponder];
    }
    
    if (self.currentStatusIndexPath == indexPath) {
        return;
    }

    if (indexPath.section == 0) {
        [SVProgressHUD setDefaultMaskType:SVProgressHUDMaskTypeClear];
        [SVProgressHUD show];
        
        switch (indexPath.row) {
            case 0: //Online
                [[MEGASdkManager sharedMEGAChatSdk] setOnlineStatus:MEGAChatStatusOnline];
                break;
                
            case 1: //Away
                [[MEGASdkManager sharedMEGAChatSdk] setOnlineStatus:MEGAChatStatusAway];
                break
                ;
            case 2: //Busy
                [[MEGASdkManager sharedMEGAChatSdk] setOnlineStatus:MEGAChatStatusBusy];
                break;
                
            case 3: //Offline
                [[MEGASdkManager sharedMEGAChatSdk] setOnlineStatus:MEGAChatStatusOffline];
                break;
        }
    } else if (indexPath.section == 2 && indexPath.row == 1) { //Auto-away - Number of minutes for Auto-away
        [self.autoAwayTimeTextField becomeFirstResponder];
    }
}

#pragma mark - UITextFieldDelegate

- (BOOL)textFieldShouldBeginEditing:(UITextField *)textField {
    textField.text = [NSString stringWithFormat:@"%lld", (self.presenceConfig.autoAwayTimeout / 60)];
    
    self.autoAwayTimeSaveButton.enabled = NO;
    self.autoAwayTimeSaveButton.hidden = NO;
    
    return YES;
}

- (BOOL)textField:(UITextField *)textField shouldChangeCharactersInRange:(NSRange)range replacementString:(NSString *)string {
    
    NSString *textFieldString = [textField text];
    NSString *currentText = [textFieldString stringByReplacingCharactersInRange:range withString:string];
    
    if ([currentText isEqualToString:[NSString stringWithFormat:@"%lld", (self.presenceConfig.autoAwayTimeout / 60)]]) {
        self.autoAwayTimeSaveButton.enabled = NO;
        return NO;
    } else if ([currentText isEqualToString:@"0"] || [currentText isEqualToString:@""]) {
        self.autoAwayTimeSaveButton.enabled = NO;
    } else {
        self.autoAwayTimeSaveButton.enabled = YES;
    }
    
    return YES;
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
    
    [SVProgressHUD setDefaultMaskType:SVProgressHUDMaskTypeNone];
    [SVProgressHUD dismiss];
    
    self.presenceConfig = presenceConfig;
    
    [self updateUIWithPresenceConfig];
}

@end
