#import "ChatRoomsViewController.h"
#import "MEGASdkManager.h"
#import "ChatRoomCell.h"
#import "MessagesViewController.h"
#import "UIImageView+MNZCategory.h"
#import "ContactsViewController.h"
#import "MEGANavigationController.h"

@interface ChatRoomsViewController () <UITableViewDataSource, UITableViewDelegate, UIActionSheetDelegate, MEGAChatRoomDelegate>

@property (weak, nonatomic) IBOutlet UITableView *tableView;

@property (nonatomic, strong) MEGAChatRoomList *chatRoomList;

@end

@implementation ChatRoomsViewController

#pragma mark - Lifecycle

- (void)viewDidLoad {
    [super viewDidLoad];
    
    self.title = @"Chat";
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    
    self.tabBarController.tabBar.hidden = NO;
    
    self.chatRoomList = [[MEGASdkManager sharedMEGAChatSdk] chatRooms];
    [self.tableView reloadData];
}

#pragma mark - IBActions

- (IBAction)addTapped:(UIBarButtonItem *)sender {
    UIActionSheet *actionSheet = [[UIActionSheet alloc] initWithTitle:@"Title" delegate:self cancelButtonTitle:@"Cancel" destructiveButtonTitle:nil otherButtonTitles:@"Start conversation", @"Invite", @"Select", nil];
    
    if ([[UIDevice currentDevice] iPadDevice]) {
        [actionSheet showInView:self.view];
    } else {
        if (([[[UIDevice currentDevice] systemVersion] compare:@"8.0" options:NSNumericSearch] == NSOrderedAscending)) {
            UIWindow *window = [[[UIApplication sharedApplication] delegate] window];
            if ([window.subviews containsObject:self.view]) {
                [actionSheet showInView:self.view];
            } else {
                [actionSheet showInView:window];
            }
        } else {
            [actionSheet showFromTabBar:self.tabBarController.tabBar];
        }
    }
    
}

#pragma mark - UITableViewDataSource

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return self.chatRoomList.size;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    ChatRoomCell *cell = [tableView dequeueReusableCellWithIdentifier:@"chatRoomCell" forIndexPath:indexPath];
    
    MEGAChatRoom *chatRoom = [self.chatRoomList chatRoomAtIndex:indexPath.row];
    MEGALogInfo(@"%@", chatRoom);
    
    cell.chatTitle.text = chatRoom.title;
    [cell.avatarImageView mnz_setImageForUser:[[MEGASdkManager sharedMEGASdk] contactForEmail:[MEGASdk base64HandleForUserHandle:[chatRoom peerHandleAtIndex:0]]]];
    if (chatRoom.isGroup) {
        cell.onlineStatusView.hidden = YES;
    } else {
        if (chatRoom.onlineStatus == 0) {
            cell.onlineStatusView.backgroundColor = [UIColor mzn_brownishGrey666666];            
        } else if (chatRoom.onlineStatus == 3) {
            cell.onlineStatusView.backgroundColor = [UIColor mzn_vividGreen13E03C];
            
        }
        cell.onlineStatusView.layer.cornerRadius = cell.onlineStatusView.frame.size.width / 2;
    }
    
    cell.unreadCount.layer.cornerRadius = 6.0f;
    cell.unreadCount.clipsToBounds = YES;
    cell.unreadCount.text = [NSString stringWithFormat:@"%ld", (long)chatRoom.unreadCount];
    
    return cell;
}

#pragma mark - UITableViewDelegate

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    
    MEGAChatRoom *chatRoom = [self.chatRoomList chatRoomAtIndex:indexPath.row];
    MessagesViewController *vc = [[MessagesViewController alloc] init];
    vc.chatRoom = chatRoom;
    [self.navigationController pushViewController:vc animated:YES];
}

#pragma mark - UIActionSheetDelegate

- (void)actionSheet:(UIActionSheet *)actionSheet clickedButtonAtIndex:(NSInteger)buttonIndex {
    if (buttonIndex == 0) {
        MEGANavigationController *navigationController = [[UIStoryboard storyboardWithName:@"Contacts" bundle:nil] instantiateViewControllerWithIdentifier:@"ContactsNavigationControllerID"];
        ContactsViewController *contactsVC = navigationController.viewControllers.firstObject;
        contactsVC.contactsMode = ContactsShareFoldersWith;
        [self presentViewController:navigationController animated:YES completion:nil];
    }
    
}

@end
