#import "ContactsViewController.h"

#import "SVProgressHUD.h"
#import "UIImage+GKContact.h"
#import "UIScrollView+EmptyDataSet.h"

#import "Helper.h"
#import "MEGAInviteContactRequestDelegate.h"
#import "MEGANavigationController.h"
#import "MEGANode+MNZCategory.h"
#import "MEGAReachabilityManager.h"
#import "MEGARemoveContactRequestDelegate.h"
#import "MEGAShareRequestDelegate.h"
#import "MEGA-Swift.h"
#import "MEGAUser+MNZCategory.h"
#import "NSFileManager+MNZCategory.h"
#import "NSString+MNZCategory.h"
#import "UIImage+MNZCategory.h"
#import "UITextField+MNZCategory.h"
#import "UIViewController+MNZCategory.h"

#import "ContactDetailsViewController.h"
#import "ContactLinkQRViewController.h"
#import "ContactTableViewCell.h"
#import "ContactRequestsViewController.h"
#import "EmptyStateView.h"
#import "ItemListViewController.h"
#import "NSArray+MNZCategory.h"

@import ChatRepo;
@import MEGAL10nObjc;
@import MEGAUIKit;
@import MEGASDKRepo;

@interface ContactsViewController () <UISearchBarDelegate, UISearchResultsUpdating, DZNEmptyDataSetSource, DZNEmptyDataSetDelegate, MEGAGlobalDelegate, ItemListViewControllerDelegate, UISearchControllerDelegate, UIGestureRecognizerDelegate, MEGAChatDelegate, ContactLinkQRViewControllerDelegate, CNContactPickerDelegate, UIAdaptivePresentationControllerDelegate>

@property (strong, nonatomic) ContactsTableViewHeader *contactsTableViewHeader;

@property (nonatomic, strong) NSMutableArray<NSMutableArray *> *visibleUsersIndexedMutableArray;
@property (nonatomic, strong) NSMutableArray<MEGAUser *> *recentlyAddedUsersArray;

@property (nonatomic, strong) NSMutableArray *outSharesForNodeMutableArray;
@property (nonatomic, strong) NSMutableArray<MEGAShare *> *pendingShareUsersArray;
@property (nonatomic) NSArray<MEGAChatListItem *> *recentsArray;

@property (weak, nonatomic) IBOutlet UIBarButtonItem *addBarButtonItem;
@property (weak, nonatomic) IBOutlet UIBarButtonItem *selectAllBarButtonItem;
@property (weak, nonatomic) IBOutlet UIBarButtonItem *editBarButtonItem;
@property (weak, nonatomic) IBOutlet UIBarButtonItem *addParticipantBarButtonItem;
@property (weak, nonatomic) IBOutlet UIBarButtonItem *createGroupBarButtonItem;

@property (weak, nonatomic) IBOutlet UIToolbar *toolbar;
@property (weak, nonatomic) IBOutlet UIBarButtonItem *deleteBarButtonItem;
@property (weak, nonatomic) IBOutlet UIBarButtonItem *inviteBarButtonItem;

@property (weak, nonatomic) IBOutlet UIBarButtonItem *cancelBarButtonItem;
@property (weak, nonatomic) IBOutlet NSLayoutConstraint *itemListViewHeightConstraint;

@property (weak, nonatomic) IBOutlet UIBarButtonItem *insertAnEmailBarButtonItem;
@property (strong, nonatomic) NSString *insertedEmail;
@property (strong, nonatomic) NSString *insertedGroupName;

@property (nonatomic, strong) NSMutableDictionary *indexPathsMutableDictionary;

@property (nonatomic, strong) MEGAUser *userTapped;

@property (nonatomic, getter=isKeyRotationEnabled) BOOL keyRotationEnabled;

@property (nonatomic, strong) NSMutableArray *searchVisibleUsersArray;

@property (strong, nonatomic) ItemListViewController *itemListVC;

@property (nonatomic) UIPanGestureRecognizer *panOnTable;

@property (weak, nonatomic) IBOutlet UITextField *enterGroupNameTextField;

@property (weak, nonatomic) IBOutlet UILabel *encryptedKeyRotationLabel;

@property (weak, nonatomic) IBOutlet UILabel *getChatLinkLabel;
@property (weak, nonatomic) IBOutlet UILabel *keyRotationFooterLabel;

@property (weak, nonatomic) IBOutlet UISwitch *allowNonHostToAddParticipantsSwitch;
@property (weak, nonatomic) IBOutlet UILabel *allowNonHostToAddParticipantsLabel;

@property (weak, nonatomic) IBOutlet UISwitch *chatLinkSwitch;

@property (weak, nonatomic) IBOutlet UIStackView *getChatLinkStackView;


@property (weak, nonatomic) IBOutlet UIStackView *optionsStackView;

@property (strong, nonatomic) MEGAUser *detailUser;
@property (strong, nonatomic) NSString *currentSearch;

@property (nonatomic) EnterGroupNameTextFieldDelegate *enterGroupNameTextFieldDelegate;

@property (nonatomic, strong) NSArray<NSNumber *> *startConversationOptions;

@end

@implementation ContactsViewController

#pragma mark - Lifecycle

- (void)viewDidLoad {
    [super viewDidLoad];
    
    //White background for the view behind the table view
    self.tableView.backgroundView = UIView.alloc.init;
    
    self.tableView.emptyDataSetSource = self;
    self.tableView.emptyDataSetDelegate = self;
    
    self.searchController = [UISearchController customSearchControllerWithSearchResultsUpdaterDelegate:self searchBarDelegate:self];
    self.searchController.delegate = self;
    
    [self.createGroupBarButtonItem setTitleTextAttributes:@{NSForegroundColorAttributeName : [UIColor colorWithRed:1 green:1 blue:1 alpha:.5]} forState:UIControlStateDisabled];
    
    [self setupSubscriptions];
    [self.viewModel showAlertForSensitiveDescendants:self.nodesArray];
    [self.viewModel didLoadView];
    [self setupContacts];
    
    self.panOnTable = [[UIPanGestureRecognizer alloc] initWithTarget:self action:@selector(shouldDismissSearchController)];
    self.panOnTable.delegate = self;
    
    self.tableView.tableFooterView = [[UIView alloc] initWithFrame:CGRectZero];
    
    [self.tableView registerNib:[UINib nibWithNibName:@"GenericHeaderFooterView" bundle:nil] forHeaderFooterViewReuseIdentifier:@"GenericHeaderFooterViewID"];
        
    [MEGASdk.shared addMEGARequestDelegate:self queueType:ListenerQueueTypeGlobalBackground];
    
    if (self.contactsMode == ContactsModeChatNamingGroup) {
        self.enterGroupNameTextField.placeholder = LocalizedString(@"Enter group name", @"Title of the dialog shown when the user it is creating a chat link and the chat has not title");
        self.enterGroupNameTextFieldDelegate = EnterGroupNameTextFieldDelegate.new;
        self.enterGroupNameTextField.delegate = self.enterGroupNameTextFieldDelegate;
        [self.allowNonHostToAddParticipantsSwitch setOn:YES];
        self.allowNonHostToAddParticipantsLabel.text = LocalizedString(@"meetings.addContacts.allowNonHost.message", @"Message to allow non host to add contacts in the group chat and meeting");
    }
    
    [self setupColors];
    
    if ([[NSProcessInfo processInfo] operatingSystemVersion].majorVersion >= 15) {
        self.tableView.sectionHeaderTopPadding = 0.0f;
    }
    
    [AppearanceManager forceSearchBarUpdate:self.searchController.searchBar 
       backgroundColorWhenDesignTokenEnable:[UIColor surface1Background]
                            traitCollection:self.traitCollection];
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    
    self.navigationController.presentationController.delegate = self;
    
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(internetConnectionChanged) name:kReachabilityChangedNotification object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(keyboardWillShow:) name:UIKeyboardWillShowNotification object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(keyboardWillHide:) name:UIKeyboardWillHideNotification object:nil];
    [self addNicknamesLoadedNotification];
    
    [MEGASdk.shared addMEGAGlobalDelegate:self];
    [MEGAChatSdk.shared addChatDelegate:self];
    [[MEGAReachabilityManager sharedManager] retryPendingConnections];
    
    [self reloadUI];
}

- (void)viewWillDisappear:(BOOL)animated {
    [super viewWillDisappear:animated];
    
    [[NSNotificationCenter defaultCenter] removeObserver:self name:kReachabilityChangedNotification object:nil];
    [[NSNotificationCenter defaultCenter] removeObserver:self name:UIKeyboardWillShowNotification object:nil];
    [[NSNotificationCenter defaultCenter] removeObserver:self name:UIKeyboardWillHideNotification object:nil];
    [self removeNicknamesLoadedNotification];
    
    [MEGASdk.shared removeMEGAGlobalDelegateAsync:self];
    [MEGAChatSdk.shared removeChatDelegate:self];
    
    if (self.isMovingFromParentViewController || [self.navigationController isBeingDismissed]) {
        [MEGASdk.shared removeMEGARequestDelegateAsync:self];
    }
}

- (void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];
    
    if (self.contactsMode == ContactsModeDefault) {
        MEGAContactRequestList *incomingContactsLists = [MEGASdk.shared incomingContactRequests];
        if (!self.avoidPresentIncomingPendingContactRequests && incomingContactsLists.size > 0) {
            ContactRequestsViewController *contactRequestsVC = [[UIStoryboard storyboardWithName:@"Contacts" bundle:nil] instantiateViewControllerWithIdentifier:@"ContactsRequestsViewControllerID"];
            
            [self.navigationController pushViewController:contactRequestsVC animated:YES];
            self.avoidPresentIncomingPendingContactRequests = YES;
        }
    }
}

- (void)viewWillTransitionToSize:(CGSize)size withTransitionCoordinator:(id<UIViewControllerTransitionCoordinator>)coordinator {
    [super viewWillTransitionToSize:size withTransitionCoordinator:coordinator];
    
    [coordinator animateAlongsideTransition:^(id<UIViewControllerTransitionCoordinatorContext> context) {
        [self.tableView reloadEmptyDataSet];
    } completion:nil];
}

- (ContactsViewModel *)viewModel {
    if (_viewModel == nil) {
        [self createViewModel];
    }
    return _viewModel;
}


#pragma mark - Private

- (void)setupContacts {
    [self setupWarningHeader];
    self.indexPathsMutableDictionary = [[NSMutableDictionary alloc] init];
    
    switch (self.contactsMode) {
        case ContactsModeDefault: {
            [self setupContactsTableViewHeader];
            
            NSArray *buttonsItems = @[self.addBarButtonItem];
            self.navigationItem.rightBarButtonItems = buttonsItems;
            break;
        }
            
        case ContactsModeShareFoldersWith: {
            self.cancelBarButtonItem.title = LocalizedString(@"cancel", @"");
            [self.cancelBarButtonItem setTitleTextAttributes:@{NSFontAttributeName:[UIFont preferredFontForTextStyle:UIFontTextStyleBody]} forState:UIControlStateNormal];
            self.navigationItem.leftBarButtonItems = @[self.cancelBarButtonItem];
            
            self.shareFolderWithBarButtonItem.title = LocalizedString(@"next", @"Button title which, if tapped, will show the share access level selection to proceed to sharing");
            [self.shareFolderWithBarButtonItem setTitleTextAttributes:@{NSFontAttributeName:[UIFont mnz_preferredFontWithStyle:UIFontTextStyleBody weight:UIFontWeightMedium]} forState:UIControlStateNormal];
            self.navigationItem.rightBarButtonItems = @[self.shareFolderWithBarButtonItem];
            self.shareFolderWithBarButtonItem.enabled = NO;
            
            self.insertAnEmailBarButtonItem.title = LocalizedString(@"inviteContact", @"Text shown when the user tries to make a call and the receiver is not a contact");
            [self.insertAnEmailBarButtonItem setTitleTextAttributes:@{NSFontAttributeName:[UIFont preferredFontForTextStyle:UIFontTextStyleBody]} forState:UIControlStateNormal];
            
            UIBarButtonItem *flexibleItem = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemFlexibleSpace target:nil action:nil];
            self.navigationController.topViewController.toolbarItems = @[flexibleItem, self.insertAnEmailBarButtonItem];
            [self.navigationController setToolbarHidden:NO];
            
            [self editTapped:self.editBarButtonItem];
            [self setupWarningHeader];
            break;
        }
            
        case ContactsModeFolderSharedWith: {
            self.editBarButtonItem.title = LocalizedString(@"select", @"Caption of a button to select files");
            self.navigationItem.rightBarButtonItems = @[self.editBarButtonItem];
            
            UIBarButtonItem *flexibleItem = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemFlexibleSpace target:nil action:nil];
            self.deleteBarButtonItem.title = LocalizedString(@"remove", @"Title for the action that allows to remove a file or folder");
            [self.deleteBarButtonItem setTitleTextAttributes:@{NSFontAttributeName:[UIFont preferredFontForTextStyle:UIFontTextStyleBody]} forState:UIControlStateNormal];
            self.toolbar.items = @[flexibleItem, self.deleteBarButtonItem];
            [self setupWarningHeader];
            break;
        }
            
        case ContactsModeChatStartConversation: {
            self.cancelBarButtonItem.title = LocalizedString(@"cancel", @"Button title to cancel something");
            self.navigationItem.rightBarButtonItems = @[self.cancelBarButtonItem];
            BOOL isEmpty = self.visibleUsersArray.count == 0;
            if (isEmpty) {
                self.noContactsLabel.text = LocalizedString(@"contactsEmptyState_title", @"Title shown when the Contacts section is empty, when you have not added any contact.");
                self.noContactsDescriptionLabel.text = LocalizedString(@"Invite contacts and start chatting securely with MEGA’s encrypted chat.", @"Text encouraging the user to invite contacts to MEGA");
                self.inviteContactButton.titleLabel.text = LocalizedString(@"inviteContact", @"Text shown when the user tries to make a call and the receiver is not a contact");
            }
            
            [self showEmptyScreen:isEmpty];
            [self hideToolbar:isEmpty];
            break;
        }
            
        case ContactsModeChatAddParticipant:
        case ContactsModeInviteParticipants:
        case ContactsModeScheduleMeeting:
        case ContactsModeChatAttachParticipant: {
            self.cancelBarButtonItem.title = LocalizedString(@"cancel", @"");
            self.addParticipantBarButtonItem.title = (self.contactsMode == ContactsModeInviteParticipants) ? LocalizedString(@"invite", @"") : (self.contactsMode == ContactsModeScheduleMeeting) ? LocalizedString(@"next", @"") : LocalizedString(@"ok", @"");
            [self setTableViewEditing:YES animated:NO];
            self.navigationItem.leftBarButtonItem = self.cancelBarButtonItem;
            self.navigationItem.rightBarButtonItems = @[self.addParticipantBarButtonItem];
            self.navigationController.toolbarHidden = YES;
            self.addParticipantBarButtonItem.enabled = !(self.contactsMode == ContactsModeInviteParticipants);
            break;
        }
            
        case ContactsModeChatCreateGroup: {
            [self setTableViewEditing:YES animated:NO];
            self.createGroupBarButtonItem.title = LocalizedString(@"next", @"");
            [self.createGroupBarButtonItem setTitleTextAttributes:[NSDictionary dictionaryWithObjectsAndKeys:[UIFont mnz_preferredFontWithStyle:UIFontTextStyleBody weight:UIFontWeightMedium], NSFontAttributeName, nil] forState:UIControlStateNormal];
            self.cancelBarButtonItem.title = LocalizedString(@"cancel", @"Button title to cancel something");
            self.navigationItem.rightBarButtonItems = @[self.createGroupBarButtonItem];
            self.navigationItem.leftBarButtonItem = self.cancelBarButtonItem;
            self.navigationController.toolbarHidden = YES;
            break;
        }
            
        case ContactsModeChatNamingGroup: {
            
            self.createGroupBarButtonItem.title = LocalizedString(@"createFolderButton", @"");
            self.encryptedKeyRotationLabel.text = LocalizedString(@"Encrypted Key Rotation", @"Label in a cell where you can enable the 'Encrypted Key Rotation'");
            self.getChatLinkLabel.text = LocalizedString(@"Get Chat Link", @"Label in a cell where you can get the chat link");
            self.keyRotationFooterLabel.text = LocalizedString(@"Key rotation is slightly more secure, but does not allow you to create a chat link and new participants will not see past messages.", @"Footer text to explain what means 'Encrypted Key Rotation'");
            [self.createGroupBarButtonItem setTitleTextAttributes:[NSDictionary dictionaryWithObjectsAndKeys:[UIFont mnz_preferredFontWithStyle:UIFontTextStyleBody weight:UIFontWeightMedium], NSFontAttributeName, nil] forState:UIControlStateNormal];
            self.navigationItem.rightBarButtonItems = @[self.createGroupBarButtonItem];
            [self.tableView setEditing:NO animated:YES];
            [self.enterGroupNameTextField becomeFirstResponder];
            
            break;
        }
            
    }
}

- (void)showInviteToolbarButtonIfNeeded {
    if ([self shouldShowInviteToolbarButtonWithIsEmpty:[self isListEmpty]]) {
        UIBarButtonItem *flexibleItem = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemFlexibleSpace target:nil action:nil];
        self.inviteBarButtonItem.title = LocalizedString(@"inviteContact", @"");
        [self.inviteBarButtonItem setTitleTextAttributes:@{NSFontAttributeName:[UIFont preferredFontForTextStyle:UIFontTextStyleBody]} forState:UIControlStateNormal];
        self.navigationController.topViewController.toolbarItems = @[flexibleItem, self.inviteBarButtonItem];
        [self.navigationController setToolbarHidden:NO];
    }
}

- (void)reloadUI {
    [self setNavigationBarTitles];
    
    [self setNavigationBarButtonItemsEnabled:MEGAReachabilityManager.isReachable];
    
    if (self.currentSearch != nil) {
        self.searchController.active = YES;
        self.searchController.searchBar.text = self.currentSearch;
        self.currentSearch = nil;
    }
    
    [self populateStartConversationOptions];
    
    self.visibleUsersArray = [[NSMutableArray alloc] init];
    [self.indexPathsMutableDictionary removeAllObjects];
    
    NSArray<MEGAUser *> *visibleContactsArray = MEGASdk.shared.visibleContacts;
    NSMutableArray *usersArray = [[NSMutableArray alloc] init];
    
    switch (self.contactsMode) {
        case ContactsModeDefault: {
            self.visibleUsersIndexedMutableArray = NSMutableArray.new;
            for (NSUInteger i = 0; i < UILocalizedIndexedCollation.currentCollation.sectionIndexTitles.count; i++) {
                NSMutableArray<MEGAUser *> *mutableArray = NSMutableArray.new;
                [self.visibleUsersIndexedMutableArray addObject:mutableArray];
            }
            self.recentlyAddedUsersArray = NSMutableArray.new;
            
            for (MEGAUser *user in visibleContactsArray) {
                [usersArray addObject:user];
                
                [self addUserToIndexedTableView:user];
            }
            
            [self sortUsersInEachSectionOfTheIndexedTableView];
            
            self.visibleUsersArray = [[usersArray sortedArrayUsingComparator:self.userSortComparator] mutableCopy];
            break;
        }
            
        case ContactsModeShareFoldersWith: {
            for (MEGAUser *user in visibleContactsArray) {
                BOOL alreadySharing = NO;
                MEGANode *node = self.nodesArray.firstObject;
                for (MEGAShare *shareUser in node.outShares) {
                    if ([shareUser.user isEqualToString:user.email]) {
                        alreadySharing = YES;
                        break;
                    }
                }
                if (!alreadySharing) {
                    [usersArray addObject:user];
                }
            }
            
            self.visibleUsersArray = [[usersArray sortedArrayUsingComparator:self.userSortComparator] mutableCopy];
            break;
        }
            
        case ContactsModeFolderSharedWith: {
            self.pendingShareUsersArray = NSMutableArray.new;
            
            self.outSharesForNodeMutableArray = self.node.outShares;
            for (MEGAShare *share in self.outSharesForNodeMutableArray) {
                if (share.isPending) {
                    [self.pendingShareUsersArray addObject:share];
                } else {
                    MEGAUser *user = [MEGASdk.shared contactForEmail:share.user];
                    if (user) {
                        [self.visibleUsersArray addObject:user];
                    }
                }
            }
            
            if (self.visibleUsersArray.count == 0) {
                self.editBarButtonItem.enabled = NO;
                self.addParticipantBarButtonItem.enabled = NO;
                self.tableView.tableHeaderView = nil;
            } else {
                [self.editBarButtonItem setEnabled:YES];
                self.addParticipantBarButtonItem.enabled = YES;
            }
            break;
        }
            
        case ContactsModeChatAddParticipant:
        case ContactsModeScheduleMeeting:
        case ContactsModeInviteParticipants: {
            for (MEGAUser *user in visibleContactsArray) {
                if ([self.participantsMutableDictionary objectForKey:[NSNumber numberWithUnsignedLongLong:user.handle]] == nil) {
                    [usersArray addObject:user];
                }
            }
            
            self.visibleUsersArray = [[usersArray sortedArrayUsingComparator:self.userSortComparator] mutableCopy];
            break;
        }
            
        default: { //ContactsModeChatStartConversation, ContactsModeChatAttachParticipant, ContactsModeChatCreateGroup and ContactsModeChatNamingGroup
            for (MEGAUser *user in visibleContactsArray) {
                [usersArray addObject:user];
            }
            
            self.visibleUsersArray = [[usersArray sortedArrayUsingComparator:self.userSortComparator] mutableCopy];
            break;
        }
    }
    
    [self.tableView reloadData];
    [self handleContactsNotVerifiedHeaderVisibility];
    
    if (self.contactsMode == ContactsModeDefault) {
        [self setupContactsTableViewHeader];
        self.tableView.tableHeaderView = self.contactsTableViewHeader;
    } else if (self.contactsMode == ContactsModeChatStartConversation) {
        self.recentsArray = [MEGAChatSdk.shared recentChatsWithMax:3];
        BOOL isEmpty = [self isListEmpty];
        [self showInviteToolbarButtonIfNeeded];
        [self showEmptyScreen:isEmpty];
        [self hideToolbar:isEmpty];
    } else if (self.contactsMode == ContactsModeChatNamingGroup) {
        self.tableView.tableHeaderView = self.chatNamingGroupTableViewHeader;
    }
    
    [self addSearchBarController];
}

- (BOOL)isListEmpty {
    return self.visibleUsersArray.count == 0;
}

- (void)populateStartConversationOptions {
    switch (self.chatOptionType) {
    case ChatOptionTypeNone:
        self.startConversationOptions = @[
            @(ContactsStartConversationNewGroupChat),
            @(ContactsStartConversationNewMeeting),
            @(ContactsStartConversationJoinMeeting)
        ];
        break;
        
    case ChatOptionTypeMeeting:
        self.startConversationOptions = @[
            @(ContactsStartConversationNewMeeting),
            @(ContactsStartConversationJoinMeeting)
        ];
        
    case ChatOptionTypeNonMeeting:
        self.startConversationOptions = @[
            @(ContactsStartConversationNewGroupChat),
        ];
        
    default:
        break;
    }
}

- (NSComparator)userSortComparator {
    return ^NSComparisonResult(MEGAUser *a, MEGAUser *b) {
        return [a.mnz_displayName compare:b.mnz_displayName options:NSCaseInsensitiveSearch];
    };
}

- (void)addUserToIndexedTableView:(MEGAUser *)user {
    MOUser *moUser = [MEGAStore.shareInstance fetchUserWithUserHandle:user.handle];
    
    NSDateComponents *components = [NSCalendar.currentCalendar components:NSCalendarUnitDay fromDate:user.timestamp toDate:NSDate.date options:0];
    NSInteger daysSinceUserAdded = components.day;
    if (daysSinceUserAdded <= 3) {
        if (moUser.interactedWith.boolValue) {
            [self indexedSectionForUser:user];
        } else {
            [self.recentlyAddedUsersArray addObject:user];
        }
    } else {
        if (!moUser.interactedWith.boolValue) {
            [MEGAStore.shareInstance updateUserWithHandle:user.handle interactedWith:YES];
        }
        
        [self indexedSectionForUser:user];
    }
}

- (void)indexedSectionForUser:(MEGAUser *)user {
    NSInteger sectionForUser = [UILocalizedIndexedCollation.currentCollation sectionForObject:user collationStringSelector:@selector(mnz_displayName)];
    NSMutableArray *usersInSectionMutableArray = self.visibleUsersIndexedMutableArray[sectionForUser];
    [usersInSectionMutableArray addObject:user];
}

- (void)sortUsersInEachSectionOfTheIndexedTableView {
    for (NSInteger section = 0; section < self.visibleUsersIndexedMutableArray.count; section++) {
        NSMutableArray *mutableArray = self.visibleUsersIndexedMutableArray[section];
        NSArray *sortedArray = [UILocalizedIndexedCollation.currentCollation sortedArrayFromArray:mutableArray collationStringSelector:@selector(mnz_displayName)];
        self.visibleUsersIndexedMutableArray[section] = sortedArray.mutableCopy;
    }
}

- (void)internetConnectionChanged {
    BOOL boolValue = MEGAReachabilityManager.isReachable;
    [self setNavigationBarButtonItemsEnabled:boolValue];
    
    if (!boolValue) {
        [self hideSearchIfNotActive];
        
        if (self.visibleUsersArray.count == 0) {
            self.tableView.tableFooterView = UIView.new;
        }
    }
    
    boolValue ? [self reloadUI] : [self.tableView reloadData];
}

- (void)setNavigationBarButtonItemsEnabled:(BOOL)boolValue {
    self.addBarButtonItem.enabled = boolValue;
    self.editButtonItem.enabled = boolValue;
    self.createGroupBarButtonItem.enabled = boolValue;
}

- (void)hideSearchIfNotActive {
    if (!self.searchController.isActive) {
        self.tableView.tableHeaderView = nil;
    }
}

- (void)selectPermissionsFromButton:(UIBarButtonItem *)sourceButton {
    if ([MEGAReachabilityManager isReachableHUDIfNot]) {
        id sender = sourceButton ? sourceButton : self.view;
        ActionSheetViewController *shareFolderActionSheet = [self prepareShareFolderAlertControllerFromSender:sender];
        [self presentViewController:shareFolderActionSheet animated:YES completion:nil];
    }
}

- (void)selectPermissionsFromCell:(ContactTableViewCell *)cell {
    if ([MEGAReachabilityManager isReachableHUDIfNot]) {
        ActionSheetViewController *shareFolderActionSheet = [self prepareShareFolderAlertControllerFromSender:cell.permissionsImageView];
        [self presentViewController:shareFolderActionSheet animated:YES completion:nil];
    }
}

- (ActionSheetViewController *)prepareShareFolderAlertControllerFromSender:(id)sender {
    __weak __typeof__(self) weakSelf = self;
    
    NSMutableArray<ActionSheetAction *> *actions = NSMutableArray.new;
    [actions addObject:[ActionSheetAction.alloc initWithTitle:LocalizedString(@"fullAccess", @"Permissions given to the user you share your folder with") detail:nil image:[UIImage imageNamed:@"fullAccessPermissions"] style:UIAlertActionStyleDefault actionHandler:^{
        [weakSelf shareNodesWithLevel:MEGAShareTypeAccessFull];
    }]];
    [actions addObject:[ActionSheetAction.alloc initWithTitle:LocalizedString(@"readAndWrite", @"Permissions given to the user you share your folder with") detail:nil image:[UIImage imageNamed:@"readWritePermissions"] style:UIAlertActionStyleDefault actionHandler:^{
        [weakSelf shareNodesWithLevel:MEGAShareTypeAccessReadWrite];
    }]];
    [actions addObject:[ActionSheetAction.alloc initWithTitle:LocalizedString(@"readOnly", @"Permissions given to the user you share your folder with") detail:nil image:[UIImage imageNamed:@"readPermissions"] style:UIAlertActionStyleDefault actionHandler:^{
        [weakSelf shareNodesWithLevel:MEGAShareTypeAccessRead];
    }]];
    ActionSheetViewController *shareFolderActionSheet = [ActionSheetViewController.alloc initWithActions:actions headerTitle:LocalizedString(@"permissions", @"Title of the view that shows the kind of permissions (Read Only, Read & Write or Full Access) that you can give to a shared folder") dismissCompletion:nil sender:sender];
    
    return shareFolderActionSheet;
}

- (void)shareNodesWithLevel:(MEGAShareType)shareType nodes:(NSArray *)nodes {
    [SVProgressHUD setDefaultMaskType:SVProgressHUDMaskTypeClear];
    [SVProgressHUD show];
    [self.contactsViewControllerDelegate nodeEditCompleted:YES];
    
    if (self.contactsMode == ContactsModeShareFoldersWith) {
        MEGAShareRequestDelegate *shareRequestDelegate = [[MEGAShareRequestDelegate alloc] initWithNumberOfRequests:nodes.count completion:^{
            if (self.searchController.isActive) {
                [self.searchController dismissViewControllerAnimated:YES completion:^{
                    [self dismissViewControllerAnimated:YES completion:nil];
                }];
            } else {
                [self dismissViewControllerAnimated:YES completion:nil];
            }
        }];
        for (id userToShare in self.selectedUsersArray) {
            if ([userToShare isKindOfClass:MEGAUser.class]) {
                MEGAUser *user = (MEGAUser *)userToShare;
                for (MEGANode *node in nodes) {
                    [MEGASdk.shared shareNode:node withUser:user level:shareType delegate:shareRequestDelegate];
                }
            } else if ([userToShare isKindOfClass:NSString.class]) {
                for (MEGANode *node in nodes) {
                    [MEGASdk.shared shareNode:node withEmail:userToShare level:shareType delegate:shareRequestDelegate];
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
        [MEGASdk.shared shareNode:self.node withUser:self.userTapped level:shareType delegate:shareRequestDelegate];
    }
}

- (void)shareNodesWithLevel:(MEGAShareType)shareType {
    [self shareNodesWithLevel:shareType nodes:self.nodesArray];
}

- (BOOL)userTypeHasChanged:(MEGAUser *)user {
    BOOL userHasChanged = NO;
    
    if ([user hasChangedType:MEGAUserChangeTypeAvatar]) {
        [user removeAvatarFromLocalCache];
        userHasChanged = YES;
    } else if ([user hasChangedType:MEGAUserChangeTypeFirstname] || [user hasChangedType:MEGAUserChangeTypeLastname] || [user hasChangedType:MEGAUserChangeTypeEmail]) {
        userHasChanged = YES;
    }
    
    return userHasChanged;
}


- (void)addContactAlertTextFieldDidChange:(UITextField *)textField {
    UIAlertController *addContactFromEmailAlertController = (UIAlertController *)self.presentedViewController;
    if ([addContactFromEmailAlertController isKindOfClass:UIAlertController.class]) {
        UIAlertAction *rightButtonAction = addContactFromEmailAlertController.actions.lastObject;
        rightButtonAction.enabled = (!textField.text.mnz_isEmpty && textField.text.mnz_isValidEmail);
    }
}

- (void)setTableViewEditing:(BOOL)editing animated:(BOOL)animated {
    [self.tableView setEditing:editing animated:animated];
    
    if (editing) {
        self.editBarButtonItem.title = LocalizedString(@"cancel", @"Button title to cancel something");
        [self.addBarButtonItem setEnabled:NO];
        
        UITabBar *tabBar = self.tabBarController.tabBar;
        if (tabBar && ![self.tabBarController.view.subviews containsObject:self.toolbar]) {
            [self.toolbar setAlpha:0.0];
            [self.tabBarController.view addSubview:self.toolbar];
            self.toolbar.translatesAutoresizingMaskIntoConstraints = NO;
            [self.toolbar setBackgroundColor:[UIColor surface1Background]];
            
            NSLayoutAnchor *bottomAnchor = tabBar.safeAreaLayoutGuide.bottomAnchor;
            
            [NSLayoutConstraint activateConstraints:@[[self.toolbar.topAnchor constraintEqualToAnchor:tabBar.topAnchor constant:0],
                                                      [self.toolbar.leadingAnchor constraintEqualToAnchor:tabBar.leadingAnchor constant:0],
                                                      [self.toolbar.trailingAnchor constraintEqualToAnchor:tabBar.trailingAnchor constant:0],
                                                      [self.toolbar.bottomAnchor constraintEqualToAnchor:bottomAnchor constant:0]]];
            
            [UIView animateWithDuration:0.33f animations:^ {
                [self.toolbar setAlpha:1.0];
            }];
        } else if (self.navigationController.isToolbarHidden) {
            self.navigationController.topViewController.toolbarItems = self.toolbar.items;
            [self.navigationController setToolbarHidden:NO animated:animated];
            [self.navigationController.toolbar setBackgroundColor:[UIColor surface1Background]];
        }
        for (ContactTableViewCell *cell in self.tableView.visibleCells) {
            UIView *view = [[UIView alloc] init];
            view.backgroundColor = UIColor.clearColor;
            cell.selectedBackgroundView = view;
        }
    } else {
        self.editBarButtonItem.title = LocalizedString(@"select", @"Caption of a button to select files");
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
        if (self.contactsMode == ContactsModeChatAddParticipant || self.contactsMode == ContactsModeInviteParticipants || self.contactsMode == ContactsModeScheduleMeeting) {
            self.addParticipantBarButtonItem.enabled = NO;
        }
    }
}

- (nullable MEGAUser *)getUserAndSetIndexPath:(NSIndexPath *)indexPath {
    MEGAUser *user = [self userAtIndexPath:indexPath];
    if (user) {
        NSString *base64Handle = [MEGASdk base64HandleForUserHandle:user.handle];
        [self.indexPathsMutableDictionary setObject:indexPath forKey:base64Handle];
    }
    
    return user;
}

- (nullable MEGAUser *)userAtIndexPath:(NSIndexPath *)indexPath {
    if (!indexPath) {
        return nil;
    }
    
    MEGAUser *user = nil;
    switch (self.contactsMode) {
        case ContactsModeDefault: {
            if (self.searchController.isActive && ![self.searchController.searchBar.text isEqual:@""]) {
                user = [self.searchVisibleUsersArray objectOrNilAtIndex:indexPath.row];
            } else {
                if (indexPath.section == 0) {
                    user = self.recentlyAddedUsersArray[indexPath.row];
                } else {
                    NSArray *sectionArray = self.visibleUsersIndexedMutableArray[[self currentIndexedSection:indexPath.section]];
                    user = [sectionArray objectOrNilAtIndex:indexPath.row];
                }
            }
            break;
        }
            
        case ContactsModeFolderSharedWith: {
            if (indexPath.section == 0 && indexPath.row > 0) {
                user = [self.visibleUsersArray objectOrNilAtIndex:indexPath.row - 1];
            }
            break;
        }
            
        case ContactsModeChatNamingGroup: {
            if (indexPath.row == self.selectedUsersArray.count) {
                user = MEGASdk.shared.myUser;
            } else {
                user = [self.selectedUsersArray objectOrNilAtIndex:indexPath.row];
            }
            break;
        }
            
        default: { //ContactsModeShareFoldersWith, ContactsModeChatStartConversation, ContactsModeChatAddParticipant, ContactsModeChatAttachParticipant and ContactsModeChatCreateGroup
            if (self.searchController.isActive && ![self.searchController.searchBar.text isEqual:@""]) {
                user = [self.searchVisibleUsersArray objectOrNilAtIndex:indexPath.row];
            } else {
                user = [self.visibleUsersArray objectOrNilAtIndex:indexPath.row];
            }
            break;
        }
    }
    
    return user;
}

- (NSIndexPath *)indexPathForUser:(MEGAUser *)user {
    if (self.searchController.isActive && ![self.searchController.searchBar.text isEqual: @""]) {
        for (MEGAUser *userInList in self.searchVisibleUsersArray) {
            if (user.handle == userInList.handle) {
                return [NSIndexPath indexPathForRow:[self.searchVisibleUsersArray indexOfObject:userInList] inSection:0];
            }
        }
    } else {
        for (MEGAUser *userInList in self.visibleUsersArray) {
            if (user.handle == userInList.handle) {
                return [NSIndexPath indexPathForRow:[self.visibleUsersArray indexOfObject:userInList] inSection:0];
            }
        }
    }
    
    return nil;
}

- (void)updatePendingContactRequestsLabel {
    if (self.contactsMode == ContactsModeDefault) {
        MEGAContactRequestList *incomingContactsLists = MEGASdk.shared.incomingContactRequests;
        self.contactsTableViewHeader.requestsDetailLabel.text = incomingContactsLists.size == 0 ? @"" : [NSString stringWithFormat:@"%ld", (long)incomingContactsLists.size];

    }
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

- (void)addItemsToList:(NSArray<ItemListModel *> *)items {
    if (self.childViewControllers.count) {
        for (ItemListModel *item in items) {
            [self.itemListVC addItem:item];
        }
    } else {
        [self insertItemListSubviewWithCompletion:^{
            for (ItemListModel *item in items) {
                [self.itemListVC addItem:item];
            }
        }];
    }
    if (self.contactsMode == ContactsModeShareFoldersWith) {
        self.shareFolderWithBarButtonItem.enabled = YES;
    }
}

- (void)viewDidLayoutSubviews{
    [super viewDidLayoutSubviews];
    [self layoutFooter];
}

- (void)insertItemListSubviewWithCompletion:(void (^ __nullable)(void))completion {
    [UIView animateWithDuration:.25 animations:^{
        self.itemListViewHeightConstraint.constant = 110;
        [self.view layoutIfNeeded];
    } completion:^(BOOL finished) {
        ItemListViewController *usersList = [[UIStoryboard storyboardWithName:@"ItemListViewController" bundle:nil] instantiateViewControllerWithIdentifier:@"ItemListViewControllerID"];
        self.itemListVC = usersList;
        self.itemListVC.itemListDelegate = self;
        [self addChildViewController:usersList];
        usersList.view.frame = self.itemListView.bounds;
        [self.itemListView addSubview:usersList.view];
        [usersList didMoveToParentViewController:self];
        if (completion) {
            completion();
        }
    }];
}

- (void)removeUsersListSubview {
    if (self.contactsMode == ContactsModeShareFoldersWith) {
        self.shareFolderWithBarButtonItem.enabled = NO;
    }
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
    //FIXME: Make it appear by default
    if (self.visibleUsersArray.count == 0) { //FIXME: Not true for each mode
        return;
    }
    
    switch (self.contactsMode) {
        case ContactsModeShareFoldersWith:
        case ContactsModeChatAttachParticipant:
        case ContactsModeChatAddParticipant:
        case ContactsModeScheduleMeeting:
        case ContactsModeChatCreateGroup:
        case ContactsModeChatStartConversation:
        case ContactsModeInviteParticipants: {
            self.searchController.hidesNavigationBarDuringPresentation = NO;
            self.navigationItem.searchController = self.searchController;
            self.navigationItem.hidesSearchBarWhenScrolling = NO;
            [self setNavigationItemStackedPlacement];
            break;
        }
            
        case ContactsModeFolderSharedWith:
        case ContactsModeChatNamingGroup:
            break;
            
        default: {
            self.navigationItem.searchController = self.searchController;
            self.navigationItem.hidesSearchBarWhenScrolling = YES;
            break;
        }
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
        case ContactsModeShareFoldersWith:
        case ContactsModeInviteParticipants:
            if (self.searchController.isActive) {
                [self.searchController.searchBar resignFirstResponder];
            }
            break;
            
        default:
            break;
    }
}

- (void)newMeeting {
    if (MEGAChatSdk.shared.mnz_existsActiveCall) {
        [MeetingAlreadyExistsAlert showWithPresenter:self];
    } else {
        __weak typeof(UIViewController) *weakPresentingViewController = self.presentingViewController;
        [self dismissViewControllerAnimated:YES completion:^{
            MeetingCreatingViewRouter *router = [[MeetingCreatingViewRouter alloc] initWithViewControllerToPresent:weakPresentingViewController type:MeetingConfigurationTypeStart link:nil userhandle:0];
            [router start];
        }];
    }
}

- (void)joinMeeting {
    if (MEGAChatSdk.shared.mnz_existsActiveCall) {
        [MeetingAlreadyExistsAlert showWithPresenter:self];
    } else {
        [[[EnterMeetingLinkRouter alloc] initWithViewControllerToPresent:self isGuest:NO] start];
    }
}

- (void)showEmailContactPicker {
    CNContactPickerViewController *contactPickerController = [[CNContactPickerViewController alloc] init];
    contactPickerController.predicateForEnablingContact = [NSPredicate predicateWithFormat:@"emailAddresses.@count > 0"];
    contactPickerController.delegate = self;

    [self presentViewController:contactPickerController animated:YES completion:nil];
}

- (void)selectUser:(MEGAUser *)user {
    NSIndexPath *indexPath = [self indexPathForUser:user];
    if (indexPath) {
        [self tableView:self.tableView didSelectRowAtIndexPath:indexPath];
        [self.tableView reloadRowsAtIndexPaths:@[indexPath] withRowAnimation:UITableViewRowAnimationAutomatic];
    }
}

- (void)inviteEmailToShareFolder:(NSString *)email {
    MEGAUser *user = [MEGASdk.shared contactForEmail:email];
    if (user && user.visibility == MEGAUserVisibilityVisible) {
        [self selectUser:user];
    } else {
        [self addItemsToList:@[[ItemListModel.alloc initWithEmail:email]]];
        [self.selectedUsersArray addObject:email];
        [self handleContactsNotVerifiedHeaderVisibility];
    }
}

- (void)addNicknamesLoadedNotification {
    __weak typeof(self) weakself = self;
    [NSNotificationCenter.defaultCenter addObserverForName:MEGAAllUsersNicknameLoaded object:nil queue:NSOperationQueue.mainQueue usingBlock:^(NSNotification * _Nonnull note) {
        [weakself.tableView reloadData];
    }];
}

- (void)removeNicknamesLoadedNotification {
    [NSNotificationCenter.defaultCenter removeObserver:self name:MEGAAllUsersNicknameLoaded object:nil];
}

- (void)showContactDetailsForUser:(MEGAUser *)user {
    [self.navigationController pushViewController:[self contactDetailsWithUser:user] animated:YES];
}

- (ContactDetailsViewController *)contactDetailsWithUser:(MEGAUser *)user {
    ContactDetailsViewController *contactDetailsVC = [[UIStoryboard storyboardWithName:@"Contacts" bundle:nil] instantiateViewControllerWithIdentifier:@"ContactDetailsViewControllerID"];
    contactDetailsVC.contactDetailsMode = ContactDetailsModeDefault;
    contactDetailsVC.userEmail = user.email;
    contactDetailsVC.userName = user.mnz_fullName;
    contactDetailsVC.userHandle = user.handle;
    
    return contactDetailsVC;
}

- (NSInteger)currentIndexedSection:(NSInteger)section {
    if (section == 0) {
        return section;
    } else {
        //This is due the section that is added on top of your MEGA contacts, 'Recently Added'
        return section - 1;
    }
}

- (void)openChatRoomForIndexPath:(NSIndexPath *)indexPath {
    MEGAUser *user = [self userAtIndexPath:indexPath];
    if (user == nil) {
        return;
    }
    
    MEGAChatRoom *chatRoom = [MEGAChatSdk.shared chatRoomByUser:user.handle];
    if (chatRoom) {
        [self openChatRoom:chatRoom];
    } else {
        [MEGAChatSdk.shared mnz_createChatRoomWithUserHandle:user.handle completion:^(MEGAChatRoom * _Nonnull chatRoom) {
            [self openChatRoom:chatRoom];
        }];
    }
    
    [MEGAStore.shareInstance updateUserWithHandle:user.handle interactedWith:YES];
}

- (void)openChatRoom:(MEGAChatRoom *)chatRoom {
    if (chatRoom == nil) {
        MEGALogDebug(@"ChatRoom is empty");
        return;
    }
    
    [[ChatContentRouter.alloc initWithChatRoom:chatRoom presenter:self.navigationController publicLink:nil showShareLinkViewAfterOpenChat:NO chatContentRoutingStyle:ChatContentRoutingStylePush] start];
}

- (void)setupContactsTableViewHeader {
    self.contactsTableViewHeader = [NSBundle.mainBundle loadNibNamed:@"ContactsTableViewHeader" owner:self options: nil].firstObject;
    self.contactsTableViewHeader.navigationController = self.navigationController;
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
        [self handleContactsNotVerifiedHeaderVisibility];
    } else {
        [self.selectedUsersArray removeAllObjects];
    }
    
    self.deleteBarButtonItem.enabled = (self.selectedUsersArray.count == 0) ? NO : YES;
    
    [self.tableView reloadData];
}

- (IBAction)infoTouchUpInside:(UIButton *)sender {
    CGPoint buttonPosition = [sender convertPoint:CGPointZero toView:self.tableView];
    NSIndexPath *indexPath = [self.tableView indexPathForRowAtPoint:buttonPosition];
    MEGAUser *user = [self userAtIndexPath:indexPath];
    if (user) {
        [MEGAStore.shareInstance updateUserWithHandle:user.handle interactedWith:YES];
        if (self.searchController.isActive) {
            self.detailUser = user;
            self.currentSearch = self.searchController.searchBar.text;
            self.searchController.active = NO;
        } else {
            [self showContactDetailsForUser:user];
        }
    } else {
        [SVProgressHUD showErrorWithStatus:@"Invalid user"];
    }
}

- (IBAction)addContact:(id)sender {
    [self executeInvite:sender];
}

- (void)executeInvite:(id)sender {
    if (self.searchController.isActive) {
        self.searchController.active = NO;
    }
    
    if (self.contactsMode == ContactsModeShareFoldersWith) {
        UIAlertController *addContactAlertController = [UIAlertController alertControllerWithTitle:LocalizedString(@"inviteContact", @"Text shown when the user tries to make a call and the receiver is not a contact") message:nil preferredStyle:UIAlertControllerStyleActionSheet];
        [addContactAlertController addAction:[UIAlertAction actionWithTitle:LocalizedString(@"cancel", @"Button title to cancel something") style:UIAlertActionStyleCancel handler:nil]];
        
        UIAlertAction *addFromEmailAlertAction = [UIAlertAction actionWithTitle:LocalizedString(@"addFromEmail", @"Item menu option to add a contact writting his/her email") style:UIAlertActionStyleDefault handler:^(UIAlertAction *action) {
            UIAlertController *addContactFromEmailAlertController = [UIAlertController alertControllerWithTitle:LocalizedString(@"addContact", @"Alert title shown when you select to add a contact inserting his/her email") message:nil preferredStyle:UIAlertControllerStyleAlert];
            
            [addContactFromEmailAlertController addTextFieldWithConfigurationHandler:^(UITextField *textField) {
                textField.placeholder = LocalizedString(@"contactEmail", @"Clue text to help the user know what should write there. In this case the contact email you want to add to your contacts list");
                [textField addTarget:self action:@selector(addContactAlertTextFieldDidChange:) forControlEvents:UIControlEventEditingChanged];
                textField.shouldReturnCompletion = ^BOOL(UITextField *textField) {
                    return (!textField.text.mnz_isEmpty && textField.text.mnz_isValidEmail);
                };
            }];
            
            [addContactFromEmailAlertController addAction:[UIAlertAction actionWithTitle:LocalizedString(@"cancel", @"Button title to cancel something") style:UIAlertActionStyleCancel handler:nil]];
            
            UIAlertAction *addContactAlertAction = [UIAlertAction actionWithTitle:LocalizedString(@"addContactButton", @"Button title to 'Add' the contact to your contacts list") style:UIAlertActionStyleDefault handler:^(UIAlertAction *action) {
                UITextField *textField = addContactFromEmailAlertController.textFields.firstObject;
                if (self.contactsMode == ContactsModeShareFoldersWith) {
                    [self inviteEmailToShareFolder:textField.text];
                } else {
                    if (MEGAReachabilityManager.isReachableHUDIfNot) {
                        MEGAInviteContactRequestDelegate *inviteContactRequestDelegate = [MEGAInviteContactRequestDelegate.alloc initWithNumberOfRequests:1];
                        [MEGASdk.shared inviteContactWithEmail:textField.text message:@"" action:MEGAInviteActionAdd delegate:inviteContactRequestDelegate];
                        [addContactAlertController dismissViewControllerAnimated:YES completion:nil];
                    }
                }
            }];
            addContactAlertAction.enabled = NO;
            [addContactFromEmailAlertController addAction:addContactAlertAction];
            
            [self presentViewController:addContactFromEmailAlertController animated:YES completion:nil];
        }];
        [addContactAlertController addAction:addFromEmailAlertAction];
        
        UIAlertAction *addFromContactsAlertAction = [UIAlertAction actionWithTitle:LocalizedString(@"addFromContacts", @"Item menu option to add a contact through your device app Contacts") style:UIAlertActionStyleDefault handler:^(UIAlertAction *action) {
            if (self.presentedViewController != nil) {
                [self.presentedViewController dismissViewControllerAnimated:YES completion:^{
                    [self showEmailContactPicker];
                }];
            } else {
                [self showEmailContactPicker];
            }
        }];
        [addContactAlertController addAction:addFromContactsAlertAction];
        
        UIAlertAction *scanCodeAlertAction = [UIAlertAction actionWithTitle:LocalizedString(@"scanCode", @"Segmented control title for view that allows the user to scan QR codes. String as short as possible.") style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
            ContactLinkQRViewController *contactLinkVC = [[UIStoryboard storyboardWithName:@"ContactLinkQR" bundle:nil] instantiateViewControllerWithIdentifier:@"ContactLinkQRViewControllerID"];
            contactLinkVC.scanCode = YES;
            contactLinkVC.modalPresentationStyle = UIModalPresentationFullScreen;
            if (self.contactsMode == ContactsModeShareFoldersWith) {
                contactLinkVC.contactLinkQRType = ContactLinkQRTypeShareFolder;
                contactLinkVC.contactLinkQRDelegate = self;
            }
            [self presentViewController:contactLinkVC animated:YES completion:nil];
        }];
        [addContactAlertController addAction:scanCodeAlertAction];
        
        addContactAlertController.modalPresentationStyle = UIModalPresentationPopover;
        if (self.addBarButtonItem) {
            addContactAlertController.popoverPresentationController.barButtonItem = self.addBarButtonItem;
        } else if (self.insertAnEmailBarButtonItem) {
            addContactAlertController.popoverPresentationController.barButtonItem = self.insertAnEmailBarButtonItem;
        } else {
            UIView *senderView = (UIView *)sender;
            addContactAlertController.popoverPresentationController.sourceRect = senderView.frame;
            addContactAlertController.popoverPresentationController.sourceView = senderView.superview;
        }
        
        [self presentViewController:addContactAlertController animated:YES completion:nil];
    } else {
        InviteContactViewController *inviteContacts = [[UIStoryboard storyboardWithName:@"InviteContact" bundle:nil] instantiateViewControllerWithIdentifier:@"InviteContactViewControllerID"];
        [self.navigationController pushViewController:inviteContacts animated:YES];
    }
}

- (IBAction)deleteAction:(UIBarButtonItem *)sender {
    MEGAShareRequestDelegate *shareRequestDelegate = [[MEGAShareRequestDelegate alloc] initToChangePermissionsWithNumberOfRequests:self.selectedUsersArray.count completion:^{
        if (self.selectedUsersArray.count == self.visibleUsersArray.count) {
            [self.navigationController popViewControllerAnimated:YES];
        } else {
            [self reloadUI];
        }
        self.navigationItem.leftBarButtonItems = @[];
        [self setTableViewEditing:NO animated:YES];
    }];
    
    for (MEGAUser *user in self.selectedUsersArray) {
        [MEGASdk.shared shareNode:self.node withUser:user level:MEGAShareTypeAccessUnknown delegate:shareRequestDelegate];
    }
}

- (IBAction)inviteContact:(UIBarButtonItem *)sender {
    [self.viewModel trackInviteToMegaToolbarTapped];
    [self executeInvite:sender];
}

- (IBAction)cancelAction:(UIBarButtonItem *)sender {
    
    if (self.searchController.isActive) {
        self.searchController.active = NO;
    }
    
    if (self.contactsMode == ContactsModeChatCreateGroup && self.navigationController.viewControllers.count != 1) {
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
    [self shareFolderAction];
}

- (IBAction)editTapped:(UIBarButtonItem *)sender {
    BOOL enableEditing = !self.tableView.isEditing;
    
    if (self.contactsMode == ContactsModeFolderSharedWith) {
        self.navigationItem.leftBarButtonItems = enableEditing ? @[self.selectAllBarButtonItem] : @[];
    }
    
    [self setTableViewEditing:enableEditing animated:YES];
}

- (IBAction)createGroupAction:(UIBarButtonItem *)sender {
    [self.viewModel trackNewGroupChatTapped];
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
        if (!self.isKeyRotationEnabled && self.chatLinkSwitch.isOn && self.enterGroupNameTextField.text.mnz_isEmpty) {
            UIAlertController *alertController = [UIAlertController alertControllerWithTitle:LocalizedString(@"Chat Link", @"Label shown in a cell where you can enable a switch to get a chat link") message:LocalizedString(@"To create a chat link you must name the group.", @"Alert message to advice the users that to generate a chat link they need enter a group name for the chat")  preferredStyle:UIAlertControllerStyleAlert];
            [alertController addAction:[UIAlertAction actionWithTitle:LocalizedString(@"ok", @"") style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
                [self.enterGroupNameTextField becomeFirstResponder];
            }]];
            [self presentViewController:alertController animated:YES completion:nil];
        } else {
            [self dismissViewControllerAnimated:YES completion:^{
                self.createGroupChat(self.selectedUsersArray, self.insertedGroupName, self.keyRotationEnabled, self.keyRotationEnabled ? NO : self.chatLinkSwitch.isOn, self.allowNonHostToAddParticipantsSwitch.isOn);
            }];
        }
    }
}

- (IBAction)addParticipantAction:(UIBarButtonItem *)sender {
    if (self.selectedUsersArray.count > 0 || self.contactsMode == ContactsModeScheduleMeeting) {
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
    self.getChatLinkView.hidden = sender.on;
    
    if (sender.on) {
        self.chatNamingGroupTableViewHeader.frame = CGRectMake(0, 0, self.chatNamingGroupTableViewHeader.frame.size.width, 356 - self.getChatLinkView.frame.size.height - 23);
    } else {
        self.chatNamingGroupTableViewHeader.frame = CGRectMake(0, 0, self.chatNamingGroupTableViewHeader.frame.size.width, 356);
    }

    [self.tableView reloadData];
}


- (IBAction)chatLinkSwitchValueChanged:(UISwitch *)sender {
    self.chatLinkSwitch.selected = !self.chatLinkSwitch.selected;
}

- (IBAction)allowNonHostToAddParticipantsSwitchValueChanged:(UISwitch *)sender {
    self.allowNonHostToAddParticipantsSwitch.selected = !self.allowNonHostToAddParticipantsSwitch.selected;
}

- (IBAction)inviteContactTouchUpInside:(UIButton *)sender {
    [self.viewModel trackInviteEmptyScreenTapped];
    [self executeInvite:sender];
}

- (IBAction)addShareWith:(id)sender {
    MEGANavigationController *navigationController = [[UIStoryboard storyboardWithName:@"Contacts" bundle:nil] instantiateViewControllerWithIdentifier:@"ContactsNavigationControllerID"];
    ContactsViewController *contactsVC = navigationController.viewControllers.firstObject;
    contactsVC.nodesArray = @[self.node];
    contactsVC.contactsMode = ContactsModeShareFoldersWith;
    [self presentViewController:navigationController animated:YES completion:nil];
}

#pragma mark - UITableViewDataSource

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    if (!MEGAReachabilityManager.isReachable) {
        return 0;
    }
    
    NSInteger numberOfRows = 0;
    switch (self.contactsMode) {
        case ContactsModeDefault: {
            if (self.searchController.isActive && ![self.searchController.searchBar.text isEqual: @""]) {
                numberOfRows = self.searchVisibleUsersArray.count;
            } else {
                if (section == 0) { //Recently Added
                    numberOfRows = self.recentlyAddedUsersArray.count;
                } else {
                    numberOfRows = self.visibleUsersIndexedMutableArray[[self currentIndexedSection:section]].count;
                }
            }
            break;
        }
            
        case ContactsModeFolderSharedWith:
            numberOfRows = (section == 0) ? (self.visibleUsersArray.count + 1) : self.pendingShareUsersArray.count;
            break;
            
        case ContactsModeChatStartConversation: {
            if (section == 0) {
                numberOfRows = self.startConversationOptions.count;
            } else if (section == 1) {
                if (self.recentsArray.count > 3) {
                    numberOfRows = 3;
                } else {
                    numberOfRows = self.recentsArray.count;
                }
                
            } else {
                numberOfRows = [self defaultNumberOfRows];
            }
            break;
        }
            
        case ContactsModeChatNamingGroup: {
            numberOfRows = (section == 0) ? self.selectedUsersArray.count + 1 : [self defaultNumberOfRows];
            break;
        }
            
        default: //ContactsModeShareFoldersWith, ContactsModeChatAddParticipant, ContactsModeChatAttachParticipant and ContactsModeChatCreateGroup
            numberOfRows = [self defaultNumberOfRows];
            break;
    }
    
    return numberOfRows;
}

- (NSInteger)defaultNumberOfRows {
    return (self.searchController.isActive && ![self.searchController.searchBar.text isEqual: @""]) ? self.searchVisibleUsersArray.count : self.visibleUsersArray.count;
}

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    NSInteger numberOfSections = 1;
    switch (self.contactsMode) {
        case ContactsModeDefault: {
            if (self.searchController.isActive && ![self.searchController.searchBar.text isEqual: @""]) {
                numberOfSections = 1;
            } else {
                numberOfSections = UILocalizedIndexedCollation.currentCollation.sectionIndexTitles.count + 1; // + Recently Added
            }
            break;
        }
            
        case ContactsModeFolderSharedWith:
            numberOfSections = 2;
            break;
            
        case ContactsModeChatStartConversation:
            numberOfSections = 3;
            break;
            
        default: //ContactsModeShareFoldersWith, ContactsModeChatAddParticipant, ContactsModeChatAttachParticipant, ContactsModeChatCreateGroup and ContactsModeChatNamingGroup
            numberOfSections = 1;
            break;
    }
    
    return numberOfSections;
}

- (id)dequeueOrInitCellWithIdentifier:(NSString *)identifier indexPath:(NSIndexPath *)indexPath {
    id cell = [self.tableView dequeueReusableCellWithIdentifier:identifier forIndexPath:indexPath];
    if (cell == nil) {
        cell = [UITableViewCell.alloc initWithStyle:UITableViewCellStyleDefault reuseIdentifier:identifier];
    }
    
    return cell;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    MEGAUser *user;
    ContactTableViewCell *cell;
    cell.backgroundColor = (self.contactsMode == ContactsModeDefault) ? [UIColor pageBackgroundColor] : [UIColor mnz_tertiaryBackground:self.traitCollection];
    switch (self.contactsMode) {
        case ContactsModeDefault: {
            cell = [self dequeueOrInitCellWithIdentifier:@"contactCell" indexPath:indexPath];
            user = [self getUserAndSetIndexPath:indexPath];
            BOOL isSearching = (self.searchController.isActive && ![self.searchController.searchBar.text isEqual: @""]);
            [cell configureDefaultCellForUser:user newUser:isSearching ? NO : (indexPath.section == 0)];
            cell.contactDetailsButton.hidden = NO;
            break;
        }
            
        case ContactsModeFolderSharedWith: {
            cell = [self dequeueOrInitCellWithIdentifier:@"ContactPermissionsNameTableViewCellID" indexPath:indexPath];
            user = [self getUserAndSetIndexPath:indexPath];
            [cell configureCellForContactsModeFolderSharedWith:user indexPath:indexPath];
            
            if (indexPath.section == 0) {
                if (indexPath.row == 0) {
                    return cell;
                } else {
                    MEGAShare *share = self.outSharesForNodeMutableArray[indexPath.row - 1];
                    cell.permissionsImageView.hidden = NO;
                    cell.permissionsImageView.image = [UIImage mnz_permissionsButtonImageForShareType:share.access];
                }
            } else if (indexPath.section == 1) {
                cell.nameLabel.text = self.pendingShareUsersArray[indexPath.row].user;
            }
            break;
        }
            
        case ContactsModeChatStartConversation: {
            if (indexPath.section == 0) {
                ContactTableViewCell *cell = [self dequeueOrInitCellWithIdentifier:@"ContactPermissionsNameTableViewCellID" indexPath:indexPath];
                [cell configureCellForContactsModeChatStartConversation:self.startConversationOptions[indexPath.row].intValue];
                
                return cell;
            } if (indexPath.section == 1) {
                ContactTableViewCell *cell = [self dequeueOrInitCellWithIdentifier:@"contactCell" indexPath:indexPath];
                MEGAChatListItem *chatListItem = self.recentsArray[indexPath.row];
                MEGAChatRoom *chatRoom = [MEGAChatSdk.shared chatRoomForChatId:chatListItem.chatId];
                if (chatListItem.isGroup) {
                    cell.nameLabel.text = chatListItem.title;
                    cell.shareLabel.text = [chatRoom participantsNamesWithMe:YES];
                    cell.onlineStatusView.backgroundColor = nil;
                    cell.avatarImageView.image = [UIImage imageForName:chatListItem.title.uppercaseString size:cell.avatarImageView.frame.size backgroundColor:[UIColor iconSecondaryColor] backgroundGradientColor:UIColor.mnz_grayDBDBDB textColor:UIColor.whiteTextColor font:[UIFont systemFontOfSize:(cell.avatarImageView.frame.size.width/2.0f)]];
                    cell.verifiedImageView.hidden = YES;
                } else {
                    uint64_t peerHandle = chatListItem.peerHandle;
                    cell.nameLabel.text = [chatRoom userDisplayNameForUserHandle:peerHandle];
                    MEGAChatStatus userStatus = [MEGAChatSdk.shared userOnlineStatus:peerHandle];
                    cell.shareLabel.text = [NSString chatStatusString:userStatus];
                    cell.onlineStatusView.backgroundColor =  [UIColor colorWithChatStatus: userStatus];
                    [cell.avatarImageView mnz_setImageForUserHandle:peerHandle name:cell.nameLabel.text];
                    NSString *peerEmail = [MEGAChatSdk.shared userEmailFromCacheByUserHandle:peerHandle];
                    if (peerEmail) {
                        MEGAUser *user = [MEGASdk.shared contactForEmail:peerEmail];
                        cell.verifiedImageView.hidden = ![MEGASdk.shared areCredentialsVerifiedOfUser:user];
                    } else {
                        cell.verifiedImageView.hidden = YES;
                    }
                }
                return cell;
            } else {
                cell = [self dequeueOrInitCellWithIdentifier:@"contactCell" indexPath:indexPath];
                user = [self getUserAndSetIndexPath:indexPath];
                [cell configureDefaultCellForUser:user newUser:NO];
            }
            break;
        }
            
        default: { //ContactsModeShareFoldersWith, ContactsModeChatAddParticipant, ContactsModeChatAttachParticipant, ContactsModeChatCreateGroup and ContactsModeChatNamingGroup
            cell = [self dequeueOrInitCellWithIdentifier:@"contactCell" indexPath:indexPath];
            user = [self getUserAndSetIndexPath:indexPath];
            [cell configureDefaultCellForUser:user newUser:NO];
            break;
        }
    }
    
    if (self.tableView.isEditing) {
        // Check if selectedNodesArray contains the current node in the tableView
        for (id item in self.selectedUsersArray) {
            if ([item class] == MEGAUser.class) {
                MEGAUser *u = (MEGAUser*)item;
                if ([u.email isEqualToString:user.email]) {
                    [self.tableView selectRowAtIndexPath:indexPath animated:NO scrollPosition:UITableViewScrollPositionNone];
                }
            }
        }
        
        UIView *view = [[UIView alloc] init];
        view.backgroundColor = UIColor.clearColor;
        cell.selectedBackgroundView = view;
    }
    
    return cell;
}

- (UIView *)tableView:(UITableView *)tableView viewForHeaderInSection:(NSInteger)section {
    static NSString *reuseIdentifier = @"GenericHeaderFooterViewID";
    GenericHeaderFooterView *headerView = [self.tableView dequeueReusableHeaderFooterViewWithIdentifier:reuseIdentifier];
    headerView.contentView.backgroundColor = (self.contactsMode == ContactsModeDefault) ? [UIColor pageBackgroundColor] : [UIColor pageBackgroundColor];

    if (self.contactsMode == ContactsModeDefault) {
        if (section == 0) {
            if (self.recentlyAddedUsersArray.count > 0) {
                headerView.titleLabel.font = [UIFont preferredFontForTextStyle:UIFontTextStyleFootnote];
                [headerView configureWithTitle:LocalizedString(@"Recently Added", @"Label for any ‘Recently Added’ button, link, text, title, etc. On iOS is used on a section that shows the 'Recently Added' contacts") topDistance:17.0 isTopSeparatorVisible:YES isBottomSeparatorVisible:YES];
                
                return headerView;
            }
        } else {
            if (self.visibleUsersIndexedMutableArray[[self currentIndexedSection:section]].count > 0) {
                [headerView configureHeaderForAlphabeticSectionWithTitle:[UILocalizedIndexedCollation.currentCollation.sectionTitles objectAtIndex:[self currentIndexedSection:section]] font:[UIFont mnz_preferredFontWithStyle:UIFontTextStyleBody weight:UIFontWeightSemibold]];
                return headerView;
            }
        }
    }
    
    if (self.contactsMode == ContactsModeFolderSharedWith) {
        if (section == 0) {
            [headerView configureWithTitle:LocalizedString(@"sharedWith", @"Title of the view where you see with who you have shared a folder") topDistance:30.0 isTopSeparatorVisible:NO isBottomSeparatorVisible:YES];
            
        } else if (section == 1 && self.pendingShareUsersArray.count > 0) {
            [headerView configureWithTitle:LocalizedString(@"pending", @"Label shown when a contact request is pending") topDistance:self.pendingShareUsersArray.count > 0 ? 30.0 : 1.0 isTopSeparatorVisible:YES isBottomSeparatorVisible:YES];
        } else {
            [headerView configureWithTitle:nil topDistance:1.00 isTopSeparatorVisible:NO isBottomSeparatorVisible:NO];
        }
        return headerView;
    }
    if (section == 0
        && (self.contactsMode == ContactsModeChatCreateGroup
            || self.contactsMode == ContactsModeShareFoldersWith
            || self.contactsMode == ContactsModeInviteParticipants
            || self.contactsMode == ContactsModeScheduleMeeting)) {
        headerView.contentView.backgroundColor = UIColor.systemBackgroundColor;
        [headerView configureWithTitle:LocalizedString(@"contactsTitle", @"Title of the Contacts section") topDistance:14.0 isTopSeparatorVisible:NO isBottomSeparatorVisible:YES];
        
        return headerView;
    }
    if (section == 0 && self.contactsMode == ContactsModeChatNamingGroup) {
        [headerView configureWithTitle:LocalizedString(@"participants", @"Label to describe the section where you can see the participants of a group chat") topDistance:24.0 isTopSeparatorVisible:NO isBottomSeparatorVisible:YES];
        headerView.marginViewHeightConstraint.constant = 0.0;
        return headerView;
    }
    if (section == 1 && self.contactsMode == ContactsModeChatNamingGroup) {
        [headerView configureWithTitle:nil topDistance:14.0 isTopSeparatorVisible:YES isBottomSeparatorVisible:YES];
        return headerView;
    }
    if (section == 1 && self.contactsMode == ContactsModeChatStartConversation) {
        if ([self hideRecentsSectionHeaderWithIsEmpty:self.recentsArray.count == 0]) {
            [headerView configureWithTitle:nil topDistance:1.00 isTopSeparatorVisible:NO isBottomSeparatorVisible:NO];
        }
        else {
            [headerView configureWithTitle:LocalizedString(@"Recents", @"Title for the recents section") topDistance:2 isTopSeparatorVisible:YES isBottomSeparatorVisible:YES];
        }
        return headerView;
    }
    if ((section == 2 && self.contactsMode == ContactsModeChatStartConversation) || (section == 1 && self.contactsMode > ContactsModeChatStartConversation)) {
        [headerView configureWithTitle:LocalizedString(@"contactsTitle", @"Title of the Contacts section") topDistance:2 isTopSeparatorVisible:YES isBottomSeparatorVisible:YES];
        return headerView;
    }
    
    // default configuration
    [headerView configureWithTitle:nil topDistance:1.00 isTopSeparatorVisible:NO isBottomSeparatorVisible:NO];
    
    return headerView;
}

- (NSArray *)sectionIndexTitlesForTableView:(UITableView *)tableView {
    if (self.contactsMode == ContactsModeDefault) {
        return (self.visibleUsersArray.count > 0) ? UILocalizedIndexedCollation.currentCollation.sectionIndexTitles : @[];
    }
    
    return @[];
}

- (NSInteger)tableView:(UITableView *)tableView sectionForSectionIndexTitle:(NSString *)title atIndex:(NSInteger)index {
    if (self.contactsMode == ContactsModeDefault) {
        return [UILocalizedIndexedCollation.currentCollation sectionForSectionIndexTitleAtIndex:index];
    }
    
    return 0;
}

#pragma mark - UITableViewDelegate

- (BOOL) tableView:(UITableView *)tableView canEditRowAtIndexPath:(NSIndexPath *)indexPath {
    if (self.contactsMode == ContactsModeFolderSharedWith) {
        if (indexPath.section == 0) {
            if (indexPath.row == 0) {
                return NO;
            } else {
                return YES;
            }
        } else {
            return NO;
        }
    } else {
        return YES;
    }
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    
    switch (self.contactsMode) {
        case ContactsModeDefault: {
            [self openChatRoomForIndexPath:indexPath];
            break;
        }
            
        case ContactsModeFolderSharedWith: {
            if (indexPath.section == 0) {
                if (indexPath.row == 0) {
                    __weak __typeof__(self) weakSelf = self;
                    [self showBackupNodesWarningIfNeededWithCompletion:^{
                        [weakSelf addShareWith:nil];
                    }];
                } else {
                    MEGAUser *user = self.visibleUsersArray[indexPath.row - 1];
                    if (!user) {
                        [SVProgressHUD showErrorWithStatus:@"Invalid user"];
                        return;
                    }
                    if (tableView.isEditing) {
                        [self.selectedUsersArray addObject:user];
                        [self handleContactsNotVerifiedHeaderVisibility];
                        self.deleteBarButtonItem.enabled = (self.selectedUsersArray.count > 0);
                        return;
                    }
                    
                    self.userTapped = user;
                    BOOL isBackupNode = [[[BackupsOCWrapper alloc] init] isBackupNode:self.node];
                    if (!isBackupNode) {
                        [self selectPermissionsFromCell:[self.tableView cellForRowAtIndexPath:indexPath]];
                    }
                }
            } else {
                if (!tableView.isEditing) {
                    UIAlertController *removePendingShareAlertController = [UIAlertController alertControllerWithTitle:LocalizedString(@"removeUserTitle", @"Alert title shown when you want to remove one or more contacts") message:self.pendingShareUsersArray[indexPath.row].user preferredStyle:UIAlertControllerStyleAlert];
                    
                    [removePendingShareAlertController addAction:[UIAlertAction actionWithTitle:LocalizedString(@"cancel", @"Button title to cancel something") style:UIAlertActionStyleCancel handler:nil]];
                    
                    [removePendingShareAlertController addAction:[UIAlertAction actionWithTitle:LocalizedString(@"ok", @"") style:UIAlertActionStyleDefault handler:^(UIAlertAction *action) {
                        MEGAShareRequestDelegate *shareRequestDelegate = [MEGAShareRequestDelegate.alloc initToChangePermissionsWithNumberOfRequests:1 completion:^{
                            [self setTableViewEditing:NO animated:NO];
                            [self reloadUI];
                        }];
                        [MEGASdk.shared shareNode:self.node withEmail:self.pendingShareUsersArray[indexPath.row].user level:MEGAShareTypeAccessUnknown delegate:shareRequestDelegate];
                    }]];
                    [self presentViewController:removePendingShareAlertController animated:YES completion:nil];
                    
                }
            }
            break;
        }
            
        case ContactsModeChatStartConversation: {
            if (indexPath.section == 0) {
                switch (self.startConversationOptions[indexPath.row].intValue) {
                    case ContactsStartConversationNewGroupChat:
                        [self startGroup];
                        break;
                    case ContactsStartConversationNewMeeting:
                        [self newMeeting];
                        break;
                    case ContactsStartConversationJoinMeeting:
                        [self joinMeeting];
                        break;
                }
            } else if (indexPath.section == 1) {
                [self dismissViewControllerAnimated:YES completion:^{
                    MEGAChatListItem *chatListItem = self.recentsArray[indexPath.row];
                    self.chatSelected(chatListItem.chatId);
                }];
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
        case ContactsModeShareFoldersWith:
        case ContactsModeInviteParticipants:
        case ContactsModeScheduleMeeting:
            if (tableView.isEditing) {
                MEGAUser *user = [self userAtIndexPath:indexPath];
                if (!user) {
                    [SVProgressHUD showErrorWithStatus:@"Invalid user"];
                    return;
                }
                [self.selectedUsersArray addObject:user];
                [self handleContactsNotVerifiedHeaderVisibility];
                if (self.contactsMode != ContactsModeScheduleMeeting) {
                    self.addParticipantBarButtonItem.enabled = (self.selectedUsersArray.count > 0);
                }
                [self addItemsToList:@[[ItemListModel.alloc initWithUser:user]]];
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
    
    MEGAUser *user;
    
    if (self.contactsMode == ContactsModeFolderSharedWith) {
        if (indexPath.section == 0) {
            if (indexPath.row == 0) {
                return;
            }else {
                user = self.visibleUsersArray[indexPath.row - 1];
            }
        } else {
            return;
        }
    } else {
        user = [self userAtIndexPath:indexPath];
    }
    
    if (tableView.isEditing) {
        //tempArray avoid crash: "was mutated while being enumerated."
        NSMutableArray *tempArray = self.selectedUsersArray.copy;
        for (id item in tempArray) {
            if ([item class] == MEGAUser.class) {
                MEGAUser *u = (MEGAUser*)item;
                if ([u.email isEqualToString:user.email]) {
                    [self.selectedUsersArray removeObject:u];
                }
            }
        }
        
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
            if (self.contactsMode == ContactsModeChatAddParticipant || self.contactsMode == ContactsModeInviteParticipants) {
                self.addParticipantBarButtonItem.enabled = NO;
            }
        }
        
        if (self.contactsMode != ContactsModeChatAddParticipant
            || self.contactsMode != ContactsModeChatAttachParticipant
            || self.contactsMode != ContactsModeChatCreateGroup
            || self.contactsMode != ContactsModeInviteParticipants
            || self.contactsMode != ContactsModeScheduleMeeting) {
            if (self.searchController.searchBar.isFirstResponder) {
                self.searchController.searchBar.text = @"";
            }
        }

        [self handleContactsNotVerifiedHeaderVisibility];

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

#pragma mark - CNContactPickerDelegate

-(void)contactPicker:(CNContactPickerViewController *)picker didSelectContacts:(NSArray<CNContact *> *)contacts {
    NSArray<NSString *> * values = [self extractEmails:contacts];

    if (self.childViewControllers.count == 0) {
        [self insertItemListSubviewWithCompletion:^{
            for (NSString *email in values) {
                [self inviteEmailToShareFolder:email];
            }
        }];
    } else {
        for (NSString *email in values) {
            [self inviteEmailToShareFolder:email];
        }
    }
}

#pragma mark - DZNEmptyDataSetSource

- (nullable UIView *)customViewForEmptyDataSet:(UIScrollView *)scrollView {
    EmptyStateView *emptyStateView = [EmptyStateView.alloc initWithImage:[self imageForEmptyState] title:[self titleForEmptyState] description:[self descriptionForEmptyState] buttonTitle:[self buttonTitleForEmptyState]];
    [emptyStateView.button addTarget:self action:@selector(buttonTouchUpInsideEmptyState:) forControlEvents:UIControlEventTouchUpInside];
    
    return emptyStateView;
}

#pragma mark - Empty State

- (NSString *)titleForEmptyState {
    NSString *text = @"";
    if (MEGAReachabilityManager.isReachable) {
        if (self.contactsMode != ContactsModeChatNamingGroup) {
            if (self.searchController.isActive ) {
                if (self.searchController.searchBar.text.length > 0) {
                    text = LocalizedString(@"noResults", @"Title shown when you make a search and there is 'No Results'");
                }
            } else {
                text = LocalizedString(@"contactsEmptyState_title", @"Title shown when the Contacts section is empty, when you have not added any contact.");
            }
        }
    } else {
        text = LocalizedString(@"noInternetConnection",  @"No Internet Connection");
    }
    
    return text;
}

- (NSString *)descriptionForEmptyState {
    NSString *text = @"";
    if (!MEGAReachabilityManager.isReachable && !MEGAReachabilityManager.sharedManager.isMobileDataEnabled) {
        text = LocalizedString(@"Mobile Data is turned off", @"Information shown when the user has disabled the 'Mobile Data' setting for MEGA in the iOS Settings.");
    }
    
    return text;
}

- (nullable UIImage *)imageForEmptyState {
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

- (nullable NSString *)buttonTitleForEmptyState {
    if (self.contactsMode >= ContactsModeChatAddParticipant) {
        return nil;
    }
    
    NSString *text = @"";
    if (MEGAReachabilityManager.isReachable && !self.searchController.isActive) {
        text = LocalizedString(@"inviteContact", @"Text shown when the user tries to make a call and the receiver is not a contact");
    } else if (!MEGAReachabilityManager.isReachable && !MEGAReachabilityManager.sharedManager.isMobileDataEnabled) {
        text = LocalizedString(@"Turn Mobile Data on", @"Button title to go to the iOS Settings to enable 'Mobile Data' for the MEGA app.");
    }
    
    return text;
}

- (void)buttonTouchUpInsideEmptyState:(UIButton *)button {
    if (MEGAReachabilityManager.isReachable) {
        [self executeInvite: button];
    } else {
        if (!MEGAReachabilityManager.sharedManager.isMobileDataEnabled) {
            [UIApplication.sharedApplication openURL:[NSURL URLWithString:UIApplicationOpenSettingsURLString] options:@{} completionHandler:nil];
        }
    }
}

#pragma mark - UISearchBarDelegate

- (void)searchBarCancelButtonClicked:(UISearchBar *)searchBar {
    self.searchVisibleUsersArray = nil;
    
    if (self.contactsMode == ContactsModeDefault) {
        self.tableView.tableHeaderView = self.contactsTableViewHeader;
    }
}

#pragma mark - UISearchControllerDelegate

- (void)presentSearchController:(UISearchController *)searchController {
    if (!searchController.searchBar.isFirstResponder) {
        [searchController.searchBar becomeFirstResponder];
    }
    
    if (self.contactsMode == ContactsModeDefault) {
        self.tableView.tableHeaderView = nil;
    }
}

- (void)didDismissSearchController:(UISearchController *)searchController {
    if (self.detailUser != nil) {
        [self showContactDetailsForUser:self.detailUser];
        self.detailUser = nil;
    }
    
    if (self.contactsMode == ContactsModeDefault) {
        self.tableView.tableHeaderView = self.contactsTableViewHeader;
    }
}

#pragma mark - UISearchResultsUpdating

- (void)updateSearchResultsForSearchController:(UISearchController *)searchController {
    NSString *searchString = searchController.searchBar.text;
    if (searchController.isActive) {
        if ([searchString isEqualToString:@""]) {
            [self.searchVisibleUsersArray removeAllObjects];
        } else {
            NSPredicate *fullnamePredicate = [NSPredicate predicateWithFormat:@"SELF.mnz_fullName contains[c] %@", searchString];
            NSPredicate *nicknamePredicate = [NSPredicate predicateWithFormat:@"SELF.mnz_nickname contains[c] %@", searchString];
            NSPredicate *emailPredicate = [NSPredicate predicateWithFormat:@"SELF.email contains[c] %@", searchString];
            NSPredicate *resultPredicate = [NSCompoundPredicate orPredicateWithSubpredicates:@[fullnamePredicate, nicknamePredicate, emailPredicate]];
            
            self.searchVisibleUsersArray = [self.visibleUsersArray filteredArrayUsingPredicate:resultPredicate].mutableCopy;
        }
    }
    
    [self.tableView reloadData];
}

#pragma mark - UIAdaptivePresentationControllerDelegate

- (BOOL)presentationControllerShouldDismiss:(UIPresentationController *)presentationController {
    if (self.contactsMode == ContactsModeChatStartConversation || self.contactsMode == ContactsModeChatNamingGroup || self.contactsMode == ContactsModeChatCreateGroup || self.contactsMode == ContactsModeShareFoldersWith) {
        return NO;
    } else {
        return YES;
    }
}

- (void)presentationControllerDidAttemptToDismiss:(UIPresentationController *)presentationController {
    if (self.contactsMode == ContactsModeChatNamingGroup || self.contactsMode == ContactsModeChatCreateGroup || self.contactsMode == ContactsModeShareFoldersWith) {
        UIBarButtonItem *sender = self.contactsMode == ContactsModeShareFoldersWith ? self.navigationItem.leftBarButtonItem : self.navigationItem.rightBarButtonItem;
        
        if (sender == nil) {
            return;
        }
        
        UIAlertController *confirmDismissAlert = [UIAlertController.alloc discardChangesFromBarButton:sender withConfirmAction:^{
            [self dismissViewControllerAnimated:YES completion:nil];
        }];
        [self presentViewController:confirmDismissAlert animated:YES completion:nil];
    }
}

#pragma mark - MEGAGlobalDelegate

- (void)onNodesUpdate:(MEGASdk *)api nodeList:(MEGANodeList *)nodeList {
    if (self.contactsMode != ContactsModeFolderSharedWith) {
        return;
    }
    
    NSUInteger size = nodeList.size;
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
    
    NSInteger count = userList.size;
    for (NSInteger i = 0 ; i < count; i++) {
        MEGAUser *user = [userList userAtIndex:i];
        NSString *base64Handle = [MEGASdk base64HandleForUserHandle:user.handle];
        NSIndexPath *indexPath = [self.indexPathsMutableDictionary objectForKey:base64Handle];
        if (([user handle] == MEGASdk.currentUserHandle.unsignedLongLongValue) && (user.isOwnChange != 0)) {
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
                
                if (indexPath.section == 0) {
                    [self.recentlyAddedUsersArray removeObjectAtIndex:indexPath.row];
                } else {
                    NSMutableArray *usersInSectionMutableArray = self.visibleUsersIndexedMutableArray[[self currentIndexedSection:indexPath.section]];
                    [usersInSectionMutableArray removeObjectAtIndex:indexPath.row];
                }
            }
            [self.tableView deleteRowsAtIndexPaths:deleteContactsOnIndexPathsArray withRowAnimation:UITableViewRowAnimationAutomatic];
            
            //Rebuild indexPaths to keep consistency with the table
            [self.indexPathsMutableDictionary removeAllObjects];
            if (self.contactsMode == ContactsModeDefault) {
                for (NSInteger section = 0; section < self.visibleUsersIndexedMutableArray.count; section++) {
                    NSMutableArray *usersInSectionMutableArray = self.visibleUsersIndexedMutableArray[section];
                    for (NSInteger row = 0; row < usersInSectionMutableArray.count; row++) {
                        MEGAUser *user = usersInSectionMutableArray[row];
                        NSString *base64Handle = [MEGASdk base64HandleForUserHandle:user.handle];
                        [self.indexPathsMutableDictionary setObject:[NSIndexPath indexPathForRow:row inSection:section + 1] forKey:base64Handle];
                    }
                }
            } else {
                for (MEGAUser *user in self.visibleUsersArray) {
                    NSString *base64Handle = [MEGASdk base64HandleForUserHandle:user.handle];
                    [self.indexPathsMutableDictionary setObject:[NSIndexPath indexPathForRow:[self.visibleUsersArray indexOfObject:user] inSection:0] forKey:base64Handle];
                }
            }
        }
    }
}

- (void)onContactRequestsUpdate:(MEGASdk *)api contactRequestList:(MEGAContactRequestList *)contactRequestList {
    [self updatePendingContactRequestsLabel];
}

#pragma mark - ItemListViewControllerDelegate

- (void)removeSelectedItem:(id)item {
    if ([item class] == MEGAUser.class) {
        MEGAUser *user = (MEGAUser *)item;
        NSString *base64Handle = [MEGASdk base64HandleForUserHandle:user.handle];
        [self.tableView deselectRowAtIndexPath:[self.indexPathsMutableDictionary objectForKey:base64Handle] animated:YES];
    }
    [self.selectedUsersArray removeObject:item];
    if (self.selectedUsersArray.count == 0) {
        [self removeUsersListSubview];
        if (self.contactsMode == ContactsModeChatAddParticipant || self.contactsMode == ContactsModeInviteParticipants) {
            self.addParticipantBarButtonItem.enabled = NO;
        }
    }
    [self handleContactsNotVerifiedHeaderVisibility];
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

//FIXME: Necessary on all Contacts modes? Crash when receiving a status update if you a not on the default mode
- (void)onChatOnlineStatusUpdate:(MEGAChatSdk *)api userHandle:(uint64_t)userHandle status:(MEGAChatStatus)onlineStatus inProgress:(BOOL)inProgress {
    if (inProgress) {
        return;
    }
    
    if (userHandle != api.myUserHandle) {
        NSString *base64Handle = [MEGASdk base64HandleForUserHandle:userHandle];
        NSIndexPath *indexPath = [self.indexPathsMutableDictionary objectForKey:base64Handle];
        if ([self.tableView.indexPathsForVisibleRows containsObject:indexPath]) {
            ContactTableViewCell *cell = (ContactTableViewCell *)[self.tableView cellForRowAtIndexPath:indexPath];
            cell.onlineStatusView.backgroundColor = [UIColor colorWithChatStatus: onlineStatus];
            cell.shareLabel.text = [NSString chatStatusString:onlineStatus];
            if (onlineStatus < MEGAChatStatusOnline) {
                [MEGAChatSdk.shared requestLastGreen:userHandle];
            }
        }
    }
}

- (void)onChatPresenceLastGreen:(MEGAChatSdk *)api userHandle:(uint64_t)userHandle lastGreen:(NSInteger)lastGreen {
    
    if (userHandle != api.myUserHandle && (self.contactsMode != ContactsModeFolderSharedWith)) {
        MEGAChatStatus chatStatus = [MEGAChatSdk.shared userOnlineStatus:userHandle];
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

#pragma mark - ContactLinkQRViewControllerProtocol

- (void)emailForScannedQR:(NSString *)email {
    [self inviteEmailToShareFolder:email];
}

@end
