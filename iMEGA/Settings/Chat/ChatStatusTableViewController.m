#import "ChatStatusTableViewController.h"

#import "MEGASdkManager.h"

#import "SelectableTableViewCell.h"

@interface ChatStatusTableViewController () <MEGAChatRequestDelegate>

@property (nonatomic) MEGAChatStatus currentChatStatus;
@property (nonatomic) NSIndexPath *currentStatusCellIndexPath;

@end

@implementation ChatStatusTableViewController

#pragma mark - Lifecycle

- (void)viewDidLoad {
    [super viewDidLoad];
    
    self.navigationItem.title = AMLocalizedString(@"status", @"Title that refers to the status of the chat (Either Online or Offline)");
    
    self.currentChatStatus = [[MEGASdkManager sharedMEGAChatSdk] onlineStatus];
    
    [self.tableView registerNib:[UINib nibWithNibName:@"SelectableTableViewCell" bundle:nil] forCellReuseIdentifier:@"SelectableTableViewCellID"];
}

#pragma mark - UITableViewDataSource

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return 2;
}

- (NSString *)tableView:(UITableView *)tableView titleForFooterInSection:(NSInteger)section {
    NSString *titleForFooter;
    switch (self.currentStatusCellIndexPath.row) {
        case 0: //Online
            titleForFooter = AMLocalizedString(@"chatStatus_OnlineFooter", @"Footer text to explain the meaning of the chat 'Online' status.");
            break;
            
        case 1: //Offline
            titleForFooter = AMLocalizedString(@"chatStatus_OfflineFooter", @"Footer text to explain the meaning of the chat 'Offline' status.");
            break;
            
        default:
            break;
    }
    
    return titleForFooter;
}

#pragma mark - UITableViewDelegate

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    SelectableTableViewCell *cell = [self.tableView dequeueReusableCellWithIdentifier:@"SelectableTableViewCellID" forIndexPath:indexPath];
    
    MEGAChatStatus cellStatus;
    switch (indexPath.row) {
        case 0: {
            cell.titleLabel.text = AMLocalizedString(@"online", nil);
            cellStatus = MEGAChatStatusOnline;
            break;
        }
            
        case 1: {
            cell.titleLabel.text = AMLocalizedString(@"offline", @"Title of the Offline section");
            cellStatus = MEGAChatStatusOffline;
            break;
        }
    }
    
    if (self.currentChatStatus == cellStatus) {
        cell.redCheckmarkImageView.hidden = NO;
        self.currentStatusCellIndexPath = indexPath;
    } else {
        cell.redCheckmarkImageView.hidden = YES;
    }
    
    return cell;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    [self.tableView deselectRowAtIndexPath:indexPath animated:YES];
    
    if ([indexPath isEqual:self.currentStatusCellIndexPath]) {
        return;
    } else {
        self.currentStatusCellIndexPath = indexPath;
    }
    
    SelectableTableViewCell *cell = [self.tableView cellForRowAtIndexPath:indexPath];
    cell.redCheckmarkImageView.hidden ? (cell.redCheckmarkImageView.hidden = NO) : (cell.redCheckmarkImageView.hidden = YES);
    
    switch (indexPath.row) {
        case 0: //Online
            [[MEGASdkManager sharedMEGAChatSdk] connect];
            break;
            
        case 1: //Offline
            [[MEGASdkManager sharedMEGAChatSdk] setOnlineStatus:MEGAChatStatusOffline delegate:self];
            break;
            
        default:
            break;
    }
}

#pragma mark - MEGAChatRequestDelegate

- (void)onChatRequestFinish:(MEGAChatSdk *)api request:(MEGAChatRequest *)request error:(MEGAChatError *)error {
    if (error.type) return;
    
    switch (request.type) {
        case MEGAChatRequestTypeConnect: {
            [[MEGASdkManager sharedMEGAChatSdk] setOnlineStatus:MEGAChatStatusOnline delegate:self];
            break;
        }
            
        case MEGAChatRequestTypeSetOnlineStatus: {
            MEGAChatStatus newChatStatus = request.number;
            if (newChatStatus == MEGAChatStatusOffline) {
                [[MEGASdkManager sharedMEGAChatSdk] disconnect];
            }
            self.currentChatStatus = newChatStatus;
            break;
        }
            
        default:
            break;
    }
    
    [self.tableView reloadData];
}

@end
