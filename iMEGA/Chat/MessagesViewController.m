#import "MessagesViewController.h"

#import "ContactDetailsViewController.h"
#import "GroupChatDetailsViewController.h"

#import "NSString+MNZCategory.h"

#import "Helper.h"
#import "MEGAOpenMessageHeaderView.h"
#import "MEGAMessagesTypingIndicatorFoorterView.h"
#import "MEGAMessage.h"

@interface MessagesViewController () <JSQMessagesViewAccessoryButtonDelegate, JSQMessagesComposerTextViewPasteDelegate>

@property (nonatomic, strong) MEGAOpenMessageHeaderView *openMessageHeaderView;
@property (nonatomic, strong) MEGAMessagesTypingIndicatorFoorterView *footerView;

@property (nonatomic, strong) NSMutableArray *indexesMessages;
@property (nonatomic, strong) NSMutableDictionary *messagesDictionary;

@property (strong, nonatomic) JSQMessagesBubbleImage *outgoingBubbleImageData;
@property (strong, nonatomic) JSQMessagesBubbleImage *incomingBubbleImageData;
@property (strong, nonatomic) JSQMessagesBubbleImage *managementBubbleImageData;

@property (nonatomic, strong) MEGAMessage *editMessage;

@property (nonatomic, assign) BOOL areAllMessagesSeen;
@property (nonatomic, assign) BOOL areMessagesLoaded;
@property (nonatomic, assign) BOOL isFirstLoad;

@property (nonatomic, strong) NSTimer *sendTypingTimer;
@property (nonatomic, strong) NSTimer *receiveTypingTimer;
@property (nonatomic, strong) NSString *peerTyping;

@end

@implementation MessagesViewController

#pragma mark - Lifecycle

- (void)viewDidLoad {
    [super viewDidLoad];
    
    self.indexesMessages = [[NSMutableArray alloc] init];
    self.messagesDictionary = [[NSMutableDictionary alloc] init];
    
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
    
    self.collectionView.collectionViewLayout.incomingAvatarViewSize = CGSizeZero;
    self.collectionView.collectionViewLayout.outgoingAvatarViewSize = CGSizeZero;
    
    [self.collectionView registerNib:[MEGAOpenMessageHeaderView nib] forSupplementaryViewOfKind:UICollectionElementKindSectionHeader withReuseIdentifier:[MEGAOpenMessageHeaderView headerReuseIdentifier]];
    
    [self.collectionView registerNib:[MEGAMessagesTypingIndicatorFoorterView nib] forSupplementaryViewOfKind:UICollectionElementKindSectionFooter withReuseIdentifier:[MEGAMessagesTypingIndicatorFoorterView footerReuseIdentifier]];
    
     //Set up message accessory button delegate and configuration
    self.collectionView.accessoryDelegate = self;
    
    self.showLoadEarlierMessagesHeader = YES;
    
    
     //Register custom menu actions for cells.
    [JSQMessagesCollectionViewCell registerMenuAction:@selector(editAction:megaMessage:)];
    
     //Allow cells to be deleted
    [JSQMessagesCollectionViewCell registerMenuAction:@selector(delete:)];
    
    JSQMessagesBubbleImageFactory *bubbleFactory = [[JSQMessagesBubbleImageFactory alloc] initWithBubbleImage:[UIImage imageNamed:@"bubble_tailless"] capInsets:UIEdgeInsetsZero layoutDirection:[UIApplication sharedApplication].userInterfaceLayoutDirection];
    
    self.outgoingBubbleImageData = [bubbleFactory outgoingMessagesBubbleImageWithColor:[UIColor mnz_grayE3E3E3]];
    self.incomingBubbleImageData = [bubbleFactory incomingMessagesBubbleImageWithColor:[UIColor whiteColor]];
    self.managementBubbleImageData = [bubbleFactory incomingMessagesBubbleImageWithColor:[UIColor mnz_grayF5F5F5]];

    self.collectionView.backgroundColor = [UIColor mnz_grayF5F5F5];
    self.collectionView.collectionViewLayout.messageBubbleFont = [UIFont fontWithName:kFont size:14.0f];
    
    self.tabBarController.tabBar.hidden = YES;
    
    [self customToolbarContentView];
    
    self.areAllMessagesSeen = NO;
    
    self.inputToolbar.contentView.textView.placeHolder = AMLocalizedString(@"writeAMessage", @"Message box label which shows that user can type message text in this textview");
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    [self customNavigationBarLabel];
}

- (void)viewWillDisappear:(BOOL)animated {
    if ([self.navigationController.viewControllers indexOfObject:self] == NSNotFound) {
        [[MEGASdkManager sharedMEGAChatSdk] closeChatRoom:self.chatRoom.chatId delegate:self];
    }
    [super viewWillDisappear:animated];
    
}

#pragma mark - Private methods

- (void)loadMessages {
    self.areMessagesLoaded = NO;
    NSInteger loadMessage = [[MEGASdkManager sharedMEGAChatSdk] loadMessagesForChat:self.chatRoom.chatId count:16];
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
    UILabel *label = [[UILabel alloc] init];
    if (self.chatRoom.isGroup) {
        NSString *title = self.chatRoom.title;
        if (self.chatRoom.ownPrivilege <= MEGAChatRoomPrivilegeRo) {
            label = [Helper customNavigationBarLabelWithTitle:title subtitle:AMLocalizedString(@"readOnly", @"Permissions given to the user you share your folder with")];
            self.inputToolbar.hidden = YES;
        } else {
            NSMutableAttributedString *titleMutableAttributedString = [[NSMutableAttributedString alloc] initWithString:self.chatRoom.title];
            [titleMutableAttributedString addAttribute:NSFontAttributeName value:[UIFont fontWithName:kFont size:18.0f] range:[title rangeOfString:title]];
            [titleMutableAttributedString addAttribute:NSForegroundColorAttributeName value:[UIColor mnz_black333333] range:[title rangeOfString:title]];
            label.textAlignment = NSTextAlignmentCenter;
            label.attributedText = titleMutableAttributedString;
            self.inputToolbar.hidden = NO;
        }
    } else {
        NSString *chatRoomState;
        if (self.chatRoom.onlineStatus > MEGAChatStatusOffline) {
            chatRoomState = AMLocalizedString(@"online", nil);
        } else {
            chatRoomState = AMLocalizedString(@"offline", @"Title of the Offline section");
        }
        
        label = [Helper customChatNavigationBarLabelWithTitle:self.chatRoom.title subtitle:chatRoomState];
    }
    
    label.frame = CGRectMake(0, 0, self.navigationItem.titleView.bounds.size.width, 44);
    [self.navigationItem setTitleView:label];
    
    label.userInteractionEnabled = YES;
    label.superview.userInteractionEnabled = YES;
    
    UITapGestureRecognizer *titleTapRecognizer =
    [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(chatRoomTitleDidTap)];
    label.gestureRecognizers = @[titleTapRecognizer];
}

- (void)customToolbarContentView {
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
}

- (BOOL)showDateBetweenMessage:(MEGAMessage *)message previousMessage:(MEGAMessage *)previousMessage {
    if ((previousMessage.senderId != message.senderId) || (previousMessage.date != message.date)) {
        NSDateComponents *previousDateComponents = [[NSCalendar currentCalendar] components:NSCalendarUnitDay | NSCalendarUnitMonth | NSCalendarUnitYear fromDate:previousMessage.date];
        NSDateComponents *currentDateComponents = [[NSCalendar currentCalendar] components:NSCalendarUnitDay | NSCalendarUnitMonth | NSCalendarUnitYear fromDate:message.date];
        if (previousDateComponents.day != currentDateComponents.day || previousDateComponents.month != currentDateComponents.month || previousDateComponents.year != currentDateComponents.year) {
            return YES;
        }
    }
    
    return NO;
}

- (BOOL)showHourForMessage:(MEGAMessage *)message withIndexPath:(NSIndexPath *)indexPath {
    BOOL showHour = NO;
    MEGAMessage *previousMessage = [self.messagesDictionary objectForKey:[self.indexesMessages objectAtIndex:(indexPath.item - 1)]];
    if ([message.senderId isEqualToString:previousMessage.senderId]) {
        if ([self showHourBetweenDate:message.date previousDate:previousMessage.date]) {
            showHour = YES;
        } else {
            //TODO: Improve algorithm it has some issues when going back on the messages history
            NSUInteger count = self.indexesMessages.count;
            for (NSUInteger i = 1; i < count; i++) {
                NSInteger index = (indexPath.item - (i + 1));
                if (index > 0) {
                    MEGAMessage *messagePriorToThePreviousOne = [self.messagesDictionary objectForKey:[self.indexesMessages objectAtIndex:index]];
                    if (messagePriorToThePreviousOne.index < 0) {
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
        
        if (self.chatRoom.peerCount == 1 || (i + 1) == self.chatRoom.peerCount) {
            participantsNames = [participantsNames stringByAppendingString:peerName];
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

#pragma mark - Custom menu actions for cells

- (void)didReceiveMenuWillShowNotification:(NSNotification *)notification {
     //Display custom menu actions for cells.
    UIMenuController *menu = [notification object];
    menu.menuItems = @[[[UIMenuItem alloc] initWithTitle:AMLocalizedString(@"edit", @"Caption of a button to edit the files that are selected") action:@selector(editAction:megaMessage:)]];
    
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

    //TODO: Add the message here instead in the callback. Problem we have not the index of the message
//    MEGAMessage *message = [[MEGAMessage alloc] initWithSenderId:senderId
//                                              senderDisplayName:senderDisplayName
//                                                           date:date
//                                                           text:text];
    if (!self.editMessage) {
        [[MEGASdkManager sharedMEGAChatSdk] sendMessageToChat:self.chatRoom.chatId message:text];
    } else {
        [[MEGASdkManager sharedMEGAChatSdk] editMessageForChat:self.chatRoom.chatId messageId:self.editMessage.messageId message:text];
    }
    self.editMessage = nil;
//    [self.indexesMessages addObject:message];
    
    [self finishSendingMessageAnimated:YES];
}

- (void)didPressAccessoryButton:(UIButton *)sender {
    [self.inputToolbar.contentView.textView resignFirstResponder];
    
    //TODO: Show bottom menu with "Send Media", "Send from Cloud Drive" and "Send Contact" options
    UIAlertController *alertController = [UIAlertController alertControllerWithTitle:@"TO-DO" message:@"🔜🤓💻📱" preferredStyle:UIAlertControllerStyleAlert];
    [alertController addAction:[UIAlertAction actionWithTitle:AMLocalizedString(@"ok", nil) style:UIAlertActionStyleCancel handler:nil]];
    [self presentViewController:alertController animated:YES completion:nil];
}

- (void)jsq_setCollectionViewInsetsTopValue:(CGFloat)top bottomValue:(CGFloat)bottom {
    CGFloat topInset = ([UIApplication sharedApplication].statusBarFrame.size.height + self.navigationController.navigationBar.frame.size.height);
    UIEdgeInsets insets = UIEdgeInsetsMake(topInset, 0.0f, bottom, 0.0f);
    self.collectionView.contentInset = insets;
    self.collectionView.scrollIndicatorInsets = insets;
}

- (void)actionSheet:(UIActionSheet *)actionSheet didDismissWithButtonIndex:(NSInteger)buttonIndex {
    if (buttonIndex == actionSheet.cancelButtonIndex) {
        [self.inputToolbar.contentView.textView becomeFirstResponder];
        return;
    }
}

#pragma mark - JSQMessages CollectionView DataSource

- (NSString *)senderId {
    return [NSString stringWithFormat:@"%llu", [[[MEGASdkManager sharedMEGASdk] myUser] handle]];
}

- (NSString *)senderDisplayName {
    return [[[MEGASdkManager sharedMEGASdk] myUser] email];
}

- (BOOL)isOutgoingMessage:(MEGAMessage *)messageItem {
    if (messageItem.isManagementMessage) {
        return NO;
    }
    return [super isOutgoingMessage:messageItem];
}

- (id<JSQMessageData>)collectionView:(JSQMessagesCollectionView *)collectionView messageDataForItemAtIndexPath:(NSIndexPath *)indexPath {
    MEGAMessage *megaMessage = [self.messagesDictionary objectForKey:[self.indexesMessages objectAtIndex:indexPath.item]];
    return megaMessage;
}

- (void)collectionView:(JSQMessagesCollectionView *)collectionView didDeleteMessageAtIndexPath:(NSIndexPath *)indexPath {
    [self.indexesMessages removeObjectAtIndex:indexPath.item];
}

- (id<JSQMessageBubbleImageDataSource>)collectionView:(JSQMessagesCollectionView *)collectionView messageBubbleImageDataForItemAtIndexPath:(NSIndexPath *)indexPath {
    MEGAMessage *message = [self.messagesDictionary objectForKey:[self.indexesMessages objectAtIndex:indexPath.item]];
    if (message.isManagementMessage || message.isDeleted) {
        return self.managementBubbleImageData;
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
    
    MEGAMessage *message = [self.messagesDictionary objectForKey:[self.indexesMessages objectAtIndex:indexPath.item]];
    BOOL showDayMonthYear = NO;
    if (indexPath.item == 0) {
        showDayMonthYear = YES;
    } else if (indexPath.item - 1 > 0) {
        MEGAMessage *previousMessage = [self.messagesDictionary objectForKey:[self.indexesMessages objectAtIndex:(indexPath.item -1)]];
        showDayMonthYear = [self showDateBetweenMessage:message previousMessage:previousMessage];
    }
    
    if (showDayMonthYear) {
        NSString *dateString = [[JSQMessagesTimestampFormatter sharedFormatter] relativeDateForDate:message.date];
        NSAttributedString *dateAttributedString = [[NSAttributedString alloc] initWithString:dateString attributes:@{NSFontAttributeName:[UIFont fontWithName:@"SFUIText-Regular" size:11.0f], NSForegroundColorAttributeName:[UIColor mnz_black333333]}];
        return dateAttributedString;
    }
    
    return nil;
}

- (NSAttributedString *)collectionView:(JSQMessagesCollectionView *)collectionView attributedTextForMessageBubbleTopLabelAtIndexPath:(NSIndexPath *)indexPath {
    
    MEGAMessage *message = [self.messagesDictionary objectForKey:[self.indexesMessages objectAtIndex:indexPath.item]];
    
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
            NSString *firstName = [self.chatRoom peerFirstnameByHandle:message.userHandle];
            NSString *lastName = [self.chatRoom peerLastnameByHandle:message.userHandle];
            if (firstName) {
                if (lastName) {
                    topCellString = [[[[firstName stringByAppendingString:@" "] stringByAppendingString:lastName] stringByAppendingString:@" "] stringByAppendingString:hour];
                } else {
                    topCellString = [[firstName stringByAppendingString:@" "] stringByAppendingString:hour];
                }
            } else {
                if (lastName) {
                    topCellString = [[lastName stringByAppendingString:@" "] stringByAppendingString:hour];
                } else {
                    // No name
                    topCellString = hour;
                }
            }
        } else {
            topCellString = hour;
        }
        
        return [[NSAttributedString alloc] initWithString:topCellString attributes:@{NSFontAttributeName:[UIFont fontWithName:kFont size:9.0f], NSForegroundColorAttributeName:[UIColor mnz_gray999999]}];
    }
    
    return nil;
}

- (NSAttributedString *)collectionView:(JSQMessagesCollectionView *)collectionView attributedTextForCellBottomLabelAtIndexPath:(NSIndexPath *)indexPath {
    MEGAMessage *megaMessage = [self.messagesDictionary objectForKey:[self.indexesMessages objectAtIndex:indexPath.item]];
    if (megaMessage.isEdited) {
        NSString *editedString = AMLocalizedString(@"edited", @"A log message in a chat to indicate that the message has been edited by the user.");
        NSAttributedString *dateAttributedString = [[NSAttributedString alloc] initWithString:editedString attributes:@{NSFontAttributeName:[UIFont fontWithName:@"SFUIText-Regular" size:9.0f], NSForegroundColorAttributeName:[UIColor mnz_blue2BA6DE]}];
        return dateAttributedString;
    }
    
    return nil;
}

#pragma mark - UICollectionView DataSource

- (NSInteger)collectionView:(UICollectionView *)collectionView numberOfItemsInSection:(NSInteger)section {
    return [self.indexesMessages count];
}

- (UICollectionViewCell *)collectionView:(JSQMessagesCollectionView *)collectionView cellForItemAtIndexPath:(NSIndexPath *)indexPath {    
    if (indexPath.row == 8 && ![[MEGASdkManager sharedMEGAChatSdk] isFullHistoryLoadedForChat:self.chatRoom.chatId]) {
        [self loadMessages];
    }
    
    JSQMessagesCollectionViewCell *cell = (JSQMessagesCollectionViewCell *)[super collectionView:collectionView cellForItemAtIndexPath:indexPath];
    MEGAMessage *megaMessage = [self.messagesDictionary objectForKey:[self.indexesMessages objectAtIndex:indexPath.item]];
    
    if (megaMessage.isDeleted) {
        cell.textView.font = [UIFont fontWithName:@"SFUIText-Light" size:14.0f];
        cell.textView.textColor = [UIColor mnz_blue2BA6DE];
    } else if (megaMessage.isManagementMessage) {
        cell.textView.font = [UIFont fontWithName:@"SFUIText-Light" size:11.0f];
        cell.textView.textColor = [UIColor mnz_black333333];
    } else if (!megaMessage.isMediaMessage) {
        cell.textView.selectable = NO;
        cell.textView.userInteractionEnabled = NO;
        cell.textView.textColor = [UIColor mnz_black333333];
        cell.textView.linkTextAttributes = @{ NSForegroundColorAttributeName : cell.textView.textColor,
                                              NSUnderlineStyleAttributeName : @(NSUnderlineStyleSingle | NSUnderlinePatternSolid) };
    }
    
    cell.accessoryButton.hidden = YES;
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
    self.footerView.typingLabel.text = [NSString stringWithFormat:AMLocalizedString(@"isTyping", nil), self.peerTyping];
    
    return self.footerView;
}

#pragma mark - UICollectionViewDelegate

#pragma mark - Custom menu items

- (BOOL)collectionView:(UICollectionView *)collectionView canPerformAction:(SEL)action forItemAtIndexPath:(NSIndexPath *)indexPath withSender:(id)sender {
    MEGAMessage *megaMessage = [self.messagesDictionary objectForKey:[self.indexesMessages objectAtIndex:indexPath.item]];
    
    if (action == @selector(copy:)) {
        return YES;
    }
    
    if (!megaMessage.isEditable) {
        return NO;
    }
    
    if (![megaMessage.senderId isEqualToString:self.senderId]) {
        return NO;
    }
    if (action == @selector(editAction:megaMessage:)) {
        return YES;
    }
    
    return [super collectionView:collectionView canPerformAction:action forItemAtIndexPath:indexPath withSender:sender];
}

- (void)collectionView:(UICollectionView *)collectionView performAction:(SEL)action forItemAtIndexPath:(NSIndexPath *)indexPath withSender:(id)sender {
    MEGAMessage *megaMessage = [self.messagesDictionary objectForKey:[self.indexesMessages objectAtIndex:indexPath.item]];
    if (action == @selector(editAction:megaMessage:)) {
        [self editAction:sender megaMessage:megaMessage];
        return;
    }
    
    if (action == @selector(delete:)) {
        [[MEGASdkManager sharedMEGAChatSdk] deleteMessageForChat:self.chatRoom.chatId messageId:megaMessage.messageId];
    }
    
    if (action != @selector(delete:)) {
        [super collectionView:collectionView performAction:action forItemAtIndexPath:indexPath withSender:sender];
    }
}

- (void)editAction:(id)sender megaMessage:(MEGAMessage *)megaMessage; {
    [self.inputToolbar.contentView.textView becomeFirstResponder];
    self.inputToolbar.contentView.textView.text = megaMessage.text;
    self.editMessage = megaMessage;
}

#pragma mark - JSQMessages collection view flow layout delegate

#pragma mark - Adjusting cell label heights

- (CGFloat)collectionView:(JSQMessagesCollectionView *)collectionView
                   layout:(JSQMessagesCollectionViewFlowLayout *)collectionViewLayout heightForCellTopLabelAtIndexPath:(NSIndexPath *)indexPath {
    MEGAMessage *message = [self.messagesDictionary objectForKey:[self.indexesMessages objectAtIndex:indexPath.item]];
    BOOL showDayMonthYear = NO;
    if (indexPath.item == 0) {
        showDayMonthYear = YES;
    } else if (indexPath.item - 1 > 0) {
        MEGAMessage *previousMessage = [self.messagesDictionary objectForKey:[self.indexesMessages objectAtIndex:(indexPath.item - 1)]];
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
        MEGAMessage *message = [self.messagesDictionary objectForKey:[self.indexesMessages objectAtIndex:indexPath.item]];
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

- (CGFloat)collectionView:(JSQMessagesCollectionView *)collectionView
                   layout:(JSQMessagesCollectionViewFlowLayout *)collectionViewLayout heightForCellBottomLabelAtIndexPath:(NSIndexPath *)indexPath {
    MEGAMessage *megaMessage = [self.messagesDictionary objectForKey:[self.indexesMessages objectAtIndex:indexPath.item]];
    if (megaMessage.isEdited) {
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
    NSLog(@"Tapped message bubble!");
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
    NSLog(@"Tapped accessory button!");
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
    MEGAMessage *megaMessage = [[MEGAMessage alloc] initWithMEGAChatMessage:message megaChatRoom:self.chatRoom];
    
    [self.indexesMessages addObject:[NSNumber numberWithInteger:message.messageIndex]];
    [self.messagesDictionary setObject:megaMessage forKey:[NSNumber numberWithInteger:message.messageIndex]];
    [self finishReceivingMessage];
    [[MEGASdkManager sharedMEGAChatSdk] setMessageSeenForChat:self.chatRoom.chatId messageId:megaMessage.messageId];
}

- (void)onMessageLoaded:(MEGAChatSdk *)api message:(MEGAChatMessage *)message {
    MEGALogInfo(@"onMessageLoaded %@", message);
    
    if (message) {
        MEGAMessage *megaMessage = [[MEGAMessage alloc] initWithMEGAChatMessage:message megaChatRoom:self.chatRoom];
        [self.messagesDictionary setObject:megaMessage forKey:[NSNumber numberWithInteger:message.messageIndex]];
        [self.indexesMessages insertObject:[NSNumber numberWithInteger:message.messageIndex] atIndex:0];
        
        if (!self.areAllMessagesSeen && message.userHandle != [[[MEGASdkManager sharedMEGASdk] myUser] handle]) {
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
        self.areMessagesLoaded = YES;
    }
}

- (void)onMessageUpdate:(MEGAChatSdk *)api message:(MEGAChatMessage *)message {
    MEGALogInfo(@"onMessageUpdate %@", message);
    
    MEGAMessage *megaMessage = [[MEGAMessage alloc] initWithMEGAChatMessage:message megaChatRoom:self.chatRoom];
    [self.messagesDictionary setObject:megaMessage forKey:[NSNumber numberWithInteger:message.messageIndex]];
    
    if ([message hasChangedForType:MEGAChatMessageChangeTypeStatus]) {
        MEGALogInfo(@"Message update: change status");
        if (message.status == MEGAChatMessageStatusServerReceived) {
            [self.indexesMessages addObject:[NSNumber numberWithInteger:message.messageIndex]];
            [self finishSendingMessageAnimated:YES];
        }
    }
    
    if ([message hasChangedForType:MEGAChatMessageChangeTypeContent]) {
        if (message.isDeleted) {
            MEGALogInfo(@"Message update (delete): change content.");
            [self.collectionView reloadData];
        } else if (message.isEdited) {
            MEGALogInfo(@"Message update (edit): change content: %@", message.content);
            [self.collectionView reloadData];
            [self scrollToBottomAnimated:YES];
        }
        
        if (message.type == MEGAChatMessageTypeTruncate) {
            [self.messagesDictionary removeAllObjects];
            [self.indexesMessages removeAllObjects];
            [self.indexesMessages addObject:[NSNumber numberWithInteger:message.messageIndex]];
            [self.messagesDictionary setObject:megaMessage forKey:[NSNumber numberWithInteger:message.messageIndex]];
            [self.collectionView reloadData];
        }
    }
}

- (void)onChatRoomUpdate:(MEGAChatSdk *)api chat:(MEGAChatRoom *)chat {
    MEGALogInfo(@"onChatRoomUpdate %@", chat);
    self.chatRoom = chat;
    switch (chat.changes) {
        case MEGAChatRoomChangeTypeStatus:
            [self customNavigationBarLabel];
            break;
            
        case MEGAChatRoomChangeTypeUnreadCount:
            break;
            
        case MEGAChatRoomChangeTypeParticipans:
            // TODO: Test when the megachat-native (#6108) bug will be fixed
            [self customNavigationBarLabel];
            break;
            
        case MEGAChatRoomChangeTypeTitle:
            [self customNavigationBarLabel];
            break;
            
        case MEGAChatRoomChangeTypeUserTyping: {
            self.showTypingIndicator = YES;
            NSIndexPath *lastCell = [NSIndexPath indexPathForItem:([self.collectionView numberOfItemsInSection:0] - 1) inSection:0];
            if ([[self.collectionView indexPathsForVisibleItems] containsObject:lastCell]) {
                [self scrollToBottomAnimated:YES];
            }
            
            if (![self.peerTyping isEqualToString:[chat peerFullnameByHandle:chat.userTypingHandle]]) {
                self.peerTyping = [chat peerFullnameByHandle:chat.userTypingHandle];
            }
            self.footerView.typingLabel.text = [NSString stringWithFormat:AMLocalizedString(@"isTyping", nil), self.peerTyping];
            
            [self.receiveTypingTimer invalidate];
            self.receiveTypingTimer = [NSTimer scheduledTimerWithTimeInterval:5.0
                                                                       target:self
                                                                     selector:@selector(hideTypingIndicator)
                                                                     userInfo:nil
                                                                      repeats:YES];
            
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

@end
