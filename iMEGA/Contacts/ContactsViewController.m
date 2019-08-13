
#import "ContactsViewController.h"

#import <ContactsUI/ContactsUI.h>

#import "UIImage+GKContact.h"
#import "NSDate+DateTools.h"
#import "SVProgressHUD.h"
#import "UIScrollView+EmptyDataSet.h"
#import "UIBarButtonItem+Badge.h"

#import "Helper.h"
#import "MEGAInviteContactRequestDelegate.h"
#import "MEGANavigationController.h"
#import "MEGAReachabilityManager.h"
#import "MEGARemoveContactRequestDelegate.h"
#import "MEGASdkManager.h"
#import "MEGAShareRequestDelegate.h"
#import "MEGAUser+MNZCategory.h"
#import "NSFileManager+MNZCategory.h"
#import "NSString+MNZCategory.h"
#import "UIAlertAction+MNZCategory.h"
#import "UIImageView+MNZCategory.h"
#import "UITextField+MNZCategory.h"

#import "ContactDetailsViewController.h"
#import "ContactLinkQRViewController.h"
#import "ContactTableViewCell.h"
#import "ShareFolderActivity.h"
#import "ItemListViewController.h"

@interface ContactsViewController () <CNContactPickerDelegate, UISearchBarDelegate, UISearchResultsUpdating, UIViewControllerPreviewingDelegate, DZNEmptyDataSetSource, DZNEmptyDataSetDelegate, MEGAGlobalDelegate, ItemListViewControllerProtocol, UISearchControllerDelegate, UIGestureRecognizerDelegate, MEGAChatDelegate>

@property (nonatomic) id<UIViewControllerPreviewing> previewingContext;

@property (weak, nonatomic) IBOutlet UITableView *tableView;

@property (weak, nonatomic) IBOutlet UIView *itemListView;
@property (weak, nonatomic) IBOutlet UIView *contactsHeaderView;
@property (weak, nonatomic) IBOutlet UILabel *contactsHeaderViewLabel;

@property (nonatomic, strong) MEGAUserList *users;
@property (nonatomic, strong) NSMutableArray *visibleUsersArray;
@property (nonatomic, strong) NSMutableArray *selectedUsersArray;
@property (nonatomic, strong) NSMutableArray *outSharesForNodeMutableArray;

@property (weak, nonatomic) IBOutlet UIBarButtonItem *addBarButtonItem;
@property (weak, nonatomic) IBOutlet UIBarButtonItem *selectAllBarButtonItem;
@property (weak, nonatomic) IBOutlet UIBarButtonItem *editBarButtonItem;
@property (weak, nonatomic) IBOutlet UIBarButtonItem *contactRequestsBarButtonItem;
@property (weak, nonatomic) IBOutlet UIBarButtonItem *backBarButtonItem;
@property (weak, nonatomic) IBOutlet UIBarButtonItem *addParticipantBarButtonItem;
@property (weak, nonatomic) IBOutlet UIBarButtonItem *createGroupBarButtonItem;

@property (weak, nonatomic) IBOutlet UIToolbar *toolbar;
@property (weak, nonatomic) IBOutlet UIBarButtonItem *deleteBarButtonItem;

@property (weak, nonatomic) IBOutlet UIBarButtonItem *cancelBarButtonItem;
@property (weak, nonatomic) IBOutlet NSLayoutConstraint *itemListViewHeightConstraint;

@property (weak, nonatomic) IBOutlet UIView *searchFixedView;
@property (weak, nonatomic) IBOutlet NSLayoutConstraint *searchFixedViewHeightConstraint;

@property (weak, nonatomic) IBOutlet UIBarButtonItem *insertAnEmailBarButtonItem;
@property (weak, nonatomic) IBOutlet UIBarButtonItem *shareFolderWithBarButtonItem;
@property (strong, nonatomic) NSString *insertedEmail;
@property (strong, nonatomic) NSString *insertedGroupName;

@property (nonatomic, strong) NSMutableDictionary *indexPathsMutableDictionary;

@property (nonatomic, strong) MEGAUser *userTapped;

@property (nonatomic, getter=isKeyRotationEnabled) BOOL keyRotationEnabled;

@property (nonatomic, strong) NSMutableArray *searchVisibleUsersArray;
@property (strong, nonatomic) UISearchController *searchController;
@property (strong, nonatomic) ItemListViewController *itemListVC;

@property (nonatomic) UIPanGestureRecognizer *panOnTable;

@property (weak, nonatomic) IBOutlet UIView *tableViewHeader;
@property (weak, nonatomic) IBOutlet UITextField *enterGroupNameTextField;
@property (weak, nonatomic) IBOutlet UILabel *encryptedKeyRotationLabel;
@property (weak, nonatomic) IBOutlet UILabel *getChatLinkLabel;
@property (weak, nonatomic) IBOutlet UILabel *keyRotationFooterLabel;
@property (weak, nonatomic) IBOutlet UIButton *checkboxButton;
@property (weak, nonatomic) IBOutlet UIStackView *getChatLinkStackView;
@property (weak, nonatomic) IBOutlet UIStackView *optionsStackView;

@property (weak, nonatomic) IBOutlet UIView *tableViewFooter;
@property (weak, nonatomic) IBOutlet UILabel *noContactsLabel;
@property (weak, nonatomic) IBOutlet UILabel *noContactsDescriptionLabel;
@property (weak, nonatomic) IBOutlet UIButton *inviteContactButton;

@end

@implementation ContactsViewController

#pragma mark - Lifecycle

- (void)viewDidLoad {
    [super viewDidLoad];
    
    //White background for the view behind the table view
    self.tableView.backgroundView = UIView.alloc.init;
    
    self.tableView.emptyDataSetSource = self;
    self.tableView.emptyDataSetDelegate = self;

    self.searchController = [Helper customSearchControllerWithSearchResultsUpdaterDelegate:self searchBarDelegate:self];
    self.searchController.delegate = self;
    
    [self.createGroupBarButtonItem setTitleTextAttributes:@{NSForegroundColorAttributeName : [UIColor colorWithRed:1 green:1 blue:1 alpha:.5]} forState:UIControlStateDisabled];

    [self setupContacts];
    
    self.panOnTable = [[UIPanGestureRecognizer alloc] initWithTarget:self action:@selector(shouldDismissSearchController)];
    self.panOnTable.delegate = self;
    
    self.tableView.tableFooterView = [[UIView alloc] initWithFrame:CGRectZero];
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(internetConnectionChanged) name:kReachabilityChangedNotification object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(keyboardWillShow:) name:UIKeyboardWillShowNotification object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(keyboardWillHide:) name:UIKeyboardWillHideNotification object:nil];

    [[MEGASdkManager sharedMEGASdk] addMEGAGlobalDelegate:self];
    [[MEGASdkManager sharedMEGAChatSdk] addChatDelegate:self];
    [[MEGAReachabilityManager sharedManager] retryPendingConnections];
    
    [self reloadUI];
}

- (void)viewWillDisappear:(BOOL)animated {
    [super viewWillDisappear:animated];
    
    [[NSNotificationCenter defaultCenter] removeObserver:self name:kReachabilityChangedNotification object:nil];
    [[NSNotificationCenter defaultCenter] removeObserver:self name:UIKeyboardWillShowNotification object:nil];
    [[NSNotificationCenter defaultCenter] removeObserver:self name:UIKeyboardWillHideNotification object:nil];

    [[MEGASdkManager sharedMEGASdk] removeMEGAGlobalDelegate:self];
    [[MEGASdkManager sharedMEGAChatSdk] removeChatDelegate:self];
}

- (void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];
    
    if (self.contactsMode == ContactsModeDefault) {
        MEGAContactRequestList *incomingContactsLists = [[MEGASdkManager sharedMEGASdk] incomingContactRequests];
        [self setContactRequestBarButtomItemWithValue:incomingContactsLists.size.integerValue];
        
        if (!self.avoidPresentIncomingPendingContactRequests && incomingContactsLists.size.intValue > 0) {
            UINavigationController *contactRequestsNC = [[UIStoryboard storyboardWithName:@"Contacts" bundle:nil] instantiateViewControllerWithIdentifier:@"ContactsRequestsNavigationControllerID"];
            [self presentViewController:contactRequestsNC animated:YES completion:nil];
            self.avoidPresentIncomingPendingContactRequests = YES;
        }
    }
}

- (UIInterfaceOrientationMask)supportedInterfaceOrientations {
    return UIInterfaceOrientationMaskAll;
}

- (void)viewWillTransitionToSize:(CGSize)size withTransitionCoordinator:(id<UIViewControllerTransitionCoordinator>)coordinator {
    [super viewWillTransitionToSize:size withTransitionCoordinator:coordinator];
    
    [coordinator animateAlongsideTransition:^(id<UIViewControllerTransitionCoordinatorContext> context) {
        [self.tableView reloadEmptyDataSet];
    } completion:nil];
}

- (void)traitCollectionDidChange:(UITraitCollection *)previousTraitCollection {
    [super traitCollectionDidChange:previousTraitCollection];
    
    if ([self.traitCollection respondsToSelector:@selector(forceTouchCapability)]) {
        if (self.traitCollection.forceTouchCapability == UIForceTouchCapabilityAvailable) {
            if (!self.previewingContext) {
                self.previewingContext = [self registerForPreviewingWithDelegate:self sourceView:self.view];
            }
        } else {
            [self unregisterForPreviewingWithContext:self.previewingContext];
            self.previewingContext = nil;
        }
    }
}

#pragma mark - Private

- (void)setupContacts {
    self.indexPathsMutableDictionary = [[NSMutableDictionary alloc] init];
    
    switch (self.contactsMode) {
        case ContactsModeDefault: {
            NSArray *buttonsItems = @[self.addBarButtonItem, self.contactRequestsBarButtonItem];
            self.navigationItem.rightBarButtonItems = buttonsItems;
            break;
        }
            
        case ContactsModeShareFoldersWith: {
            [self updatePromptTitle];
            
            self.selectAllBarButtonItem.image =  nil;
            self.selectAllBarButtonItem.title = AMLocalizedString(@"selectAll", @"Select all items/elements on the list");
            [self.selectAllBarButtonItem setTitleTextAttributes:@{NSFontAttributeName:[UIFont mnz_SFUIRegularWithSize:17.0f]} forState:UIControlStateNormal];
            self.navigationItem.leftBarButtonItem = self.selectAllBarButtonItem;
            
            self.cancelBarButtonItem.title = AMLocalizedString(@"cancel", nil);
            [self.cancelBarButtonItem setTitleTextAttributes:@{NSFontAttributeName:[UIFont mnz_SFUIRegularWithSize:17.0f]} forState:UIControlStateNormal];
            self.navigationItem.rightBarButtonItems = @[self.cancelBarButtonItem];
            
            self.insertAnEmailBarButtonItem.title = AMLocalizedString(@"addFromEmail", @"Item menu option to add a contact writting his/her email");
            [self.insertAnEmailBarButtonItem setTitleTextAttributes:@{NSFontAttributeName:[UIFont mnz_SFUIRegularWithSize:17.0f], NSForegroundColorAttributeName:UIColor.mnz_redMain} forState:UIControlStateNormal];
            
            self.shareFolderWithBarButtonItem.title = AMLocalizedString(@"share", @"Button title which, if tapped, will trigger the action of sharing with the contact or contacts selected");
            [self.shareFolderWithBarButtonItem setTitleTextAttributes:@{NSFontAttributeName:[UIFont mnz_SFUIMediumWithSize:17.0f], NSForegroundColorAttributeName:UIColor.mnz_redMain} forState:UIControlStateNormal];
            
            UIBarButtonItem *flexibleItem = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemFlexibleSpace target:nil action:nil];
            self.navigationController.topViewController.toolbarItems = @[self.insertAnEmailBarButtonItem, flexibleItem, self.shareFolderWithBarButtonItem];
            [self.navigationController setToolbarHidden:NO];
            
            [self editTapped:self.editBarButtonItem];
            break;
        }
            
        case ContactsModeFolderSharedWith: {
            self.editBarButtonItem.title = AMLocalizedString(@"select", @"Caption of a button to select files");
            self.navigationItem.rightBarButtonItems = @[self.editBarButtonItem];
            
            UIBarButtonItem *flexibleItem = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemFlexibleSpace target:nil action:nil];
            self.deleteBarButtonItem.title = AMLocalizedString(@"remove", @"Title for the action that allows to remove a file or folder");
            [self.deleteBarButtonItem setTitleTextAttributes:@{NSFontAttributeName:[UIFont mnz_SFUIRegularWithSize:17.0f], NSForegroundColorAttributeName:UIColor.mnz_redMain} forState:UIControlStateNormal];
            self.toolbar.items = @[flexibleItem, self.deleteBarButtonItem];
            break;
        }
            
        case ContactsModeChatStartConversation: {
            self.cancelBarButtonItem.title = AMLocalizedString(@"cancel", @"Button title to cancel something");
            self.navigationItem.rightBarButtonItems = @[self.cancelBarButtonItem];
            if (self.visibleUsersArray.count == 0) {
                self.noContactsLabel.text = AMLocalizedString(@"contactsEmptyState_title", @"Title shown when the Contacts section is empty, when you have not added any contact.");
                self.noContactsDescriptionLabel.text = AMLocalizedString(@"Start chatting securely with your contacts using end-to-end encryption", @"Empty Conversations description");
                self.inviteContactButton.titleLabel.text = AMLocalizedString(@"inviteContact", @"Text shown when the user tries to make a call and the receiver is not a contact");
            }
            break;
        }
            
        case ContactsModeChatAddParticipant:
        case ContactsModeChatAttachParticipant: {
            self.cancelBarButtonItem.title = AMLocalizedString(@"cancel", nil);
            self.addParticipantBarButtonItem.title = AMLocalizedString(@"ok", nil);
            [self setTableViewEditing:YES animated:NO];
            self.navigationItem.leftBarButtonItem = self.cancelBarButtonItem;
            self.navigationItem.rightBarButtonItems = @[self.addParticipantBarButtonItem];
            self.navigationController.toolbarHidden = YES;
            break;
        }
            
        case ContactsModeChatCreateGroup: {
            self.tableView.backgroundColor = UIColor.mnz_grayFCFCFC;
            [self setTableViewEditing:YES animated:NO];
            self.createGroupBarButtonItem.title = AMLocalizedString(@"next", nil);
            [self.createGroupBarButtonItem setTitleTextAttributes:[NSDictionary dictionaryWithObjectsAndKeys:
                                                                   [UIFont mnz_SFUIMediumWithSize:17],
                                                                   NSFontAttributeName,
                                                                   nil]
                                                         forState:UIControlStateNormal];
            self.cancelBarButtonItem.title = AMLocalizedString(@"cancel", @"Button title to cancel something");
            self.navigationItem.rightBarButtonItems = @[self.createGroupBarButtonItem];
            self.navigationItem.leftBarButtonItem = self.cancelBarButtonItem;
            self.navigationController.toolbarHidden = YES;
            break;
        }
            
        case ContactsModeChatNamingGroup: {
            self.backBarButtonItem.image = self.backBarButtonItem.image.imageFlippedForRightToLeftLayoutDirection;
            self.createGroupBarButtonItem.title = AMLocalizedString(@"createFolderButton", nil);
            self.encryptedKeyRotationLabel.text = AMLocalizedString(@"Encrypted Key Rotation", @"Label in a cell where you can enable the 'Encrypted Key Rotation'");
            self.getChatLinkLabel.text = AMLocalizedString(@"Get Chat Link", @"Label in a cell where you can get the chat link");
            self.keyRotationFooterLabel.text = AMLocalizedString(@"Key rotation is slightly more secure, but does not allow you to create a chat link and new participants will not see past messages.", @"Footer text to explain what means 'Encrypted Key Rotation'");
            [self.createGroupBarButtonItem setTitleTextAttributes:[NSDictionary dictionaryWithObjectsAndKeys:
                                                              [UIFont mnz_SFUIMediumWithSize:17],
                                                              NSFontAttributeName,
                                                              nil]
                                                    forState:UIControlStateNormal];
            self.navigationItem.rightBarButtonItems = @[self.createGroupBarButtonItem];
            [self.tableView setEditing:NO animated:YES];
            [self.enterGroupNameTextField becomeFirstResponder];
            self.checkboxButton.selected = self.getChatLinkEnabled;
            
            if (self.getChatLinkEnabled) {
                self.optionsStackView.hidden = self.getChatLinkEnabled;
                self.tableViewHeader.frame = CGRectMake(0, 0, self.tableViewHeader.frame.size.width, 60);
            } else {          
                UITapGestureRecognizer *singleFingerTap = [UITapGestureRecognizer.alloc initWithTarget:self action:@selector(checkboxTouchUpInside:)];
                [self.getChatLinkStackView addGestureRecognizer:singleFingerTap];
            }
            
            break;
        }
            
    }
}

- (void)reloadUI {
    [self setNavigationBarTitle];
    
    [self setNavigationBarButtonItemsEnabled:MEGAReachabilityManager.isReachable];
    
    self.visibleUsersArray = [[NSMutableArray alloc] init];
    [self.indexPathsMutableDictionary removeAllObjects];
    
    if (self.contactsMode == ContactsModeFolderSharedWith) {
        self.outSharesForNodeMutableArray = [self outSharesForNode:self.node];
        for (MEGAShare *share in self.outSharesForNodeMutableArray) {
            MEGAUser *user = [[MEGASdkManager sharedMEGASdk] contactForEmail:[share user]];
            [self.visibleUsersArray addObject:user];
        }
    } else {
        self.users = [[MEGASdkManager sharedMEGASdk] contacts];
        NSInteger count = self.users.size.integerValue;
        NSMutableArray *usersArray = [[NSMutableArray alloc] init];
        for (NSInteger i = 0; i < count; i++) {
            MEGAUser *user = [self.users userAtIndex:i];
            if ([user visibility] == MEGAUserVisibilityVisible) {
                if (self.contactsMode == ContactsModeChatAddParticipant) {
                    if ([self.participantsMutableDictionary objectForKey:[NSNumber numberWithUnsignedLongLong:user.handle]] == nil) {
                        [usersArray addObject:user];
                    }
                } else {
                    [usersArray addObject:user];
                }
            }
        }
        NSSortDescriptor *sort = [NSSortDescriptor sortDescriptorWithKey:@"mnz_fullName" ascending:YES selector:@selector(localizedCaseInsensitiveCompare:)];
        self.visibleUsersArray = [NSMutableArray arrayWithArray:[usersArray sortedArrayUsingDescriptors:@[sort]]];
    }
    
    [self.tableView reloadData];
    
    if (self.contactsMode == ContactsModeFolderSharedWith) {
        if (self.visibleUsersArray.count == 0) {
            [self.editBarButtonItem setEnabled:NO];
            self.addParticipantBarButtonItem.enabled = NO;
            self.tableView.tableHeaderView = nil;
        } else {
            [self.editBarButtonItem setEnabled:YES];
            self.addParticipantBarButtonItem.enabled = YES;
            [self addSearchBarController];
        }
    } else if (self.contactsMode == ContactsModeChatNamingGroup) {
        self.tableView.tableHeaderView = self.tableViewHeader;
    } else if (self.contactsMode == ContactsModeChatStartConversation) {
        if (self.visibleUsersArray.count == 0) {
            self.tableView.tableFooterView = self.tableViewFooter;
        } else {
            [self addSearchBarController];
            self.tableView.tableFooterView = UIView.new;
        }
    } else {
        [self addSearchBarController];
    }
}

- (void)internetConnectionChanged {
    BOOL boolValue = MEGAReachabilityManager.isReachable;
    [self setNavigationBarButtonItemsEnabled:boolValue];
    
    if (!boolValue) {
        [self hideSearchIfNotActive];
    }
    
    boolValue ? [self reloadUI] : [self.tableView reloadData];
}

- (void)setNavigationBarButtonItemsEnabled:(BOOL)boolValue {
    self.contactRequestsBarButtonItem.enabled = boolValue;
    self.addBarButtonItem.enabled = boolValue;
    self.editButtonItem.enabled = boolValue;
    self.createGroupBarButtonItem.enabled = boolValue;
}

- (void)hideSearchIfNotActive {
    if (!self.searchController.isActive) {
        self.tableView.tableHeaderView = nil;
    }
}

- (NSMutableArray *)outSharesForNode:(MEGANode *)node {
    NSMutableArray *outSharesForNodeMutableArray = [[NSMutableArray alloc] init];
    
    MEGAShareList *outSharesForNodeShareList = [[MEGASdkManager sharedMEGASdk] outSharesForNode:node];
    NSUInteger outSharesForNodeCount = [[outSharesForNodeShareList size] unsignedIntegerValue];
    for (NSInteger i = 0; i < outSharesForNodeCount; i++) {
        MEGAShare *share = [outSharesForNodeShareList shareAtIndex:i];
        if ([share user] != nil) {
            [outSharesForNodeMutableArray addObject:share];
        }
    }
    
    return outSharesForNodeMutableArray;
}

- (void)selectPermissionsFromButton:(UIBarButtonItem *)sourceButton {
    if ([MEGAReachabilityManager isReachableHUDIfNot]) {
        UIAlertController *shareFolderAlertController = [self prepareShareFolderAlertController];
        
        if (sourceButton) {
            shareFolderAlertController.popoverPresentationController.barButtonItem = sourceButton;
        } else {
            shareFolderAlertController.popoverPresentationController.sourceRect = self.view.frame;
            shareFolderAlertController.popoverPresentationController.sourceView = self.view;
        }
        
        [self presentViewController:shareFolderAlertController animated:YES completion:nil];
    }
}

- (void)selectPermissionsFromCellRect:(CGRect)cellRect {
    if ([MEGAReachabilityManager isReachableHUDIfNot]) {
        UIAlertController *shareFolderAlertController = [self prepareShareFolderAlertController];
        
        shareFolderAlertController.popoverPresentationController.sourceRect = cellRect;
        shareFolderAlertController.popoverPresentationController.sourceView = self.tableView;
        
        [self presentViewController:shareFolderAlertController animated:YES completion:nil];
    }
}

- (UIAlertController *)prepareShareFolderAlertController {
    UIAlertController *shareFolderAlertController = [UIAlertController alertControllerWithTitle:AMLocalizedString(@"permissions", @"Title of the view that shows the kind of permissions (Read Only, Read & Write or Full Access) that you can give to a shared folder") message:nil preferredStyle:UIAlertControllerStyleActionSheet];
    [shareFolderAlertController addAction:[UIAlertAction actionWithTitle:AMLocalizedString(@"cancel", @"Button title to cancel something") style:UIAlertActionStyleCancel handler:nil]];
    
    UIAlertAction *fullAccessAlertAction = [UIAlertAction actionWithTitle:AMLocalizedString(@"fullAccess", @"Permissions given to the user you share your folder with") style:UIAlertActionStyleDefault handler:^(UIAlertAction *action) {
        [self shareNodesWithLevel:MEGAShareTypeAccessFull];
    }];
    [fullAccessAlertAction mnz_setTitleTextColor:UIColor.mnz_black333333];
    [shareFolderAlertController addAction:fullAccessAlertAction];
    
    UIAlertAction *readAndWritetAlertAction = [UIAlertAction actionWithTitle:AMLocalizedString(@"readAndWrite", @"Permissions given to the user you share your folder with") style:UIAlertActionStyleDefault handler:^(UIAlertAction *action) {
        [self shareNodesWithLevel:MEGAShareTypeAccessReadWrite];
    }];
    [readAndWritetAlertAction mnz_setTitleTextColor:UIColor.mnz_black333333];
    [shareFolderAlertController addAction:readAndWritetAlertAction];
    
    UIAlertAction *readOnlyAlertAction = [UIAlertAction actionWithTitle:AMLocalizedString(@"readOnly", @"Permissions given to the user you share your folder with") style:UIAlertActionStyleDefault handler:^(UIAlertAction *action) {
        [self shareNodesWithLevel:MEGAShareTypeAccessRead];
    }];
    [readOnlyAlertAction mnz_setTitleTextColor:UIColor.mnz_black333333];
    [shareFolderAlertController addAction:readOnlyAlertAction];
    
    shareFolderAlertController.modalPresentationStyle = UIModalPresentationPopover;
    
    return shareFolderAlertController;
}

- (void)shareNodesWithLevel:(MEGAShareType)shareType {
    [SVProgressHUD setDefaultMaskType:SVProgressHUDMaskTypeClear];
    [SVProgressHUD show];
    
    if (self.contactsMode == ContactsModeShareFoldersWith) {
        MEGAShareRequestDelegate *shareRequestDelegate = [[MEGAShareRequestDelegate alloc] initWithNumberOfRequests:self.nodesArray.count completion:^{
            if (self.searchController.isActive) {
                [self.searchController dismissViewControllerAnimated:YES completion:^{
                    [self dismissViewControllerAnimated:YES completion:nil];
                }];
            } else {
                [self dismissViewControllerAnimated:YES completion:nil];
            }
        }];
        if (self.insertedEmail) {
            for (MEGANode *node in self.nodesArray) {
                [[MEGASdkManager sharedMEGASdk] shareNode:node withEmail:self.insertedEmail level:shareType delegate:shareRequestDelegate];
            }
            self.insertedEmail = nil;
        } else {
            for (MEGAUser *user in self.selectedUsersArray) {
                for (MEGANode *node in self.nodesArray) {
                    [[MEGASdkManager sharedMEGASdk] shareNode:node withUser:user level:shareType delegate:shareRequestDelegate];
                }
            }
        }
    } else if (self.contactsMode == ContactsModeFolderSharedWith) {
        void (^completion)(void);
        if (shareType == MEGAShareTypeAccessUnknown) {
            completion = ^{
                if (self.selectedUsersArray.count == self.visibleUsersArray.count) {
                    [self.navigationController popToRootViewControllerAnimated:YES];
                }
                
                [self editTapped:self.editBarButtonItem];
            };
        } else {
            completion = ^{
                NSString *base64Handle = [MEGASdk base64HandleForUserHandle:self.userTapped.handle];
                NSIndexPath *indexPath = [self.indexPathsMutableDictionary objectForKey:base64Handle];
                if (indexPath != nil) {
                    [self.tableView reloadRowsAtIndexPaths:@[indexPath] withRowAnimation:UITableViewRowAnimationAutomatic];
                }
            };
        }
        MEGAShareRequestDelegate *shareRequestDelegate = [[MEGAShareRequestDelegate alloc] initToChangePermissionsWithNumberOfRequests:1 completion:completion];
        [[MEGASdkManager sharedMEGASdk] shareNode:self.node withUser:self.userTapped level:shareType delegate:shareRequestDelegate];
    }
}

- (BOOL)userTypeHasChanged:(MEGAUser *)user {
    BOOL userHasChanged = NO;
    
    if ([user hasChangedType:MEGAUserChangeTypeAvatar]) {
        NSString *userBase64Handle = [MEGASdk base64HandleForUserHandle:user.handle];
        NSString *avatarFilePath = [[Helper pathForSharedSandboxCacheDirectory:@"thumbnailsV3"] stringByAppendingPathComponent:userBase64Handle];
        [NSFileManager.defaultManager mnz_removeItemAtPath:avatarFilePath];
        userHasChanged = YES;
    } else if ([user hasChangedType:MEGAUserChangeTypeFirstname] || [user hasChangedType:MEGAUserChangeTypeLastname] || [user hasChangedType:MEGAUserChangeTypeEmail]) {
        userHasChanged = YES;
    }
    
    return userHasChanged;
}

- (void)setNavigationBarTitle {
    [self updatePromptTitle];
    
    switch (self.contactsMode) {
        case ContactsModeDefault:
        case ContactsModeShareFoldersWith:
            self.navigationItem.title = AMLocalizedString(@"contactsTitle", @"Title of the Contacts section");
            break;
            
        case ContactsModeFolderSharedWith:
            self.navigationItem.title = AMLocalizedString(@"sharedWith", @"Title of the view where you see with who you have shared a folder");
            break;
            
        case ContactsModeChatStartConversation:
            self.navigationItem.title = AMLocalizedString(@"startConversation", @"start a chat/conversation");
            break;
            
        case ContactsModeChatAddParticipant:
            self.navigationItem.title = AMLocalizedString(@"addParticipants", @"Menu item to add participants to a chat");
            break;
            
        case ContactsModeChatAttachParticipant:
            self.navigationItem.title = AMLocalizedString(@"sendContact", @"A button label. The button sends contact information to a user in the conversation.");
            break;
            
        case ContactsModeChatCreateGroup:
            self.navigationItem.title = AMLocalizedString(@"addParticipants", @"Menu item to add participants to a chat");
            break;
            
        case ContactsModeChatNamingGroup:
            if (self.getChatLinkEnabled) {
                self.navigationItem.title = AMLocalizedString(@"New Chat Link", @"Text button for init a group chat with link.");
            } else {
                self.navigationItem.title = [AMLocalizedString(@"New group chat", @"Text button for init a group chat") capitalizedString];
            }
            break;
    }
}

- (void)updatePromptTitle {
    if (self.contactsMode == ContactsModeShareFoldersWith) {
        NSString *promptString;
        NSNumber *selectedUsersCount = [NSNumber numberWithUnsignedInteger:self.selectedUsersArray.count];
        if (selectedUsersCount.unsignedIntegerValue == 0) {
            promptString = AMLocalizedString(@"select", @"Button that allows you to select a given folder");
        } else if (selectedUsersCount.unsignedIntegerValue == 1) {
            promptString = AMLocalizedString(@"oneContact", @"");
        } else {
            promptString = AMLocalizedString(@"XContactsSelected", @"[X] will be replaced by a plural number, indicating the total number of contacts the user has");
            promptString = [promptString stringByReplacingOccurrencesOfString:@"[X]" withString:selectedUsersCount.stringValue];
        }
        self.navigationItem.prompt = promptString;
    }
}

- (void)addContactAlertTextFieldDidChange:(UITextField *)textField {
    UIAlertController *addContactFromEmailAlertController = (UIAlertController *)self.presentedViewController;
    if (addContactFromEmailAlertController) {
        UIAlertAction *rightButtonAction = addContactFromEmailAlertController.actions.lastObject;
        rightButtonAction.enabled = (!textField.text.mnz_isEmpty && textField.text.mnz_isValidEmail);
    }
}

- (void)setTableViewEditing:(BOOL)editing animated:(BOOL)animated {
    [self.tableView setEditing:editing animated:animated];
    
    if (editing) {
        self.editBarButtonItem.title = AMLocalizedString(@"cancel", @"Button title to cancel something");
        [self.addBarButtonItem setEnabled:NO];
        
        if (self.tabBarController) {
            [self.toolbar setAlpha:0.0];
            [self.tabBarController.view addSubview:self.toolbar];
            self.toolbar.translatesAutoresizingMaskIntoConstraints = NO;
            
            NSLayoutAnchor *bottomAnchor;
            if (@available(iOS 11.0, *)) {
                bottomAnchor = self.tabBarController.tabBar.safeAreaLayoutGuide.bottomAnchor;
            } else {
                bottomAnchor = self.tabBarController.tabBar.bottomAnchor;
            }
            
            [NSLayoutConstraint activateConstraints:@[[self.toolbar.topAnchor constraintEqualToAnchor:self.tabBarController.tabBar.topAnchor constant:0],
                                                      [self.toolbar.leadingAnchor constraintEqualToAnchor:self.tabBarController.tabBar.leadingAnchor constant:0],
                                                      [self.toolbar.trailingAnchor constraintEqualToAnchor:self.tabBarController.tabBar.trailingAnchor constant:0],
                                                      [self.toolbar.bottomAnchor constraintEqualToAnchor:bottomAnchor constant:0]]];
            
            [UIView animateWithDuration:0.33f animations:^ {
                [self.toolbar setAlpha:1.0];
            }];
        } else if (self.navigationController.isToolbarHidden) {
            self.navigationController.topViewController.toolbarItems = self.toolbar.items;
            [self.navigationController setToolbarHidden:NO animated:animated];
        }
        for (ContactTableViewCell *cell in self.tableView.visibleCells) {
            UIView *view = [[UIView alloc] init];
            view.backgroundColor = UIColor.clearColor;
            cell.selectedBackgroundView = view;
        }
    } else {
        self.editBarButtonItem.title = AMLocalizedString(@"select", @"Caption of a button to select files");
        self.selectedUsersArray = nil;
        [self.addBarButtonItem setEnabled:YES];
        
        if (self.tabBarController) {
            [UIView animateWithDuration:0.33f animations:^ {
                [self.toolbar setAlpha:0.0];
            } completion:^(BOOL finished) {
                if (finished) {
                    [self.toolbar removeFromSuperview];
                }
            }];
        } else {
            self.navigationController.topViewController.toolbarItems = @[];
            [self.navigationController setToolbarHidden:YES animated:animated];
        }
        
        for (ContactTableViewCell *cell in self.tableView.visibleCells) {
            cell.selectedBackgroundView = nil;
        }
    }
    
    if (!self.selectedUsersArray) {
        self.selectedUsersArray = [NSMutableArray new];
        [self.deleteBarButtonItem setEnabled:NO];
    }
}

- (MEGAUser *)userAtIndexPath:(NSIndexPath *)indexPath {
    MEGAUser *user = nil;
    if (indexPath) {
        if (self.searchController.isActive && ![self.searchController.searchBar.text isEqual: @""]) {
            user = [self.searchVisibleUsersArray objectAtIndex:indexPath.row];
        } else {
            user = [self.visibleUsersArray objectAtIndex:indexPath.row];
        }
    }
    return user;
}

- (void)setContactRequestBarButtomItemWithValue:(NSInteger)value {
    self.contactRequestsBarButtonItem.badgeBGColor = UIColor.whiteColor;
    self.contactRequestsBarButtonItem.badgeTextColor = UIColor.mnz_redMain;
    self.contactRequestsBarButtonItem.badgeFont = [UIFont mnz_SFUIMediumWithSize:11.0f];
    self.contactRequestsBarButtonItem.shouldAnimateBadge = NO;
    if (@available(iOS 11.0, *)) {
        self.contactRequestsBarButtonItem.badgeOriginY = 0.0f;
    }
    
    self.contactRequestsBarButtonItem.badgeValue = [NSString stringWithFormat:@"%ld", (long)value];
}

- (void)startGroup {
    if (self.searchController.isActive) {
        self.searchController.active = NO;
    }
    ContactsViewController *contactsVC = [[UIStoryboard storyboardWithName:@"Contacts" bundle:nil] instantiateViewControllerWithIdentifier:@"ContactsViewControllerID"];
    if (self.visibleUsersArray.count > 0) {
        contactsVC.contactsMode = ContactsModeChatCreateGroup;
    } else {
        contactsVC.contactsMode = ContactsModeChatNamingGroup;
    }
    contactsVC.createGroupChat = self.createGroupChat;
    [self.navigationController pushViewController:contactsVC animated:YES];
}

- (void)addUserToList:(MEGAUser *)user {
    if (self.childViewControllers.count) {
        [self.itemListVC addItem:[[ItemListModel alloc] initWithUser:user]];
    } else {
        [UIView animateWithDuration:.25 animations:^{
            self.itemListViewHeightConstraint.constant = 110;
            [self.view layoutIfNeeded];
        } completion:^(BOOL finished) {
            ItemListViewController *usersList = [[UIStoryboard storyboardWithName:@"Contacts" bundle:nil] instantiateViewControllerWithIdentifier:@"ItemListViewControllerID"];
            self.itemListVC = usersList;
            self.itemListVC.itemListDelegate = self;
            [self addChildViewController:usersList];
            usersList.view.frame = self.itemListView.bounds;
            [self.itemListView addSubview:usersList.view];
            [usersList didMoveToParentViewController:self];
            [self.itemListVC addItem:[[ItemListModel alloc] initWithUser:user]];
        }];
    }
}

- (void)removeUsersListSubview {
    ItemListViewController *usersList = self.childViewControllers.lastObject;
    [usersList willMoveToParentViewController:nil];
    [usersList.view removeFromSuperview];
    [usersList removeFromParentViewController];
    [self.view layoutIfNeeded];
    [UIView animateWithDuration:.25 animations:^ {
        self.itemListViewHeightConstraint.constant = 0;
        [self.view layoutIfNeeded];
    }];
}

- (void)addSearchBarController {
    if (self.visibleUsersArray.count == 0) {
        return;
    }
    
    switch (self.contactsMode) {
        case ContactsModeChatAttachParticipant:
        case ContactsModeChatAddParticipant:
        case ContactsModeChatCreateGroup:
        case ContactsModeChatStartConversation: {
            self.searchFixedViewHeightConstraint.constant = self.searchController.searchBar.frame.size.height;
            [self.searchFixedView addSubview:self.searchController.searchBar];
            self.searchController.searchBar.autoresizingMask = UIViewAutoresizingFlexibleWidth;
            self.searchController.hidesNavigationBarDuringPresentation = NO;
            break;
        }
            
        default:
            if (!self.tableView.tableHeaderView) {
                self.tableView.tableHeaderView = self.searchController.searchBar;
                [self.tableView setContentOffset:CGPointMake(0, CGRectGetHeight(self.searchController.searchBar.frame))];
                self.definesPresentationContext = YES;
                self.searchController.hidesNavigationBarDuringPresentation = YES;
            }
            break;
    }
    
    if (self.contactsMode == ContactsModeChatCreateGroup) {
        self.searchController.searchBar.barTintColor = UIColor.mnz_grayFCFCFC;
    }
}

- (void)keyboardWillShow:(NSNotification *)notification {
    [self.tableView addGestureRecognizer:self.panOnTable];
}

- (void)keyboardWillHide:(NSNotification *)notification {
    [self shouldDismissSearchController];
    [self.tableView removeGestureRecognizer:self.panOnTable];
}

- (void)shouldDismissSearchController {
    switch (self.contactsMode) {
        case ContactsModeChatStartConversation:
        case ContactsModeChatAddParticipant:
        case ContactsModeChatAttachParticipant:
        case ContactsModeChatCreateGroup:
            if (self.searchController.isActive) {
                [self.searchController.searchBar resignFirstResponder];
            }
            break;
            
        default:
            break;
    }
}

- (void)newChatLink {
    if (self.searchController.isActive) {
        self.searchController.active = NO;
    }
    ContactsViewController *contactsVC = [[UIStoryboard storyboardWithName:@"Contacts" bundle:nil] instantiateViewControllerWithIdentifier:@"ContactsViewControllerID"];
    contactsVC.contactsMode = ContactsModeChatNamingGroup;
    contactsVC.createGroupChat = self.createGroupChat;
    contactsVC.getChatLinkEnabled = YES;
    [self.navigationController pushViewController:contactsVC animated:YES];
}

#pragma mark - IBActions

- (IBAction)selectAllAction:(UIBarButtonItem *)sender {
    if (self.selectedUsersArray.count != self.visibleUsersArray.count) {
        [self.selectedUsersArray removeAllObjects];
        
        MEGAUser *user = nil;
        for (NSInteger i = 0; i < self.visibleUsersArray.count; i++) {
            user = [self.visibleUsersArray objectAtIndex:i];
            [self.selectedUsersArray addObject:user];
        }
    } else {
        [self.selectedUsersArray removeAllObjects];
    }
    
    [self updatePromptTitle];
    
    self.deleteBarButtonItem.enabled = (self.selectedUsersArray.count == 0) ? NO : YES;
    
    [self.tableView reloadData];
}

- (IBAction)addContact:(UIView *)sender {
    if (self.searchController.isActive) {
        self.searchController.active = NO;
    }
    UIAlertController *addContactAlertController = [UIAlertController alertControllerWithTitle:AMLocalizedString(@"inviteContact", @"Text shown when the user tries to make a call and the receiver is not a contact") message:nil preferredStyle:UIAlertControllerStyleActionSheet];
    [addContactAlertController addAction:[UIAlertAction actionWithTitle:AMLocalizedString(@"cancel", @"Button title to cancel something") style:UIAlertActionStyleCancel handler:nil]];
    
    UIAlertAction *addFromEmailAlertAction = [UIAlertAction actionWithTitle:AMLocalizedString(@"addFromEmail", @"Item menu option to add a contact writting his/her email") style:UIAlertActionStyleDefault handler:^(UIAlertAction *action) {
        UIAlertController *addContactFromEmailAlertController = [UIAlertController alertControllerWithTitle:AMLocalizedString(@"addContact", @"Alert title shown when you select to add a contact inserting his/her email") message:nil preferredStyle:UIAlertControllerStyleAlert];
        
        [addContactFromEmailAlertController addTextFieldWithConfigurationHandler:^(UITextField *textField) {
            textField.placeholder = AMLocalizedString(@"contactEmail", @"Clue text to help the user know what should write there. In this case the contact email you want to add to your contacts list");
            [textField addTarget:self action:@selector(addContactAlertTextFieldDidChange:) forControlEvents:UIControlEventEditingChanged];
            textField.shouldReturnCompletion = ^BOOL(UITextField *textField) {
                return (!textField.text.mnz_isEmpty && textField.text.mnz_isValidEmail);
            };
        }];
        
        [addContactFromEmailAlertController addAction:[UIAlertAction actionWithTitle:AMLocalizedString(@"cancel", @"Button title to cancel something") style:UIAlertActionStyleCancel handler:nil]];
        
        UIAlertAction *addContactAlertAction = [UIAlertAction actionWithTitle:AMLocalizedString(@"addContactButton", @"Button title to 'Add' the contact to your contacts list") style:UIAlertActionStyleDefault handler:^(UIAlertAction *action) {
            if ([MEGAReachabilityManager isReachableHUDIfNot]) {
                UITextField *textField = [[addContactFromEmailAlertController textFields] firstObject];
                MEGAInviteContactRequestDelegate *inviteContactRequestDelegate = [[MEGAInviteContactRequestDelegate alloc] initWithNumberOfRequests:1];
                [[MEGASdkManager sharedMEGASdk] inviteContactWithEmail:textField.text message:@"" action:MEGAInviteActionAdd delegate:inviteContactRequestDelegate];
                [addContactAlertController dismissViewControllerAnimated:YES completion:nil];
            }
        }];
        addContactAlertAction.enabled = NO;
        [addContactFromEmailAlertController addAction:addContactAlertAction];
        
        [self presentViewController:addContactFromEmailAlertController animated:YES completion:nil];
    }];
    [addFromEmailAlertAction mnz_setTitleTextColor:UIColor.mnz_black333333];
    [addContactAlertController addAction:addFromEmailAlertAction];
    
    UIAlertAction *addFromContactsAlertAction = [UIAlertAction actionWithTitle:AMLocalizedString(@"addFromContacts", @"Item menu option to add a contact through your device app Contacts") style:UIAlertActionStyleDefault handler:^(UIAlertAction *action) {
        if (self.presentedViewController != nil) {
            [self.presentedViewController dismissViewControllerAnimated:NO completion:nil];
        }
        
        CNContactPickerViewController *contactsPickerViewController = [[CNContactPickerViewController alloc] init];
        contactsPickerViewController.predicateForEnablingContact = [NSPredicate predicateWithFormat:@"emailAddresses.@count > 0"];
        contactsPickerViewController.predicateForSelectionOfProperty = [NSPredicate predicateWithFormat:@"(key == 'emailAddresses')"];
        contactsPickerViewController.delegate = self;
        [self presentViewController:contactsPickerViewController animated:YES completion:nil];
    }];
    [addFromContactsAlertAction mnz_setTitleTextColor:UIColor.mnz_black333333];
    [addContactAlertController addAction:addFromContactsAlertAction];
    
    UIAlertAction *scanCodeAlertAction = [UIAlertAction actionWithTitle:AMLocalizedString(@"scanCode", @"Segmented control title for view that allows the user to scan QR codes. String as short as possible.") style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
        ContactLinkQRViewController *contactLinkVC = [[UIStoryboard storyboardWithName:@"Contacts" bundle:nil] instantiateViewControllerWithIdentifier:@"ContactLinkQRViewControllerID"];
        contactLinkVC.scanCode = YES;
        [self presentViewController:contactLinkVC animated:YES completion:nil];
    }];
    [scanCodeAlertAction mnz_setTitleTextColor:UIColor.mnz_black333333];
    [addContactAlertController addAction:scanCodeAlertAction];
    
    addContactAlertController.modalPresentationStyle = UIModalPresentationPopover;
    if (self.addBarButtonItem) {
        addContactAlertController.popoverPresentationController.barButtonItem = self.addBarButtonItem;
    } else {
        addContactAlertController.popoverPresentationController.sourceRect = sender.frame;
        addContactAlertController.popoverPresentationController.sourceView = sender.superview;
    }
    
    [self presentViewController:addContactAlertController animated:YES completion:nil];
}

- (IBAction)deleteAction:(UIBarButtonItem *)sender {
    if (self.contactsMode == ContactsModeFolderSharedWith) {
        MEGAShareRequestDelegate *shareRequestDelegate = [[MEGAShareRequestDelegate alloc] initToChangePermissionsWithNumberOfRequests:self.selectedUsersArray.count completion:^{
            if (self.selectedUsersArray.count == self.visibleUsersArray.count) {
                [self.navigationController popViewControllerAnimated:YES];
            } else {
                [self reloadUI];
            }
            
            [self setTableViewEditing:NO animated:YES];
        }];
        
        for (MEGAUser *user in self.selectedUsersArray) {
            [[MEGASdkManager sharedMEGASdk] shareNode:self.node withUser:user level:MEGAShareTypeAccessUnknown delegate:shareRequestDelegate];
        }
    } else {
        NSString *message = (self.selectedUsersArray.count > 1) ? [NSString stringWithFormat:AMLocalizedString(@"removeMultipleUsersMessage", nil), self.selectedUsersArray.count] :[NSString stringWithFormat:AMLocalizedString(@"removeUserMessage", nil), [self.selectedUsersArray.firstObject email]];
        UIAlertController *removeUserAlertController = [UIAlertController alertControllerWithTitle:AMLocalizedString(@"removeUserTitle", @"Alert title shown when you want to remove one or more contacts") message:message preferredStyle:UIAlertControllerStyleAlert];
        
        [removeUserAlertController addAction:[UIAlertAction actionWithTitle:AMLocalizedString(@"cancel", @"Button title to cancel something") style:UIAlertActionStyleCancel handler:nil]];
        
        [removeUserAlertController addAction:[UIAlertAction actionWithTitle:AMLocalizedString(@"ok", nil) style:UIAlertActionStyleDefault handler:^(UIAlertAction *action) {
            if ([MEGAReachabilityManager isReachableHUDIfNot]) {
                MEGARemoveContactRequestDelegate *removeContactRequestDelegate = [[MEGARemoveContactRequestDelegate alloc] initWithNumberOfRequests:self.selectedUsersArray.count completion:^{
                    [self setTableViewEditing:NO animated:NO];
                }];
                for (NSInteger i = 0; i < self.selectedUsersArray.count; i++) {
                    [[MEGASdkManager sharedMEGASdk] removeContactUser:[self.selectedUsersArray objectAtIndex:i] delegate:removeContactRequestDelegate];
                }
                [self dismissViewControllerAnimated:YES completion:nil];
            }
        }]];
        
        [self presentViewController:removeUserAlertController animated:YES completion:nil];
    }
}

- (IBAction)cancelAction:(UIBarButtonItem *)sender {
    if (self.shareFolderActivity != nil) {
        [self.shareFolderActivity activityDidFinish:YES];
    }
    
    if (self.searchController.isActive) {
        self.searchController.active = NO;
    }
    
    if (self.contactsMode == ContactsModeChatCreateGroup) {
        [self.navigationController popViewControllerAnimated:YES];
    } else {
        [self dismissViewControllerAnimated:YES completion:nil];
    }
}

- (IBAction)backAction:(UIBarButtonItem *)sender {
    self.navigationItem.leftBarButtonItems = @[self.cancelBarButtonItem];
    switch (self.contactsMode) {
        case ContactsModeChatNamingGroup:
            [self.navigationController popViewControllerAnimated:YES];
            break;
            
        default:
            break;
    }
}

- (IBAction)shareFolderWithAction:(UIBarButtonItem *)sender {
    if (self.selectedUsersArray.count == 0) {
        return;
    }
    
    [self selectPermissionsFromButton:self.shareFolderWithBarButtonItem];
}

- (IBAction)insertAnEmailAction:(UIBarButtonItem *)sender {
    UIAlertController *insertAnEmailToShareWithAlertController = [UIAlertController alertControllerWithTitle:AMLocalizedString(@"shareFolder", @"Button title which, if tapped, will trigger the action of sharing with the contact or contacts selected, the folder you want inside your Cloud Drive") message:nil preferredStyle:UIAlertControllerStyleAlert];
    
    [insertAnEmailToShareWithAlertController addTextFieldWithConfigurationHandler:^(UITextField *textField) {
        textField.placeholder = AMLocalizedString(@"contactEmail", @"Clue text to help the user know what should write there. In this case the contact email you want to add to your contacts list");
        [textField addTarget:self action:@selector(addContactAlertTextFieldDidChange:) forControlEvents:UIControlEventEditingChanged];
        [self addContactAlertTextFieldDidChange:textField];
        textField.shouldReturnCompletion = ^BOOL(UITextField *textField) {
            return (!textField.text.mnz_isEmpty && textField.text.mnz_isValidEmail);
        };
    }];
    
    [insertAnEmailToShareWithAlertController addAction:[UIAlertAction actionWithTitle:AMLocalizedString(@"cancel", @"Button title to cancel something") style:UIAlertActionStyleCancel handler:nil]];
    
    UIAlertAction *okAlertAction = [UIAlertAction actionWithTitle:AMLocalizedString(@"ok", nil) style:UIAlertActionStyleDefault handler:^(UIAlertAction *action) {
        if ([MEGAReachabilityManager isReachableHUDIfNot]) {
            UITextField *textField = [[insertAnEmailToShareWithAlertController textFields] firstObject];
            self.insertedEmail = textField.text;
            [self selectPermissionsFromButton:self.insertAnEmailBarButtonItem];
            [insertAnEmailToShareWithAlertController dismissViewControllerAnimated:YES completion:nil];
        }
    }];
    [insertAnEmailToShareWithAlertController addAction:okAlertAction];
    okAlertAction.enabled = NO;
    
    [self presentViewController:insertAnEmailToShareWithAlertController animated:YES completion:nil];
}

- (IBAction)editTapped:(UIBarButtonItem *)sender {
    BOOL enableEditing = !self.tableView.isEditing;
    
    if (self.contactsMode == ContactsModeFolderSharedWith) {
        self.navigationItem.leftBarButtonItems = enableEditing ? @[self.selectAllBarButtonItem] : @[];
    }
    
    [self setTableViewEditing:enableEditing animated:YES];
}

- (IBAction)createGroupAction:(UIBarButtonItem *)sender {
    if (self.contactsMode == ContactsModeChatCreateGroup) {
        if (self.searchController.isActive) {
            self.searchController.active = NO;
        }
        ContactsViewController *contactsVC = [[UIStoryboard storyboardWithName:@"Contacts" bundle:nil] instantiateViewControllerWithIdentifier:@"ContactsViewControllerID"];
        contactsVC.contactsMode = ContactsModeChatNamingGroup;
        contactsVC.createGroupChat = self.createGroupChat;
        contactsVC.selectedUsersArray = self.selectedUsersArray;
        [self.navigationController pushViewController:contactsVC animated:YES];
    } else {
        if (!self.isKeyRotationEnabled && self.checkboxButton.selected && self.enterGroupNameTextField.text.mnz_isEmpty) {
            UIAlertController *alertController = [UIAlertController alertControllerWithTitle:AMLocalizedString(@"Chat Link", @"Label shown in a cell where you can enable a switch to get a chat link") message:AMLocalizedString(@"To create a chat link you must name the group.", @"Alert message to advice the users that to generate a chat link they need enter a group name for the chat")  preferredStyle:UIAlertControllerStyleAlert];
            [alertController addAction:[UIAlertAction actionWithTitle:AMLocalizedString(@"ok", nil) style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
                [self.enterGroupNameTextField becomeFirstResponder];
            }]];
            [self presentViewController:alertController animated:YES completion:nil];
        } else {
            [self dismissViewControllerAnimated:YES completion:^{
                self.createGroupChat(self.selectedUsersArray, self.insertedGroupName, self.keyRotationEnabled, self.keyRotationEnabled ? NO : self.checkboxButton.isSelected);
            }];
        }
    }
}

- (IBAction)addParticipantAction:(UIBarButtonItem *)sender {
    if (self.selectedUsersArray.count > 0) {
        if (self.searchController.isActive) {
            self.searchController.active = NO;
        }
        self.userSelected(self.selectedUsersArray);
        [self dismissViewControllerAnimated:YES completion:nil];
    }
}

- (IBAction)groupNameCanged:(UITextField *)sender {
    self.insertedGroupName = sender.text;    
}

- (IBAction)keyRotationSwitchValueChanged:(UISwitch *)sender {
    self.keyRotationEnabled = sender.on;
    self.getChatLinkStackView.hidden = sender.on;
    if (sender.on) {
        self.tableViewHeader.frame = CGRectMake(0, 0, self.tableViewHeader.frame.size.width, 266 - self.getChatLinkStackView.frame.size.height - 23);
    } else {
        self.tableViewHeader.frame = CGRectMake(0, 0, self.tableViewHeader.frame.size.width, 266);
    }
    
    [self.tableView reloadData];
}

- (IBAction)checkboxTouchUpInside:(UIButton *)sender {
    self.checkboxButton.selected = !self.checkboxButton.selected;
}

- (IBAction)inviteContactTouchUpInside:(UIButton *)sender {
    [self addContact:sender];
}

#pragma mark - UITableViewDataSource

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    NSInteger numberOfRows = 0;
    if (MEGAReachabilityManager.isReachable) {
        if (self.contactsMode == ContactsModeChatStartConversation && section == 0) {
            return 3;
        } else if (self.contactsMode == ContactsModeChatNamingGroup && section == 0) {
            return self.selectedUsersArray.count + 1;
        }
        
        numberOfRows = (self.searchController.isActive && ![self.searchController.searchBar.text isEqual: @""]) ? self.searchVisibleUsersArray.count : self.visibleUsersArray.count;
    }
    return numberOfRows;
}

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    switch (self.contactsMode) {
        case ContactsModeChatStartConversation:
            return 2;
            break;
        
        default:
            return 1;
            break;
    }
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    
    if (self.contactsMode == ContactsModeChatStartConversation && indexPath.section == 0) {
        ContactTableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"ContactPermissionsEmailTableViewCellID" forIndexPath:indexPath];
        cell.permissionsImageView.hidden = YES;
        if (indexPath.row == 0) {
            cell.nameLabel.text = AMLocalizedString(@"inviteContact", @"Text shown when the user tries to make a call and the receiver is not a contact");
            cell.avatarImageView.image = [UIImage imageNamed:@"inviteToChat"];
        } else if (indexPath.row == 1) {
            cell.nameLabel.text = AMLocalizedString(@"New group chat", @"Text button for init a group chat").capitalizedString;
            cell.avatarImageView.image = [UIImage imageNamed:@"createGroup"];
        } else {
            cell.nameLabel.text = AMLocalizedString(@"New Chat Link", @"Text button for init a group chat with link.");
            cell.avatarImageView.image = [UIImage imageNamed:@"chatLink"];
        }
        return cell;
    } else {
        MEGAUser *user;
        if (self.contactsMode == ContactsModeChatNamingGroup) {
            if (indexPath.row == self.selectedUsersArray.count) {
                user = MEGASdkManager.sharedMEGASdk.myUser;
            } else {
                user = [self.selectedUsersArray objectAtIndex:indexPath.row];
            }
        } else {
            user = [self userAtIndexPath:indexPath];
        }
        NSString *base64Handle = [MEGASdk base64HandleForUserHandle:user.handle];
        [self.indexPathsMutableDictionary setObject:indexPath forKey:base64Handle];
        
        ContactTableViewCell *cell;
        NSString *userName = user.mnz_fullName;
        
        if (user.handle == MEGASdkManager.sharedMEGASdk.myUser.handle) {
            userName = [userName stringByAppendingString:[NSString stringWithFormat:@" (%@)", AMLocalizedString(@"me", @"The title for my message in a chat. The message was sent from yourself.")]];
        }
        
        if (self.contactsMode == ContactsModeFolderSharedWith) {
            if (userName) {
                cell = [tableView dequeueReusableCellWithIdentifier:@"ContactPermissionsNameTableViewCellID" forIndexPath:indexPath];
                [cell.nameLabel setText:userName];
                cell.shareLabel.text = user.email;
            } else {
                cell = [tableView dequeueReusableCellWithIdentifier:@"ContactPermissionsEmailTableViewCellID" forIndexPath:indexPath];
                cell.nameLabel.text = user.email;
            }
            MEGAShare *share = [self.outSharesForNodeMutableArray objectAtIndex:indexPath.row];
            [cell.permissionsImageView setImage:[Helper permissionsButtonImageForShareType:share.access]];
        } else if (self.contactsMode == ContactsModeShareFoldersWith) {
            cell = [tableView dequeueReusableCellWithIdentifier:@"contactCell" forIndexPath:indexPath];
            cell.nameLabel.text = userName ? userName : user.email;
            
            cell.onlineStatusView.backgroundColor = [UIColor mnz_colorForStatusChange:[[MEGASdkManager sharedMEGAChatSdk] userOnlineStatus:user.handle]];
            
            int numFilesShares = [[[[MEGASdkManager sharedMEGASdk] inSharesForUser:user] size] intValue];
            cell.shareLabel.hidden = (numFilesShares == 0) ? YES : NO;
            if (numFilesShares == 1) {
                cell.shareLabel.text = AMLocalizedString(@"oneFolderShared", @" folder shared");
            } else {
                cell.shareLabel.text = [NSString stringWithFormat:AMLocalizedString(@"foldersShared", @" folders shared"), numFilesShares];
            }
        } else {
            cell = [tableView dequeueReusableCellWithIdentifier:@"contactCell" forIndexPath:indexPath];
            
            cell.nameLabel.text = userName ? userName : user.email;
            MEGAChatStatus userStatus = [[MEGASdkManager sharedMEGAChatSdk] userOnlineStatus:user.handle];
            cell.shareLabel.text = [NSString chatStatusString:userStatus];
            cell.onlineStatusView.backgroundColor = [UIColor mnz_colorForStatusChange:userStatus];

            if (userStatus < MEGAChatStatusOnline) {
                [[MEGASdkManager sharedMEGAChatSdk] requestLastGreen:user.handle];
            }
        } 
        
        [cell.avatarImageView mnz_setImageForUserHandle:user.handle name:cell.nameLabel.text];
        
        if (self.tableView.isEditing) {
            // Check if selectedNodesArray contains the current node in the tableView
            for (MEGAUser *u in self.selectedUsersArray) {
                if ([[u email] isEqualToString:[user email]]) {
                    [self.tableView selectRowAtIndexPath:indexPath animated:NO scrollPosition:UITableViewScrollPositionNone];
                }
            }
            
            UIView *view = [[UIView alloc] init];
            view.backgroundColor = UIColor.clearColor;
            cell.selectedBackgroundView = view;
            cell.separatorInset = UIEdgeInsetsMake(0, 97, 0, 0);
        }
        
        if (@available(iOS 11.0, *)) {
            cell.avatarImageView.accessibilityIgnoresInvertColors = YES;
        }
        
        return cell;
    }
}

- (UIView *)tableView:(UITableView *)tableView viewForHeaderInSection:(NSInteger)section {
    if (section == 0 && self.contactsMode == ContactsModeChatCreateGroup) {
        self.contactsHeaderViewLabel.text = AMLocalizedString(@"contactsTitle", @"Title of the Contacts section").uppercaseString;
        return self.contactsHeaderView;
    }
    if (section == 0 && self.contactsMode == ContactsModeChatNamingGroup) {
        NSString *participants = AMLocalizedString(@"participants", @"Label to describe the section where you can see the participants of a group chat").uppercaseString;
        self.contactsHeaderViewLabel.text = participants;
        return self.contactsHeaderView;
    }
    if (section == 1 && self.contactsMode >= ContactsModeChatStartConversation) {
        self.contactsHeaderViewLabel.text = AMLocalizedString(@"contactsTitle", @"Title of the Contacts section").uppercaseString;
        return self.contactsHeaderView;
    }
    
    return nil;
}


- (CGFloat)tableView:(UITableView *)tableView heightForHeaderInSection:(NSInteger)section {
    CGFloat heightForHeader = 0.0f;
    switch (section) {
        case 0:
            if (self.contactsMode == ContactsModeChatCreateGroup) {
                heightForHeader = 24.0f;
            }
            if (self.contactsMode == ContactsModeChatNamingGroup) {
                heightForHeader = 45.0f;
            }
            break;

        case 1:
            if (self.contactsMode >= ContactsModeChatStartConversation) {
                heightForHeader = 35.0f;
            }
            break;
    }
    
    return heightForHeader;
}

#pragma mark - UITableViewDelegate

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    
    switch (self.contactsMode) {
        case ContactsModeDefault: {
            MEGAUser *user = [self userAtIndexPath:indexPath];
            if (!user) {
                [SVProgressHUD showErrorWithStatus:@"Invalid user"];
                return;
            }
            ContactDetailsViewController *contactDetailsVC = [[UIStoryboard storyboardWithName:@"Contacts" bundle:nil] instantiateViewControllerWithIdentifier:@"ContactDetailsViewControllerID"];
            contactDetailsVC.contactDetailsMode = ContactDetailsModeDefault;
            contactDetailsVC.userEmail = user.email;
            contactDetailsVC.userName = user.mnz_fullName;
            contactDetailsVC.userHandle = user.handle;
            [self.navigationController pushViewController:contactDetailsVC animated:YES];
            break;
        }
            
        case ContactsModeShareFoldersWith:
            if (tableView.isEditing) {
                MEGAUser *user = [self userAtIndexPath:indexPath];
                if (!user) {
                    [SVProgressHUD showErrorWithStatus:@"Invalid user"];
                    return;
                }
                [self.selectedUsersArray addObject:user];
                [self updatePromptTitle];
                return;
            }
            break;
            
        case ContactsModeFolderSharedWith: {
            MEGAUser *user = [self userAtIndexPath:indexPath];
            if (!user) {
                [SVProgressHUD showErrorWithStatus:@"Invalid user"];
                return;
            }
            if (tableView.isEditing) {
                [self.selectedUsersArray addObject:user];
                self.deleteBarButtonItem.enabled = (self.selectedUsersArray.count > 0);
                return;
            }
            
            self.userTapped = user;
            CGRect cellRect = [self.tableView rectForRowAtIndexPath:indexPath];
            [self selectPermissionsFromCellRect:cellRect];
            break;
        }
            
        case ContactsModeChatStartConversation: {
            if (indexPath.section == 0) {
                if (indexPath.row == 0) {
                    [self addContact:[self.tableView cellForRowAtIndexPath:indexPath]];
                } else if (indexPath.row == 1) {
                    [self startGroup];
                } else {
                    [self newChatLink];
                }
            } else {
                MEGAUser *user = [self userAtIndexPath:indexPath];
                if (!user) {
                    [SVProgressHUD showErrorWithStatus:@"Invalid user"];
                    return;
                }
                self.searchController.active = NO;
                
                [self dismissViewControllerAnimated:YES completion:^{
                    self.userSelected(@[user]);
                }];
            }
            break;
        }
            
        case ContactsModeChatAddParticipant:
        case ContactsModeChatAttachParticipant:
        case ContactsModeChatCreateGroup:
            if (tableView.isEditing) {
                MEGAUser *user = [self userAtIndexPath:indexPath];
                if (!user) {
                    [SVProgressHUD showErrorWithStatus:@"Invalid user"];
                    return;
                }
                [self.selectedUsersArray addObject:user];
                [self addUserToList:user];
                if (self.searchController.searchBar.isFirstResponder) {
                    self.searchController.searchBar.text = @"";
                }
                return;
            }
            break;
        default:
            break;
    }
    
    [self.tableView deselectRowAtIndexPath:indexPath animated:YES];
}

- (void)tableView:(UITableView *)tableView didDeselectRowAtIndexPath:(NSIndexPath *)indexPath {
    
    if (self.contactsMode == ContactsModeChatStartConversation && indexPath == 0) {
        return;
    }
    
    MEGAUser *user = [self userAtIndexPath:indexPath];
    
    if (tableView.isEditing) {
        //tempArray avoid crash: "was mutated while being enumerated."
        NSMutableArray *tempArray = self.selectedUsersArray.copy;
        for (MEGAUser *u in tempArray) {
            if ([u.email isEqualToString:user.email]) {
                [self.selectedUsersArray removeObject:u];
            }
        }
        
        [self updatePromptTitle];
        
        if (self.itemListVC) {
            [self.itemListVC removeItem:[[ItemListModel alloc] initWithUser:user]];
        }
        
        if (self.selectedUsersArray.count == 0) {
            if (self.itemListVC) {
                [self removeUsersListSubview];
            }
            if (self.contactsMode != ContactsModeChatStartConversation) {
                self.deleteBarButtonItem.enabled = NO;
            }
        }
        
        if (self.contactsMode != (ContactsModeChatAddParticipant|ContactsModeChatAttachParticipant|ContactsModeChatCreateGroup)) {
            if (self.searchController.searchBar.isFirstResponder) {
                self.searchController.searchBar.text = @"";
            }
        }
        
        return;
    }
}

- (void)tableView:(UITableView *)tableView willBeginEditingRowAtIndexPath:(NSIndexPath *)indexPath {
    if (self.contactsMode == ContactsModeDefault || self.contactsMode == ContactsModeFolderSharedWith || self.contactsMode == ContactsModeChatStartConversation) {
        return;
    }
    
    [self setTableViewEditing:YES animated:YES];
}

- (void)tableView:(UITableView *)tableView didEndEditingRowAtIndexPath:(NSIndexPath *)indexPath {
    [self setTableViewEditing:NO animated:YES];
}

- (UITableViewCellEditingStyle)tableView:(UITableView *)tableView editingStyleForRowAtIndexPath:(NSIndexPath *)indexPath {
    if (self.contactsMode == ContactsModeChatStartConversation || self.contactsMode == ContactsModeChatNamingGroup) {
        return UITableViewCellEditingStyleNone;
    }
    
    MEGAUser *user = [self userAtIndexPath:indexPath];
    
    self.selectedUsersArray = [NSMutableArray new];
    [self.selectedUsersArray addObject:user];
    
    [self.deleteBarButtonItem setEnabled:YES];
    
    return (UITableViewCellEditingStyleDelete);
}

- (void)tableView:(UITableView *)tableView commitEditingStyle:(UITableViewCellEditingStyle)editingStyle forRowAtIndexPath:(NSIndexPath *)indexPath {
    if (editingStyle == UITableViewCellEditingStyleDelete) {
        switch (self.contactsMode) {
            case ContactsModeDefault: {
                MEGARemoveContactRequestDelegate *removeContactRequestDelegate = [[MEGARemoveContactRequestDelegate alloc] initWithNumberOfRequests:1 completion:^{
                    [self setTableViewEditing:NO animated:NO];
                }];
                MEGAUser *user = [self userAtIndexPath:indexPath];
                [[MEGASdkManager sharedMEGASdk] removeContactUser:user delegate:removeContactRequestDelegate];
                break;
            }
                
            case ContactsModeShareFoldersWith:
                break;
                
            case ContactsModeFolderSharedWith: {
                [self deleteAction:self.deleteBarButtonItem];
                break;
            }
                
            default:
                break;
        }
    }
}

- (NSString *)tableView:(UITableView *)tableView titleForDeleteConfirmationButtonForRowAtIndexPath:(NSIndexPath *)indexPath {
    NSString *titleForDeleteConfirmationButton;
    switch (self.contactsMode) {
        case ContactsModeShareFoldersWith:
        case ContactsModeChatStartConversation:
        case ContactsModeChatAddParticipant:
        case ContactsModeChatAttachParticipant:
        case ContactsModeChatCreateGroup:
        case ContactsModeChatNamingGroup:
            titleForDeleteConfirmationButton = @"";
            break;
        
        case ContactsModeDefault:
        case ContactsModeFolderSharedWith:
            titleForDeleteConfirmationButton = AMLocalizedString(@"remove", @"Title for the action that allows to remove a file or folder");
            break;
    }
    
    return titleForDeleteConfirmationButton;
}

#pragma mark - UIViewControllerPreviewingDelegate

- (UIViewController *)previewingContext:(id<UIViewControllerPreviewing>)previewingContext viewControllerForLocation:(CGPoint)location {
    if (self.contactsMode != ContactDetailsModeDefault) {
        return nil;
    }
    
    CGPoint rowPoint = [self.tableView convertPoint:location fromView:self.view];
    NSIndexPath *indexPath = [self.tableView indexPathForRowAtPoint:rowPoint];
    if (!indexPath || ![self.tableView numberOfRowsInSection:indexPath.section]) {
        return nil;
    }
    
    previewingContext.sourceRect = [self.tableView convertRect:[self.tableView cellForRowAtIndexPath:indexPath].frame toView:self.view];
    
    ContactDetailsViewController *contactDetailsVC = [[UIStoryboard storyboardWithName:@"Contacts" bundle:nil] instantiateViewControllerWithIdentifier:@"ContactDetailsViewControllerID"];
    contactDetailsVC.contactDetailsMode = ContactDetailsModeDefault;
    MEGAUser *user = [self.visibleUsersArray objectAtIndex:indexPath.row];
    contactDetailsVC.userEmail = user.email;
    contactDetailsVC.userName = user.mnz_fullName;
    contactDetailsVC.userHandle = user.handle;
    
    return contactDetailsVC;
}

- (void)previewingContext:(id<UIViewControllerPreviewing>)previewingContext commitViewController:(UIViewController *)viewControllerToCommit {
    [self.navigationController pushViewController:viewControllerToCommit animated:YES];
}

#pragma mark - CNContactPickerDelegate

- (void)contactPicker:(CNContactPickerViewController *)picker didSelectContacts:(NSArray<CNContact *> *)contacts {
    NSMutableArray<NSString *> *contactEmails = NSMutableArray.new;
    for (CNContact *contact in contacts) {
        for (CNContactProperty *contactProperty in contact.emailAddresses) {
            NSString *email = contactProperty.value;
            if (email.mnz_isValidEmail) {
                [contactEmails addObject:email];
            } else {
                 [SVProgressHUD showErrorWithStatus:[NSString stringWithFormat:@"%@ %@", AMLocalizedString(@"theEmailAddressFormatIsInvalid", @"Add contacts and share dialog error message when user try to add wrong email address"), email]];
            }
        }
    }
    MEGAInviteContactRequestDelegate *inviteContactRequestDelegate = [MEGAInviteContactRequestDelegate.alloc initWithNumberOfRequests:contactEmails.count];
    for (NSString *email in contactEmails) {
        [MEGASdkManager.sharedMEGASdk inviteContactWithEmail:email message:@"" action:MEGAInviteActionAdd delegate:inviteContactRequestDelegate];
    }
}

#pragma mark - DZNEmptyDataSetSource

- (NSAttributedString *)titleForEmptyDataSet:(UIScrollView *)scrollView {
    NSString *text = @"";
    if (MEGAReachabilityManager.isReachable) {
        if (self.contactsMode != ContactsModeChatNamingGroup) {
            if (self.searchController.isActive ) {
                if (self.searchController.searchBar.text.length > 0) {
                    text = AMLocalizedString(@"noResults", @"Title shown when you make a search and there is 'No Results'");
                }
            } else {
                text = AMLocalizedString(@"contactsEmptyState_title", @"Title shown when the Contacts section is empty, when you have not added any contact.");
            }
        }
    } else {
        text = AMLocalizedString(@"noInternetConnection",  @"No Internet Connection");
    }
    
    return [[NSAttributedString alloc] initWithString:text attributes:[Helper titleAttributesForEmptyState]];
}

- (nullable NSAttributedString *)descriptionForEmptyDataSet:(UIScrollView *)scrollView {
    NSString *text = @"";
    if (!MEGAReachabilityManager.isReachable && !MEGAReachabilityManager.sharedManager.isMobileDataEnabled) {
        text = AMLocalizedString(@"Mobile Data is turned off", @"Information shown when the user has disabled the 'Mobile Data' setting for MEGA in the iOS Settings.");
    }
    
    NSDictionary *attributes = @{NSFontAttributeName:[UIFont preferredFontForTextStyle:UIFontTextStyleFootnote], NSForegroundColorAttributeName:UIColor.mnz_gray777777};
    
    return [NSAttributedString.alloc initWithString:text attributes:attributes];
}

- (UIImage *)imageForEmptyDataSet:(UIScrollView *)scrollView {
    if (MEGAReachabilityManager.isReachable) {
        if (self.contactsMode == ContactsModeChatNamingGroup) {
            return nil;
        }
        if (self.searchController.isActive) {
            if (self.searchController.searchBar.text.length > 0) {
                return [UIImage imageNamed:@"searchEmptyState"];
            } else {
                return nil;
            }
        } else {
            return [UIImage imageNamed:@"contactsEmptyState"];
        }
    } else {
        return [UIImage imageNamed:@"noInternetEmptyState"];
    }
}

- (NSAttributedString *)buttonTitleForEmptyDataSet:(UIScrollView *)scrollView forState:(UIControlState)state {
    if (self.contactsMode >= ContactsModeChatAddParticipant) {
        return nil;
    }
    
    NSString *text = @"";
    if (MEGAReachabilityManager.isReachable && !self.searchController.isActive) {
        text = AMLocalizedString(@"inviteContact", @"Text shown when the user tries to make a call and the receiver is not a contact");
    } else {
        if (!MEGAReachabilityManager.sharedManager.isMobileDataEnabled) {
            text = AMLocalizedString(@"Turn Mobile Data on", @"Button title to go to the iOS Settings to enable 'Mobile Data' for the MEGA app.");
        }
    }
    
    return [[NSAttributedString alloc] initWithString:text attributes:[Helper buttonTextAttributesForEmptyState]];
}

- (UIImage *)buttonBackgroundImageForEmptyDataSet:(UIScrollView *)scrollView forState:(UIControlState)state {
    UIEdgeInsets capInsets = [Helper capInsetsForEmptyStateButton];
    UIEdgeInsets rectInsets = [Helper rectInsetsForEmptyStateButton];
    
    return [[[UIImage imageNamed:@"emptyStateButton"] resizableImageWithCapInsets:capInsets resizingMode:UIImageResizingModeStretch] imageWithAlignmentRectInsets:rectInsets];
}

- (UIColor *)backgroundColorForEmptyDataSet:(UIScrollView *)scrollView {
    return UIColor.whiteColor;
}

- (CGFloat)verticalOffsetForEmptyDataSet:(UIScrollView *)scrollView {
    return [Helper verticalOffsetForEmptyStateWithNavigationBarSize:self.navigationController.navigationBar.frame.size searchBarActive:self.searchController.isActive];
}

- (CGFloat)spaceHeightForEmptyDataSet:(UIScrollView *)scrollView {
    return [Helper spaceHeightForEmptyState];
}

#pragma mark - DZNEmptyDataSetDelegate

- (void)emptyDataSet:(UIScrollView *)scrollView didTapButton:(UIButton *)button {
    if (MEGAReachabilityManager.isReachable) {
        [self addContact:button];
    } else {
        if (!MEGAReachabilityManager.sharedManager.isMobileDataEnabled) {
            [UIApplication.sharedApplication openURL:[NSURL URLWithString:UIApplicationOpenSettingsURLString] options:@{} completionHandler:nil];
        }
    }
}

#pragma mark - UISearchBarDelegate

- (void)searchBarCancelButtonClicked:(UISearchBar *)searchBar {
    self.searchVisibleUsersArray = nil;
    
    if (!MEGAReachabilityManager.isReachable) {
        self.tableView.tableHeaderView = nil;
    }
}

#pragma mark - UISearchControllerDelegate

- (void)didPresentSearchController:(UISearchController *)searchController {
    switch (self.contactsMode) {
        case ContactsModeChatStartConversation:
        case ContactsModeChatAddParticipant:
        case ContactsModeChatAttachParticipant:
        case ContactsModeChatCreateGroup:
            searchController.searchBar.showsCancelButton = NO;
            break;
            
        default:
            searchController.searchBar.showsCancelButton = YES;
            break;
    }
}

#pragma mark - UISearchResultsUpdating

- (void)updateSearchResultsForSearchController:(UISearchController *)searchController {
    NSString *searchString = searchController.searchBar.text;
    if (searchController.isActive) {
        if ([searchString isEqualToString:@""]) {
            [self.searchVisibleUsersArray removeAllObjects];
        } else {
            NSPredicate *resultPredicate = [NSPredicate predicateWithFormat:@"SELF.mnz_fullName contains[c] %@", searchString];
            self.searchVisibleUsersArray = [self.visibleUsersArray filteredArrayUsingPredicate:resultPredicate].mutableCopy;
        }
    }
    
    [self.tableView reloadData];
}

#pragma mark - MEGAGlobalDelegate

- (void)onNodesUpdate:(MEGASdk *)api nodeList:(MEGANodeList *)nodeList {
    if (self.contactsMode != ContactsModeFolderSharedWith) {
        return;
    }
    
    NSUInteger size = nodeList.size.unsignedIntegerValue;
    for (NSUInteger i = 0; i < size; i++) {
        MEGANode *nodeUpdated = [nodeList nodeAtIndex:i];
        if (nodeUpdated.handle == self.node.handle) {
            self.node = nodeUpdated;
            [self reloadUI];
            break;
        }
    }
}

- (void)onUsersUpdate:(MEGASdk *)api userList:(MEGAUserList *)userList {
    BOOL userAdded = NO;
    
    NSMutableArray *updateContactsIndexPathMutableArray = [[NSMutableArray alloc] init];
    NSMutableDictionary *deleteContactsIndexPathMutableDictionary = [[NSMutableDictionary alloc] init];
    
    NSInteger count = userList.size.integerValue;
    for (NSInteger i = 0 ; i < count; i++) {
        MEGAUser *user = [userList userAtIndex:i];
        NSString *base64Handle = [MEGASdk base64HandleForUserHandle:user.handle];
        NSIndexPath *indexPath = [self.indexPathsMutableDictionary objectForKey:base64Handle];
        if (([user handle] == [[[MEGASdkManager sharedMEGASdk] myUser] handle]) && (user.isOwnChange != 0)) {
            continue;
        } else if (user.isOwnChange == 0) { //If the change is external, update the modified contacts
            switch (user.visibility) {
                case MEGAUserVisibilityHidden: { //If I deleted a contact
                    if (indexPath != nil) {
                        [deleteContactsIndexPathMutableDictionary setObject:user forKey:indexPath];
                    }
                    continue;
                }
                    
                case MEGAUserVisibilityVisible: {
                    if (indexPath == nil) {
                        userAdded = YES;
                    }
                    break;
                }
                    
                default:
                    break;
            }
            
            BOOL userHasChanged = [self userTypeHasChanged:user];
            if (userHasChanged && (indexPath != nil)) {
                [updateContactsIndexPathMutableArray addObject:indexPath];
            }
        } else if (user.isOwnChange != 0) { //If the change is internal
            if (user.visibility != MEGAUserVisibilityVisible) { //If I deleted a contact
                if (indexPath != nil) {
                    [deleteContactsIndexPathMutableDictionary setObject:user forKey:indexPath];
                }
            } else {
                if ((user.visibility == MEGAUserVisibilityVisible) && (indexPath == nil)) { //If someone has accepted me as contact
                    userAdded = YES;
                }
                continue;
            }
        }
    }
    
    if (userAdded) {
        [self reloadUI];
    } else {
        if (updateContactsIndexPathMutableArray.count != 0) {
            [self.tableView reloadRowsAtIndexPaths:updateContactsIndexPathMutableArray withRowAnimation:UITableViewRowAnimationAutomatic];
        }
        
        NSArray *deleteContactsOnIndexPathsArray = [deleteContactsIndexPathMutableDictionary allKeys];
        if (deleteContactsOnIndexPathsArray.count != 0) {
            for (NSIndexPath *indexPath in deleteContactsOnIndexPathsArray) {
                [self.visibleUsersArray removeObjectAtIndex:indexPath.row];
                MEGAUser *userToDelete = [deleteContactsIndexPathMutableDictionary objectForKey:indexPath];
                NSString *userToDeleteBase64Handle = [MEGASdk base64HandleForUserHandle:userToDelete.handle];
                [self.indexPathsMutableDictionary removeObjectForKey:userToDeleteBase64Handle];
            }
            [self.tableView deleteRowsAtIndexPaths:deleteContactsOnIndexPathsArray withRowAnimation:UITableViewRowAnimationAutomatic];
        }
    }
}

- (void)onContactRequestsUpdate:(MEGASdk *)api contactRequestList:(MEGAContactRequestList *)contactRequestList {
    MEGAContactRequestList *incomingContactsLists = [[MEGASdkManager sharedMEGASdk] incomingContactRequests];
    [self setContactRequestBarButtomItemWithValue:incomingContactsLists.size.integerValue];
}

#pragma mark - ItemListViewControllerProtocol

- (void)removeSelectedItem:(id)item {
    MEGAUser *user = (MEGAUser *)item;
    NSString *base64Handle = [MEGASdk base64HandleForUserHandle:user.handle];
    [self.tableView deselectRowAtIndexPath:[self.indexPathsMutableDictionary objectForKey:base64Handle] animated:YES];
    [self.selectedUsersArray removeObject:user];
    if (self.selectedUsersArray.count == 0) {
        [self removeUsersListSubview];
    }
}

#pragma mark - UIGestureRecognizerDelegate

- (BOOL)gestureRecognizer:(UIGestureRecognizer *)gestureRecognizer shouldRecognizeSimultaneouslyWithGestureRecognizer:(UIGestureRecognizer *)otherGestureRecognizer {
    if (gestureRecognizer == self.panOnTable) {
        return YES;
    } else {
        return NO;
    }
}

#pragma mark - MEGAChatDelegate

- (void)onChatOnlineStatusUpdate:(MEGAChatSdk *)api userHandle:(uint64_t)userHandle status:(MEGAChatStatus)onlineStatus inProgress:(BOOL)inProgress {
    if (inProgress) {
        return;
    }

    if (userHandle != api.myUserHandle) {
        NSString *base64Handle = [MEGASdk base64HandleForUserHandle:userHandle];
        NSIndexPath *indexPath = [self.indexPathsMutableDictionary objectForKey:base64Handle];
        if ([self.tableView.indexPathsForVisibleRows containsObject:indexPath]) {
            ContactTableViewCell *cell = (ContactTableViewCell *)[self.tableView cellForRowAtIndexPath:indexPath];
            cell.onlineStatusView.backgroundColor = [UIColor mnz_colorForStatusChange:onlineStatus];
            cell.shareLabel.text = [NSString chatStatusString:onlineStatus];
            if (onlineStatus < MEGAChatStatusOnline) {
                [MEGASdkManager.sharedMEGAChatSdk requestLastGreen:userHandle];
            }
        }
    }
}

- (void)onChatPresenceLastGreen:(MEGAChatSdk *)api userHandle:(uint64_t)userHandle lastGreen:(NSInteger)lastGreen {

    if (userHandle != api.myUserHandle && (self.contactsMode >= ContactsModeChatStartConversation || self.contactsMode == ContactsModeDefault)) {
        MEGAChatStatus chatStatus = [[MEGASdkManager sharedMEGAChatSdk] userOnlineStatus:userHandle];
        if (chatStatus < MEGAChatStatusOnline) {
            NSString *base64Handle = [MEGASdk base64HandleForUserHandle:userHandle];
            NSIndexPath *indexPath = [self.indexPathsMutableDictionary objectForKey:base64Handle];
            
            if ([self.tableView.indexPathsForVisibleRows containsObject:indexPath]) {
                ContactTableViewCell *cell = (ContactTableViewCell *)[self.tableView cellForRowAtIndexPath:indexPath];
                cell.shareLabel.text = [NSString mnz_lastGreenStringFromMinutes:lastGreen];
            }
        }
    }
}

@end
