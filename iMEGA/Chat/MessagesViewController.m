#import "MessagesViewController.h"

#import "SVProgressHUD.h"
#import "UIImage+GKContact.h"

#import "BrowserViewController.h"
#import "CallViewController.h"
#import "ChatAttachedContactsViewController.h"
#import "ChatAttachedNodesViewController.h"
#import "ContactsViewController.h"
#import "ContactDetailsViewController.h"
#import "GroupChatDetailsViewController.h"

#import "Helper.h"
#import "DevicePermissionsHelper.h"
#import "MainTabBarController.h"
#import "MEGAAssetsPickerController.h"
#import "MEGAChatMessage+MNZCategory.h"
#import "MEGACreateFolderRequestDelegate.h"
#import "MEGACopyRequestDelegate.h"
#import "MEGAImagePickerController.h"
#import "MEGAInviteContactRequestDelegate.h"
#import "MEGAMessagesTypingIndicatorFoorterView.h"
#import "MEGANavigationController.h"
#import "MEGANode+MNZCategory.h"
#import "MEGANodeList+MNZCategory.h"
#import "MEGAOpenMessageHeaderView.h"
#import "MEGAProcessAsset.h"
#import "MEGAReachabilityManager.h"
#import "MEGAStartUploadTransferDelegate.h"
#import "MEGAStore.h"
#import "MEGAToolbarContentView.h"
#import "NSAttributedString+MNZCategory.h"
#import "NSString+MNZCategory.h"
#import "UIImage+MNZCategory.h"

#import <UserNotifications/UserNotifications.h>

const CGFloat kGroupChatCellLabelHeight = 35.0f;
const CGFloat k1on1CellLabelHeight = 28.0f;
const CGFloat kAvatarImageDiameter = 24.0f;

@interface MessagesViewController () <JSQMessagesViewAccessoryButtonDelegate, JSQMessagesComposerTextViewPasteDelegate, MEGAChatDelegate, MEGAChatRequestDelegate, MEGARequestDelegate>

@property (nonatomic, strong) MEGAOpenMessageHeaderView *openMessageHeaderView;
@property (nonatomic, strong) MEGAMessagesTypingIndicatorFoorterView *footerView;

@property (nonatomic, strong) NSMutableArray *messages;

@property (strong, nonatomic) JSQMessagesBubbleImage *outgoingBubbleImageData;
@property (strong, nonatomic) JSQMessagesBubbleImage *incomingBubbleImageData;

@property (nonatomic, strong) MEGAChatMessage *editMessage;

@property (nonatomic, assign) BOOL areAllMessagesSeen;
@property (nonatomic, assign) BOOL isFirstLoad;

@property (nonatomic, strong) NSTimer *sendTypingTimer;
@property (nonatomic, strong) NSTimer *receiveTypingTimer;
@property (nonatomic, strong) NSString *peerTyping;

@property (nonatomic, strong) UIBarButtonItem *unreadBarButtonItem;
@property (nonatomic, strong) UILabel *unreadLabel;

@property (nonatomic, getter=shouldStopInvitingContacts) BOOL stopInvitingContacts;

@property (strong, nonatomic) NSMutableDictionary *participantsMutableDictionary;
@property (strong, nonatomic) NSMutableArray *nodesLoaded;

@property (strong, nonatomic) UIProgressView *navigationBarProgressView;

@property (strong, nonatomic) UIBarButtonItem * videoCallBarButtonItem;
@property (strong, nonatomic) UIBarButtonItem * audioCallBarButtonItem;

@property (nonatomic) long long totalBytesToUpload;
@property (nonatomic) long long remainingBytesToUpload;
@property (nonatomic) float totalProgressOfTransfersCompleted;

@property (nonatomic) JSQMessagesAvatarImageFactory *avatarImageFactory;
@property (nonatomic) NSMutableDictionary *avatarImages;

@property (nonatomic) NSString *lastChatRoomStateString;
@property (nonatomic) UIColor *lastChatRoomStateColor;
@property (nonatomic) UIImage *peerAvatar;

@property (nonatomic) CGFloat lastBottomInset;
@property (nonatomic) CGFloat lastVerticalOffset;

@end

@implementation MessagesViewController

#pragma mark - Lifecycle

- (void)viewDidLoad {
    [super viewDidLoad];
    
    _messages = [[NSMutableArray alloc] init];
    
    if ([[MEGASdkManager sharedMEGAChatSdk] openChatRoom:self.chatRoom.chatId delegate:self]) {
        MEGALogDebug(@"Chat room opened: %@", self.chatRoom);
        self.isFirstLoad = YES;
        [self loadMessages];
    } else {
        UIAlertController *alertController = [UIAlertController alertControllerWithTitle:AMLocalizedString(@"error", nil) message:AMLocalizedString(@"chatNotFound", nil) preferredStyle:UIAlertControllerStyleAlert];
        [alertController addAction:[UIAlertAction actionWithTitle:AMLocalizedString(@"ok", nil) style:UIAlertActionStyleCancel handler:^(UIAlertAction *action) {
            [self.navigationController popViewControllerAnimated:YES];
        }]];
        [self presentViewController:alertController animated:YES completion:nil];
        MEGALogError(@"The delegate is NULL or the chatroom is not found");
    }
    
    self.inputToolbar.contentView.textView.jsq_pasteDelegate = self;
    
    UITapGestureRecognizer *tapGesture = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(hideInputToolbar)];
    tapGesture.cancelsTouchesInView = NO;
    [self.collectionView addGestureRecognizer:tapGesture];
    
    [self customiseCollectionViewLayout];
    
    [self.collectionView registerNib:[MEGAOpenMessageHeaderView nib] forSupplementaryViewOfKind:UICollectionElementKindSectionHeader withReuseIdentifier:[MEGAOpenMessageHeaderView headerReuseIdentifier]];
    
    [self.collectionView registerNib:[MEGAMessagesTypingIndicatorFoorterView nib] forSupplementaryViewOfKind:UICollectionElementKindSectionFooter withReuseIdentifier:[MEGAMessagesTypingIndicatorFoorterView footerReuseIdentifier]];
    
     //Set up message accessory button delegate and configuration
    self.collectionView.accessoryDelegate = self;
    
    self.showLoadEarlierMessagesHeader = YES;
    
     //Register custom menu actions for cells.
    [JSQMessagesCollectionViewCell registerMenuAction:@selector(edit:message:)];
    [JSQMessagesCollectionViewCell registerMenuAction:@selector(import:message:)];
    [JSQMessagesCollectionViewCell registerMenuAction:@selector(download:message:)];
    [JSQMessagesCollectionViewCell registerMenuAction:@selector(addContact:message:)];
    [JSQMessagesCollectionViewCell registerMenuAction:@selector(revoke:message:indexPath:)];

    [self setupMenuController:[UIMenuController sharedMenuController]];
    
     //Allow cells to be deleted
    [JSQMessagesCollectionViewCell registerMenuAction:@selector(delete:)];
    
    JSQMessagesBubbleImageFactory *bubbleFactory = [[JSQMessagesBubbleImageFactory alloc] initWithBubbleImage:[UIImage imageNamed:@"bubble_tailless"] capInsets:UIEdgeInsetsZero layoutDirection:[UIApplication sharedApplication].userInterfaceLayoutDirection];
    
    self.outgoingBubbleImageData = [bubbleFactory outgoingMessagesBubbleImageWithColor:[UIColor mnz_green00BFA5]];
    self.incomingBubbleImageData = [bubbleFactory incomingMessagesBubbleImageWithColor:[UIColor mnz_grayE2EAEA]];

    self.collectionView.backgroundColor = [UIColor whiteColor];
    
    [self customToolbarContentView];
    
    self.areAllMessagesSeen = NO;
    
    UITapGestureRecognizer *singleTap = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(popViewController)];
    
    _unreadLabel = [[UILabel alloc] initWithFrame:CGRectMake(25, 6, 30, 30)];
    self.unreadLabel.font = [UIFont mnz_SFUIMediumWithSize:12.0f];
    self.unreadLabel.textColor = [UIColor mnz_redD90007];
    self.unreadLabel.userInteractionEnabled = YES;
    
    if (self.presentingViewController && self.parentViewController) {
        _unreadBarButtonItem = [[UIBarButtonItem alloc] initWithCustomView:self.unreadLabel];
        UIBarButtonItem *chatBackBarButtonItem = [[UIBarButtonItem alloc] initWithTitle:AMLocalizedString(@"chat", @"Chat section header") style:UIBarButtonItemStylePlain target:self action:@selector(dismissChatRoom)];
        self.navigationItem.leftBarButtonItems = @[chatBackBarButtonItem, self.unreadBarButtonItem];
    } else {
        //TODO: leftItemsSupplementBackButton
        UIView *view = [[UIView alloc] initWithFrame:CGRectMake(0, 0, 66, 44)];
        UIImageView *imageView = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"backArrow"]];
        imageView.frame = CGRectMake(0, 10, 22, 22);
        [view addGestureRecognizer:singleTap];
        [view addSubview:imageView];
        [view addSubview:self.unreadLabel];
        
        UIBarButtonItem *backBarButtonItem = [[UIBarButtonItem alloc] initWithCustomView:view];
        self.navigationItem.leftBarButtonItems = @[backBarButtonItem];
    }
    self.stopInvitingContacts = NO;
    
    self.navigationController.interactivePopGestureRecognizer.delegate = nil;
    
    _nodesLoaded = [[NSMutableArray alloc] init];

    // Avatar images
    self.avatarImageFactory = [[JSQMessagesAvatarImageFactory alloc] initWithDiameter:kAvatarImageDiameter];
    self.avatarImages = [[NSMutableDictionary alloc] init];
    
    _lastChatRoomStateString = @"";
    _lastChatRoomStateColor = [UIColor whiteColor];
    if (self.chatRoom.isGroup) {
        _peerAvatar = [UIImage imageForName:self.chatRoom.title.uppercaseString size:CGSizeMake(80.0f, 80.0f) backgroundColor:[UIColor mnz_gray999999] textColor:[UIColor whiteColor] font:[UIFont mnz_SFUIRegularWithSize:40.0f]];
    } else {
        _peerAvatar = [UIImage mnz_imageForUserHandle:[self.chatRoom peerHandleAtIndex:0] size:CGSizeMake(80.0f, 80.0f) delegate:nil];
    }
    
    // Add an observer to get notified when going to background:
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(willResignActive)
                                                 name:UIApplicationWillResignActiveNotification
                                               object:nil];
    
    // Add an observer to get notified when coming back to foreground:
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(willEnterForeground)
                                                 name:UIApplicationWillEnterForegroundNotification
                                               object:nil];
    
    if (@available(iOS 10.0, *)) {
        [[UNUserNotificationCenter currentNotificationCenter] removeDeliveredNotificationsWithIdentifiers:@[[MEGASdk base64HandleForUserHandle:self.chatRoom.chatId]]];
        [[UNUserNotificationCenter currentNotificationCenter] removePendingNotificationRequestsWithIdentifiers:@[[MEGASdk base64HandleForUserHandle:self.chatRoom.chatId]]];
    }
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    
    [[MEGASdkManager sharedMEGAChatSdk] addChatDelegate:self];
    
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(internetConnectionChanged) name:kReachabilityChangedNotification object:nil];
    
    [self customNavigationBarLabel];
    [self rightBarButtonItems];
    [self updateUnreadLabel];
    
    self.inputToolbar.contentView.textView.text = [[MEGAStore shareInstance] fetchChatDraftWithChatId:self.chatRoom.chatId].text;
}

- (void)willEnterForeground {
    // Workaround to avoid wrong collection view height when coming back to foreground
    if ([self.inputToolbar.contentView.textView isFirstResponder]) {
        [self jsq_setCollectionViewInsetsTopValue:0.0f bottomValue:self.lastBottomInset];
        CGPoint offset = self.collectionView.contentOffset;
        offset.y = self.lastVerticalOffset;
        self.collectionView.contentOffset = offset;
    }
}

- (void)willResignActive {
    [[MEGAStore shareInstance] insertOrUpdateChatDraftWithChatId:self.chatRoom.chatId text:self.inputToolbar.contentView.textView.text];
    self.lastBottomInset = self.collectionView.scrollIndicatorInsets.bottom;
    self.lastVerticalOffset = self.collectionView.contentOffset.y;
}

- (void)viewWillDisappear:(BOOL)animated {
    [super viewWillDisappear:animated];
    
    [[NSNotificationCenter defaultCenter] removeObserver:self name:kReachabilityChangedNotification object:nil];

    if ([self.navigationController.viewControllers indexOfObject:self] == NSNotFound || self.presentingViewController) {
        [[MEGASdkManager sharedMEGAChatSdk] closeChatRoom:self.chatRoom.chatId delegate:self];
    }
    [[MEGASdkManager sharedMEGAChatSdk] removeChatDelegate:self];
    
    self.automaticallyScrollsToMostRecentMessage = NO;
    
    [[MEGAStore shareInstance] insertOrUpdateChatDraftWithChatId:self.chatRoom.chatId text:self.inputToolbar.contentView.textView.text];
}

- (BOOL)hidesBottomBarWhenPushed {
    return YES;
}

- (void)popViewController {
    [self.navigationController popViewControllerAnimated:YES];
}

- (void)dismissChatRoom {
    [self dismissViewControllerAnimated:YES completion:nil];
}

#pragma mark - Private methods

- (void)loadMessages {
    NSInteger loadMessage = [[MEGASdkManager sharedMEGAChatSdk] loadMessagesForChat:self.chatRoom.chatId count:32];
    switch (loadMessage) {
        case 0:
            MEGALogDebug(@"There's no more history available");
            break;
            
        case 1:
            MEGALogDebug(@"Messages will be fetched locally");
            break;
            
        case 2:
            MEGALogDebug(@"Messages will be requested to the server");
            break;
            
        default:
            break;
    }
}

- (void)customNavigationBarLabel {    
    if (self.chatRoom.ownPrivilege <= MEGAChatRoomPrivilegeRo) {
        self.inputToolbar.hidden = YES;
    } else {
        self.inputToolbar.hidden = NO;
    }
    
    UILabel *label = [[UILabel alloc] init];
    NSString *chatRoomTitle = self.chatRoom.title ? self.chatRoom.title : @"";
    NSString *chatRoomState;
    
    MEGAChatConnection connectionState = [[MEGASdkManager sharedMEGAChatSdk] chatConnectionState:self.chatRoom.chatId];
    switch (connectionState) {
        case MEGAChatConnectionOffline:
        case MEGAChatConnectionInProgress:            
        case MEGAChatConnectionLogging:
            chatRoomState = AMLocalizedString(@"connecting", nil);
            self.lastChatRoomStateColor = [UIColor mnz_colorForStatusChange:MEGAChatStatusOffline];
            
            break;
            
        case MEGAChatConnectionOnline:
            if (self.chatRoom.isGroup) {
                if (self.chatRoom.ownPrivilege <= MEGAChatRoomPrivilegeRo) {
                    chatRoomState = AMLocalizedString(@"readOnly", @"Permissions given to the user you share your folder with");
                }
            } else {
                if (self.chatRoom.ownPrivilege <= MEGAChatRoomPrivilegeRo) {
                    chatRoomState = AMLocalizedString(@"readOnly", @"Permissions given to the user you share your folder with");
                } else {
                    chatRoomState = [NSString chatStatusString:[[MEGASdkManager sharedMEGAChatSdk] userOnlineStatus:[self.chatRoom peerHandleAtIndex:0]]];
                    self.lastChatRoomStateColor = [UIColor mnz_colorForStatusChange:[[MEGASdkManager sharedMEGAChatSdk] userOnlineStatus:[self.chatRoom peerHandleAtIndex:0]]];
                }
            }
            break;
    }
    
    if (chatRoomState) {
        label = [Helper customNavigationBarLabelWithTitle:chatRoomTitle subtitle:chatRoomState];
        self.lastChatRoomStateString = chatRoomState;
    } else {
        label = [Helper customNavigationBarLabelWithTitle:chatRoomTitle subtitle:@""];
    }
    
    label.adjustsFontSizeToFitWidth = YES;
    label.minimumScaleFactor = 0.8f;
    label.frame = CGRectMake(0, 0, self.navigationItem.titleView.bounds.size.width, 44);
    [self.navigationItem setTitleView:label];
    
    label.userInteractionEnabled = YES;
    label.superview.userInteractionEnabled = YES;
    
    UITapGestureRecognizer *titleTapRecognizer =
    [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(chatRoomTitleDidTap)];
    label.gestureRecognizers = @[titleTapRecognizer];
}

- (void)rightBarButtonItems {
    if (self.chatRoom.isGroup) {
        if (self.chatRoom.ownPrivilege == MEGAChatRoomPrivilegeModerator) {
            UIBarButtonItem *addContactBarButtonItem = [[UIBarButtonItem alloc] initWithImage:[UIImage imageNamed:@"addContact"] style:UIBarButtonItemStyleDone target:self action:@selector(presentAddOrAttachParticipantToGroup:)];
            self.navigationItem.rightBarButtonItem = addContactBarButtonItem;
        }
    } else {
        _videoCallBarButtonItem = [[UIBarButtonItem alloc] initWithImage:[UIImage imageNamed:@"videoCall"] style:UIBarButtonItemStyleDone target:self action:@selector(startAudioVideoCall:)];
        _audioCallBarButtonItem = [[UIBarButtonItem alloc] initWithImage:[UIImage imageNamed:@"audioCall"] style:UIBarButtonItemStyleDone target:self action:@selector(startAudioVideoCall:)];
        self.videoCallBarButtonItem.tag = 1;
        self.navigationItem.rightBarButtonItems = @[self.videoCallBarButtonItem, self.audioCallBarButtonItem];
        self.audioCallBarButtonItem.enabled = self.videoCallBarButtonItem.enabled = ((self.chatRoom.ownPrivilege >= MEGAChatRoomPrivilegeStandard) && [MEGAReachabilityManager isReachable]);
    }
}

- (void)startAudioVideoCall:(UIBarButtonItem *)sender {
    [DevicePermissionsHelper audioPermissionWithCompletionHandler:^(BOOL granted) {
        if (granted) {
            if (sender.tag) {
                [DevicePermissionsHelper videoPermissionWithCompletionHandler:^(BOOL granted) {
                    if (granted) {
                        [self openCallViewWithVideo:sender.tag];
                    } else {
                        [self presentViewController:[DevicePermissionsHelper videoPermisionAlertController] animated:YES completion:nil];
                    }
                }];
            } else {
                [self openCallViewWithVideo:sender.tag];
            }
        } else {
            [self presentViewController:[DevicePermissionsHelper audioPermisionAlertController] animated:YES completion:nil];
        }
    }];
}

- (void)openCallViewWithVideo:(BOOL)videoCall {
    if ([[UIDevice currentDevice] orientation] != UIInterfaceOrientationPortrait) {
        NSNumber *value = [NSNumber numberWithInt:UIInterfaceOrientationPortrait];
        [[UIDevice currentDevice] setValue:value forKey:@"orientation"];
    }
    CallViewController *callVC = [[UIStoryboard storyboardWithName:@"Chat" bundle:nil] instantiateViewControllerWithIdentifier:@"CallViewControllerID"];
    callVC.chatRoom = self.chatRoom;
    callVC.videoCall = videoCall;
    callVC.callType = CallTypeOutgoing;
    callVC.modalTransitionStyle = UIModalTransitionStyleCrossDissolve;

    if (@available(iOS 10.0, *)) {
        callVC.megaCallManager = [(MainTabBarController *)self.navigationController.tabBarController megaCallManager];
    }
    [self presentViewController:callVC animated:YES completion:nil];
}

- (void)presentAddOrAttachParticipantToGroup:(UIBarButtonItem *)sender {
    BOOL addParticipant = sender ? YES : NO;
    MEGANavigationController *navigationController = [[UIStoryboard storyboardWithName:@"Contacts" bundle:nil] instantiateViewControllerWithIdentifier:@"ContactsNavigationControllerID"];
    ContactsViewController *contactsVC = navigationController.viewControllers.firstObject;
    contactsVC.contactsMode = addParticipant ? ContactsModeChatAddParticipant : ContactsModeChatAttachParticipant;
    self.participantsMutableDictionary = [[NSMutableDictionary alloc] init];
    NSUInteger peerCount = self.chatRoom.peerCount;
    for (NSUInteger i = 0; i < peerCount; i++) {
        uint64_t peerHandle = [self.chatRoom peerHandleAtIndex:i];
        if ([self.chatRoom peerPrivilegeByHandle:peerHandle] > MEGAChatRoomPrivilegeRm) {
            [self.participantsMutableDictionary setObject:[NSNumber numberWithUnsignedLongLong:peerHandle] forKey:[NSNumber numberWithUnsignedLongLong:peerHandle]];
        }
    }
    contactsVC.participantsMutableDictionary = [self.participantsMutableDictionary copy];
    
    contactsVC.userSelected = ^void(NSArray *users) {
        if (addParticipant) {
            for (NSInteger i = 0; i < users.count; i++) {
                if (self.shouldStopInvitingContacts) {
                    break;
                }
                MEGAUser *user = [users objectAtIndex:i];
                [[MEGASdkManager sharedMEGAChatSdk] inviteToChat:self.chatRoom.chatId user:user.handle privilege:MEGAChatRoomPrivilegeStandard delegate:self];
            }
        } else {
            MEGAChatMessage *message = [[MEGASdkManager sharedMEGAChatSdk] attachContactsToChat:self.chatRoom.chatId contacts:users];
            message.chatRoom = self.chatRoom;
            [self.messages addObject:message];
            [self.collectionView insertItemsAtIndexPaths:@[[NSIndexPath indexPathForItem:self.messages.count-1 inSection:0]]];
            [self finishSendingMessageAnimated:YES];
        }
    };
    
    [self presentViewController:navigationController animated:YES completion:^{
        self.automaticallyScrollsToMostRecentMessage = YES;
    }];
}

- (void)updateUnreadLabel {
    NSInteger unreadChats = [[MEGASdkManager sharedMEGAChatSdk] unreadChats];
    NSString *unreadChatsString = unreadChats ? [NSString stringWithFormat:@"(%ld)", unreadChats] : nil;
    self.unreadLabel.text = unreadChatsString;
}

- (void)customiseCollectionViewLayout {
    self.collectionView.collectionViewLayout.messageBubbleFont = [UIFont mnz_SFUIRegularWithSize:15.0f];
    self.collectionView.collectionViewLayout.messageBubbleTextViewFrameInsets = UIEdgeInsetsMake(0.0f, 0.0f, 0.0f, 0.0f);
    self.collectionView.collectionViewLayout.messageBubbleTextViewTextContainerInsets = UIEdgeInsetsMake(10.0f, 10.0f, 10.0f, 10.0f);
    
    self.collectionView.collectionViewLayout.incomingAvatarViewSize = CGSizeMake(kAvatarImageDiameter, kAvatarImageDiameter);
    self.collectionView.collectionViewLayout.outgoingAvatarViewSize = CGSizeMake(0.0f, 0.0f);
    
    self.collectionView.collectionViewLayout.minimumLineSpacing = 5.0f;
    
    self.collectionView.collectionViewLayout.sectionInset = UIEdgeInsetsMake(10.0f, 17.0f, 10.0f, 17.0f);
    self.collectionView.collectionViewLayout.messageBubbleLeftRightMargin = 10.0f;
}

- (void)customToolbarContentView {
    self.inputToolbar.contentView.textView.placeHolderTextColor = [UIColor mnz_grayCCCCCC];
    self.inputToolbar.contentView.textView.placeHolder = AMLocalizedString(@"writeAMessage", @"Message box label which shows that user can type message text in this textview");
    self.inputToolbar.contentView.textView.font = [UIFont mnz_SFUIRegularWithSize:15.0f];
    self.inputToolbar.contentView.textView.textColor = [UIColor mnz_black333333];
    self.inputToolbar.contentView.textView.tintColor = [UIColor mnz_green00BFA5];
}

- (BOOL)showDateBetweenMessage:(MEGAChatMessage *)message previousMessage:(MEGAChatMessage *)previousMessage {
    if ((previousMessage.senderId != message.senderId) || (previousMessage.date != message.date)) {
        NSDateComponents *previousDateComponents = [[NSCalendar currentCalendar] components:NSCalendarUnitDay | NSCalendarUnitMonth | NSCalendarUnitYear fromDate:previousMessage.date];
        NSDateComponents *currentDateComponents = [[NSCalendar currentCalendar] components:NSCalendarUnitDay | NSCalendarUnitMonth | NSCalendarUnitYear fromDate:message.date];
        if (previousDateComponents.day != currentDateComponents.day || previousDateComponents.month != currentDateComponents.month || previousDateComponents.year != currentDateComponents.year) {
            return YES;
        }
    }
    
    return NO;
}

- (BOOL)showHourForMessage:(MEGAChatMessage *)message withIndexPath:(NSIndexPath *)indexPath {
    if (message.managementMessage || indexPath.item == 0) {
        return YES;
    }
    
    MEGAChatMessage *previousMessage = [self.messages objectAtIndex:(indexPath.item - 1)];
    if (previousMessage.isManagementMessage) {
        return YES;
    }
    
    BOOL showHour = NO;
    if ([message.senderId isEqualToString:previousMessage.senderId]) {
        if ([self showHourBetweenDate:message.date previousDate:previousMessage.date]) {
            showHour = YES;
        } else {
            JSQMessagesCollectionViewCell *previousMessageCell = (JSQMessagesCollectionViewCell *)[self.collectionView cellForItemAtIndexPath:[NSIndexPath indexPathForItem:(indexPath.item - 1) inSection:0]];
            if (previousMessageCell.messageBubbleTopLabel.attributedText == nil) {
                NSUInteger count = self.messages.count;
                for (NSUInteger i = 1; i < count; i++) {
                    NSInteger index = (indexPath.item - (i + 1));
                    if (index > 0) {
                        MEGAChatMessage *messagePriorToThePreviousOne = [self.messages objectAtIndex:index];
                        if (messagePriorToThePreviousOne.messageIndex < 0) {
                            break;
                        }
                        
                        if ([message.senderId isEqualToString:messagePriorToThePreviousOne.senderId]) {
                            if ([self showHourBetweenDate:message.date previousDate:messagePriorToThePreviousOne.date]) {
                                JSQMessagesCollectionViewCell *messagePriorToThePreviousOneCell = (JSQMessagesCollectionViewCell *)[self.collectionView cellForItemAtIndexPath:[NSIndexPath indexPathForItem:index inSection:0]];
                                if (messagePriorToThePreviousOneCell.messageBubbleTopLabel.attributedText) {
                                    break;
                                }
                            }
                        } else { //The timestamp should not appear because is already shown on the message prior to the previous message, that has a different sender
                            break;
                        }
                    }
                }
            }
        }
    } else { //If the previous message is from other sender, show timestamp
        showHour = YES;
    }
    
    return showHour;
}

- (BOOL)showHourBetweenDate:(NSDate *)date previousDate:(NSDate *)previousDate {
    NSUInteger numberOfSecondsToShowHour = (60 * 6) - 1;
    NSTimeInterval timeDifferenceBetweenMessages = [date timeIntervalSinceDate:previousDate];
    if (timeDifferenceBetweenMessages > numberOfSecondsToShowHour) {
        return YES;
    }

    return NO;
}

- (void)chatRoomTitleDidTap {
    if (self.chatRoom.isGroup) {
        GroupChatDetailsViewController *groupChatDetailsVC = [[UIStoryboard storyboardWithName:@"Chat" bundle:nil] instantiateViewControllerWithIdentifier:@"GroupChatDetailsViewControllerID"];
        groupChatDetailsVC.chatRoom = self.chatRoom;
        
        [self.navigationController pushViewController:groupChatDetailsVC animated:YES];
    } else {
        NSString *peerEmail = [[MEGASdkManager sharedMEGAChatSdk] contacEmailByHandle:[self.chatRoom peerHandleAtIndex:0]];
        NSString *peerFirstname = [self.chatRoom peerFirstnameAtIndex:0];
        NSString *peerLastname = [self.chatRoom peerLastnameAtIndex:0];
        NSString *peerName = [NSString stringWithFormat:@"%@ %@", peerFirstname, peerLastname];
        uint64_t peerHandle = [self.chatRoom peerHandleAtIndex:0];
        
        ContactDetailsViewController *contactDetailsVC = [[UIStoryboard storyboardWithName:@"Contacts" bundle:nil] instantiateViewControllerWithIdentifier:@"ContactDetailsViewControllerID"];
        contactDetailsVC.contactDetailsMode = ContactDetailsModeFromChat;
        contactDetailsVC.chatId = self.chatRoom.chatId;
        contactDetailsVC.userEmail = peerEmail;
        contactDetailsVC.userName = peerName;
        contactDetailsVC.userHandle = peerHandle;
        [self.navigationController pushViewController:contactDetailsVC animated:YES];
    }
}

- (void)setChatOpenMessageForIndexPath:(NSIndexPath *)indexPath {
    if (self.openMessageHeaderView == nil) {
        self.openMessageHeaderView = [self.collectionView dequeueReusableSupplementaryViewOfKind:UICollectionElementKindSectionHeader withReuseIdentifier:@"MEGAOpenMessageHeaderViewID" forIndexPath:indexPath];
    }
    
    NSString *participantsNames = @"";
    for (NSUInteger i = 0; i < self.chatRoom.peerCount; i++) {
        NSString *peerName;
        NSString *peerFirstname = [self.chatRoom peerFirstnameAtIndex:i];
        if (peerFirstname.length > 0 && ![[peerFirstname stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceCharacterSet]] isEqualToString:@""]) {
            peerName = peerFirstname;
        } else {
            NSString *peerLastname = [self.chatRoom peerLastnameAtIndex:i];
            if (peerLastname.length > 0 && ![[peerLastname stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceCharacterSet]] isEqualToString:@""]) {
                peerName = peerLastname;
            }
        }
        
        if (!peerName.length) {
            peerName = [self.chatRoom peerEmailByHandle:[self.chatRoom peerHandleAtIndex:i]];
        }
        
        if (self.chatRoom.peerCount == 1 || (i + 1) == self.chatRoom.peerCount) {
            participantsNames = [participantsNames stringByAppendingString:peerName ? peerName : @"Unknown user"];
        } else {
            participantsNames = [participantsNames stringByAppendingString:[NSString stringWithFormat:@"%@, ", peerName]];
        }
    }
    
    //TODO: Show text in chattingWithLabel when its string is translated.
//    self.openMessageHeaderView.chattingWithLabel.text = AMLocalizedString(@"chattingWith", @"Title show above the name of the persons with whom you're chatting");
    self.openMessageHeaderView.chattingWithLabel.text = nil;
    self.openMessageHeaderView.conversationWithLabel.text = participantsNames;
    self.openMessageHeaderView.onlineStatusLabel.text = self.lastChatRoomStateString;
    self.openMessageHeaderView.onlineStatusView.backgroundColor = self.lastChatRoomStateColor;
    self.openMessageHeaderView.conversationWithAvatar.image = self.chatRoom.isGroup ? nil : self.peerAvatar;
    self.openMessageHeaderView.introductionLabel.text = AMLocalizedString(@"chatIntroductionMessage", @"Full text: MEGA protects your chat with end-to-end (user controlled) encryption providing essential safety assurances: Confidentiality - Only the author and intended recipients are able to decipher and read the content. Authenticity - There is an assurance that the message received was authored by the stated sender, and its content has not been tampered with during transport or on the server.");
    
    NSString *confidentialityExplanationString = AMLocalizedString(@"confidentialityExplanation", @"Chat advantages information. Full text: Mega protects your chat with end-to-end (user controlled) encryption providing essential safety assurances: [S]Confidentiality.[/S] Only the author and intended recipients are able to decipher and read the content. [S]Authenticity.[/S] The system ensures that the data received is from the sender displayed, and its content has not been manipulated during transit.");
    NSString *confidentialityString = [confidentialityExplanationString mnz_stringBetweenString:@"[S]" andString:@"[/S]"];
    confidentialityExplanationString = [confidentialityExplanationString stringByReplacingOccurrencesOfString:[NSString stringWithFormat:@"[S]%@[/S]", confidentialityString] withString:@""];
    
    NSMutableAttributedString *confidentialityAttributedString = [[NSMutableAttributedString alloc] initWithString:confidentialityString attributes:@{NSFontAttributeName:[UIFont mnz_SFUIRegularWithSize:15.0f], NSForegroundColorAttributeName:[UIColor mnz_redF0373A]}];
    NSMutableAttributedString *confidentialityExplanationAttributedString = [[NSMutableAttributedString alloc] initWithString:confidentialityExplanationString attributes:@{NSFontAttributeName:[UIFont mnz_SFUIRegularWithSize:15.0f], NSForegroundColorAttributeName:[UIColor mnz_gray777777]}];
    [confidentialityAttributedString appendAttributedString:confidentialityExplanationAttributedString];
    self.openMessageHeaderView.confidentialityLabel.attributedText = confidentialityAttributedString;
    
    NSString *authenticityExplanationString = AMLocalizedString(@"authenticityExplanation", @"Chat advantages information. Full text: Mega protects your chat with end-to-end (user controlled) encryption providing essential safety assurances: [S]Confidentiality.[/S] Only the author and intended recipients are able to decipher and read the content. [S]Authenticity.[/S] The system ensures that the data received is from the sender displayed, and its content has not been manipulated during transit.");
    NSString *authenticityString = [authenticityExplanationString mnz_stringBetweenString:@"[S]" andString:@"[/S]"];
    authenticityExplanationString = [authenticityExplanationString stringByReplacingOccurrencesOfString:[NSString stringWithFormat:@"[S]%@[/S]", authenticityString] withString:@""];

    NSMutableAttributedString *authenticityAttributedString = [[NSMutableAttributedString alloc] initWithString:authenticityString attributes:@{NSFontAttributeName:[UIFont mnz_SFUIRegularWithSize:15.0f], NSForegroundColorAttributeName:[UIColor mnz_redF0373A]}];
    NSMutableAttributedString *authenticityExplanationAttributedString = [[NSMutableAttributedString alloc] initWithString:authenticityExplanationString attributes:@{NSFontAttributeName:[UIFont mnz_SFUIRegularWithSize:15.0f], NSForegroundColorAttributeName:[UIColor mnz_gray777777]}];
    [authenticityAttributedString appendAttributedString:authenticityExplanationAttributedString];
    self.openMessageHeaderView.authenticityLabel.attributedText = authenticityAttributedString;
}

- (void)hideTypingIndicator {
    self.showTypingIndicator = NO;
}

- (void)doNothing {}

- (void)setupMenuController:(UIMenuController *)menuController {
    UIMenuItem *editMenuItem = [[UIMenuItem alloc] initWithTitle:AMLocalizedString(@"edit", @"Caption of a button to edit the files that are selected") action:@selector(edit:message:)];
    UIMenuItem *importMenuItem = [[UIMenuItem alloc] initWithTitle:AMLocalizedString(@"import", @"Caption of a button to edit the files that are selected") action:@selector(import:message:)];
    UIMenuItem *downloadMenuItem = [[UIMenuItem alloc] initWithTitle:AMLocalizedString(@"saveForOffline", @"Caption of a button to edit the files that are selected") action:@selector(download:message:)];
    UIMenuItem *addContactMenuItem = [[UIMenuItem alloc] initWithTitle:AMLocalizedString(@"addContact", @"Alert title shown when you select to add a contact inserting his/her email") action:@selector(addContact:message:)];
    UIMenuItem *revokeMenuItem = [[UIMenuItem alloc] initWithTitle:AMLocalizedString(@"revoke", @"A button title to revoke the access to an attachment in a chat.") action:@selector(revoke:message:indexPath:)];
    menuController.menuItems = @[importMenuItem, editMenuItem, downloadMenuItem, addContactMenuItem, revokeMenuItem];
}

- (void)loadNodesFromMessage:(MEGAChatMessage *)message atTheBeginning:(BOOL)atTheBeginning {
    if (message.type == MEGAChatMessageTypeAttachment) {
        for (NSUInteger i = 0; i < message.nodeList.size.integerValue; i++) {
            MEGANode *node = [message.nodeList nodeAtIndex:i];
            if (atTheBeginning) {
                [self.nodesLoaded insertObject:node atIndex:0];
            } else {
                [self.nodesLoaded addObject:node];
            }
        }
    }
}

- (void)showImagePickerForSourceType:(UIImagePickerControllerSourceType)sourceType {
    if (sourceType == UIImagePickerControllerSourceTypeCamera) {
        MEGAImagePickerController *imagePickerController = [[MEGAImagePickerController alloc] initToShareThroughChatWithSourceType:sourceType filePathCompletion:^(NSString *filePath, UIImagePickerControllerSourceType sourceType) {
            MEGANode *parentNode = [[MEGASdkManager sharedMEGASdk] nodeForPath:@"/My chat files"];
            [self startUploadAndAttachWithPath:filePath parentNode:parentNode];
        }];
        
        [self presentViewController:imagePickerController animated:YES completion:^{
            self.automaticallyScrollsToMostRecentMessage = YES;
        }];
    }
}

- (void)startUploadAndAttachWithPath:(NSString *)path parentNode:(MEGANode *)parentNode {
    [self showProgressViewUnderNavigationBar];
    
    MEGAStartUploadTransferDelegate *startUploadTransferDelegate = [[MEGAStartUploadTransferDelegate alloc] initToUploadToChatWithTotalBytes:^(long long totalBytes) {
        self.totalBytesToUpload += totalBytes;
        self.remainingBytesToUpload += totalBytes;
    } progress:^(float transferredBytes, float totalBytes) {
        float asignableProgresRegardWithTotal = (totalBytes / self.totalBytesToUpload);
        float transferProgress = (transferredBytes / totalBytes);
        float currentAsignableProgressForThisTransfer = (transferProgress * asignableProgresRegardWithTotal);
        
        if (currentAsignableProgressForThisTransfer < asignableProgresRegardWithTotal) {
            if (self.totalProgressOfTransfersCompleted != 0) {
                currentAsignableProgressForThisTransfer += self.totalProgressOfTransfersCompleted;
            }
            
            if (currentAsignableProgressForThisTransfer > self.navigationBarProgressView.progress) {
                [self.navigationBarProgressView setProgress:currentAsignableProgressForThisTransfer animated:YES];
            }
        }
    } completion:^(long long totalBytes) {
        float progressCompletedRegardWithTotal = ((float)totalBytes / self.totalBytesToUpload);
        self.totalProgressOfTransfersCompleted += progressCompletedRegardWithTotal;
        self.remainingBytesToUpload -= totalBytes;
        
        if (self.remainingBytesToUpload == 0) {
            [self resetAndHideProgressView];
        }
    }];
    
    NSString *appData = [NSString stringWithFormat:@"attachToChatID=%llu", self.chatRoom.chatId];
    [[MEGASdkManager sharedMEGASdk] startUploadWithLocalPath:path parent:parentNode appData:appData isSourceTemporary:YES delegate:startUploadTransferDelegate];
}

- (void)attachOrCopyAndAttachNode:(MEGANode *)node toParentNode:(MEGANode *)parentNode {
    if (node) {
        if (node.parentHandle == parentNode.handle) {
            // The file is already in the folder, attach node.
            [[MEGASdkManager sharedMEGAChatSdk] attachNodeToChat:self.chatRoom.chatId node:node.handle delegate:self];
        } else {
            MEGACopyRequestDelegate *copyRequestDelegate = [[MEGACopyRequestDelegate alloc] initToAttachToChatWithCompletion:^{
                [[MEGASdkManager sharedMEGAChatSdk] attachNodeToChat:self.chatRoom.chatId node:node.handle delegate:self];
            }];
            // The file is already in MEGA, in other folder, has to be copied to this folder.
            [[MEGASdkManager sharedMEGASdk] copyNode:node newParent:parentNode delegate:copyRequestDelegate];
        }
    }
}

- (void)showProgressViewUnderNavigationBar {
    if (self.navigationBarProgressView) {
        self.navigationBarProgressView.hidden = NO;
    } else {
        self.navigationBarProgressView = [[UIProgressView alloc] initWithProgressViewStyle:UIProgressViewStyleBar];
        self.navigationBarProgressView.autoresizingMask = UIViewAutoresizingFlexibleLeftMargin | UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleRightMargin;
        self.navigationBarProgressView.frame = CGRectMake(self.navigationController.navigationBar.bounds.origin.x, self.navigationController.navigationBar.bounds.size.height, self.navigationController.navigationBar.bounds.size.width, 2.0f);
        self.navigationBarProgressView.progressTintColor = [UIColor mnz_redD90007];
        self.navigationBarProgressView.trackTintColor = [UIColor clearColor];
        
        dispatch_async(dispatch_get_main_queue(), ^{
            [self.navigationController.navigationBar addSubview:self.navigationBarProgressView];
        });
    }
}

- (void)resetAndHideProgressView {
    self.totalBytesToUpload = 0.0;
    self.totalProgressOfTransfersCompleted = 0.0f;
    self.navigationBarProgressView.progress = 0.0f;
    self.navigationBarProgressView.hidden = YES;
}

- (void)handleTruncateMessage:(MEGAChatMessage *)message {
    [self.messages removeAllObjects];
    [self.messages addObject:message];
    [self.collectionView reloadData];
    [self.nodesLoaded removeAllObjects];
}

- (void)internetConnectionChanged {
    self.audioCallBarButtonItem.enabled = self.videoCallBarButtonItem.enabled = ((self.chatRoom.ownPrivilege >= MEGAChatRoomPrivilegeStandard) && [MEGAReachabilityManager isReachable]);
    
    [self customNavigationBarLabel];

    if (self.openMessageHeaderView) {
        self.openMessageHeaderView.onlineStatusLabel.text = self.lastChatRoomStateString;
        self.openMessageHeaderView.onlineStatusView.backgroundColor = self.lastChatRoomStateColor;
    }
}

- (void)hideInputToolbar {
    if (self.inputToolbar.imagePickerView) {
        [self.inputToolbar mnz_accesoryButtonPressed:self.inputToolbar.imagePickerView.accessoryImageButton];
    } else if (self.inputToolbar.contentView.textView.isFirstResponder) {
        [self.inputToolbar mnz_accesoryButtonPressed:self.inputToolbar.contentView.accessoryTextButton];
    }
}

#pragma mark - Custom menu actions for cells

- (void)didReceiveMenuWillShowNotification:(NSNotification *)notification {
     //Display custom menu actions for cells.
    [self setupMenuController:[notification object]];
    
    [super didReceiveMenuWillShowNotification:notification];
}

#pragma mark - JSQMessagesViewController method overrides

- (void)didPressSendButton:(UIButton *)button
           withMessageText:(NSString *)text
                  senderId:(NSString *)senderId
         senderDisplayName:(NSString *)senderDisplayName
                      date:(NSDate *)date {
    
    if (text.mnz_isEmpty) {
        return;
    }
    
    MEGAChatMessage *message;
    if (self.editMessage) {
        if ([self.editMessage.content isEqualToString:self.inputToolbar.contentView.textView.text]) {
            //If the user didn't change anything on the message that was editing, just go out of edit mode.
        } else {
            uint64_t messageId = (self.editMessage.status == MEGAChatMessageStatusSending) ? self.editMessage.temporalId : self.editMessage.messageId;
            message = [[MEGASdkManager sharedMEGAChatSdk] editMessageForChat:self.chatRoom.chatId messageId:messageId message:text];
            message.chatRoom = self.chatRoom;
            NSUInteger index = [self.messages indexOfObject:self.editMessage];
            if (index != NSNotFound) {
                [self.messages replaceObjectAtIndex:index withObject:message];
                [self.collectionView reloadItemsAtIndexPaths:@[[NSIndexPath indexPathForItem:index inSection:0]]];
            }
        }
        
        self.automaticallyScrollsToMostRecentMessage = NO;
        
        self.editMessage = nil;
    } else {
        message = [[MEGASdkManager sharedMEGAChatSdk] sendMessageToChat:self.chatRoom.chatId message:text];
        message.chatRoom = self.chatRoom;
        [self.messages addObject:message];
        [self.collectionView insertItemsAtIndexPaths:@[[NSIndexPath indexPathForItem:self.messages.count-1 inSection:0]]];
        
        self.automaticallyScrollsToMostRecentMessage = YES;
    }
    
    MEGALogInfo(@"didPressSendButton %@", message);
    
    [self finishSendingMessageAnimated:YES];
}

- (void)messagesInputToolbar:(MEGAInputToolbar *)toolbar didPressSendButton:(UIButton *)sender toAttachAssets:(NSArray<PHAsset *> *)assets {
    MEGANode *parentNode = [[MEGASdkManager sharedMEGASdk] nodeForPath:@"/My chat files"];
    if (parentNode) {
        [self uploadAssets:assets toParentNode:parentNode];
    } else {
        MEGACreateFolderRequestDelegate *createFolderRequestDelegate = [[MEGACreateFolderRequestDelegate alloc] initWithCompletion:^(MEGARequest *request) {
            MEGANode *node = [[MEGASdkManager sharedMEGASdk] nodeForHandle:request.nodeHandle];
            [self uploadAssets:assets toParentNode:node];
        }];
        [[MEGASdkManager sharedMEGASdk] createFolderWithName:@"My chat files" parent:[[MEGASdkManager sharedMEGASdk] rootNode] delegate:createFolderRequestDelegate];
    }
}

- (void)uploadAssets:(NSArray<PHAsset *> *)assets toParentNode:(MEGANode *)parentNode {
    for (PHAsset *asset in assets) {
        MEGAProcessAsset *processAsset = [[MEGAProcessAsset alloc] initToShareThroughChatWithAsset:asset filePath:^(NSString *filePath) {
            [self startUploadAndAttachWithPath:filePath parentNode:parentNode];
        } node:^(MEGANode *node) {
            [self attachOrCopyAndAttachNode:node toParentNode:parentNode];
        } error:^(NSError *error) {
            NSString *message;
            NSString *title;
            switch (error.code) {
                case -1:
                    title = error.localizedDescription;
                    message = error.localizedFailureReason;
                    break;
                    
                case -2:
                    title = AMLocalizedString(@"error", nil);
                    message = error.localizedDescription;
                    break;
                    
                default:
                    title = AMLocalizedString(@"error", nil);
                    message = error.localizedDescription;
                    break;
            }
            UIAlertController *alertController = [UIAlertController alertControllerWithTitle:title message:message preferredStyle:UIAlertControllerStyleAlert];
            [alertController addAction:[UIAlertAction actionWithTitle:AMLocalizedString(@"ok", nil) style:UIAlertActionStyleCancel handler:nil]];
            [self presentViewController:alertController animated:YES completion:nil];
        }];
        [processAsset prepare];
    }
}

- (void)didPressAccessoryButton:(UIButton *)sender {
    switch (sender.tag) {
        case MEGAChatAccessoryButtonCamera: {
            if ([AVCaptureDevice respondsToSelector:@selector(requestAccessForMediaType:completionHandler:)]) {
                [AVCaptureDevice requestAccessForMediaType:AVMediaTypeVideo completionHandler:^(BOOL permissionGranted) {
                    if (permissionGranted) {
                        dispatch_async(dispatch_get_main_queue(), ^{
                            [self showImagePickerForSourceType:UIImagePickerControllerSourceTypeCamera];
                        });
                    } else {
                        dispatch_async(dispatch_get_main_queue(), ^{
                            UIAlertController *permissionsAlertController = [UIAlertController alertControllerWithTitle:AMLocalizedString(@"attention", @"Alert title to attract attention") message:AMLocalizedString(@"cameraPermissions", @"Alert message to remember that MEGA app needs permission to use the Camera to take a photo or video and it doesn't have it") preferredStyle:UIAlertControllerStyleAlert];
                            [permissionsAlertController addAction:[UIAlertAction actionWithTitle:AMLocalizedString(@"cancel", @"Button title to cancel something") style:UIAlertActionStyleCancel handler:nil]];
                            
                            [permissionsAlertController addAction:[UIAlertAction actionWithTitle:AMLocalizedString(@"ok", @"") style:UIAlertActionStyleDefault handler:^(UIAlertAction *action) {
                                [[UIApplication sharedApplication] openURL:[NSURL URLWithString:UIApplicationOpenSettingsURLString]];
                            }]];
                            
                            [self presentViewController:permissionsAlertController animated:YES completion:nil];
                        });
                    }
                }];
            }
            break;
        }
            
        case MEGAChatAccessoryButtonUpload: {
            NSString *alertControllerTitle = AMLocalizedString(@"send", @"Label for any 'Send' button, link, text, title, etc. - (String as short as possible).");
            UIAlertController *selectOptionAlertController = [UIAlertController alertControllerWithTitle:alertControllerTitle message:nil preferredStyle:UIAlertControllerStyleActionSheet];
            [selectOptionAlertController addAction:[UIAlertAction actionWithTitle:AMLocalizedString(@"cancel", @"Button title to cancel something") style:UIAlertActionStyleCancel handler:nil]];
            
            UIAlertAction *sendFromCloudDriveAlertAction = [UIAlertAction actionWithTitle:AMLocalizedString(@"fromCloudDrive", @"") style:UIAlertActionStyleDefault handler:^(UIAlertAction *action) {
                MEGANavigationController *navigationController = [[UIStoryboard storyboardWithName:@"Cloud" bundle:nil] instantiateViewControllerWithIdentifier:@"BrowserNavigationControllerID"];
                [self presentViewController:navigationController animated:YES completion:nil];
                
                BrowserViewController *browserVC = navigationController.viewControllers.firstObject;
                browserVC.browserAction = BrowserActionSendFromCloudDrive;
                browserVC.selectedNodes = ^void(NSArray *selectedNodes) {
                    for (MEGANode *node in selectedNodes) {
                        [[MEGASdkManager sharedMEGAChatSdk] attachNodeToChat:self.chatRoom.chatId node:node.handle delegate:self];
                    }
                };
            }];
            [sendFromCloudDriveAlertAction setValue:[UIColor mnz_black333333] forKey:@"titleTextColor"];
            [selectOptionAlertController addAction:sendFromCloudDriveAlertAction];
            
            UIAlertAction *sendContactAlertAction = [UIAlertAction actionWithTitle:AMLocalizedString(@"contact", @"referring to a contact in the contact list of the user") style:UIAlertActionStyleDefault handler:^(UIAlertAction *action) {
                [self presentAddOrAttachParticipantToGroup:nil];
            }];
            [sendContactAlertAction setValue:[UIColor mnz_black333333] forKey:@"titleTextColor"];
            [selectOptionAlertController addAction:sendContactAlertAction];
            
            selectOptionAlertController.modalPresentationStyle = UIModalPresentationOverCurrentContext;
            selectOptionAlertController.popoverPresentationController.sourceView = self.inputToolbar.contentView;
            selectOptionAlertController.popoverPresentationController.sourceRect = self.inputToolbar.contentView.accessoryUploadButton.frame;
            selectOptionAlertController.popoverPresentationController.sourceView = self.inputToolbar.contentView;
            
            [self presentViewController:selectOptionAlertController animated:YES completion:nil];
            selectOptionAlertController.view.tintColor = [UIColor mnz_redD90007];

            break;
        }
            
        default:
            break;
    }
}

- (void)didEndAnimatingAfterButton:(UIButton *)sender {
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.3f * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        [self scrollToBottomAnimated:YES];
    });
}

- (void)jsq_setCollectionViewInsetsTopValue:(CGFloat)top bottomValue:(CGFloat)bottom {
    UIEdgeInsets insets = UIEdgeInsetsMake(0.0f, 0.0f, bottom, 0.0f);
    self.collectionView.contentInset = insets;
    self.collectionView.scrollIndicatorInsets = insets;
}

#pragma mark - JSQMessages CollectionView DataSource

- (NSString *)senderId {
    return [NSString stringWithFormat:@"%llu", [[MEGASdkManager sharedMEGAChatSdk] myUserHandle]];
}

- (NSString *)senderDisplayName {
    return [[MEGASdkManager sharedMEGAChatSdk] myEmail];
}

- (BOOL)isOutgoingMessage:(MEGAChatMessage *)messageItem {
    if (messageItem.isManagementMessage) {
        return NO;
    }
    return [super isOutgoingMessage:messageItem];
}

- (id<JSQMessageData>)collectionView:(JSQMessagesCollectionView *)collectionView messageDataForItemAtIndexPath:(NSIndexPath *)indexPath {
    MEGAChatMessage *message = [self.messages objectAtIndex:indexPath.item];
    return message;
}

- (void)collectionView:(JSQMessagesCollectionView *)collectionView didDeleteMessageAtIndexPath:(NSIndexPath *)indexPath {
    [self.messages removeObjectAtIndex:indexPath.item];
}

- (id<JSQMessageBubbleImageDataSource>)collectionView:(JSQMessagesCollectionView *)collectionView messageBubbleImageDataForItemAtIndexPath:(NSIndexPath *)indexPath {
    MEGAChatMessage *message = [self.messages objectAtIndex:indexPath.item];
    if (message.isManagementMessage || message.isDeleted) {
        return nil;
    }
    
    if ([message.senderId isEqualToString:self.senderId]) {
        return self.outgoingBubbleImageData;
    }
    
    return self.incomingBubbleImageData;
}

- (id<JSQMessageAvatarImageDataSource>)collectionView:(JSQMessagesCollectionView *)collectionView avatarImageDataForItemAtIndexPath:(NSIndexPath *)indexPath {
    MEGAChatMessage *message = [self.messages objectAtIndex:indexPath.item];
    if (message.userHandle == [[MEGASdkManager sharedMEGAChatSdk] myUserHandle]) {
        return nil;
    }
    if (indexPath.item < self.messages.count-1) {
        MEGAChatMessage *nextMessage = [self.messages objectAtIndex:indexPath.item+1];
        if (nextMessage.userHandle == message.userHandle) {
            return nil;
        }
    }
    NSNumber *avatarKey = [NSNumber numberWithUnsignedLong:message.userHandle];
    UIImage *avatar = [self.avatarImages objectForKey:avatarKey];
    if (!avatar) {
        avatar = [UIImage mnz_imageForUserHandle:message.userHandle size:CGSizeMake(kAvatarImageDiameter, kAvatarImageDiameter) delegate:nil];
        if (avatar) {
            [self.avatarImages setObject:avatar forKey:avatarKey];
        } else {
            return nil;
        }
    }
    return [self.avatarImageFactory avatarImageWithImage:avatar];
}

- (NSAttributedString *)collectionView:(JSQMessagesCollectionView *)collectionView attributedTextForCellTopLabelAtIndexPath:(NSIndexPath *)indexPath {
    
    MEGAChatMessage *message = [self.messages objectAtIndex:indexPath.item];
    BOOL showDayMonthYear = NO;
    if (indexPath.item == 0) {
        showDayMonthYear = YES;
    } else if (indexPath.item - 1 > 0) {
        MEGAChatMessage *previousMessage = [self.messages objectAtIndex:(indexPath.item -1)];
        showDayMonthYear = [self showDateBetweenMessage:message previousMessage:previousMessage];
    }
    
    if (showDayMonthYear) {
        NSString *dateString = [[JSQMessagesTimestampFormatter sharedFormatter] relativeDateForDate:message.date];
        NSAttributedString *dateAttributedString = [[NSAttributedString alloc] initWithString:dateString attributes:@{NSFontAttributeName:[UIFont mnz_SFUIMediumWithSize:12.0f], NSForegroundColorAttributeName:[UIColor mnz_black333333]}];
        return dateAttributedString;
    }
    
    return nil;
}

- (NSAttributedString *)collectionView:(JSQMessagesCollectionView *)collectionView attributedTextForMessageBubbleTopLabelAtIndexPath:(NSIndexPath *)indexPath {
    
    MEGAChatMessage *message = [self.messages objectAtIndex:indexPath.item];
    
    BOOL showMessageBubbleTopLabel = [self showHourForMessage:message withIndexPath:indexPath];
    if (showMessageBubbleTopLabel) {
        NSString *hour = [[JSQMessagesTimestampFormatter sharedFormatter] timeForDate:message.date];
        NSAttributedString *hourAttributed = [[NSAttributedString alloc] initWithString:hour attributes:@{NSFontAttributeName:[UIFont mnz_SFUIRegularWithSize:12.0f], NSForegroundColorAttributeName:[UIColor grayColor]}];
        NSMutableAttributedString *topCellAttributed = [[NSMutableAttributedString alloc] init];
        
        if (self.chatRoom.isGroup && !message.isManagementMessage) {
            NSString *fullname = [self.chatRoom peerFullnameByHandle:message.userHandle];
            if (!fullname.length) {
                fullname = [self.chatRoom peerEmailByHandle:message.userHandle];
                if (!fullname) {
                    fullname = @"";
                }
            }
            NSAttributedString *fullnameAttributed = [[NSAttributedString alloc] initWithString:[fullname stringByAppendingString:@"   "] attributes:@{NSFontAttributeName:[UIFont mnz_SFUIRegularWithSize:12.0f], NSForegroundColorAttributeName:[UIColor grayColor]}];
            [topCellAttributed appendAttributedString:fullnameAttributed];
            [topCellAttributed appendAttributedString:hourAttributed];
        } else {
            [topCellAttributed appendAttributedString:hourAttributed];
        }
        
        return topCellAttributed;
    }
    
    return nil;
}

#pragma mark - UICollectionView DataSource

- (NSInteger)collectionView:(UICollectionView *)collectionView numberOfItemsInSection:(NSInteger)section {
    return self.messages.count;
}

- (UICollectionViewCell *)collectionView:(JSQMessagesCollectionView *)collectionView cellForItemAtIndexPath:(NSIndexPath *)indexPath {
    if (indexPath.row == 8 && ![[MEGASdkManager sharedMEGAChatSdk] isFullHistoryLoadedForChat:self.chatRoom.chatId]) {
        [self loadMessages];
    }
    
    JSQMessagesCollectionViewCell *cell = (JSQMessagesCollectionViewCell *)[super collectionView:collectionView cellForItemAtIndexPath:indexPath];
    MEGAChatMessage *message = [self.messages objectAtIndex:indexPath.item];
    
    cell.accessoryButton.hidden = YES;
    
    if (message.isDeleted) {
        cell.textView.font = [UIFont mnz_SFUIRegularItalicWithSize:15.0f];
        cell.textView.textColor = [UIColor mnz_blue2BA6DE];
    } else if (message.isManagementMessage) {
        cell.textView.linkTextAttributes = @{NSForegroundColorAttributeName: [UIColor mnz_black333333],
                                             NSUnderlineColorAttributeName: [UIColor mnz_black333333],
                                             NSUnderlineStyleAttributeName: @(NSUnderlineStyleNone)};
        cell.textView.attributedText = message.attributedText;
    } else if (!message.isMediaMessage) {
        cell.textView.font = [UIFont mnz_SFUIRegularWithSize:15.0f];
        cell.textView.textColor = [message.senderId isEqualToString:self.senderId] ? [UIColor whiteColor] : [UIColor mnz_black333333];
        
        cell.textView.linkTextAttributes = @{ NSForegroundColorAttributeName : cell.textView.textColor,
                                              NSUnderlineStyleAttributeName : @(NSUnderlineStyleSingle | NSUnderlinePatternSolid) };
    }
    
    if (message.status == MEGAChatMessageStatusSending || message.status == MEGAChatMessageStatusSendingManual) {
        cell.contentView.alpha = 0.7f;
        if (message.status == MEGAChatMessageStatusSendingManual) {
            [cell.accessoryButton setImage:[UIImage imageNamed:@"sending_manual"] forState:UIControlStateNormal];
            cell.accessoryButton.hidden = NO;
        }
    } else {
        cell.contentView.alpha = 1.0f;
    }
    
    if ([cell.textView.text mnz_isPureEmojiString]) {
        cell.messageBubbleImageView.image = nil;
        cell.textView.font = [UIFont mnz_defaultFontForPureEmojiStringWithEmojis:[cell.textView.text mnz_emojiCount]];
    } else if (message.attributedText.length > 0) {
        cell.textView.attributedText = message.attributedText;
    }
    
    return cell;
}

- (UICollectionReusableView *)collectionView:(UICollectionView *)collectionView viewForSupplementaryElementOfKind:(NSString *)kind atIndexPath:(NSIndexPath *)indexPath {
    UICollectionReusableView *reusableview = nil;
    
    if (self.showTypingIndicator && [kind isEqualToString:UICollectionElementKindSectionFooter]) {
        self.footerView = [self dequeueTypingIndicatorFooterViewForIndexPath:indexPath];
        return self.footerView;
    }
    
    if (kind == UICollectionElementKindSectionHeader) {
        [self setChatOpenMessageForIndexPath:indexPath];
        return self.openMessageHeaderView;
    }

    return reusableview;
}

- (CGSize)collectionView:(UICollectionView *)collectionView layout:(UICollectionViewLayout *)collectionViewLayout referenceSizeForHeaderInSection:(NSInteger)section {
    BOOL isiPhone4XOr5X = ([[UIDevice currentDevice] iPhone4X] || [[UIDevice currentDevice] iPhone5X]);
    CGFloat height = (isiPhone4XOr5X ? 490.0f : 470.0f);
    CGFloat minimumHeight = self.isFirstLoad ? 0.0f : height;
    
    return CGSizeMake(self.view.frame.size.width, minimumHeight);
}

#pragma mark - Typing indicator

- (MEGAMessagesTypingIndicatorFoorterView *)dequeueTypingIndicatorFooterViewForIndexPath:(NSIndexPath *)indexPath {
    
    self.footerView = [self.collectionView dequeueReusableSupplementaryViewOfKind:UICollectionElementKindSectionFooter
                                                                                                 withReuseIdentifier:[MEGAMessagesTypingIndicatorFoorterView footerReuseIdentifier]
                                                                                                        forIndexPath:indexPath];
    self.footerView.typingLabel.font = [UIFont mnz_SFUIMediumWithSize:10.0f];
    self.footerView.typingLabel.textColor = [UIColor mnz_gray999999];
    self.footerView.typingLabel.text = [NSString stringWithFormat:AMLocalizedString(@"isTyping", nil), self.peerTyping];
    
    return self.footerView;
}

#pragma mark - UICollectionViewDelegate

#pragma mark - Custom menu items

- (BOOL)collectionView:(UICollectionView *)collectionView canPerformAction:(SEL)action forItemAtIndexPath:(NSIndexPath *)indexPath withSender:(id)sender {
    MEGAChatMessage *message = [self.messages objectAtIndex:indexPath.item];
    switch (message.type) {
        case MEGAChatMessageTypeInvalid:
        case MEGAChatMessageTypeRevokeAttachment:
            break;
            
        case MEGAChatMessageTypeNormal: {
            //All messages
            if (action == @selector(copy:)) return YES;
            
            //Your messages
            if ([message.senderId isEqualToString:self.senderId]) {
                if (action == @selector(delete:)) {
                    if (message.isDeletable) {
                        if (!self.editMessage || self.editMessage.messageId != message.messageId) {
                            return YES;
                        }
                    }
                }
                
                if (action == @selector(edit:message:)) {
                    if (message.isEditable) return YES;
                }
            }
            break;
        }
            
        case MEGAChatMessageTypeAlterParticipants:
        case MEGAChatMessageTypeTruncate:
        case MEGAChatMessageTypePrivilegeChange:
        case MEGAChatMessageTypeChatTitle: {
            if (action == @selector(copy:)) return YES;
            break;
        }
            
        case MEGAChatMessageTypeAttachment: {
            if (action == @selector(download:message:)) return YES;
            
            if ([message.senderId isEqualToString:self.senderId]) {
                if (action == @selector(revoke:message:indexPath:) && message.isDeletable) return YES;
            } else {
                if (action == @selector(import:message:)) return YES;
            }
            break;
        }
            
        case MEGAChatMessageTypeContact: {
            if ([message.senderId isEqualToString:self.senderId]) {
                if (action == @selector(delete:)) {
                    if (message.isDeletable) return YES;
                }
                //TODO: View profile / Start new chat
            } else {
                if (action == @selector(addContact:message:)) return YES;
            }
            break;
        }
            
        default:
            return NO;
            break;
    }
    
    return NO;
}

- (void)collectionView:(UICollectionView *)collectionView performAction:(SEL)action forItemAtIndexPath:(NSIndexPath *)indexPath withSender:(id)sender {
    MEGAChatMessage *message = [self.messages objectAtIndex:indexPath.item];
    if (action == @selector(edit:message:)) {
        [self edit:sender message:message];
        return;
    }
    if (action == @selector(import:message:)) {
        [self import:sender message:message];
        return;
    }
    if (action == @selector(download:message:)) {
        [self download:sender message:message];
        return;
    }
    if (action == @selector(addContact:message:)) {
        [self addContact:sender message:message];
        return;
    }
    if (action == @selector(revoke:message:indexPath:)) {
        [self revoke:sender message:message indexPath:indexPath];
        return;
    }
    
    if (action == @selector(delete:)) {
        MEGAChatMessage *deleteMessage = [[MEGASdkManager sharedMEGAChatSdk] deleteMessageForChat:self.chatRoom.chatId messageId:message.messageId];
        deleteMessage.chatRoom = self.chatRoom;
        [self.messages replaceObjectAtIndex:indexPath.item withObject:deleteMessage];
    }
    
    if (action != @selector(delete:)) {
        [super collectionView:collectionView performAction:action forItemAtIndexPath:indexPath withSender:sender];
    }
}

- (void)edit:(id)sender message:(MEGAChatMessage *)message {
    [self.inputToolbar.contentView.textView becomeFirstResponder];
    self.inputToolbar.contentView.textView.text = message.content;
    self.editMessage = message;
}

- (void)import:(id)sender message:(MEGAChatMessage *)message {
    NSMutableArray *nodesArray = [[NSMutableArray alloc] init];
    for (NSUInteger i = 0; i < message.nodeList.size.unsignedIntegerValue; i++) {
        MEGANode *node = [message.nodeList nodeAtIndex:i];
        [nodesArray addObject:node];
    }
    MEGANavigationController *navigationController = [[UIStoryboard storyboardWithName:@"Cloud" bundle:nil] instantiateViewControllerWithIdentifier:@"BrowserNavigationControllerID"];
    [self presentViewController:navigationController animated:YES completion:nil];
    BrowserViewController *browserVC = navigationController.viewControllers.firstObject;
    browserVC.selectedNodesArray = nodesArray;
    browserVC.browserAction = BrowserActionImport;
}

- (void)download:(id)sender message:(MEGAChatMessage *)message {
    for (NSUInteger i = 0; i < message.nodeList.size.unsignedIntegerValue; i++) {
        MEGANode *node = [message.nodeList nodeAtIndex:i];
        [Helper downloadNode:node folderPath:[Helper relativePathForOffline] isFolderLink:NO];
    }
    [SVProgressHUD showImage:[UIImage imageNamed:@"hudDownload"] status:AMLocalizedString(@"downloadStarted", @"Message shown when a download starts")];
}

- (void)addContact:(id)sender message:(MEGAChatMessage *)message {
    NSUInteger usersCount = message.usersCount;
    MEGAInviteContactRequestDelegate *inviteContactRequestDelegate = [[MEGAInviteContactRequestDelegate alloc] initWithNumberOfRequests:usersCount];
    for (NSUInteger i = 0; i < usersCount; i++) {
        NSString *email = [message userEmailAtIndex:i];
        [[MEGASdkManager sharedMEGASdk] inviteContactWithEmail:email message:@"" action:MEGAInviteActionAdd delegate:inviteContactRequestDelegate];
    }
}
        
- (void)revoke:(id)sender message:(MEGAChatMessage *)message indexPath:(NSIndexPath *)indexPath {
    [[MEGASdkManager sharedMEGAChatSdk] revokeAttachmentMessageForChat:self.chatRoom.chatId messageId:message.messageId];
}

#pragma mark - JSQMessages collection view flow layout delegate

#pragma mark - Adjusting cell label heights

- (CGFloat)collectionView:(JSQMessagesCollectionView *)collectionView
                   layout:(JSQMessagesCollectionViewFlowLayout *)collectionViewLayout heightForCellTopLabelAtIndexPath:(NSIndexPath *)indexPath {
    MEGAChatMessage *message = [self.messages objectAtIndex:indexPath.item];
    BOOL showDayMonthYear = NO;
    if (indexPath.item == 0) {
        showDayMonthYear = YES;
    } else if (indexPath.item - 1 > 0) {
        MEGAChatMessage *previousMessage = [self.messages objectAtIndex:(indexPath.item - 1)];
        showDayMonthYear = [self showDateBetweenMessage:message previousMessage:previousMessage];
    }
    
    if (showDayMonthYear) {
        return kJSQMessagesCollectionViewCellLabelHeightDefault;
    }
    
    return 0.0f;
}

- (CGFloat)collectionView:(JSQMessagesCollectionView *)collectionView
                   layout:(JSQMessagesCollectionViewFlowLayout *)collectionViewLayout heightForMessageBubbleTopLabelAtIndexPath:(NSIndexPath *)indexPath {
    CGFloat height = 0.0f;
    MEGAChatMessage *message = [self.messages objectAtIndex:indexPath.item];
    
    BOOL showMessageBubleTopLabel = [self showHourForMessage:message withIndexPath:indexPath];
    if (showMessageBubleTopLabel) {
        if (self.chatRoom.isGroup) {
            height = kGroupChatCellLabelHeight;
        } else {
            height = k1on1CellLabelHeight;
        }
    }
    
    return height;
}

#pragma mark - Responding to collection view tap events

- (void)collectionView:(JSQMessagesCollectionView *)collectionView
                header:(JSQMessagesLoadEarlierHeaderView *)headerView didTapLoadEarlierMessagesButton:(UIButton *)sender {
    NSLog(@"Load earlier messages!");
    [self loadMessages];
}

- (void)collectionView:(JSQMessagesCollectionView *)collectionView didTapAvatarImageView:(UIImageView *)avatarImageView atIndexPath:(NSIndexPath *)indexPath {
    NSLog(@"Tapped avatar!");
}

- (void)collectionView:(JSQMessagesCollectionView *)collectionView didTapMessageBubbleAtIndexPath:(NSIndexPath *)indexPath {
    [self hideInputToolbar];
    
    MEGAChatMessage *message = [self.messages objectAtIndex:indexPath.item];
    if (message.type == MEGAChatMessageTypeAttachment) {
        if (message.nodeList.size.unsignedIntegerValue == 1) {
            MEGANode *node = [message.nodeList nodeAtIndex:0];
            if (node.name.mnz_isImagePathExtension) {
                NSArray *reverseArray = [[[self.nodesLoaded reverseObjectEnumerator] allObjects] mutableCopy];
                [node mnz_openImageInNavigationController:self.navigationController withNodes:reverseArray folderLink:NO displayMode:2 enableMoveToRubbishBin:NO];
            } else {
                [node mnz_openNodeInNavigationController:self.navigationController folderLink:NO];
            }
        } else {
            NSArray *reverseArray = [[[self.nodesLoaded reverseObjectEnumerator] allObjects] mutableCopy];
            ChatAttachedNodesViewController *chatAttachedNodesVC = [[UIStoryboard storyboardWithName:@"Chat" bundle:nil] instantiateViewControllerWithIdentifier:@"ChatAttachedNodesViewControllerID"];
            chatAttachedNodesVC.message = message;
            chatAttachedNodesVC.nodesLoadedInChatroom = reverseArray;
            [self.navigationController pushViewController:chatAttachedNodesVC animated:YES];
        }
    } else if (message.type == MEGAChatMessageTypeContact) {
        if (message.usersCount == 1) {
            NSString *userEmail = [message userEmailAtIndex:0];
            MEGAUser *user = [[MEGASdkManager sharedMEGASdk] contactForEmail:userEmail];
            if ((user != nil) && (user.visibility == MEGAUserVisibilityVisible)) { //It's one of your contacts, open 'Contact Info' view
                ContactDetailsViewController *contactDetailsVC = [[UIStoryboard storyboardWithName:@"Contacts" bundle:nil] instantiateViewControllerWithIdentifier:@"ContactDetailsViewControllerID"];
                contactDetailsVC.contactDetailsMode = ContactDetailsModeDefault;
                contactDetailsVC.userEmail          = userEmail;
                contactDetailsVC.userName           = [message userNameAtIndex:0];
                contactDetailsVC.userHandle         = [message userHandleAtIndex:0];
                [self.navigationController pushViewController:contactDetailsVC animated:YES];
            }
        } else {
            ChatAttachedContactsViewController *chatAttachedContactsVC = [[UIStoryboard storyboardWithName:@"Chat" bundle:nil] instantiateViewControllerWithIdentifier:@"ChatAttachedContactsViewControllerID"];
            chatAttachedContactsVC.message = message;
            [self.navigationController pushViewController:chatAttachedContactsVC animated:YES];
        }
    }
}

- (void)collectionView:(JSQMessagesCollectionView *)collectionView didTapCellAtIndexPath:(NSIndexPath *)indexPath touchLocation:(CGPoint)touchLocation {
    [self hideInputToolbar];
}

#pragma mark - JSQMessagesComposerTextViewPasteDelegate methods

- (BOOL)composerTextView:(JSQMessagesComposerTextView *)textView shouldPasteWithSender:(id)sender {
    if ([UIPasteboard generalPasteboard].image) {
        return NO;
    }
    return YES;
}

#pragma mark - JSQMessagesViewAccessoryDelegate methods

- (void)messageView:(JSQMessagesCollectionView *)view didTapAccessoryButtonAtIndexPath:(NSIndexPath *)path {
    __block MEGAChatMessage *message = [self.messages objectAtIndex:path.item];
    if (message.status == MEGAChatMessageStatusSendingManual) {
        if ([[UIDevice currentDevice] iPhoneDevice]) {
            [self.inputToolbar.contentView.textView resignFirstResponder];
        }
        UIAlertController *alertController = [UIAlertController alertControllerWithTitle:nil message:nil preferredStyle:UIAlertControllerStyleActionSheet];
        
        [alertController addAction:[UIAlertAction actionWithTitle:AMLocalizedString(@"cancel", @"Button title to cancel something") style:UIAlertActionStyleCancel handler:nil]];
        
        UIAlertAction *retryAlertAction = [UIAlertAction actionWithTitle:AMLocalizedString(@"retry", @"Button which allows to retry send message in chat conversation.") style:UIAlertActionStyleDefault handler:^(UIAlertAction *action) {
            NSLog(@"retry tapped"); // sent message + discard || delete
            [[MEGASdkManager sharedMEGAChatSdk] removeUnsentMessageForChat:self.chatRoom.chatId rowId:message.rowId];
            
            switch (message.type) {
                case MEGAChatMessageTypeNormal: {
                    MEGAChatMessage *retryMessage = [[MEGASdkManager sharedMEGAChatSdk] sendMessageToChat:self.chatRoom.chatId message:message.text];
                    [self.messages replaceObjectAtIndex:path.item withObject:retryMessage];
                    break;
                }
                    
                case MEGAChatMessageTypeAttachment: {
                    MEGANode *node = [message.nodeList nodeAtIndex:0];
                    [[MEGASdkManager sharedMEGAChatSdk] attachNodeToChat:self.chatRoom.chatId node:node.handle delegate:self];
                    [self.messages removeObjectAtIndex:path.item];
                    [self.collectionView deleteItemsAtIndexPaths:@[path]];
                    break;
                }
                    
                case MEGAChatMessageTypeContact: {
                    NSMutableArray *users = [[NSMutableArray alloc] init];
                    for (NSUInteger i = 0; i < message.usersCount; i++) {
                        MEGAUser *user = [[MEGASdkManager sharedMEGASdk] contactForEmail:[message userEmailAtIndex:i]];
                        if (user) {
                            [users addObject:user];
                        }
                    }
                    
                    MEGAChatMessage *retryMessage = [[MEGASdkManager sharedMEGAChatSdk] attachContactsToChat:self.chatRoom.chatId contacts:users];
                    [self.messages replaceObjectAtIndex:path.item withObject:retryMessage];
                    break;
                }
                    
                default:
                    break;
            }
        }];
        [retryAlertAction setValue:[UIColor mnz_black333333] forKey:@"titleTextColor"];
        [alertController addAction:retryAlertAction];
        
        [alertController addAction:[UIAlertAction actionWithTitle:AMLocalizedString(@"deleteMessage", @"Button which allows to delete message in chat conversation.") style:UIAlertActionStyleDefault handler:^(UIAlertAction *action) {
            [[MEGASdkManager sharedMEGAChatSdk] removeUnsentMessageForChat:self.chatRoom.chatId rowId:message.rowId];
            [self.messages removeObjectAtIndex:path.item];
            [self.collectionView deleteItemsAtIndexPaths:@[path]];
        }]];
        
        alertController.modalPresentationStyle = UIModalPresentationPopover;
        UIPopoverPresentationController *popoverPresentationController = [alertController popoverPresentationController];
        CGRect deleteRect = [[view cellForItemAtIndexPath:path] bounds];
        popoverPresentationController.sourceRect = deleteRect;
        popoverPresentationController.sourceView = [view cellForItemAtIndexPath:path];
        popoverPresentationController.permittedArrowDirections = UIPopoverArrowDirectionAny;
        
        [self presentViewController:alertController animated:YES completion:nil];
    }
}

#pragma mark - UITextViewDelegate

- (void)textViewDidChange:(UITextView *)textView {
    [super textViewDidChange:textView];
    NSInteger textLength =  textView.text.length;
    if (textLength > 0 && ![self.sendTypingTimer isValid]) {
        self.sendTypingTimer = [NSTimer scheduledTimerWithTimeInterval:4.0 target:self selector:@selector(doNothing) userInfo:nil repeats:NO];
        [[MEGASdkManager sharedMEGAChatSdk] sendTypingNotificationForChat:self.chatRoom.chatId];
    }
}

#pragma mark - MEGAChatRoomDelegate

- (void)onMessageReceived:(MEGAChatSdk *)api message:(MEGAChatMessage *)message {
    MEGALogInfo(@"onMessageReceived %@", message);
    message.chatRoom = self.chatRoom;
    
    switch (message.type) {
        case MEGAChatMessageTypeInvalid:
            break;
            
        case MEGAChatMessageTypeNormal:
        case MEGAChatMessageTypeAlterParticipants:
        case MEGAChatMessageTypePrivilegeChange:
        case MEGAChatMessageTypeChatTitle:
        case MEGAChatMessageTypeAttachment:
        case MEGAChatMessageTypeContact:
            [self.messages addObject:message];
            [self finishReceivingMessage];
            [[MEGASdkManager sharedMEGAChatSdk] setMessageSeenForChat:self.chatRoom.chatId messageId:message.messageId];
            
            [self loadNodesFromMessage:message atTheBeginning:YES];
            break;
            
        case MEGAChatMessageTypeTruncate:
            [self handleTruncateMessage:message];
            break;
            
        case MEGAChatMessageTypeRevokeAttachment:
            break;
            
        default:
            break;
    }
}

- (void)onMessageLoaded:(MEGAChatSdk *)api message:(MEGAChatMessage *)message {
    MEGALogInfo(@"onMessageLoaded %@", message);
    
    if (message) {
        message.chatRoom = self.chatRoom;
        
        switch (message.type) {
            case MEGAChatMessageTypeInvalid:
                break;
                
            case MEGAChatMessageTypeNormal:
            case MEGAChatMessageTypeAlterParticipants:
            case MEGAChatMessageTypeTruncate:
            case MEGAChatMessageTypePrivilegeChange:
            case MEGAChatMessageTypeChatTitle:
            case MEGAChatMessageTypeAttachment:
            case MEGAChatMessageTypeContact: {
                if (!message.isDeleted) {
                    [self.messages insertObject:message atIndex:0];
                }
                break;
            }
                
            case MEGAChatMessageTypeRevokeAttachment:
                break;
                
            default:
                break;
        }
        
        [self loadNodesFromMessage:message atTheBeginning:NO];
    
        if (!self.areAllMessagesSeen && message.userHandle != [[MEGASdkManager sharedMEGAChatSdk] myUserHandle]) {
            if ([[MEGASdkManager sharedMEGAChatSdk] lastChatMessageSeenForChat:self.chatRoom.chatId].messageId != message.messageId) {
                if ([[MEGASdkManager sharedMEGAChatSdk] setMessageSeenForChat:self.chatRoom.chatId messageId:message.messageId]) {
                    self.areAllMessagesSeen = YES;
                } else {
                    MEGALogError(@"setMessageSeenForChat failed: The chatid is invalid or the message is older than last-seen-by-us message.");
                }
            } else {
                self.areAllMessagesSeen = YES;
            }
        }
    } else {
        if (self.isFirstLoad) {
            [self.collectionView reloadData];
            self.isFirstLoad = NO;
        } else {
            // TODO: improve load earlier messages
            CGFloat oldContentOffsetFromBottomY = self.collectionView.contentSize.height - self.collectionView.contentOffset.y;
            [self.collectionView reloadData];
            [self.collectionView layoutIfNeeded];
            CGPoint newContentOffset = CGPointMake(self.collectionView.contentOffset.x, self.collectionView.contentSize.height - oldContentOffsetFromBottomY);
            self.collectionView.contentOffset = newContentOffset;
        }
    }
}

- (void)onMessageUpdate:(MEGAChatSdk *)api message:(MEGAChatMessage *)message {
    MEGALogInfo(@"onMessageUpdate %@", message);
    
    message.chatRoom = self.chatRoom;
    if ([message hasChangedForType:MEGAChatMessageChangeTypeStatus]) {
        switch (message.status) {
            case MEGAChatMessageStatusUnknown:
                break;
                
            case MEGAChatMessageStatusSending:
                break;
                
            case MEGAChatMessageStatusSendingManual:
                break;
                
            case MEGAChatMessageStatusServerReceived: {
                if (message.type == MEGAChatMessageTypeAttachment) {
                    message.chatRoom = self.chatRoom;
                    [self.messages addObject:message];
                    [self finishReceivingMessage];
                    [self loadNodesFromMessage:message atTheBeginning:YES];
                    if ([[MEGASdkManager sharedMEGAChatSdk] myUserHandle] == message.userHandle) {
                        [self scrollToBottomAnimated:YES];
                    }
                } else {
                    NSPredicate *predicate = [NSPredicate predicateWithFormat:@"temporalId == %" PRIu64, message.temporalId];
                    NSArray *filteredArray = [self.messages filteredArrayUsingPredicate:predicate];
                    if (filteredArray.count) {
                        NSUInteger index = [self.messages indexOfObject:filteredArray[0]];
                        [self.messages replaceObjectAtIndex:index withObject:message];
                        NSIndexPath *indexPath = [NSIndexPath indexPathForRow:index inSection:0];
                        [self.collectionView reloadItemsAtIndexPaths:@[indexPath]];
                    } else {
                        MEGALogWarning(@"Message to update is not in the array of messages");
                        NSAssert(filteredArray.count, @"Message to update is not in the array of messages");
                    }
                }
                break;
            }
                
            case MEGAChatMessageStatusServerRejected: {
                NSPredicate *predicate = [NSPredicate predicateWithFormat:@"messageId == %" PRIu64, message.messageId];
                NSArray *filteredArray = [self.messages filteredArrayUsingPredicate:predicate];
                if (filteredArray.count) {
                    NSUInteger index = [self.messages indexOfObject:filteredArray[0]];
                    NSIndexPath *indexPath = [NSIndexPath indexPathForRow:index inSection:0];
                
                    [self.messages removeObjectAtIndex:index];
                    [self.collectionView deleteItemsAtIndexPaths:@[indexPath]];
                }
                break;
            }
                
            case MEGAChatMessageStatusDelivered:
                break;
                
            case MEGAChatMessageStatusNotSeen:
                break;
                
            case MEGAChatMessageStatusSeen:
                break;
                
            default:
                break;
        }
    }
    
    if ([message hasChangedForType:MEGAChatMessageChangeTypeContent]) {
        if (message.isDeleted || message.isEdited) {
            NSPredicate *predicate = [NSPredicate predicateWithFormat:@"messageId == %" PRIu64, message.messageId];
            NSArray *filteredArray = [self.messages filteredArrayUsingPredicate:predicate];
            if (filteredArray.count) {
                NSUInteger index = [self.messages indexOfObject:filteredArray[0]];
                NSIndexPath *indexPath = [NSIndexPath indexPathForRow:index inSection:0];
                if (message.isEdited) {
                    [self.messages replaceObjectAtIndex:index withObject:message];
                    [self.collectionView reloadItemsAtIndexPaths:@[indexPath]];
                }
                if (message.isDeleted) {
                    [self.messages removeObjectAtIndex:index];
                    [self.collectionView deleteItemsAtIndexPaths:@[indexPath]];
                }
            } else {
                MEGALogWarning(@"Message to update is not in the array of messages");
                NSAssert(filteredArray.count, @"Message to update is not in the array of messages");
            }
        }
        
        if (message.type == MEGAChatMessageTypeTruncate) {
            [self handleTruncateMessage:message];
        }
    }
}

- (void)onChatRoomUpdate:(MEGAChatSdk *)api chat:(MEGAChatRoom *)chat {
    MEGALogInfo(@"onChatRoomUpdate %@", chat);
    self.chatRoom = chat;
    switch (chat.changes) {
        case MEGAChatRoomChangeTypeUnreadCount:
            [self updateUnreadLabel];
            break;
            
        case MEGAChatRoomChangeTypeParticipants: {
            [self customNavigationBarLabel];
            
            [self.collectionView performBatchUpdates:^{
                [self.collectionView.collectionViewLayout invalidateLayoutWithContext:[JSQMessagesCollectionViewFlowLayoutInvalidationContext context]];
                [self.collectionView reloadItemsAtIndexPaths:[self.collectionView indexPathsForVisibleItems]];
            } completion:^(BOOL finished) {
                [self scrollToBottomAnimated:YES];
            }];
            
            break;
        }
            
        case MEGAChatRoomChangeTypeTitle:
            [self customNavigationBarLabel];
            break;
            
        case MEGAChatRoomChangeTypeUserTyping: {
            if (chat.userTypingHandle != api.myUserHandle) {
                self.showTypingIndicator = YES;
                NSIndexPath *lastCell = [NSIndexPath indexPathForItem:([self.collectionView numberOfItemsInSection:0] - 1) inSection:0];
                if ([[self.collectionView indexPathsForVisibleItems] containsObject:lastCell]) {
                    [self scrollToBottomAnimated:YES];
                }
                
                if (![self.peerTyping isEqualToString:[chat peerFullnameByHandle:chat.userTypingHandle]]) {
                    self.peerTyping = [chat peerFullnameByHandle:chat.userTypingHandle];
                }
                
                if (!self.peerTyping.length) {
                    self.peerTyping = [chat peerEmailByHandle:chat.userTypingHandle];
                }
                
                self.footerView.typingLabel.text = [NSString stringWithFormat:AMLocalizedString(@"isTyping", nil), self.peerTyping];
                
                [self.receiveTypingTimer invalidate];
                self.receiveTypingTimer = [NSTimer scheduledTimerWithTimeInterval:5.0
                                                                           target:self
                                                                         selector:@selector(hideTypingIndicator)
                                                                         userInfo:nil
                                                                          repeats:YES];
            }
            
            break;
        }
            
        case MEGAChatRoomChangeTypeClosed:
            [api closeChatRoom:chat.chatId delegate:self];
            [self.navigationController popToRootViewControllerAnimated:YES];
            break;
            
        default:
            break;
    }
}

- (void)onChatOnlineStatusUpdate:(MEGAChatSdk *)api userHandle:(uint64_t)userHandle status:(MEGAChatStatus)onlineStatus inProgress:(BOOL)inProgress {
    if (inProgress || userHandle == api.myUserHandle) {
        return;
    }
    
    [self customNavigationBarLabel];
    
    if (self.openMessageHeaderView) {
        self.openMessageHeaderView.onlineStatusLabel.text = self.lastChatRoomStateString;
        self.openMessageHeaderView.onlineStatusView.backgroundColor = self.lastChatRoomStateColor;
    }
}

- (void)onChatConnectionStateUpdate:(MEGAChatSdk *)api chatId:(uint64_t)chatId newState:(int)newState {
    if (chatId == self.chatRoom.chatId) {
        [self customNavigationBarLabel];
    }
}

#pragma mark - MEGAChatRequest

- (void)onChatRequestFinish:(MEGAChatSdk *)api request:(MEGAChatRequest *)request error:(MEGAChatError *)error {
    if (error.type) return;
    
    switch (request.type) {
        case MEGAChatRequestTypeInviteToChatRoom: {
            switch (error.type) {
                case MEGAChatErrorTypeArgs: //If the chat is not a group chat (cannot invite peers)
                case MEGAChatErrorTypeAccess: //If the logged in user doesn't have privileges to invite peers.
                case MEGAChatErrorTypeNoEnt: //If there isn't any chat with the specified chatid.
                    self.stopInvitingContacts = YES;
                    [SVProgressHUD showErrorWithStatus:error.name];
                    break;
                    
                default:
                    if (error.type) {
                        [SVProgressHUD showErrorWithStatus:error.name];
                    }
                    break;
            }
            break;
        }
            
        case MEGAChatRequestTypeNodeMessage: {
            if (error.type) {
                [SVProgressHUD showErrorWithStatus:error.name];
                return;
            }
            break;
        }
            
        default:
            break;
    }
}

@end
