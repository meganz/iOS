
#import "ShareDestinationTableViewController.h"

#import "BrowserViewController.h"
#import "MEGAShare-Swift.h"
#import "NSString+MNZCategory.h"
#import "SendToViewController.h"
#import "ShareAttachment.h"
#import "ShareViewController.h"
#import "UIImageView+MNZCategory.h"

@interface ShareDestinationTableViewController () <UITextFieldDelegate, MEGAChatDelegate>

@property (weak, nonatomic) UINavigationController *navigationController;
@property (weak, nonatomic) ShareViewController *shareViewController;
@property (nonatomic) NSUserDefaults *sharedUserDefaults;

@property (weak, nonatomic) IBOutlet UIBarButtonItem *cancelBarButtonItem;

@property (weak, nonatomic) UITextField *activeTextField;

@property (nonatomic, getter=isChatReady) BOOL chatReady;

@end

@implementation ShareDestinationTableViewController

#pragma mark - Lifecycle

- (void)viewDidLoad {
    [super viewDidLoad];
    
    self.navigationController = (UINavigationController *)self.parentViewController;
    self.shareViewController = (ShareViewController *)self.navigationController.parentViewController;
    self.sharedUserDefaults = [NSUserDefaults.alloc initWithSuiteName:MEGAGroupIdentifier];

    self.cancelBarButtonItem.title = NSLocalizedString(@"cancel", nil);
    
    // Add observers to get notified when the extension goes to background and comes back to foreground:
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(didBecomeActive)
                                                 name:NSExtensionHostDidBecomeActiveNotification
                                               object:nil];
    
    UITapGestureRecognizer *tapGesture = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(hideKeyboard)];
    tapGesture.cancelsTouchesInView = NO;
    [self.tableView addGestureRecognizer:tapGesture];
    
    self.chatReady = MEGASdkManager.sharedMEGAChatSdk.initState == MEGAChatInitOnlineSession && MEGASdkManager.sharedMEGAChatSdk.activeChatListItems.size == 0;
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    
    [self.navigationController setToolbarHidden:YES animated:animated];
    [[MEGASdkManager sharedMEGAChatSdk] addChatDelegate:self];
}

- (void)viewWillDisappear:(BOOL)animated {
    [super viewWillDisappear:animated];
    
    [[MEGASdkManager sharedMEGAChatSdk] removeChatDelegate:self];
}

- (void)didBecomeActive {
    [self.tableView reloadData];
}

- (void)traitCollectionDidChange:(UITraitCollection *)previousTraitCollection {
    [super traitCollectionDidChange:previousTraitCollection];
    
    if ([self.traitCollection hasDifferentColorAppearanceComparedToTraitCollection:previousTraitCollection]) {
        [ExtensionAppearanceManager setupAppearance:self.traitCollection];
        [ExtensionAppearanceManager forceNavigationBarUpdate:self.navigationController.navigationBar traitCollection:self.traitCollection];
        
        [self updateAppearance];
    }
}

#pragma mark - Private

- (void)updateAppearance {
    self.tableView.separatorColor = [UIColor mnz_separatorForTraitCollection:self.traitCollection];
    self.tableView.backgroundColor = [UIColor mnz_backgroundGroupedElevated:self.traitCollection];
}

- (void)hideKeyboard {
    [self.view endEditing:YES];
}

#pragma mark - Table view data source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return 2;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    NSUInteger rows = 0;
    
    if (section == 0) {
        return 2;
    } else if (section == 1) {
        return [ShareAttachment attachmentsArray].count;
    }
    
    return rows;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    UITableViewCell *cell;
    cell.backgroundColor = [UIColor mnz_secondaryBackgroundGroupedElevated:self.traitCollection];
    
    if (indexPath.section == 0) {
        cell = [self.tableView dequeueReusableCellWithIdentifier:@"destinationCell" forIndexPath:indexPath];
        if (!cell) {
            cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:@"destinationCell"];
        }
        
        UIImageView *imageView = cell.contentView.subviews.firstObject;
        UILabel *label = cell.contentView.subviews.lastObject;

        
        cell.tintColor = [UIColor mnz_primaryGrayForTraitCollection:self.traitCollection];
        if (indexPath.row == 0) {
            imageView.image = [UIImage imageNamed:@"upload"];
            label.text = NSLocalizedString(@"uploadToMega", nil);
            label.enabled = cell.userInteractionEnabled = YES;
            cell.accessoryView = nil;
            cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
        } else if (indexPath.row == 1) {
            imageView.image = [UIImage imageNamed:@"sendToContact"];
            imageView.tintColor = UIColor.grayColor;
            label.text = NSLocalizedString(@"sendToContact", nil);
            label.enabled = cell.userInteractionEnabled = self.isChatReady;
            
            if (self.isChatReady) {
                cell.tintColor = [UIColor mnz_primaryGrayForTraitCollection:self.traitCollection];
                cell.accessoryView = nil;
                cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
            } else {
                cell.tintColor = [[UIColor mnz_primaryGrayForTraitCollection:self.traitCollection] colorWithAlphaComponent:0.5];
                
                UIActivityIndicatorView *activityIndicator = UIActivityIndicatorView.mnz_init;
                [activityIndicator startAnimating];
                cell.accessoryView = activityIndicator;
            }
        }
    } else {
        cell = [self.tableView dequeueReusableCellWithIdentifier:@"fileCell" forIndexPath:indexPath];
        if (!cell) {
            cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:@"fileCell"];
        }
        
        ShareAttachment *attachment = [[ShareAttachment attachmentsArray] objectAtIndex:indexPath.row];
        NSString *extension;
        if (attachment.type == ShareAttachmentTypeURL) {
            extension = @"html";
        } else {
            extension = [attachment.name componentsSeparatedByString:@"."].lastObject;
        }
        UIImageView *imageView = cell.contentView.subviews.firstObject;
        UITextField *textField = cell.contentView.subviews.lastObject;
        [imageView mnz_setImageForExtension:extension];
        textField.text = attachment.name;
        textField.tag = indexPath.row;
        textField.delegate = self;
    }
    
    return cell;
}

-(NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section {
    NSString *sectionTitle = @"";
    
    if (section == 0) {
        sectionTitle = NSLocalizedString(@"selectDestination", nil);
    } else if (section == 1) {
        NSString *format = [ShareAttachment attachmentsArray].count == 1 ? NSLocalizedString(@"oneFile", nil) : NSLocalizedString(@"files", nil);
        sectionTitle = [NSString stringWithFormat:format, [ShareAttachment attachmentsArray].count];
    }
    
    return sectionTitle;
}

- (NSString *)tableView:(UITableView *)tableView titleForFooterInSection:(NSInteger)section {
    NSString *sectionFooter = @"";
    
    if (section == 1) {
        sectionFooter = NSLocalizedString(@"tapFileToRename", nil);
    }
    
    return sectionFooter;
}

- (void)tableView:(UITableView *)tableView willDisplayFooterView:(UIView *)view forSection:(NSInteger)section {
    if (section == 1) {
        UITableViewHeaderFooterView *footer = (UITableViewHeaderFooterView *)view;
        footer.textLabel.textAlignment = NSTextAlignmentCenter;
    }
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
    if (self.activeTextField && self.activeTextField.isFirstResponder) {
        [self.activeTextField resignFirstResponder];
    }
    [[MEGASdkManager sharedMEGAChatSdk] removeChatDelegate:self];
    [self.shareViewController hideViewWithCompletion:^{
        [self.extensionContext cancelRequestWithError:[NSError errorWithDomain:@"Cancel tapped" code:-1 userInfo:nil]];
    }];
}

#pragma mark - UITextFieldDelegate

- (void)textFieldDidBeginEditing:(UITextField *)textField {
    self.activeTextField = textField;
    ShareAttachment *attachment = [[ShareAttachment attachmentsArray] objectAtIndex:textField.tag];
    if (attachment.type == ShareAttachmentTypeURL) {
        return;
    }
    
    NSString *name = textField.text;
    NSString *extension = [name componentsSeparatedByString:@"."].lastObject;

    UITextPosition *beginning = textField.beginningOfDocument;
    UITextRange *textRange;
    if (extension.mnz_isEmpty) {
        UITextPosition *end = textField.endOfDocument;
        textRange = [textField textRangeFromPosition:beginning toPosition:end];
    } else {
        NSRange filenameRange = [name rangeOfString:@"." options:NSBackwardsSearch];
        UITextPosition *beforeExtension = [textField positionFromPosition:beginning offset:filenameRange.location];
        textRange = [textField textRangeFromPosition:beginning toPosition:beforeExtension];
    }
    textField.selectedTextRange = textRange;
}

- (void)textFieldDidEndEditing:(UITextField *)textField {
    if ([ShareAttachment attachmentsArray].count > textField.tag) {
        ([ShareAttachment attachmentsArray][textField.tag]).name = textField.text;
    }
}

- (BOOL)textFieldShouldReturn:(UITextField *)textField {
    [textField resignFirstResponder];
    self.activeTextField = nil;
    
    return YES;
}

#pragma mark - MEGAChatDelegate

- (void)onChatInitStateUpdate:(MEGAChatSdk *)api newState:(MEGAChatInit)newState {
    MEGALogInfo(@"onChatInitStateUpdate new state: %td", newState);
    BOOL wasChatReady = self.chatReady;
    self.chatReady = newState == MEGAChatInitOnlineSession && MEGASdkManager.sharedMEGAChatSdk.activeChatListItems.size == 0;
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
