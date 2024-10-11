#import "RubbishBinTableViewController.h"

#import "NSString+MNZCategory.h"
#import "UIApplication+MNZCategory.h"
#import "UITextField+MNZCategory.h"

#import "Helper.h"
#import "MEGANavigationController.h"
#import "MEGAReachabilityManager.h"

#import "CustomModalAlertViewController.h"
#import "MEGASdk+MNZCategory.h"
#import "MEGA-Swift.h"

@import MEGAL10nObjc;
@import MEGAUIKit;
@import MEGASDKRepo;

@interface RubbishBinTableViewController () <MEGARequestDelegate>

@property (weak, nonatomic) IBOutlet UIActivityIndicatorView *clearRubbishBinAI;

@property (weak, nonatomic) IBOutlet UISwitch *rubbishBinCleaningSchedulerSwitch;

@property (weak, nonatomic) IBOutlet UIView *longerRetentionPeriodUpgradetoProView;
@property (weak, nonatomic) IBOutlet UILabel *longerRetentionPeriodUpgradetoProLabel;

@property NSInteger rubbishBinAutopurgePeriod;

@end

@implementation RubbishBinTableViewController

#pragma mark - Lifecycle

- (void)viewDidLoad {
    [super viewDidLoad];
    
    [self updateAppearance];
    
    if ([MEGASdk.shared mnz_isProAccount]) {
        self.tableView.tableFooterView = nil;
    } else {
        self.tableView.tableFooterView = self.longerRetentionPeriodUpgradetoProView;
        [self setupTableViewHeaderAndFooter];
        [self.longerRetentionPeriodUpgradetoProLabel addGestureRecognizer:[UITapGestureRecognizer.alloc initWithTarget:self action:@selector(showUpgradeToPro)]];
    }
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    
    self.navigationItem.title = LocalizedString(@"rubbishBinLabel", @"Title of one of the Settings sections where you can see your MEGA 'Rubbish Bin'");
    
    self.clearRubbishBinLabel.text = LocalizedString(@"emptyRubbishBin", @"Section title where you can 'Empty Rubbish Bin' of your MEGA account");
    [self updateClearRubbishBinDetailLabel];
    
    self.rubbishBinCleaningSchedulerLabel.text = [LocalizedString(@"Rubbish-Bin Cleaning Scheduler:", @"Title for the Rubbish-Bin Cleaning Scheduler feature") stringByReplacingOccurrencesOfString:@":" withString:@""];
    [self.rubbishBinCleaningSchedulerSwitch setOn:[MEGASdk.shared serverSideRubbishBinAutopurgeEnabled]];
    
    self.removeFilesOlderThanLabel.text = LocalizedString(@"Remove files older than", @"A rubbish bin scheduler setting which allows removing old files from the rubbish bin automatically. E.g. Remove files older than 15 days.");
    
    [MEGASdk.shared getRubbishBinAutopurgePeriodWithDelegate:self];
}

- (void)traitCollectionDidChange:(UITraitCollection *)previousTraitCollection {
    [super traitCollectionDidChange:previousTraitCollection];
    
    if ([self.traitCollection hasDifferentColorAppearanceComparedToTraitCollection:previousTraitCollection]) {
        [self updateAppearance];
    }
    
    if (self.traitCollection.preferredContentSizeCategory != previousTraitCollection.preferredContentSizeCategory) {
        [self setupTableViewHeaderAndFooter];
    }
}

- (void)setupTableViewHeaderAndFooter {
    if (![MEGASdk.shared mnz_isProAccount]) {
        [self setLongerRetentionPeriodUpgradetoProLabel];
        [self.tableView sizeFooterToFit];
    }
}

#pragma mark - Private

- (void)setLongerRetentionPeriodUpgradetoProLabel {
    NSString *longerRetentionUpgradeToProText = LocalizedString(@"settings.fileManagement.rubbishBin.longerRetentionUpgrade", @"This text is displayed in Settings, File Management in Rubbish Bien view. Upgrade to Pro will be bold and green. And if you tap it, the Upgrade Account view will appear.");
    
    NSString *semiboldAndGreenText = [longerRetentionUpgradeToProText mnz_stringBetweenString:@"[S]" andString:@"[/S]"];
    longerRetentionUpgradeToProText = longerRetentionUpgradeToProText.mnz_removeWebclientFormatters;
    NSRange semiboldAndGreenTextRange = [longerRetentionUpgradeToProText rangeOfString:semiboldAndGreenText];

    UIColor *secondaryGrayColor = [UIColor iconSecondaryColor];
    NSMutableAttributedString *longerRetentionUpgradeToProMAS = [NSMutableAttributedString.alloc initWithString:longerRetentionUpgradeToProText attributes:@{NSForegroundColorAttributeName : secondaryGrayColor}];
    
    UIColor *turquoiseColor = [UIColor supportSuccessColor];
    UIFont *semiboldFont = [UIFont mnz_preferredFontWithStyle:UIFontTextStyleFootnote weight:UIFontWeightSemibold];
    [longerRetentionUpgradeToProMAS setAttributes:@{NSFontAttributeName : semiboldFont, NSForegroundColorAttributeName : turquoiseColor} range:semiboldAndGreenTextRange];

    self.longerRetentionPeriodUpgradetoProLabel.font = [UIFont mnz_preferredFontWithStyle:UIFontTextStyleFootnote weight:UIFontWeightRegular];
    self.longerRetentionPeriodUpgradetoProLabel.textColor = secondaryGrayColor;
    self.longerRetentionPeriodUpgradetoProLabel.attributedText = longerRetentionUpgradeToProMAS;
}

- (void)scheduleRubbishBinClearingTextFieldDidChange:(UITextField *)textField {
    UIAlertController *scheduleRubbishBinClearingAlertController = (UIAlertController *)self.presentedViewController;
    if ([scheduleRubbishBinClearingAlertController isKindOfClass:UIAlertController.class]) {
        UIAlertAction *doneAction = scheduleRubbishBinClearingAlertController.actions.lastObject;
        doneAction.enabled = textField.text.mnz_isDecimalNumber;
    }
}

- (void)updateClearRubbishBinDetailLabel {
    [self.clearRubbishBinAI stopAnimating];
    self.clearRubbishBinDetailLabel.hidden = NO;
    NSNumber *rubbishBinSizeNumber = [MEGASdk.shared sizeForNode:[MEGASdk.shared rubbishNode]];
    NSString *stringFromByteCount = [NSString memoryStyleStringFromByteCount:rubbishBinSizeNumber.unsignedLongLongValue];
    self.clearRubbishBinDetailLabel.text = [NSString mnz_formatStringFromByteCountFormatter:stringFromByteCount];
}

#pragma mark - IBActions

- (IBAction)scheduleRubbishBinClearingSwitchTouchUpInside:(UIButton *)sender {
    if (self.rubbishBinCleaningSchedulerSwitch.isOn) {
        if ([MEGASdk.shared mnz_isProAccount]) {
            if ([MEGAReachabilityManager isReachableHUDIfNot]) {
                [MEGASdk.shared setRubbishBinAutopurgePeriodInDays:0 delegate:self];
            }
        } else {
            CustomModalAlertViewController *customModalAlertVC = [[CustomModalAlertViewController alloc] init];
            customModalAlertVC.image = [UIImage imageNamed:@"retention_illustration"];
            customModalAlertVC.viewTitle = [LocalizedString(@"Rubbish-Bin Cleaning Scheduler:", @"Title for the Rubbish-Bin Cleaning Scheduler feature") stringByReplacingOccurrencesOfString:@":" withString:@""];
            customModalAlertVC.detail = LocalizedString(@"To disable the Rubbish-Bin Cleaning Scheduler or set a longer retention period, you need to subscribe to a PRO plan.", @"Description shown when you try to disable the feature Rubbish-Bin Cleaning Scheduler and you are a free user");
            customModalAlertVC.firstButtonTitle = LocalizedString(@"seePlans", @"Button title to see the available pro plans in MEGA");
            customModalAlertVC.dismissButtonTitle = LocalizedString(@"notNow", @"Used in the \"rich previews\", when the user first tries to send an url - we ask them before we generate previews for that URL, since we need to send them unencrypted to our servers.");
            __weak typeof(CustomModalAlertViewController) *weakCustom = customModalAlertVC;
            customModalAlertVC.firstCompletion = ^{
                [weakCustom dismissViewControllerAnimated:YES completion:^{
                    [self showUpgradeToPro];
                }];
            };
            
            customModalAlertVC.dismissCompletion = ^{
                [weakCustom dismissViewControllerAnimated:YES completion:nil];
            };
            
            [UIApplication.mnz_presentingViewController presentViewController:customModalAlertVC animated:YES completion:nil];
        }
    } else {
        if ([MEGAReachabilityManager isReachableHUDIfNot]) {
            NSInteger days = [MEGASdk.shared mnz_isProAccount] ? 90 : 14;
            [MEGASdk.shared setRubbishBinAutopurgePeriodInDays:days delegate:self];
        }
    }
}

#pragma mark - UITableViewDataSource

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return [MEGASdk.shared serverSideRubbishBinAutopurgeEnabled] ? 2 : 1;
}

- (NSString *)tableView:(UITableView *)tableView titleForFooterInSection:(NSInteger)section {
    NSString *titleFooter;
    switch (section) {
        case 0:
            titleFooter = LocalizedString(@"emptyRubbishBinAlertTitle", @"Alert title shown when you tap 'Empty Rubbish Bin'");
            break;
            
        case 1:
            titleFooter = ([MEGASdk.shared mnz_isProAccount]) ? LocalizedString(@"The Rubbish Bin can be cleaned for you automatically. The minimum period is 7 days.", @"New server-side rubbish-bin cleaning scheduler description (for PRO users)") : LocalizedString(@"The Rubbish Bin is cleaned for you automatically. The minimum period is 7 days and your maximum period is 30 days.", @"New server-side rubbish-bin cleaning scheduler description (for Free users)");
            break;
    }
    
    return titleFooter;
}

#pragma mark - UITableViewDelegate

- (void)tableView:(UITableView *)tableView willDisplayCell:(UITableViewCell *)cell forRowAtIndexPath:(NSIndexPath *)indexPath {
    cell.backgroundColor = [UIColor pageBackgroundColor];
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    switch (indexPath.section) {
        case 0: { //Clear Rubbish Bin
            if ([MEGAReachabilityManager isReachableHUDIfNot]) {
                UIAlertController *emptyRubbishBinAlertController = [UIAlertController alertControllerWithTitle:LocalizedString(@"emptyRubbishBinAlertTitle", @"Alert title shown when you tap 'Empty Rubbish Bin'") message:nil preferredStyle:UIAlertControllerStyleAlert];
                [emptyRubbishBinAlertController addAction:[UIAlertAction actionWithTitle:LocalizedString(@"cancel", @"") style:UIAlertActionStyleCancel handler:nil]];
                [emptyRubbishBinAlertController addAction:[UIAlertAction actionWithTitle:LocalizedString(@"ok", @"") style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
                    self.clearRubbishBinDetailLabel.hidden = YES;
                    [self.clearRubbishBinAI startAnimating];
                    [MEGASdk.shared cleanRubbishBinWithDelegate:[RequestDelegate.alloc initWithCompletion:^(MEGARequest * _Nullable request, MEGAError * _Nullable error) {
                        if (!error) {
                            [MEGASdk.shared catchupWithDelegate:[RequestDelegate.alloc initWithCompletion:^(MEGARequest * _Nullable request, MEGAError * _Nullable error) {
                                if (!error) {
                                    [self updateClearRubbishBinDetailLabel];
                                }
                            }]];
                        }
                    }]];
                }]];
                [self presentViewController:emptyRubbishBinAlertController animated:YES completion:nil];
            }
            break;
        }
            
        case 1: { //Remove files older than
            if (indexPath.row == 1) {
                if ([MEGAReachabilityManager isReachableHUDIfNot]) {
                    UIAlertController *scheduleRubbishBinClearingAlertController = [UIAlertController alertControllerWithTitle:LocalizedString(@"Remove files older than", @"A rubbish bin scheduler setting which allows removing old files from the rubbish bin automatically. E.g. Remove files older than 15 days.") message:nil preferredStyle:UIAlertControllerStyleAlert];
                    [scheduleRubbishBinClearingAlertController addTextFieldWithConfigurationHandler:^(UITextField * _Nonnull textField) {
                        textField.keyboardType = UIKeyboardTypeNumberPad;
                        textField.placeholder = LocalizedString(@"settings.fileManagement.rubbishBin.cleanScheduler.placeholder.days", @"Rubbish bin items to be removed in days placeholder");
                        [textField addTarget:self action:@selector(scheduleRubbishBinClearingTextFieldDidChange:) forControlEvents:UIControlEventEditingChanged];
                        textField.shouldReturnCompletion = ^BOOL(UITextField *textField) {
                            return textField.text.mnz_isDecimalNumber;
                        };
                    }];
                    
                    [scheduleRubbishBinClearingAlertController addAction:[UIAlertAction actionWithTitle:LocalizedString(@"cancel", @"") style:UIAlertActionStyleCancel handler:nil]];
                    UIAlertAction *doneAction = [UIAlertAction actionWithTitle:LocalizedString(@"done", @"") style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
                        NSString *days = scheduleRubbishBinClearingAlertController.textFields.firstObject.text;
                        if ([MEGASdk.shared mnz_isProAccount]) {
                            if (days.integerValue > 365) {
                                days = @"365";
                            }
                        } else {
                            if (days.integerValue > 30) {
                                days = @"30";
                            }
                        }
                        
                        if (days.integerValue < 7) {
                            days = @"7";
                        }
                        
                        if (self.rubbishBinAutopurgePeriod != days.integerValue) {
                            [MEGASdk.shared setRubbishBinAutopurgePeriodInDays:days.integerValue delegate:self];
                        }
                    }];
                    doneAction.enabled = NO;
                    [scheduleRubbishBinClearingAlertController addAction:doneAction];
                    
                    [self presentViewController:scheduleRubbishBinClearingAlertController animated:YES completion:nil];
                }
            }
        }
            
        default:
            break;
    }
    
    [tableView deselectRowAtIndexPath:indexPath animated:YES];
}

#pragma mark - MEGARequestDelegate

- (void)onRequestFinish:(MEGASdk *)api request:(MEGARequest *)request error:(MEGAError *)error {
    if ((request.type == MEGARequestTypeGetAttrUser || request.type == MEGARequestTypeSetAttrUser) && (request.paramType == MEGAUserAttributeRubbishTime)) {
        if (error.type) {
            if (error.type == MEGAErrorTypeApiENoent) {
                self.rubbishBinAutopurgePeriod = [MEGASdk.shared mnz_isProAccount] ? 90 : 14;
                self.removeFilesOlderThanDetailLabel.text = [NSString stringWithFormat:@"%ld", (long)self.rubbishBinAutopurgePeriod];
            }
        } else {
            // Zero means that the rubbish-bin cleaning scheduler is disabled (only if the account is PRO). Any negative value means that the configured value is invalid.
            if (request.number < 0) {
                return;
            }
            
            self.rubbishBinAutopurgePeriod = request.number;
            if (self.rubbishBinAutopurgePeriod == 0) {
                self.rubbishBinCleaningSchedulerSwitch.on = NO;
            } else {
                self.rubbishBinCleaningSchedulerSwitch.on = YES;
            }
            self.removeFilesOlderThanDetailLabel.text = [NSString stringWithFormat:@"%ld", (long)self.rubbishBinAutopurgePeriod];
        }
        [self.tableView reloadData];
    }
}

@end
