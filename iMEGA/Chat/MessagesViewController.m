#import "MessagesViewController.h"
#import "MEGAMessage.h"

@interface MessagesViewController () <JSQMessagesViewAccessoryButtonDelegate, JSQMessagesComposerTextViewPasteDelegate>

@property (nonatomic, strong) NSMutableArray *indexesMessages;
@property (nonatomic, strong) NSMutableDictionary *messagesDictionary;

@property (strong, nonatomic) JSQMessagesBubbleImage *outgoingBubbleImageData;
@property (strong, nonatomic) JSQMessagesBubbleImage *incomingBubbleImageData;

@property (nonatomic, strong) MEGAMessage *editMessage;

@end

@implementation MessagesViewController

#pragma mark - Lifecycle

- (void)viewDidLoad {
    [super viewDidLoad];
    
    self.indexesMessages = [[NSMutableArray alloc] init];
    self.messagesDictionary = [[NSMutableDictionary alloc] init];
    
    if ([[MEGASdkManager sharedMEGAChatSdk] openChatRoom:self.chatRoom.chatId delegate:self]) {        
        MEGALogDebug(@"Chat room opened");
        [self loadMessages];
    } else {
        MEGALogDebug(@"The delegate is NULL or the chatroom is not found");
    }
    
    self.title = self.chatRoom.title;
    
    self.inputToolbar.contentView.textView.pasteDelegate = self;
    
    self.collectionView.collectionViewLayout.incomingAvatarViewSize = CGSizeZero;
    self.collectionView.collectionViewLayout.outgoingAvatarViewSize = CGSizeZero;
    
     //Set up message accessory button delegate and configuration
    self.collectionView.accessoryDelegate = self;
    
    self.showLoadEarlierMessagesHeader = YES;
    
    
     //Register custom menu actions for cells.
    [JSQMessagesCollectionViewCell registerMenuAction:@selector(editAction:megaMessage:)];
    
    
     //Allow cells to be deleted
    [JSQMessagesCollectionViewCell registerMenuAction:@selector(delete:)];
    
    /**
     *  Create message bubble images objects.
     *
     *  Be sure to create your bubble images one time and reuse them for good performance.
     *
     */
    JSQMessagesBubbleImageFactory *bubbleFactory = [[JSQMessagesBubbleImageFactory alloc] init];
    self.outgoingBubbleImageData = [bubbleFactory outgoingMessagesBubbleImageWithColor:[UIColor jsq_messageBubbleLightGrayColor]];
    self.incomingBubbleImageData = [bubbleFactory incomingMessagesBubbleImageWithColor:[UIColor jsq_messageBubbleGreenColor]];
}

- (void)viewWillDisappear:(BOOL)animated {
    [super viewWillDisappear:animated];
    
    [[MEGASdkManager sharedMEGAChatSdk] closeChatRoom:self.chatRoom.chatId delegate:self];
}

#pragma mark - Private methods

- (void)loadMessages {
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

#pragma mark - Custom menu actions for cells

- (void)didReceiveMenuWillShowNotification:(NSNotification *)notification {
     //Display custom menu actions for cells.
    UIMenuController *menu = [notification object];
    menu.menuItems = @[ [[UIMenuItem alloc] initWithTitle:@"Edit" action:@selector(editAction:megaMessage:)] ];
    
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
    
    UIActionSheet *sheet = [[UIActionSheet alloc] initWithTitle:NSLocalizedString(@"Media messages", nil)
                                                       delegate:self
                                              cancelButtonTitle:NSLocalizedString(@"Cancel", nil)
                                         destructiveButtonTitle:nil
                                              otherButtonTitles:NSLocalizedString(@"Send photo", nil), NSLocalizedString(@"Send location", nil), NSLocalizedString(@"Send video", nil), NSLocalizedString(@"Send audio", nil), nil];
    
    [sheet showFromToolbar:self.inputToolbar];
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

- (id<JSQMessageData>)collectionView:(JSQMessagesCollectionView *)collectionView messageDataForItemAtIndexPath:(NSIndexPath *)indexPath {
    MEGAMessage *megaMessage = [self.messagesDictionary objectForKey:[self.indexesMessages objectAtIndex:indexPath.item]];
    return megaMessage;
}

- (void)collectionView:(JSQMessagesCollectionView *)collectionView didDeleteMessageAtIndexPath:(NSIndexPath *)indexPath {
    [self.indexesMessages removeObjectAtIndex:indexPath.item];
}

- (id<JSQMessageBubbleImageDataSource>)collectionView:(JSQMessagesCollectionView *)collectionView messageBubbleImageDataForItemAtIndexPath:(NSIndexPath *)indexPath {
    MEGAMessage *message = [self.messagesDictionary objectForKey:[self.indexesMessages objectAtIndex:indexPath.item]];
    
    if ([message.senderId isEqualToString:self.senderId]) {
        return self.outgoingBubbleImageData;
    }
    
    return self.incomingBubbleImageData;
}

- (id<JSQMessageAvatarImageDataSource>)collectionView:(JSQMessagesCollectionView *)collectionView avatarImageDataForItemAtIndexPath:(NSIndexPath *)indexPath {
    return nil;
}

- (NSAttributedString *)collectionView:(JSQMessagesCollectionView *)collectionView attributedTextForCellTopLabelAtIndexPath:(NSIndexPath *)indexPath{
    MEGAMessage *message = [self.messagesDictionary objectForKey:[self.indexesMessages objectAtIndex:indexPath.item]];
    return [[JSQMessagesTimestampFormatter sharedFormatter] attributedTimestampForDate:message.date];
}

- (NSAttributedString *)collectionView:(JSQMessagesCollectionView *)collectionView attributedTextForMessageBubbleTopLabelAtIndexPath:(NSIndexPath *)indexPath {
    MEGAMessage *message = [self.messagesDictionary objectForKey:[self.indexesMessages objectAtIndex:indexPath.item]];
    
    // iOS7-style sender name labels
    if ([message.senderId isEqualToString:self.senderId]) {
        return nil;
    }
    
    if (indexPath.item - 1 > 0) {
        MEGAMessage *previousMessage = [self.messagesDictionary objectForKey:[self.indexesMessages objectAtIndex:indexPath.item-1]];
        if ([[previousMessage senderId] isEqualToString:message.senderId]) {
            return nil;
        }
    }
    
    NSString *name = [NSString stringWithFormat:@"%@ %@", [self.chatRoom peerFirstnameByHandle:message.userHandle], [self.chatRoom peerLastnameByHandle:message.userHandle]];
    return [[NSAttributedString alloc] initWithString:name];
}

- (NSAttributedString *)collectionView:(JSQMessagesCollectionView *)collectionView attributedTextForCellBottomLabelAtIndexPath:(NSIndexPath *)indexPath {
    MEGAMessage *megaMessage = [self.messagesDictionary objectForKey:[self.indexesMessages objectAtIndex:indexPath.item]];
    if (megaMessage.isEdited) {
        return [[NSAttributedString alloc] initWithString:@"Edited"];
    }
    return nil;
}

#pragma mark - UICollectionView DataSource

- (NSInteger)collectionView:(UICollectionView *)collectionView numberOfItemsInSection:(NSInteger)section {
    return [self.indexesMessages count];
}

- (UICollectionViewCell *)collectionView:(JSQMessagesCollectionView *)collectionView cellForItemAtIndexPath:(NSIndexPath *)indexPath {
    JSQMessagesCollectionViewCell *cell = (JSQMessagesCollectionViewCell *)[super collectionView:collectionView cellForItemAtIndexPath:indexPath];
    MEGAMessage *megaMessage = [self.messagesDictionary objectForKey:[self.indexesMessages objectAtIndex:indexPath.item]];
    
    if (!megaMessage.isMediaMessage) {
        cell.textView.selectable = NO;
        cell.textView.userInteractionEnabled = NO;
    }
    
    if (!megaMessage.isMediaMessage) {
        
        if ([megaMessage.senderId isEqualToString:self.senderId]) {
            cell.textView.textColor = [UIColor blackColor];
        }
        else {
            cell.textView.textColor = [UIColor whiteColor];
        }
        
        cell.textView.linkTextAttributes = @{ NSForegroundColorAttributeName : cell.textView.textColor,
                                              NSUnderlineStyleAttributeName : @(NSUnderlineStyleSingle | NSUnderlinePatternSolid) };
    }
    
    cell.accessoryButton.hidden = YES;
    return cell;
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
        return kJSQMessagesCollectionViewCellLabelHeightDefault;
}

- (CGFloat)collectionView:(JSQMessagesCollectionView *)collectionView
                   layout:(JSQMessagesCollectionViewFlowLayout *)collectionViewLayout heightForMessageBubbleTopLabelAtIndexPath:(NSIndexPath *)indexPath {
    // iOS7-style sender name labels
    MEGAMessage *currentMessage = [self.messagesDictionary objectForKey:[self.indexesMessages objectAtIndex:indexPath.item]];
    if ([[currentMessage senderId] isEqualToString:self.senderId]) {
        return 0.0f;
    }
    
    if (indexPath.item - 1 > 0) {
        MEGAMessage *previousMessage = [self.messagesDictionary objectForKey:[self.indexesMessages objectAtIndex:indexPath.item - 1]];
        if ([[previousMessage senderId] isEqualToString:[currentMessage senderId]]) {
            return 0.0f;
        }
    }
    
    return kJSQMessagesCollectionViewCellLabelHeightDefault;
}

- (CGFloat)collectionView:(JSQMessagesCollectionView *)collectionView
                   layout:(JSQMessagesCollectionViewFlowLayout *)collectionViewLayout heightForCellBottomLabelAtIndexPath:(NSIndexPath *)indexPath {
    return 30.0f;
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



#pragma mark - MEGAChatRoomDelegate

- (void)onMessageReceived:(MEGAChatSdk *)api message:(MEGAChatMessage *)message {
    MEGALogInfo(@"onMessageReceived %@", message);
    MEGAMessage *megaMessage = [[MEGAMessage alloc] initWithMEGAChatMessage:message];
    
    [self.indexesMessages addObject:[NSNumber numberWithInteger:message.messageIndex]];
    [self.messagesDictionary setObject:megaMessage forKey:[NSNumber numberWithInteger:message.messageIndex]];
    [self finishReceivingMessage];
}

- (void)onMessageLoaded:(MEGAChatSdk *)api message:(MEGAChatMessage *)message {
    MEGALogInfo(@"onMessageLoaded %@", message);
    
    if (message && message.type != MEGAChatMessageTypeTruncate) {
        MEGAMessage *megaMessage = [[MEGAMessage alloc] initWithMEGAChatMessage:message];        
        [self.messagesDictionary setObject:megaMessage forKey:[NSNumber numberWithInteger:message.messageIndex]];
        [self.indexesMessages insertObject:[NSNumber numberWithInteger:message.messageIndex] atIndex:0];
    } else {
        [self.collectionView reloadData];
        [self scrollToBottomAnimated:YES];
    }
}

- (void)onMessageUpdate:(MEGAChatSdk *)api message:(MEGAChatMessage *)message {
    MEGALogInfo(@"onMessageUpdate %@", message);
    
    MEGAMessage *megaMessage = [[MEGAMessage alloc] initWithMEGAChatMessage:message];
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
    }
    
}

- (void)onChatRoomUpdate:(MEGAChatSdk *)api chat:(MEGAChatRoom *)chat {
    NSLog(@"onChatRoomUpdate %@", chat);
}

@end
