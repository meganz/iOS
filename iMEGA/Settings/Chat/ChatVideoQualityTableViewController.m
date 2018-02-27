
#import "ChatVideoQualityTableViewController.h"
#import "SelectableTableViewCell.h"
#import "ChatVideoUploadQuality.h"

@interface ChatVideoQualityTableViewController ()

@property (weak, nonatomic) IBOutlet UILabel *lowLabel;
@property (weak, nonatomic) IBOutlet UIImageView *lowRedCheckmark;

@property (weak, nonatomic) IBOutlet UILabel *mediumLabel;
@property (weak, nonatomic) IBOutlet UIImageView *mediumRedCheckmark;

@property (weak, nonatomic) IBOutlet UILabel *originalLabel;
@property (weak, nonatomic) IBOutlet UIImageView *originalRedCheckmark;

@property (weak, nonatomic) NSIndexPath *currentChatVideoQualityIndexPath;

@end

@implementation ChatVideoQualityTableViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    self.navigationItem.title = AMLocalizedString(@"videoQuality", @"Title that refers to the quality of the chat (Either Online or Offline)");
    
    _lowLabel.text = AMLocalizedString(@"low", @"Low");
    _mediumLabel.text = AMLocalizedString(@"medium", nil);
    _originalLabel.text = AMLocalizedString(@"original", @"Original");
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    
    NSNumber *videoQualityNumber = [[NSUserDefaults standardUserDefaults] objectForKey:@"ChatVideoQuality"];
    ChatVideoUploadQuality videoQuality;
    if (videoQualityNumber) {
        videoQuality = videoQualityNumber.unsignedIntegerValue;
    } else {
        [[NSUserDefaults standardUserDefaults] setObject:@(ChatVideoUploadQualityMedium) forKey:@"ChatVideoQuality"];
        [[NSUserDefaults standardUserDefaults] synchronize];
        videoQuality = ChatVideoUploadQualityMedium;
    }
    
    switch (videoQuality) {
        case ChatVideoUploadQualityLow:
            _currentChatVideoQualityIndexPath = [NSIndexPath indexPathForRow:0 inSection:0];
            break;
            
        case ChatVideoUploadQualityMedium:
            _currentChatVideoQualityIndexPath = [NSIndexPath indexPathForRow:1 inSection:0];
            break;
            
        case ChatVideoUploadQualityOriginal:
            _currentChatVideoQualityIndexPath = [NSIndexPath indexPathForRow:2 inSection:0];
            break;
            
        default:
            break;
    }
    
    SelectableTableViewCell *cell = [self.tableView cellForRowAtIndexPath:self.currentChatVideoQualityIndexPath];
    cell.redCheckmarkImageView.hidden = NO;
}

#pragma mark - Table view data source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return 3;
}

#pragma mark - UITableViewDelegate

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    [self.tableView deselectRowAtIndexPath:indexPath animated:YES];
    
    if (self.currentChatVideoQualityIndexPath == indexPath) {
        return;
    } else {
        SelectableTableViewCell *cell = [self.tableView cellForRowAtIndexPath:self.currentChatVideoQualityIndexPath];
        cell.redCheckmarkImageView.hidden = YES;
        self.currentChatVideoQualityIndexPath = indexPath;
    }
    
    switch (indexPath.row) {
        case 0:
            [[NSUserDefaults standardUserDefaults] setObject:@(ChatVideoUploadQualityLow) forKey:@"ChatVideoQuality"];
            break;
            
        case 1:
            [[NSUserDefaults standardUserDefaults] setObject:@(ChatVideoUploadQualityMedium) forKey:@"ChatVideoQuality"];
            break;
            
        case 2:
            [[NSUserDefaults standardUserDefaults] setObject:@(ChatVideoUploadQualityOriginal) forKey:@"ChatVideoQuality"];
            break;
            
        default:
            break;
    }
    
    [[NSUserDefaults standardUserDefaults] synchronize];
        
    SelectableTableViewCell *cell = [self.tableView cellForRowAtIndexPath:indexPath];
    cell.redCheckmarkImageView.hidden = NO;
}

@end
