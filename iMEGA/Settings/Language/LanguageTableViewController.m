
#import "LanguageTableViewController.h"

#import <UserNotifications/UserNotifications.h>

#import "Helper.h"
#import "MEGASDKManager.h"
#import "SelectableTableViewCell.h"

@interface LanguageTableViewController ()

@property (nonatomic) NSDictionary *languagesDictionary;
@property (nonatomic) NSUInteger languageIndex;

@end

@implementation LanguageTableViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    NSString *language = [[LocalizationSystem sharedLocalSystem] getLanguage];
    self.languageIndex = [[Helper languagesSupportedIDs] indexOfObject:language];
    
    self.languagesDictionary = @{@"ar":@"العربية",
                                 @"bg":@"български език",
                                 @"cs":@"Čeština",
                                 @"de":@"Deutsch",
                                 @"en":@"English",
                                 @"es":@"Español",
                                 @"fa":@"فارسی",
                                 @"fi":@"Suomi",
                                 @"fr":@"Français",
                                 @"he":@"עברית",
                                 @"hu":@"magyar",
                                 @"id":@"Bahasa Indonesia",
                                 @"it":@"Italiano",
                                 @"ja":@"日本語",
                                 @"ko":@"한국어",
                                 @"nl":@"Nederlands",
                                 @"pl":@"Język Polski",
                                 @"pt-br":@"Português Brasileiro",
                                 @"pt":@"Português",
                                 @"ro":@"Limba Română",
                                 @"ru":@"Pусский язык",
                                 @"sk":@"Slovenský",
                                 @"sl":@"Slovenščina",
                                 @"sr":@"српски језик",
                                 @"sv":@"Svenska",
                                 @"th":@"ไทย",
                                 @"tl":@"Tagalog",
                                 @"tr":@"Türkçe",
                                 @"uk":@"українська мова",
                                 @"vi":@"Tiếng Việt",
                                 @"zh-Hans":@"简体中文",
                                 @"zh-Hant":@"中文繁體"};
    
    [self.tableView registerNib:[UINib nibWithNibName:@"SelectableTableViewCell" bundle:nil] forCellReuseIdentifier:@"SelectableTableViewCellID"];

    self.navigationItem.title = AMLocalizedString(@"language", @"Title of one of the Settings sections where you can set up the 'Language' of the app");
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
}

#pragma mark - Table view data source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return 1;
}

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

#pragma mark - Table view delegate

-(void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    UIAlertController *alertController = [UIAlertController alertControllerWithTitle:@"Restart MEGA to apply new language?" message:@"" preferredStyle:UIAlertControllerStyleAlert];
    [alertController addAction:[UIAlertAction actionWithTitle:AMLocalizedString(@"ok", nil) style:UIAlertActionStyleDefault handler:^(UIAlertAction *action) {
        // Change the language:
        NSString *selectedLanguage = [Helper languageID:indexPath.row];
        [[LocalizationSystem sharedLocalSystem] setLanguage:selectedLanguage];
        [[MEGASdkManager sharedMEGASdk] setLanguageCode:selectedLanguage];

        // Schedule a notification to make it easy to reopen MEGA:
        if ([[UIDevice currentDevice] systemVersionGreaterThanOrEqualVersion:@"10.0"]) {
            UNUserNotificationCenter *center = [UNUserNotificationCenter currentNotificationCenter];
            UNAuthorizationOptions options = UNAuthorizationOptionAlert + UNAuthorizationOptionSound;
            [center requestAuthorizationWithOptions:options
                                  completionHandler:^(BOOL granted, NSError * _Nullable error) {
                                      if (granted) {
                                          UNMutableNotificationContent *content = [UNMutableNotificationContent new];
                                          content.title = @"Tap here to open MEGA";
                                          content.sound = [UNNotificationSound defaultSound];
                                          UNTimeIntervalNotificationTrigger *trigger = [UNTimeIntervalNotificationTrigger triggerWithTimeInterval:1
                                                                                                                                          repeats:NO];
                                          NSString *identifier = @"nz.mega";
                                          UNNotificationRequest *request = [UNNotificationRequest requestWithIdentifier:identifier
                                                                                                                content:content trigger:trigger];
                                          [center addNotificationRequest:request withCompletionHandler:^(NSError * _Nullable error) {
                                              exit(0);
                                          }];
                                      } else {
                                          exit(0);
                                      }
                                  }];
        } else {
            // TODO: Handle iOS 8 and 9
            exit(0);
        }
    }]];
    [alertController addAction:[UIAlertAction actionWithTitle:AMLocalizedString(@"cancel", nil) style:UIAlertActionStyleCancel handler:^(UIAlertAction *action) {
        [self.tableView deselectRowAtIndexPath:indexPath animated:YES];
    }]];
    [self presentViewController:alertController animated:YES completion:nil];
}

@end
