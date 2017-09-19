#import "MessagesViewController.h"

#import "SVProgressHUD.h"

#import "BrowserViewController.h"
#import "ChatAttachedContactsViewController.h"
#import "ChatAttachedNodesViewController.h"
#import "ContactsViewController.h"
#import "ContactDetailsViewController.h"
#import "GroupChatDetailsViewController.h"

#import "Helper.h"
#import "MEGAAssetsPickerController.h"
#import "MEGAChatMessage+MNZCategory.h"
#import "MEGACopyRequestDelegate.h"
#import "MEGAImagePickerController.h"
#import "MEGAInviteContactRequestDelegate.h"
#import "MEGAMessagesTypingIndicatorFoorterView.h"
#import "MEGANavigationController.h"
#import "MEGANode+MNZCategory.h"
#import "MEGANodeList+MNZCategory.h"
#import "MEGAOpenMessageHeaderView.h"
#import "MEGAProcessAsset.h"
#import "MEGAStartUploadTransferDelegate.h"
#import "NSString+MNZCategory.h"

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

@property (nonatomic, strong) UIBarButtonItem *moreBarButtonItem;
@property (nonatomic, getter=shouldStopInvitingContacts) BOOL stopInvitingContacts;

@property (strong, nonatomic) NSMutableDictionary *participantsMutableDictionary;
@property (strong, nonatomic) NSMutableArray *nodesLoaded;

@property (strong, nonatomic) UIProgressView *navigationBarProgressView;

@property (nonatomic) long long totalBytesToUpload;
@property (nonatomic) long long remainingBytesToUpload;
@property (nonatomic) float totalProgressOfTransfersCompleted;

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
    
    self.inputToolbar.contentView.textView.pasteDelegate = self;
    
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
    
    self.outgoingBubbleImageData = [bubbleFactory outgoingMessagesBubbleImageWithColor:[UIColor mnz_grayE3E3E3]];
    self.incomingBubbleImageData = [bubbleFactory incomingMessagesBubbleImageWithColor:[UIColor whiteColor]];

    self.collectionView.backgroundColor = [UIColor mnz_grayF5F5F5];
    
    [self customToolbarContentView];
    
    self.areAllMessagesSeen = NO;
    
    UITapGestureRecognizer *singleTap = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(popViewController)];
    UITapGestureRecognizer *singleTap2 = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(popViewController)];
    
    _unreadLabel = [[UILabel alloc] initWithFrame:CGRectMake(0, 0, 30, 30)];
    self.unreadLabel.font = [UIFont mnz_SFUIMediumWithSize:12.0f];
    self.unreadLabel.textColor = [UIColor mnz_redD90007];
    self.unreadLabel.userInteractionEnabled = YES;
    [self.unreadLabel addGestureRecognizer:singleTap];
    _unreadBarButtonItem = [[UIBarButtonItem alloc] initWithCustomView:self.unreadLabel];
    
    if (self.presentingViewController) {
        UIBarButtonItem *chatBackBarButtonItem = [[UIBarButtonItem alloc] initWithTitle:AMLocalizedString(@"chat", @"Chat section header") style:UIBarButtonItemStylePlain target:self action:@selector(dismissChatRoom)];
        self.navigationItem.leftBarButtonItems = @[chatBackBarButtonItem, self.unreadBarButtonItem];
    } else {
        UIImageView *imageView = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"backArrow"]];
        imageView.frame = CGRectMake(0, 0, 22, 22);
        [imageView addGestureRecognizer:singleTap2];
        
        UIBarButtonItem *backBarButtonItem = [[UIBarButtonItem alloc] initWithCustomView:imageView];
        self.navigationItem.leftBarButtonItems = @[backBarButtonItem, self.unreadBarButtonItem];
    }
    self.stopInvitingContacts = NO;
    
    self.navigationController.interactivePopGestureRecognizer.delegate = nil;
    
    _nodesLoaded = [[NSMutableArray alloc] init];
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    [[MEGASdkManager sharedMEGAChatSdk] addChatDelegate:self];
    [self customNavigationBarLabel];
    [self rightBarButtonItems];
    [self updateUnreadLabel];
}

- (void)viewWillDisappear:(BOOL)animated {
    [super viewWillDisappear:animated];
    if ([self.navigationController.viewControllers indexOfObject:self] == NSNotFound || self.presentingViewController) {
        [[MEGASdkManager sharedMEGAChatSdk] closeChatRoom:self.chatRoom.chatId delegate:self];
    }
    [[MEGASdkManager sharedMEGAChatSdk] removeChatDelegate:self];
    
    self.automaticallyScrollsToMostRecentMessage = NO;
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
    if (self.chatRoom.isGroup) {
        NSString *title = self.chatRoom.title;
        if (self.chatRoom.ownPrivilege <= MEGAChatRoomPrivilegeRo) {
            label = [Helper customNavigationBarLabelWithTitle:title subtitle:AMLocalizedString(@"readOnly", @"Permissions given to the user you share your folder with")];
        } else {
            NSMutableAttributedString *titleMutableAttributedString = [[NSMutableAttributedString alloc] initWithString:self.chatRoom.title attributes:@{NSFontAttributeName:[UIFont mnz_SFUIRegularWithSize:17.0f], NSForegroundColorAttributeName:[UIColor mnz_black333333]}];
            label.textAlignment = NSTextAlignmentCenter;
            label.attributedText = titleMutableAttributedString;
        }
    } else {
        NSString *chatRoomState = [NSString chatStatusString:[[MEGASdkManager sharedMEGAChatSdk] userOnlineStatus:[self.chatRoom peerHandleAtIndex:0]]];
        label = [Helper customNavigationBarLabelWithTitle:self.chatRoom.title subtitle:chatRoomState];
    }
    
    label.frame = CGRectMake(0, 0, self.navigationItem.titleView.bounds.size.width, 44);
    [self.navigationItem setTitleView:label];
    
    label.userInteractionEnabled = YES;
    label.superview.userInteractionEnabled = YES;
    
    UITapGestureRecognizer *titleTapRecognizer =
    [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(chatRoomTitleDidTap)];
    label.gestureRecognizers = @[titleTapRecognizer];
}

- (void)rightBarButtonItems {
    if (self.chatRoom.isGroup && (self.chatRoom.ownPrivilege == MEGAChatRoomPrivilegeModerator)) {
        self.moreBarButtonItem = [[UIBarButtonItem alloc] initWithImage:[UIImage imageNamed:@"addContact"] style:UIBarButtonItemStyleDone target:self action:@selector(presentAddOrAttachParticipantToGroup:)];
        self.navigationItem.rightBarButtonItem = self.moreBarButtonItem;
    }
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
            [self finishSendingMessageAnimated:YES];
        }
    };
    
    [self presentViewController:navigationController animated:YES completion:nil];
}

- (void)updateUnreadLabel {
    NSInteger unreadChats = [[MEGASdkManager sharedMEGAChatSdk] unreadChats];
    NSString *unreadChatsString = unreadChats ? [NSString stringWithFormat:@"(%ld)", unreadChats] : nil;
    self.unreadLabel.text = unreadChatsString;
}

- (void)customiseCollectionViewLayout {
    self.collectionView.collectionViewLayout.messageBubbleFont = [UIFont mnz_SFUIRegularWithSize:14.0f];
    self.collectionView.collectionViewLayout.messageBubbleTextViewTextContainerInsets = UIEdgeInsetsMake(9.0f, 9.0f, 9.0f, 9.0f);
    
    self.collectionView.collectionViewLayout.incomingAvatarViewSize = CGSizeZero;
    self.collectionView.collectionViewLayout.outgoingAvatarViewSize = CGSizeZero;
    
    self.collectionView.collectionViewLayout.minimumLineSpacing = 2.0f;
}

- (void)customToolbarContentView {
    self.inputToolbar.contentView.textView.placeHolderTextColor = [UIColor mnz_grayCCCCCC];
    self.inputToolbar.contentView.textView.placeHolder = AMLocalizedString(@"writeAMessage", @"Message box label which shows that user can type message text in this textview");
    self.inputToolbar.contentView.textView.font = [UIFont mnz_SFUIRegularWithSize:14.0f];
    self.inputToolbar.contentView.textView.textColor = [UIColor mnz_black333333];
    self.inputToolbar.contentView.textView.tintColor = [UIColor mnz_redD90007];
    
    UIImage *image = [UIImage imageNamed:@"add"];
    UIButton *attachButton = [UIButton buttonWithType:UIButtonTypeCustom];
    [attachButton setImage:image forState:UIControlStateNormal];
    [attachButton setFrame:CGRectMake(30, 0, 22, 22)];
    self.inputToolbar.contentView.leftBarButtonItem = attachButton;

    image = [UIImage imageNamed:@"send"];
    UIButton *sendButton = [UIButton buttonWithType:UIButtonTypeCustom];
    [sendButton setImage:image forState:UIControlStateNormal];
    [sendButton setFrame:CGRectMake(0, 0, 22, 22)];
    self.inputToolbar.contentView.rightBarButtonItem = sendButton;
    self.inputToolbar.contentView.leftContentPadding = self.inputToolbar.contentView.rightContentPadding = 10.0f;
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
    BOOL showHour = NO;
    MEGAChatMessage *previousMessage = [self.messages objectAtIndex:(indexPath.item - 1)];
    if ([message.senderId isEqualToString:previousMessage.senderId]) {
        if ([self showHourBetweenDate:message.date previousDate:previousMessage.date]) {
            showHour = YES;
        } else {
            //TODO: Improve algorithm it has some issues when going back on the messages history
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
                            JSQMessagesCollectionViewCell *cell = (JSQMessagesCollectionViewCell *)[self.collectionView cellForItemAtIndexPath:[NSIndexPath indexPathForItem:index inSection:0]];
                            if (cell.messageBubbleTopLabel == nil) {
                                showHour = NO;
                            } else {
                                showHour = YES;
                            }
                            break;
                        }
                    } else { // The timestamp should not appear because is already shown on the previous message
                        showHour = NO;
                        break;
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
    self.openMessageHeaderView.conversationWithLabel.text = [NSString stringWithFormat:AMLocalizedString(@"conversationWith", @""), participantsNames];
    self.openMessageHeaderView.introductionLabel.text = AMLocalizedString(@"chatIntroductionMessage", @"Full text: MEGA protects your chat with end-to-end (user controlled) encryption providing essential safety assurances: Confidentiality - Only the author and intended recipients are able to decipher and read the content. Authenticity - There is an assurance that the message received was authored by the stated sender, and its content has not been tampered with during transport or on the server.");
    
    NSString *confidentialityExplanationString = AMLocalizedString(@"confidentialityExplanation", @"Chat advantages information. Full text: Mega protects your chat with end-to-end (user controlled) encryption providing essential safety assurances: [S]Confidentiality.[/S] Only the author and intended recipients are able to decipher and read the content. [S]Authenticity.[/S] The system ensures that the data received is from the sender displayed, and its content has not been manipulated during transit.");
    NSString *confidentialityString = [confidentialityExplanationString mnz_stringBetweenString:@"[S]" andString:@"[/S]"];
    confidentialityExplanationString = [confidentialityExplanationString stringByReplacingOccurrencesOfString:[NSString stringWithFormat:@"[S]%@[/S] ", confidentialityString] withString:@""];
    self.openMessageHeaderView.confidentialityLabel.text = confidentialityString;
    self.openMessageHeaderView.confidentialityExplanationLabel.text = confidentialityExplanationString;
    
    NSString *authenticityExplanationString = AMLocalizedString(@"authenticityExplanation", @"Chat advantages information. Full text: Mega protects your chat with end-to-end (user controlled) encryption providing essential safety assurances: [S]Confidentiality.[/S] Only the author and intended recipients are able to decipher and read the content. [S]Authenticity.[/S] The system ensures that the data received is from the sender displayed, and its content has not been manipulated during transit.");
    NSString *authenticityString = [authenticityExplanationString mnz_stringBetweenString:@"[S]" andString:@"[/S]"];
    authenticityExplanationString = [authenticityExplanationString stringByReplacingOccurrencesOfString:[NSString stringWithFormat:@"[S]%@[/S] ", authenticityString] withString:@""];
    self.openMessageHeaderView.authenticityLabel.text = authenticityString;
    self.openMessageHeaderView.authenticityExplanationLabel.text = authenticityExplanationString;
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

- (void)presentSendMediaAlertController {
    UIAlertController *sendMediaAlertController = [UIAlertController alertControllerWithTitle:nil message:nil preferredStyle:UIAlertControllerStyleActionSheet];
    [sendMediaAlertController addAction:[UIAlertAction actionWithTitle:AMLocalizedString(@"cancel", @"Button title to cancel something") style:UIAlertActionStyleCancel handler:^(UIAlertAction *action) {
        [self dismissViewControllerAnimated:YES completion:nil];
    }]];
    
    UIAlertAction *fromPhotosAlertAction = [UIAlertAction actionWithTitle:AMLocalizedString(@"choosePhotoVideo", @"Menu option from the `Add` section that allows the user to choose a photo or video to upload it to MEGA") style:UIAlertActionStyleDefault handler:^(UIAlertAction *action) {
        [self showImagePickerForSourceType:UIImagePickerControllerSourceTypePhotoLibrary];
    }];
    [sendMediaAlertController addAction:fromPhotosAlertAction];
    
    UIAlertAction *captureAlertAction = [UIAlertAction actionWithTitle:AMLocalizedString(@"capturePhotoVideo", @"Menu option from the `Add` section that allows the user to capture a video or a photo and upload it directly to MEGA.") style:UIAlertActionStyleDefault handler:^(UIAlertAction *action) {
        if ([AVCaptureDevice respondsToSelector:@selector(requestAccessForMediaType:completionHandler:)]) {
            [AVCaptureDevice requestAccessForMediaType:AVMediaTypeVideo completionHandler:^(BOOL permissionGranted) {
                if (permissionGranted) {
                    dispatch_async(dispatch_get_main_queue(), ^{
                        [self showImagePickerForSourceType:UIImagePickerControllerSourceTypeCamera];
                    });
                } else {
                    dispatch_async(dispatch_get_main_queue(), ^{
                        UIAlertController *permissionsAlertController = [UIAlertController alertControllerWithTitle:AMLocalizedString(@"attention", @"Alert title to attract attention") message:AMLocalizedString(@"cameraPermissions", @"Alert message to remember that MEGA app needs permission to use the Camera to take a photo or video and it doesn't have it") preferredStyle:UIAlertControllerStyleAlert];
                        [permissionsAlertController addAction:[UIAlertAction actionWithTitle:AMLocalizedString(@"cancel", @"Button title to cancel something") style:UIAlertActionStyleCancel handler:^(UIAlertAction *action) {
                            [self dismissViewControllerAnimated:YES completion:nil];
                        }]];
                        
                        [permissionsAlertController addAction:[UIAlertAction actionWithTitle:AMLocalizedString(@"ok", @"") style:UIAlertActionStyleDefault handler:^(UIAlertAction *action) {
                            [[UIApplication sharedApplication] openURL:[NSURL URLWithString:UIApplicationOpenSettingsURLString]];
                        }]];
                        
                        [self presentViewController:permissionsAlertController animated:YES completion:nil];
                    });
                }
            }];
        }
    }];
    [sendMediaAlertController addAction:captureAlertAction];
    
    sendMediaAlertController.modalPresentationStyle = UIModalPresentationOverCurrentContext;
    sendMediaAlertController.popoverPresentationController.sourceView = self.view;
    sendMediaAlertController.popoverPresentationController.sourceRect = CGRectMake(self.inputToolbar.contentView.leftBarButtonItem.frame.size.width, self.view.frame.size.height, 0.0f, 0.0f);
    
    [self presentViewController:sendMediaAlertController animated:YES completion:nil];
}

- (void)showImagePickerForSourceType:(UIImagePickerControllerSourceType)sourceType {
    if (sourceType == UIImagePickerControllerSourceTypeCamera) {
        MEGAImagePickerController *imagePickerController = [[MEGAImagePickerController alloc] initToShareThroughChatWithSourceType:sourceType filePathCompletion:^(NSString *filePath, UIImagePickerControllerSourceType sourceType) {
            MEGANode *parentNode = [[MEGASdkManager sharedMEGASdk] nodeForPath:@"/My chat files"];
            [self startUploadAndAttachWithPath:filePath parentNode:parentNode];
        }];
        
        [self presentViewController:imagePickerController animated:YES completion:nil];
    } else {
        [PHPhotoLibrary requestAuthorization:^(PHAuthorizationStatus status) {
            dispatch_async(dispatch_get_main_queue(), ^{
                MEGAAssetsPickerController *pickerViewController = [[MEGAAssetsPickerController alloc] initToUploadToChatWithAssetsCompletion:^(NSArray *assets) {
                    for (PHAsset *asset in assets) {
                        MEGANode *parentNode = [[MEGASdkManager sharedMEGASdk] nodeForPath:@"/My chat files"];
                        MEGAProcessAsset *processAsset = [[MEGAProcessAsset alloc] initWithAsset:asset parentNode:parentNode filePath:^(NSString *filePath) {
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
                        processAsset.originalName = YES;
                        [processAsset prepare];
                    }
                }];
                if ([[UIDevice currentDevice] iPadDevice]) {
                    pickerViewController.modalPresentationStyle = UIModalPresentationFormSheet;
                }
                
                [self presentViewController:pickerViewController animated:YES completion:nil];
            });
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
    /**
     *  Sending a message. Your implementation of this method should do *at least* the following:
     *
     *  1. Play sound (optional)
     *  2. Add new id<JSQMessageData> object to your data source
     *  3. Call `finishSendingMessage`
     */
    
    // [JSQSystemSoundPlayer jsq_playMessageSentSound];
    MEGAChatMessage *message;
    if (!self.editMessage) {
        message = [[MEGASdkManager sharedMEGAChatSdk] sendMessageToChat:self.chatRoom.chatId message:text];
        message.chatRoom = self.chatRoom;
        [self.messages addObject:message];
    } else {
        message = [[MEGASdkManager sharedMEGAChatSdk] editMessageForChat:self.chatRoom.chatId messageId:self.editMessage.messageId message:text];
        message.chatRoom = self.chatRoom;
        NSUInteger index = [self.messages indexOfObject:self.editMessage];
        [self.messages replaceObjectAtIndex:index withObject:message];
        self.editMessage = nil;
    }
    
    MEGALogInfo(@"didPressSendButton %@", message);
    
    [self finishSendingMessageAnimated:YES];
    [self scrollToBottomAnimated:YES];
}

- (void)didPressAccessoryButton:(UIButton *)sender {
    [self.inputToolbar.contentView.textView resignFirstResponder];
    
    UIAlertController *selectOptionAlertController = [UIAlertController alertControllerWithTitle:nil message:nil preferredStyle:UIAlertControllerStyleActionSheet];
    [selectOptionAlertController addAction:[UIAlertAction actionWithTitle:AMLocalizedString(@"cancel", @"Button title to cancel something") style:UIAlertActionStyleCancel handler:^(UIAlertAction *action) {
        [self dismissViewControllerAnimated:YES completion:nil];
        
        [self.inputToolbar.contentView.textView becomeFirstResponder];
    }]];
    
    UIAlertAction *sendMediaAlertAction = [UIAlertAction actionWithTitle:AMLocalizedString(@"sendMedia", @"A button label. The button allows to capture or upload pictures or videos directly to chat.") style:UIAlertActionStyleDefault handler:^(UIAlertAction *action) {
        [self presentSendMediaAlertController];
    }];
    [selectOptionAlertController addAction:sendMediaAlertAction];
    
    UIAlertAction *sendFromCloudDriveAlertAction = [UIAlertAction actionWithTitle:AMLocalizedString(@"addFromMyCloudDrive", @"Button label. Allows to share files(from my Cloud Drive) in chat conversation") style:UIAlertActionStyleDefault handler:^(UIAlertAction *action) {
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
    [selectOptionAlertController addAction:sendFromCloudDriveAlertAction];
    
    UIAlertAction *sendContactAlertAction = [UIAlertAction actionWithTitle:AMLocalizedString(@"sendContact", @"A button label. The button sends contact information to a user in the conversation.") style:UIAlertActionStyleDefault handler:^(UIAlertAction *action) {
        [self presentAddOrAttachParticipantToGroup:nil];
    }];
    [selectOptionAlertController addAction:sendContactAlertAction];
    
    selectOptionAlertController.modalPresentationStyle = UIModalPresentationOverCurrentContext;
    selectOptionAlertController.popoverPresentationController.sourceView = self.view;
    selectOptionAlertController.popoverPresentationController.sourceRect = CGRectMake(self.inputToolbar.contentView.leftBarButtonItem.frame.size.width, self.view.frame.size.height, 0.0f, 0.0f);
    
    [self presentViewController:selectOptionAlertController animated:YES completion:nil];
}

- (void)jsq_setCollectionViewInsetsTopValue:(CGFloat)top bottomValue:(CGFloat)bottom {
    CGFloat topInset = ([UIApplication sharedApplication].statusBarFrame.size.height + self.navigationController.navigationBar.frame.size.height);
    UIEdgeInsets insets = UIEdgeInsetsMake(topInset, 0.0f, bottom, 0.0f);
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
    return nil;
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
        NSAttributedString *dateAttributedString = [[NSAttributedString alloc] initWithString:dateString attributes:@{NSFontAttributeName:[UIFont mnz_SFUIMediumWithSize:11.0f], NSForegroundColorAttributeName:[UIColor mnz_black333333]}];
        return dateAttributedString;
    }
    
    return nil;
}

- (NSAttributedString *)collectionView:(JSQMessagesCollectionView *)collectionView attributedTextForMessageBubbleTopLabelAtIndexPath:(NSIndexPath *)indexPath {
    
    MEGAChatMessage *message = [self.messages objectAtIndex:indexPath.item];
    
    BOOL showMessageBubleTopLabel = NO;
    if (indexPath.item == 0) {
        showMessageBubleTopLabel = YES;
    } else {
        if (message.isManagementMessage) {
            showMessageBubleTopLabel = YES;
        } else {
            showMessageBubleTopLabel = [self showHourForMessage:message withIndexPath:indexPath];
        }
    }

    if (showMessageBubleTopLabel) {
        NSString *hour = [[JSQMessagesTimestampFormatter sharedFormatter] timeForDate:message.date];
        NSString *topCellString = nil;
        
        if (self.chatRoom.isGroup && !message.isManagementMessage) {
            NSString *fullname = [self.chatRoom peerFullnameByHandle:message.userHandle];
            if (!fullname.length) {
                fullname = [self.chatRoom peerEmailByHandle:message.userHandle];
            }
            // For my own messages show only the hour (fullname is nil, because I am not in the peer list)
            topCellString = [NSString stringWithFormat:@"%@ %@", fullname ? fullname : @"", hour];
        } else {
            topCellString = hour;
        }
        
        return [[NSAttributedString alloc] initWithString:topCellString attributes:@{NSFontAttributeName:[UIFont mnz_SFUIRegularWithSize:9.0f], NSForegroundColorAttributeName:[UIColor mnz_gray999999]}];
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
    
    if (message.isEdited) {
        [cell.accessoryButton setImage:nil forState:UIControlStateNormal];
        [cell.accessoryButton setAttributedTitle:[[NSAttributedString alloc] initWithString:AMLocalizedString(@"edited", @"A log message in a chat to indicate that the message has been edited by the user.") attributes:@{NSFontAttributeName:[UIFont mnz_SFUIRegularWithSize:9.0f], NSForegroundColorAttributeName:[UIColor mnz_blue2BA6DE]}] forState:UIControlStateNormal];
        cell.accessoryButton.hidden = NO;
        
        cell.textView.font = [UIFont mnz_SFUIRegularWithSize:14.0f];
        if (message.status == MEGAChatMessageStatusSending || message.status == MEGAChatMessageStatusSendingManual) {
            cell.textView.textColor = [UIColor mnz_black333333_02];
            if (message.status == MEGAChatMessageStatusSendingManual) {
                [cell.accessoryButton setImage:[UIImage imageNamed:@"sending_manual"] forState:UIControlStateNormal];
                cell.accessoryButton.hidden = NO;
            }
        } else {
            cell.textView.textColor = [UIColor mnz_black333333];
        }
    } else if (message.isDeleted) {
        cell.textView.font = [UIFont mnz_SFUIRegularItalicWithSize:14.0f];
        cell.textView.textColor = [UIColor mnz_blue2BA6DE];
    } else if (message.isManagementMessage) {
        cell.textView.attributedText = message.attributedText;
    } else if (!message.isMediaMessage) {
        cell.textView.selectable = NO;
        cell.textView.userInteractionEnabled = NO;
        cell.textView.font = [UIFont mnz_SFUIRegularWithSize:14.0f];
        if (message.status == MEGAChatMessageStatusSending || message.status == MEGAChatMessageStatusSendingManual) {
            cell.textView.textColor = [UIColor mnz_black333333_02];
            if (message.status == MEGAChatMessageStatusSendingManual) {
                [cell.accessoryButton setImage:[UIImage imageNamed:@"sending_manual"] forState:UIControlStateNormal];
                cell.accessoryButton.hidden = NO;
            }
        } else {
            cell.textView.textColor = [UIColor mnz_black333333];
        }
        cell.textView.linkTextAttributes = @{ NSForegroundColorAttributeName : cell.textView.textColor,
                                              NSUnderlineStyleAttributeName : @(NSUnderlineStyleSingle | NSUnderlinePatternSolid) };
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
    CGFloat height = (isiPhone4XOr5X ? 340.0f : 320.0f);
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
                    if (message.isDeletable) return YES;
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
    self.inputToolbar.contentView.textView.text = message.text;
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
    BOOL showMessageBubleTopLabel = NO;
    if (indexPath.item == 0) {
        showMessageBubleTopLabel = YES;
    } else {
        MEGAChatMessage *message = [self.messages objectAtIndex:indexPath.item];
        if (message.isManagementMessage) {
            showMessageBubleTopLabel = YES;
        } else {
            showMessageBubleTopLabel = [self showHourForMessage:message withIndexPath:indexPath];
        }
    }
    
    if (showMessageBubleTopLabel) {
        return kJSQMessagesCollectionViewCellLabelHeightDefault;
    }
    
    return 0.0f;
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
    NSLog(@"Tapped cell at %@!", NSStringFromCGPoint(touchLocation));
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
        
        [alertController addAction:[UIAlertAction actionWithTitle:AMLocalizedString(@"cancel", @"Button title to cancel something") style:UIAlertActionStyleCancel handler:^(UIAlertAction *action) {
            [self dismissViewControllerAnimated:YES completion:nil];
        }]];
        
        [alertController addAction:[UIAlertAction actionWithTitle:AMLocalizedString(@"retry", @"Button which allows to retry send message in chat conversation.") style:UIAlertActionStyleDefault handler:^(UIAlertAction *action) {
            NSLog(@"retry tapped"); // sent message + discard || delete
            [[MEGASdkManager sharedMEGAChatSdk] removeUnsentMessageForChat:self.chatRoom.chatId rowId:message.rowId];
            MEGAChatMessage *retryMessage = [[MEGASdkManager sharedMEGAChatSdk] sendMessageToChat:self.chatRoom.chatId message:message.text];
            retryMessage.chatRoom = self.chatRoom;
            [self.messages replaceObjectAtIndex:path.item withObject:retryMessage];
        }]];
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
    if (message.type != MEGAChatMessageTypeRevokeAttachment) {        
        [self.messages addObject:message];
    }
    [self finishReceivingMessage];
    [[MEGASdkManager sharedMEGAChatSdk] setMessageSeenForChat:self.chatRoom.chatId messageId:message.messageId];
            
    [self loadNodesFromMessage:message atTheBeginning:YES];
}

- (void)onMessageLoaded:(MEGAChatSdk *)api message:(MEGAChatMessage *)message {
    MEGALogInfo(@"onMessageLoaded %@", message);
    
    if (message) {
        message.chatRoom = self.chatRoom;
        if (message.type != MEGAChatMessageTypeRevokeAttachment && !message.isDeleted) {
            [self.messages insertObject:message atIndex:0];
        }
        
        [self loadNodesFromMessage:message atTheBeginning:NO];
    
        if (!self.areAllMessagesSeen && message.userHandle != [[MEGASdkManager sharedMEGAChatSdk] myUserHandle]) {
            if ([[MEGASdkManager sharedMEGAChatSdk] lastChatMessageSeenForChat:self.chatRoom.chatId].messageId != message.messageId) {
                if ([[MEGASdkManager sharedMEGAChatSdk] setMessageSeenForChat:self.chatRoom.chatId messageId:message.messageId]) {
                    [self updateUnreadLabel];
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
                    NSUInteger index = [self.messages indexOfObject:filteredArray[0]];
                    [self.messages replaceObjectAtIndex:index withObject:message];
                    NSIndexPath *indexPath = [NSIndexPath indexPathForRow:index inSection:0];
                    [self.collectionView reloadItemsAtIndexPaths:@[indexPath]];
                }
                break;
            }
            case MEGAChatMessageStatusServerRejected:
                break;
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
        }
        
        if (message.type == MEGAChatMessageTypeTruncate) {
            [self.messages removeAllObjects];
            [self.messages addObject:message];
            [self.collectionView reloadData];
            [self.nodesLoaded removeAllObjects];
        }
    }
}

- (void)onChatRoomUpdate:(MEGAChatSdk *)api chat:(MEGAChatRoom *)chat {
    MEGALogInfo(@"onChatRoomUpdate %@", chat);
    self.chatRoom = chat;
    switch (chat.changes) {
        case MEGAChatRoomChangeTypeUnreadCount:
            break;
            
        case MEGAChatRoomChangeTypeParticipans:
            [self customNavigationBarLabel];
            break;
            
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
