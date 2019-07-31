
#import "RequirePasscodeTimeDurationTableViewController.h"

#import "LTHPasscodeViewController.h"

#import "NSString+MNZCategory.h"
#import "UIColor+MNZCategory.h"

typedef NS_ENUM(NSUInteger, RequirePasscode) {
    RequirePasscodeImmediatelly,
    RequirePasscodeAfterFiveSeconds,
    RequirePasscodeAfterTenSeconds,
    RequirePasscodeAfterThirtySeconds,
    RequirePasscodeAfterOneMinute,
    RequirePasscodeAfterTwoMinutes,
    RequirePasscodeAfterFiveMinutes
};

@interface RequirePasscodeTimeDurationTableViewController ()

@property (strong, nonatomic) NSArray<NSString *> *rowTitles;

@end

@implementation RequirePasscodeTimeDurationTableViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    self.tableView = [UITableView.alloc initWithFrame:CGRectZero style:UITableViewStyleGrouped];
    [self.tableView registerClass:UITableViewCell.class forCellReuseIdentifier:@"tableViewCellId"];
    
    self.title = AMLocalizedString(@"Require passcode", @"Label indicating that the passcode (pin) view will be displayed if the application goes back to foreground after being x time in background. Examples: require passcode immediately, require passcode after 5 minutes");
    
    NSMutableArray <NSString *> *titles = NSMutableArray.new;
    [titles addObject:AMLocalizedString(@"Immediately", @"Label indicating that the enter passcode (pin) view will be displayed immediately if the application goes back to foreground after being in background.")];
    [titles addObject:[NSString mnz_stringFromCallDuration:FiveSeconds]];
    [titles addObject:[NSString mnz_stringFromCallDuration:TenSeconds]];
    [titles addObject:[NSString mnz_stringFromCallDuration:ThirtySeconds]];
    [titles addObject:[NSString mnz_stringFromCallDuration:OneMinute]];
    [titles addObject:[NSString mnz_stringFromCallDuration:TwoMinutes]];
    [titles addObject:[NSString mnz_stringFromCallDuration:FiveMinutes]];
    _rowTitles = [NSMutableArray arrayWithArray:titles];
}

#pragma mark - Table view data source

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return self.rowTitles.count;
}


- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"tableViewCellId" forIndexPath:indexPath];
    cell.textLabel.textColor = UIColor.mnz_black333333;
    cell.textLabel.font = [UIFont systemFontOfSize:17 weight:UIFontWeightRegular];
    NSTimeInterval timeDuration = LTHPasscodeViewController.timerDuration;
    
    cell.textLabel.text = [self.rowTitles objectAtIndex:indexPath.row];
    switch (indexPath.row) {
        case RequirePasscodeImmediatelly:
            cell.accessoryType = (timeDuration == Immediatelly) ? UITableViewCellAccessoryCheckmark : UITableViewCellAccessoryNone;
            break;
        case RequirePasscodeAfterFiveSeconds:
            cell.accessoryType = (timeDuration == FiveSeconds) ? UITableViewCellAccessoryCheckmark : UITableViewCellAccessoryNone;
            break;
        case RequirePasscodeAfterTenSeconds:
            cell.accessoryType = (timeDuration == TenSeconds) ? UITableViewCellAccessoryCheckmark : UITableViewCellAccessoryNone;
            break;
        case RequirePasscodeAfterThirtySeconds:
            cell.accessoryType = (timeDuration == ThirtySeconds) ? UITableViewCellAccessoryCheckmark : UITableViewCellAccessoryNone;
            break;
        case RequirePasscodeAfterOneMinute:
            cell.accessoryType = (timeDuration == OneMinute) ? UITableViewCellAccessoryCheckmark : UITableViewCellAccessoryNone;
            break;
        case RequirePasscodeAfterTwoMinutes:
            cell.accessoryType = (timeDuration == TwoMinutes) ? UITableViewCellAccessoryCheckmark : UITableViewCellAccessoryNone;
            break;
        case RequirePasscodeAfterFiveMinutes:
            cell.accessoryType = (timeDuration == FiveMinutes) ? UITableViewCellAccessoryCheckmark : UITableViewCellAccessoryNone;
            break;
            
        default:
            break;
    }
    
    if (cell.accessoryType == UITableViewCellAccessoryCheckmark) {
        cell.accessoryView = [UIImageView.alloc initWithImage:[UIImage imageNamed:@"red_checkmark"]];
    } else {
        cell.accessoryView = nil;
    }
    
    return cell;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    [tableView deselectRowAtIndexPath:indexPath animated:YES];
    switch (indexPath.row) {
        case RequirePasscodeImmediatelly:
            [LTHPasscodeViewController saveTimerDuration:Immediatelly];
            break;
        case RequirePasscodeAfterFiveSeconds:
            [LTHPasscodeViewController saveTimerDuration:FiveSeconds];
            break;
        case RequirePasscodeAfterTenSeconds:
            [LTHPasscodeViewController saveTimerDuration:TenSeconds];
            break;
        case RequirePasscodeAfterThirtySeconds:
            [LTHPasscodeViewController saveTimerDuration:ThirtySeconds];
            break;
        case RequirePasscodeAfterOneMinute:
            [LTHPasscodeViewController saveTimerDuration:OneMinute];
            break;
        case RequirePasscodeAfterTwoMinutes:
            [LTHPasscodeViewController saveTimerDuration:TwoMinutes];
            break;
        case RequirePasscodeAfterFiveMinutes:
            [LTHPasscodeViewController saveTimerDuration:FiveMinutes];
            break;
            
        default:
            break;
    }
    [tableView reloadData];
}

@end
