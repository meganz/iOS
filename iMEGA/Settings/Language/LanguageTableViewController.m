
#import "LanguageTableViewController.h"

#import <UserNotifications/UserNotifications.h>

#import "DevicePermissionsHelper.h"
#import "Helper.h"
#import "MEGASDKManager.h"
#import "MEGA-Swift.h"
#import "SelectableTableViewCell.h"

@interface LanguageTableViewController ()

@property (nonatomic) NSDictionary *languagesDictionary;
@property (nonatomic) NSUInteger languageIndex;

@end

@implementation LanguageTableViewController

#pragma mark - Lifecycle

- (void)viewDidLoad {
    [super viewDidLoad];
    
    NSString *language = [[LocalizationSystem sharedLocalSystem] getLanguage];
    self.languageIndex = [[Helper languagesSupportedIDs] indexOfObject:language];
    
    self.languagesDictionary = @{@"ar":@"العربية",
                                 @"de":@"Deutsch",
                                 @"en":@"English",
                                 @"es":@"Español",
                                 @"fr":@"Français",
                                 @"id":@"Bahasa Indonesia",
                                 @"it":@"Italiano",
                                 @"ja":@"日本語",
                                 @"ko":@"한국어",
                                 @"nl":@"Nederlands",
                                 @"pl":@"Język Polski",
                                 @"pt-br":@"Português Brasileiro",
                                 @"ro":@"Română",
                                 @"ru":@"Pусский язык",
                                 @"th":@"ไทย",
                                 @"tl":@"Tagalog",
                                 @"uk":@"українська мова",
                                 @"vi":@"Tiếng Việt",
                                 @"zh-Hans":@"简体中文",
                                 @"zh-Hant":@"中文繁體"};
    
    [self.tableView registerNib:[UINib nibWithNibName:@"SelectableTableViewCell" bundle:nil] forCellReuseIdentifier:@"SelectableTableViewCellID"];

    self.navigationItem.title = AMLocalizedString(@"language", @"Title of one of the Settings sections where you can set up the 'Language' of the app");
    
    [self updateAppearance];
}

- (void)traitCollectionDidChange:(UITraitCollection *)previousTraitCollection {
    [super traitCollectionDidChange:previousTraitCollection];
    
    if (@available(iOS 13.0, *)) {
        if ([self.traitCollection hasDifferentColorAppearanceComparedToTraitCollection:previousTraitCollection]) {
            [self updateAppearance];
        }
    }
}

#pragma mark - Private

- (void)updateAppearance {
    self.tableView.separatorColor = [UIColor mnz_separatorForTraitCollection:self.traitCollection];
    self.tableView.backgroundColor = [UIColor mnz_backgroundGroupedForTraitCollection:self.traitCollection];
    
    [self.tableView reloadData];
}

#pragma mark - UITableViewDataSource

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return self.languagesDictionary.count;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    SelectableTableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"SelectableTableViewCellID" forIndexPath:indexPath];
    if (!cell) {
        cell = [[SelectableTableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:@"SelectableTableViewCellID"];
    }
    
    NSString *languageID = [Helper languageID:indexPath.row];
    cell.titleLabel.text = [self.languagesDictionary objectForKey:languageID];
    cell.redCheckmarkImageView.hidden = indexPath.row != self.languageIndex;
    
    return cell;
}

#pragma mark - UITableViewDelegate

- (void)tableView:(UITableView *)tableView willDisplayCell:(UITableViewCell *)cell forRowAtIndexPath:(NSIndexPath *)indexPath {
    cell.backgroundColor = [UIColor mnz_secondaryBackgroundGrouped:self.traitCollection];
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    if (indexPath.row == self.languageIndex) {
        [self.tableView deselectRowAtIndexPath:indexPath animated:YES];
        return;
    }
    
    UIAlertController *alertController = [UIAlertController alertControllerWithTitle:AMLocalizedString(@"languageRestartAlert", @"Text shown in an alert when the user is about to change the language of the app") message:@"" preferredStyle:UIAlertControllerStyleAlert];
    [alertController addAction:[UIAlertAction actionWithTitle:AMLocalizedString(@"ok", nil) style:UIAlertActionStyleDefault handler:^(UIAlertAction *action) {
        // Change the language:
        NSString *selectedLanguage = [Helper languageID:indexPath.row];
        [[LocalizationSystem sharedLocalSystem] setLanguage:selectedLanguage];
        [[MEGASdkManager sharedMEGASdk] setLanguageCode:selectedLanguage];
        [[NSUserDefaults.alloc initWithSuiteName:MEGAGroupIdentifier] setObject:selectedLanguage forKey:@"languageCode"];
        
        // Schedule a notification to make it easy to reopen MEGA:
        NSString *notificationText = AMLocalizedString(@"languageRestartNotification", @"Text shown in a notification to make it easy for the user to restart the app after the language is changed");
        if (DevicePermissionsHelper.shouldAskForNotificationsPermissions) {
            exit(0);
        } else {
            [DevicePermissionsHelper notificationsPermissionWithCompletionHandler:^(BOOL granted) {
                if (granted) {
                    UNMutableNotificationContent *content = [UNMutableNotificationContent new];
                    content.body = notificationText;
                    content.sound = UNNotificationSound.defaultSound;
                    UNTimeIntervalNotificationTrigger *trigger = [UNTimeIntervalNotificationTrigger triggerWithTimeInterval:1
                                                                                                                    repeats:NO];
                    NSString *identifier = @"nz.mega";
                    UNNotificationRequest *request = [UNNotificationRequest requestWithIdentifier:identifier
                                                                                          content:content trigger:trigger];
                    [UNUserNotificationCenter.currentNotificationCenter addNotificationRequest:request withCompletionHandler:^(NSError * _Nullable error) {
                        exit(0);
                    }];
                } else {
                    exit(0);
                }
            }];
        }
    }]];
    
    [alertController addAction:[UIAlertAction actionWithTitle:AMLocalizedString(@"cancel", nil) style:UIAlertActionStyleCancel handler:^(UIAlertAction *action) {
        [self.tableView deselectRowAtIndexPath:indexPath animated:YES];
    }]];
    
    [self presentViewController:alertController animated:YES completion:nil];
}

@end
