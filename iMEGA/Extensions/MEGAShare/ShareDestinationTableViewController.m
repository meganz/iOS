#import "ShareDestinationTableViewController.h"

#import "BrowserViewController.h"
#import "MEGAShare-Swift.h"
#import "NSString+MNZCategory.h"
#import "SendToViewController.h"
#import "ShareAttachment.h"
#import "ShareViewController.h"
#import "UIImageView+MNZCategory.h"

@import MEGAL10nObjc;

@interface ShareDestinationTableViewController () <UITextFieldDelegate, MEGAChatDelegate>

@property (weak, nonatomic) UINavigationController *navigationController;
@property (weak, nonatomic) ShareViewController *shareViewController;
@property (nonatomic) NSUserDefaults *sharedUserDefaults;

@property (weak, nonatomic) IBOutlet UIBarButtonItem *cancelBarButtonItem;

@end

@implementation ShareDestinationTableViewController

#pragma mark - Lifecycle

- (void)viewDidLoad {
    [super viewDidLoad];
    
    self.navigationController = (UINavigationController *)self.parentViewController;
    self.shareViewController = (ShareViewController *)self.navigationController.parentViewController;
    self.sharedUserDefaults = [NSUserDefaults.alloc initWithSuiteName:MEGAGroupIdentifier];

    self.cancelBarButtonItem.title = LocalizedString(@"cancel", @"");
    
    // Add observers to get notified when the extension goes to background and comes back to foreground:
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(didBecomeActive)
                                                 name:NSExtensionHostDidBecomeActiveNotification
                                               object:nil];
    
    UITapGestureRecognizer *tapGesture = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(hideKeyboard)];
    tapGesture.cancelsTouchesInView = NO;
    [self.tableView addGestureRecognizer:tapGesture];
    [self registerCustomCells];
    
    self.chatReady = MEGAChatSdk.shared.initState == MEGAChatInitOnlineSession && MEGAChatSdk.shared.activeChatListItems.size == 0;
    
    [self initializeCameraUploadsNode];
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    
    [self.navigationController setToolbarHidden:YES animated:animated];
    [MEGAChatSdk.shared addChatDelegate:self];
}

- (void)viewWillDisappear:(BOOL)animated {
    [super viewWillDisappear:animated];
    
    [MEGAChatSdk.shared removeChatDelegate:self];
}

- (void)didBecomeActive {
    [self.tableView reloadData];
}

- (void)traitCollectionDidChange:(UITraitCollection *)previousTraitCollection {
    [super traitCollectionDidChange:previousTraitCollection];
    
    if ([self.traitCollection hasDifferentColorAppearanceComparedToTraitCollection:previousTraitCollection]) {
        [AppearanceManager setupAppearance:self.traitCollection];
        [AppearanceManager forceNavigationBarUpdate:self.navigationController.navigationBar];
        
        [self updateAppearance];
    }
}

#pragma mark - Private

- (void)hideKeyboard {
    [self.view endEditing:YES];
}

#pragma mark - Table view delegate

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    if (indexPath.section == 0) {
        if (indexPath.row == 0) {
            UIStoryboard *cloudStoryboard = [UIStoryboard storyboardWithName:@"Cloud" bundle:[NSBundle bundleForClass:BrowserViewController.class]];
            BrowserViewController *browserVC = [cloudStoryboard instantiateViewControllerWithIdentifier:@"BrowserViewControllerID"];
            browserVC.browserAction = BrowserActionShareExtension;
            browserVC.browserViewControllerDelegate = self.shareViewController;
            self.shareViewController.chatDestination = NO;
            [self.navigationController setToolbarHidden:NO animated:YES];
            [self.navigationController pushViewController:browserVC animated:YES];
        } else if (indexPath.row == 1) {
            UIStoryboard *chatStoryboard = [UIStoryboard storyboardWithName:@"Chat" bundle:[NSBundle bundleForClass:SendToViewController.class]];
            SendToViewController *sendToViewController = [chatStoryboard instantiateViewControllerWithIdentifier:@"SendToViewControllerID"];
            sendToViewController.sendMode = SendModeShareExtension;
            sendToViewController.sendToViewControllerDelegate = self.shareViewController;
            self.shareViewController.chatDestination = YES;
            [self.navigationController pushViewController:sendToViewController animated:YES];
        }
    }
    [tableView deselectRowAtIndexPath:indexPath animated:YES];
}

#pragma mark - IBActions

- (IBAction)cancelAction:(UIBarButtonItem *)sender {
    [MEGAChatSdk.shared removeChatDelegate:self];
    [self.shareViewController hideViewWithCompletion:^{
        [self.extensionContext cancelRequestWithError:[NSError errorWithDomain:@"Cancel tapped" code:-1 userInfo:nil]];
    }];
}

#pragma mark - MEGAChatDelegate

- (void)onChatInitStateUpdate:(MEGAChatSdk *)api newState:(MEGAChatInit)newState {
    MEGALogInfo(@"onChatInitStateUpdate new state: %td", newState);
    BOOL wasChatReady = self.chatReady;
    self.chatReady = newState == MEGAChatInitOnlineSession && MEGAChatSdk.shared.activeChatListItems.size == 0;
    if (wasChatReady != self.isChatReady) {
        [self.tableView reloadData];
    }
}

- (void)onChatConnectionStateUpdate:(MEGAChatSdk *)api chatId:(uint64_t)chatId newState:(int)newState {
    MEGALogInfo(@"onChatConnectionStateUpdate: %@, new state: %d", [MEGASdk base64HandleForUserHandle:chatId], newState);
    BOOL shouldReload = NO;
    
    if (chatId == MEGAInvalidHandle && newState == MEGAChatConnectionOnline) {
        if (!self.isChatReady) {
            self.chatReady = YES;
            shouldReload = YES;
        }
    } else {
        if (self.isChatReady) {
            self.chatReady = NO;
            shouldReload = YES;
        }
    }
    
    if (shouldReload) {
        [self.tableView reloadData];
    }
}

@end
