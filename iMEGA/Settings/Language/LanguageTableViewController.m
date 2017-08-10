
#import "LanguageTableViewController.h"

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
        NSString *selectedLanguage = [Helper languageID:indexPath.row];
        [[LocalizationSystem sharedLocalSystem] setLanguage:selectedLanguage];
        [[MEGASdkManager sharedMEGASdk] setLanguageCode:selectedLanguage];
        exit(0);
    }]];
    [alertController addAction:[UIAlertAction actionWithTitle:AMLocalizedString(@"cancel", nil) style:UIAlertActionStyleCancel handler:^(UIAlertAction *action) {
        [self.tableView deselectRowAtIndexPath:indexPath animated:YES];
    }]];
    [self presentViewController:alertController animated:YES completion:nil];
}

@end
