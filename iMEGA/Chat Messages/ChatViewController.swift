import UIKit
import MessageKit

class ChatViewController: MessagesViewController {

    // MARK: - Properties
    let sdk = MEGASdkManager.sharedMEGASdk()

    @objc var chatRoom: MEGAChatRoom! {
        didSet {
            update()
        }
    }
    var chatCall: MEGAChatCall?

    @objc var publicChatLink: URL?
    @objc var publicChatWithLinkCreated: Bool = false
    var chatInputBar: ChatInputBar?
    var editMessage: ChatMessage? {
        didSet {
            chatInputBar?.editMessage = editMessage
        }
    }
    var addToChatViewController: AddToChatViewController?
    var selectedMessages = Set<ChatMessage>()
    var lastGreenString: String?
    @objc var previewMode = false {
        didSet {
            reloadInputViews()
        }
    }
    
    let shareBarButtonItem = UIBarButtonItem(image: UIImage(named: "share")?.imageFlippedForRightToLeftLayoutDirection(), style: .done,  target: self, action: #selector(ChatViewController.shareSelectedMessages))
    let forwardBarButtonItem = UIBarButtonItem(image: UIImage(named: "forwardToolbar")?.imageFlippedForRightToLeftLayoutDirection(), style: .done, target: self, action: #selector(ChatViewController.forwardSelectedMessages))
    let copyBarButtonItem = UIBarButtonItem(image: UIImage(named: "copy")?.imageFlippedForRightToLeftLayoutDirection(), style: .done, target: self, action: #selector(ChatViewController.copySelectedMessages))
    let offlineBarButtonItem = UIBarButtonItem(image: UIImage(named: "offline")?.imageFlippedForRightToLeftLayoutDirection(), style: .done, target: self, action: #selector(ChatViewController.downloadSelectedMessages))
    let saveToPhotosButtonItem = UIBarButtonItem(image: UIImage(named: "saveToPhotos")?.imageFlippedForRightToLeftLayoutDirection(), style: .done, target: self, action: #selector(ChatViewController.saveToPhotoSelectedMessages))
    let importButtonItem = UIBarButtonItem(image: UIImage(named: "import")?.imageFlippedForRightToLeftLayoutDirection(), style: .done, target: self, action: #selector(ChatViewController.importSelectedMessages))
    
    let deleteBarButtonItem = UIBarButtonItem(barButtonSystemItem: .trash, target: self, action: #selector(ChatViewController.deleteSelectedMessages))
    
    var sendTypingTimer: Timer?
    var keyboardVisible = false
    var richLinkWarningCounterValue: UInt = 0
    var isVoiceRecordingInProgress = false
    var unreadNewMessagesCount = 0 {
        didSet {
            chatBottomInfoScreen.unreadNewMessagesCount = unreadNewMessagesCount
        }
    }
    
    open lazy var audioController = BasicAudioController(messageCollectionView: messagesCollectionView)

    // topbanner
    var timer: Timer?
    var initDuration: TimeInterval?
    var topBannerButtonTopConstraint: NSLayoutConstraint?
    lazy var topBannerButton: UIButton = {
          let button = UIButton()
          button.setTitleColor(.white, for: .normal)
          button.titleLabel?.font = UIFont.preferredFont(forTextStyle: .caption1)
          return button
      }()
    
    lazy var previewerView: PreviewersView = {
        let view = PreviewersView.instanceFromNib
        return view
    }()
    
    var messages: [MessageType] {
        return chatRoomDelegate.messages
    }

    var myUser = User(senderId: String(format: "%llu", MEGASdkManager.sharedMEGAChatSdk().myUserHandle ?? 0), displayName: "")

    lazy var chatRoomDelegate: ChatRoomDelegate = {
        return ChatRoomDelegate(chatRoom: chatRoom)
    }()

    lazy var audioCallBarButtonItem: UIBarButtonItem = {
        return UIBarButtonItem(image: UIImage(named: "audioCall"),
                               style: .done,
                               target: self,
                               action: #selector(startAudioCall))
    }()

    lazy var videoCallBarButtonItem = {
        return UIBarButtonItem(image: UIImage(named: "videoCall"),
                               style: .done,
                               target: self,
                               action: #selector(startVideoCall))
    }()

    lazy var addParticpantBarButtonItem = {
        return UIBarButtonItem(image: UIImage(named: "addContact"),
                               style: .done,
                               target: self,
                               action: #selector(addParticipant))
    }()
    
    lazy var cancelBarButtonItem = {
        return UIBarButtonItem(barButtonSystemItem: .cancel, target: self, action: #selector(cancelSelecting))
     }()
    
    private lazy var chatBottomInfoScreen: ChatBottomNewMessageIndicatorView = {
        let chatBottomNewMessageIndicatorView = ChatBottomNewMessageIndicatorView()
        return chatBottomNewMessageIndicatorView
    }()
    
    private var chatBottomInfoScreenBottomConstraint: NSLayoutConstraint?
    private var chatBottomInfoScreenBottomPadding: CGFloat = 5.0

    // MARK: - Overriden methods

    override func setEditing(_ editing: Bool, animated: Bool) {
        guard let chatViewMessagesFlowLayout = messagesCollectionView.messagesCollectionViewFlowLayout as? ChatViewMessagesFlowLayout else {
            return
        }
        let finishing = !editing
        
        if finishing {
            selectedMessages.removeAll()
            navigationController?.setToolbarHidden(true, animated: true)
            if let layout = messagesCollectionView.collectionViewLayout as? MessagesCollectionViewFlowLayout {
                layout.setMessageIncomingAvatarSize(CGSize(width: 30, height: 30))
            }
        } else {
            if let layout = messagesCollectionView.collectionViewLayout as? MessagesCollectionViewFlowLayout {
                layout.setMessageIncomingAvatarSize(.zero)
            }
            chatInputBar?.dismissKeyboard()
            navigationController?.setToolbarHidden(false, animated: true)
        }
        
        super.setEditing(editing, animated: animated)
        UIView.performWithoutAnimation({
            chatViewMessagesFlowLayout.editing = editing
            self.messagesCollectionView.reloadItems(at: self.messagesCollectionView.indexPathsForVisibleItems)
            self.messagesCollectionView.collectionViewLayout.invalidateLayout()
        })
        reloadInputViews()
        configureNavigationBar()
        updateToolbarState()
    }
    
    override func viewDidLoad() {
        messagesCollectionView = MessagesCollectionView(frame: .zero,
                                                        collectionViewLayout: ChatViewMessagesFlowLayout())
        registerCustomCells()

        super.viewDidLoad()
        chatRoomDelegate.chatViewController = self
        configureMessageCollectionView()
        update()
        
        messagesCollectionView.allowsMultipleSelection = true
        configureMenus()
        configureTopBannerButton()
        configurePreviewerButton()
        addObservers()
        addChatBottomInfoScreenToView()
        configureGuesture()
        
    }
    
    
     @objc private func longPressed(_ gesture: UIGestureRecognizer) {
        
        let touchLocation = gesture.location(in: messagesCollectionView)
        guard let indexPath = messagesCollectionView.indexPathForItem(at: touchLocation) else { return }
        
        guard let messagesDataSource = messagesCollectionView.messagesDataSource else {
            fatalError("Ouch. nil data source for messages")
        }
        
        guard let chatMessage = messagesDataSource.messageForItem(at: indexPath, in: messagesCollectionView) as? ChatMessage, let cell = messagesCollectionView.cellForItem(at: indexPath) as? MessageContentCell else {
            return
        }
        
        switch chatMessage.kind {
        case .custom:
            if self.isEditing {
                return
            }
            
            let megaMessage = chatMessage.message
            if megaMessage.isManagementMessage || chatMessage.transfer?.type == .upload {
                return
            }
            let menu = ChatMessageActionMenuViewController(chatMessage: chatMessage, sender: cell.messageContainerView, chatViewController: self)
            present(viewController: menu)
        default:
            return
        }
        
    }
    
    override var hidesBottomBarWhenPushed: Bool {
        get {
            return true
        }
        set {
            super.hidesBottomBarWhenPushed = newValue
        }
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        MEGASdkManager.sharedMEGAChatSdk().add(self as MEGAChatDelegate)
        MEGASdkManager.sharedMEGAChatSdk().add(self as MEGAChatCallDelegate)

        previewerView.isHidden = chatRoom.previewersCount == 0
        previewerView.previewersLabel.text = "\(chatRoom.previewersCount)"
        configureNavigationBar()
                
        NotificationCenter.default.addObserver(self,
                                               selector: #selector(becomeFirstResponder),
                                               name: NSNotification.Name.MEGAPasscodeViewControllerWillClose,
                                               object: nil)
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        dismissKeyboardIfRequired()
        NotificationCenter.default.removeObserver(self, name: NSNotification.Name.MEGAPasscodeViewControllerWillClose, object: nil)
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        checkIfChatHasActiveCall()
        reloadInputViews()
        TransfersWidgetViewController.sharedTransfer().progressView?.hideWidget()
        
        if (presentingViewController != nil) && parent != nil && UIApplication.mnz_visibleViewController() == self {
            navigationItem.leftBarButtonItem = UIBarButtonItem(title: NSLocalizedString("close", comment: ""), style: .plain, target: self, action: #selector(dismissChatRoom))
        }
        
        if publicChatWithLinkCreated {
            let customModalAlertVC = CustomModalAlertViewController()
            customModalAlertVC.modalPresentationStyle = .overCurrentContext
            customModalAlertVC.image = UIImage(named: "chatLinkCreation")
            customModalAlertVC.viewTitle = chatRoom.title
            customModalAlertVC.detail = NSLocalizedString("People can join your group by using this link.", comment: "Text explaining users how the chat links work.")
            customModalAlertVC.firstButtonTitle = NSLocalizedString("share", comment: "Button title which, if tapped, will trigger the action of sharing with the contact or contacts selected")
            customModalAlertVC.link = publicChatLink?.absoluteString
            customModalAlertVC.secondButtonTitle = NSLocalizedString("delete", comment: "")
            customModalAlertVC.dismissButtonTitle = NSLocalizedString("dismiss", comment: "Label for any 'Dismiss' button, link, text, title, etc. - (String as short as possible).")
            customModalAlertVC.firstCompletion = { [weak customModalAlertVC] in
                customModalAlertVC?.dismiss(animated: true, completion: {
                    let activityVC = UIActivityViewController(activityItems: [self.publicChatLink?.absoluteString], applicationActivities: nil)
                    self.publicChatWithLinkCreated = false
                    if UIDevice.current.iPadDevice {
                        activityVC.popoverPresentationController?.sourceView = self.view
                        activityVC.popoverPresentationController?.sourceRect = self.view.frame
                    }
                    self.present(viewController: activityVC)
                    
                })
                
            }
            customModalAlertVC.secondCompletion = { [weak customModalAlertVC] in
                customModalAlertVC?.dismiss(animated: true, completion: {
                    MEGASdkManager.sharedMEGAChatSdk().removeChatLink(self.chatRoom.chatId, delegate: MEGAChatGenericRequestDelegate(completion: { (request, error) in
                        if error.type == .MEGAChatErrorTypeOk {
                            SVProgressHUD.showSuccess(withStatus: NSLocalizedString("linkRemoved", comment: "Message shown when the link to a file or folder has been removed"))
                        }
                    }))
                    
                })
            }
            
            customModalAlertVC.dismissCompletion = { [weak customModalAlertVC] in
                self.publicChatWithLinkCreated = false
                customModalAlertVC?.dismiss(animated: true, completion: nil)
            }
            
            present(viewController: customModalAlertVC)
        }
        
        setLastMessageAsSeen()
        loadDraft()
    }
    
    override func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)
        saveDraft()
        MEGASdkManager.sharedMEGAChatSdk().remove(self as MEGAChatDelegate)
        MEGASdkManager.sharedMEGAChatSdk().remove(self as MEGAChatCallDelegate)

        if previewMode || isMovingFromParent || presentingViewController != nil && navigationController?.viewControllers.count == 1 {
            closeChatRoom()
        }
        audioController.stopAnyOngoingPlaying()
    }

    override func traitCollectionDidChange(_ previousTraitCollection: UITraitCollection?) {
        super.traitCollectionDidChange(previousTraitCollection)
        
        guard #available(iOS 13, *), traitCollection.hasDifferentColorAppearance(comparedTo: previousTraitCollection) else {
            return
        }
        messagesCollectionView.reloadData()
        
        if let inputbar = inputAccessoryView as? ChatInputBar {
            inputbar.set(keyboardAppearance: traitCollection.userInterfaceStyle == .dark ? .dark : .light)
        }
    }
    
    override func viewWillTransition(to size: CGSize, with coordinator: UIViewControllerTransitionCoordinator) {
        super.viewWillTransition(to: size, with: coordinator)
        
        coordinator.animate(alongsideTransition: { [weak self] _ in
            self?.relayoutChatInputBarIfNeeded()
        }) { [weak self] _ in
            self?.relayoutChatInputBarIfNeeded()
        }
    }
    
    override func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {

        return super.collectionView(collectionView, cellForItemAt: indexPath)
    }
        
    override func collectionView(_ collectionView: UICollectionView, shouldShowMenuForItemAt indexPath: IndexPath) -> Bool {
        return false
    }
    
    func scrollViewDidScroll(_ scrollView: UIScrollView) {
        if scrollView.contentOffset.y < 200 {
            guard !chatRoomDelegate.loadingState && !chatRoomDelegate.isFullChatHistoryLoaded else {
                return
            }
            chatRoomDelegate.loadMoreMessages()
        }
        
        if let inputBar = inputAccessoryView as? ChatInputBar,
           scrollView.isTracking || scrollView.isDragging,
           inputBar.voiceRecordingViewCanBeDismissed {
            inputBar.voiceRecordingViewEnabled = false
        }
        showOrHideJumpToBottom()
    }
    
    override func collectionView(_ collectionView: UICollectionView, viewForSupplementaryElementOfKind kind: String, at indexPath: IndexPath) -> UICollectionReusableView {
        
        switch kind {
        case "kCollectionElementKindEditOverlay":
            guard let overlayView = collectionView.dequeueReusableSupplementaryView(ofKind: "kCollectionElementKindEditOverlay",
                                                                                    withReuseIdentifier: MessageEditCollectionOverlayView.reuseIdentifier,
                                                                                    for: indexPath) as? MessageEditCollectionOverlayView,
                let message = messages[indexPath.section] as? ChatMessage else {
                return super.collectionView(collectionView, viewForSupplementaryElementOfKind: kind, at: indexPath)
            }
            overlayView.delegate = self
            overlayView.indexPath = indexPath
            overlayView.configureDisplaying(isActive: selectedMessages.contains(message))
            return overlayView
        default:
            break
        }
        
        return super.collectionView(collectionView, viewForSupplementaryElementOfKind: kind, at: indexPath)
    }

    func customCell(for message: MessageType, at indexPath: IndexPath, in messagesCollectionView: MessagesCollectionView) -> UICollectionViewCell {

        guard let messagesDataSource = messagesCollectionView.messagesDataSource else {
              fatalError("Ouch. nil data source for messages")
        }
        
        if let notificationMessage = message as? ChatNotificationMessage {
            guard let cell = messagesCollectionView.dequeueReusableCell(withReuseIdentifier: ChatUnreadMessagesLabelCollectionCell.reuseIdentifier,
                                                                        for: indexPath) as? ChatUnreadMessagesLabelCollectionCell,
                case .unreadMessage(let count) = notificationMessage.type else {
                                                                            fatalError("Could not dequeue `ChatUnreadMessagesLabelCollectionCell`")
            }
            cell.unreadMessageCount = count
            return cell
        }

        let chatMessage = messagesDataSource.messageForItem(at: indexPath, in: messagesCollectionView) as! ChatMessage
        if chatMessage.transfer?.transferChatMessageType() == .voiceClip  {
            let cell = messagesCollectionView.dequeueReusableCell(withReuseIdentifier: ChatVoiceClipCollectionViewCell.reuseIdentifier, for: indexPath) as! ChatVoiceClipCollectionViewCell
            cell.configure(with: chatMessage, at: indexPath, and: messagesCollectionView)
            return cell
        } else if chatMessage.transfer?.transferChatMessageType() == .attachment {
            let cell = messagesCollectionView.dequeueReusableCell(withReuseIdentifier: ChatMediaCollectionViewCell.reuseIdentifier, for: indexPath) as! ChatMediaCollectionViewCell
            cell.configure(with: chatMessage, at: indexPath, and: messagesCollectionView)
            return cell
        } else if chatMessage.message.type == .attachment
            || chatMessage.message.type == .contact {
            if (chatMessage.message.nodeList?.size?.intValue ?? 0 == 1) {
                let node = chatMessage.message.nodeList.node(at: 0)!
                if (node.name!.mnz_isImagePathExtension || node.name!.mnz_isVideoPathExtension) {
                    let cell = messagesCollectionView.dequeueReusableCell(withReuseIdentifier: ChatMediaCollectionViewCell.reuseIdentifier, for: indexPath) as! ChatMediaCollectionViewCell
                    cell.configure(with: chatMessage, at: indexPath, and: messagesCollectionView)
                    return cell
                }
            }

            let cell = messagesCollectionView.dequeueReusableCell(withReuseIdentifier: ChatViewAttachmentCell.reuseIdentifier, for: indexPath) as! ChatViewAttachmentCell
            cell.configure(with: chatMessage, at: indexPath, and: messagesCollectionView)
            return cell
        } else if chatMessage.message.type == .normal {
            if chatMessage.message.warningDialog.rawValue > MEGAChatMessageWarningDialog.none.rawValue {
                let cell = messagesCollectionView.dequeueReusableCell(withReuseIdentifier: ChatRichPreviewDialogCollectionViewCell.reuseIdentifier, for: indexPath) as! ChatRichPreviewDialogCollectionViewCell
                cell.configure(with: chatMessage, at: indexPath, and: messagesCollectionView)
                return cell
            } else if chatMessage.message.containsMEGALink() {
                let cell = messagesCollectionView.dequeueReusableCell(withReuseIdentifier: ChatRichPreviewMediaCollectionViewCell.reuseIdentifier, for: indexPath) as! ChatRichPreviewMediaCollectionViewCell
                cell.configure(with: chatMessage, at: indexPath, and: messagesCollectionView)
                return cell
            }
            
            let cell = messagesCollectionView.dequeueReusableCell(withReuseIdentifier: ChatTextMessageViewCell.reuseIdentifier, for: indexPath) as! ChatTextMessageViewCell
            cell.configure(with: chatMessage, at: indexPath, and: messagesCollectionView)
            return cell
        } else if chatMessage.message.type == .voiceClip {
            let cell = messagesCollectionView.dequeueReusableCell(withReuseIdentifier: ChatVoiceClipCollectionViewCell.reuseIdentifier, for: indexPath) as! ChatVoiceClipCollectionViewCell
            cell.configure(with: chatMessage, at: indexPath, and: messagesCollectionView)
            return cell
        } else if chatMessage.message.type == .containsMeta {
            if chatMessage.message.containsMeta.type == .geolocation {
                  let cell = messagesCollectionView.dequeueReusableCell(withReuseIdentifier: ChatLocationCollectionViewCell.reuseIdentifier, for: indexPath) as! ChatLocationCollectionViewCell
                          cell.configure(with: chatMessage, at: indexPath, and: messagesCollectionView)
                          return cell
            } else if chatMessage.message.containsMeta.type == .richPreview {
                let cell = messagesCollectionView.dequeueReusableCell(withReuseIdentifier: ChatRichPreviewMediaCollectionViewCell.reuseIdentifier, for: indexPath) as! ChatRichPreviewMediaCollectionViewCell
                cell.configure(with: chatMessage, at: indexPath, and: messagesCollectionView)
                return cell
            } else if chatMessage.message.containsMeta.type == .giphy {
                let cell = messagesCollectionView.dequeueReusableCell(withReuseIdentifier: ChatGiphyCollectionViewCell.reuseIdentifier, for: indexPath) as! ChatGiphyCollectionViewCell
                cell.configure(with: chatMessage, at: indexPath, and: messagesCollectionView)
                return cell
            } else {
                let cell = messagesCollectionView.dequeueReusableCell(withReuseIdentifier: ChatTextMessageViewCell.reuseIdentifier, for: indexPath) as! ChatTextMessageViewCell
                cell.configure(with: chatMessage, at: indexPath, and: messagesCollectionView)
                return cell
            }
        } else if chatMessage.message.isManagementMessage {
            switch chatMessage.message.type {
            case .callEnded, .callStarted:
                let cell = messagesCollectionView.dequeueReusableCell(withReuseIdentifier: ChatViewCallCollectionCell.reuseIdentifier, for: indexPath) as! ChatViewCallCollectionCell
                cell.configure(with: chatMessage, at: indexPath, and: messagesCollectionView)
                return cell
            default:
                let cell = messagesCollectionView.dequeueReusableCell(withReuseIdentifier: ChatManagmentTypeCollectionViewCell.reuseIdentifier, for: indexPath) as! ChatManagmentTypeCollectionViewCell
                cell.configure(with: chatMessage, at: indexPath, and: messagesCollectionView)
                return cell
            }
        } else {
            let cell = messagesCollectionView.dequeueReusableCell(withReuseIdentifier: ChatViewCallCollectionCell.reuseIdentifier, for: indexPath) as! ChatViewCallCollectionCell
            cell.configure(with: chatMessage, at: indexPath, and: messagesCollectionView)
            return cell
        }

    }

    // MARK: - Interface methods

    @objc func updateUnreadLabel() {
        let unreadChats = MEGASdkManager.sharedMEGAChatSdk().unreadChats ?? 0
        let unreadChatsString = unreadChats > 0 ? "\(unreadChats)" : ""
        
        let backBarButton = UIBarButtonItem(title: unreadChatsString, style: .plain, target: nil, action: nil)
        navigationController?.viewControllers.first?.navigationItem.backBarButtonItem = backBarButton
    }

    @objc func showOptions(forPeerWithHandle handle: UInt64, senderView: UIView) {

    }
    
    @objc func closeChatRoom() {
        chatRoomDelegate.closeChatRoom()
    }
    
    func showJumpToBottom() {
        
        chatBottomInfoScreen.unreadNewMessagesCount = unreadNewMessagesCount
        
        let contentInset = messagesCollectionView.adjustedContentInset.bottom
        
        chatBottomInfoScreenBottomConstraint?.constant = -(contentInset + chatBottomInfoScreenBottomPadding)
        view.layoutIfNeeded()
        
        guard chatBottomInfoScreen.isHidden == true else {
            return
        }
        
        chatBottomInfoScreen.alpha = 0.0
        chatBottomInfoScreen.isHidden = false
        
        UIView.animate(withDuration: 0.2, delay: 0.3, options: .curveEaseInOut, animations: {
            self.chatBottomInfoScreen.alpha = 1.0
        }, completion: nil)
    }

    // MARK: - Internal methods used by the extension of this class

    func isFromCurrentSender(message: MessageType) -> Bool {
        return UInt64(message.sender.senderId) == MEGASdkManager.sharedMEGAChatSdk().myUserHandle
    }

    func isDateLabelVisible(for indexPath: IndexPath) -> Bool {
        if isPreviousMessageSentSameDay(at: indexPath) {
            return false
        }

        return true
    }

    func isTimeLabelVisible(at indexPath: IndexPath) -> Bool {
        guard let previousIndexPath = indexPath.previousSectionIndexPath,
            let previousMessageIndexPath = mostRecentChatMessage(withinIndexPath: previousIndexPath) else {
                return true
        }
        
        if !isPreviousMessageSameSender(at: indexPath)
            || !isMessageSentAtSameMinute(between: indexPath, and: previousMessageIndexPath) {
            return true
        }
        
        return false
    }

    func isPreviousMessageSentSameDay(at indexPath: IndexPath) -> Bool {
        guard let previousIndexPath = indexPath.previousSectionIndexPath,
            let previousMessageIndexPath = mostRecentChatMessage(withinIndexPath: previousIndexPath),
            let previousMessageDate = messages[safe: previousMessageIndexPath.section]?.sentDate else {
                return false
        }


        return messages[safe: indexPath.section]?.sentDate.isSameDay(date: previousMessageDate) ?? false
    }

    /// This method ignores the milliseconds.
    func isPreviousMessageSentSameTime(at indexPath: IndexPath) -> Bool {
        guard let previousIndexPath = indexPath.previousSectionIndexPath,
            let previousMessageIndexPath = mostRecentChatMessage(withinIndexPath: previousIndexPath)   else {
                return true
        }
        return isMessageSentAtSameMinute(between: previousMessageIndexPath, and: indexPath)
    }
    
    func isMessageSentAtSameMinute(between indexPath1: IndexPath, and indexPath2: IndexPath) -> Bool {
        let previousMessageDate = messages[indexPath1.section].sentDate
        return messages[indexPath2.section].sentDate.isSameMinute(date: previousMessageDate)
    }

    func isPreviousMessageSameSender(at indexPath: IndexPath) -> Bool {
        guard let previousIndexPath = indexPath.previousSectionIndexPath,
            let previousMessageIndexPath = mostRecentChatMessage(withinIndexPath: previousIndexPath)  else {
                return false
        }
        return messages[indexPath.section].sender.senderId == messages[previousMessageIndexPath.section].sender.senderId
    }
    
    func avatarImage(for message: MessageType) -> UIImage? {
        return UIImage.mnz_image(forUserHandle: UInt64(message.sender.senderId)!, name: message.sender.displayName, size: CGSize(width: 24, height: 24), delegate: MEGAGenericRequestDelegate { (request, error) in
        })
    }

    func initials(for message: MessageType) -> String {

        if let user = MEGAStore.shareInstance()?.fetchUser(withUserHandle: UInt64(message.sender.senderId)!) {
            return (user.displayName as NSString).mnz_initialForAvatar()
        }

        if let peerFullname = chatRoom.participantName(forUserHandle:UInt64(message.sender.senderId)!) {
            return (peerFullname as NSString).mnz_initialForAvatar()
        }

        return ""
    }

    // MARK: - Private methods
    
    private func mostRecentChatMessage(withinIndexPath indexPath: IndexPath) -> IndexPath? {
        if messages[safe: indexPath.section] is ChatMessage {
            return indexPath
        }
        
        guard let previousIndexPath = indexPath.previousSectionIndexPath else { return nil }
        return mostRecentChatMessage(withinIndexPath: previousIndexPath)
    }
    
    private func configureMessageCollectionView() {
        messagesCollectionView.register(ChatViewIntroductionHeaderView.nib,
                                        forSupplementaryViewOfKind: UICollectionView.elementKindSectionHeader,
                                        withReuseIdentifier: ChatViewIntroductionHeaderView.reuseIdentifier)

        messagesCollectionView.register(LoadingMessageReusableView.nib,
        forSupplementaryViewOfKind: UICollectionView.elementKindSectionHeader,
        withReuseIdentifier: LoadingMessageReusableView.reuseIdentifier)
        
        messagesCollectionView.register(MessageEditCollectionOverlayView.nib,
                                        forSupplementaryViewOfKind: "kCollectionElementKindEditOverlay",
                                        withReuseIdentifier: MessageEditCollectionOverlayView.reuseIdentifier)
        messagesCollectionView.register(MessageReactionReusableView.nib,
                                        forSupplementaryViewOfKind: UICollectionView.elementKindSectionFooter,
                                            withReuseIdentifier: MessageReactionReusableView.reuseIdentifier)
            
        messagesCollectionView.messagesDataSource = self
        messagesCollectionView.messagesLayoutDelegate = self
        messagesCollectionView.messagesDisplayDelegate = self
        messagesCollectionView.messageCellDelegate = self

        messagesCollectionView.emptyDataSetSource = self
        messagesCollectionView.emptyDataSetDelegate = self
        
        maintainPositionOnKeyboardFrameChanged = true
    }
    
    private func configureMenus() {
        let forwardMenuItem = UIMenuItem(title:NSLocalizedString("forward", comment: "Item of a menu to forward a message chat to another chatroom"), action: #selector(MessageCollectionViewCell.forward(_:)))
        
        let importMenuItem = UIMenuItem(title:NSLocalizedString("Import to Cloud Drive", comment: "Caption of a button to edit the files that are selected"), action: #selector(MessageCollectionViewCell.importMessage(_:)))
        
        let editMenuItem = UIMenuItem(title:NSLocalizedString("edit", comment: "Caption of a button to edit the files that are selected"), action: #selector(MessageCollectionViewCell.edit(_:)))

        let downloadMenuItem = UIMenuItem(title:NSLocalizedString("saveForOffline", comment: "Caption of a button to download the files that are selected"), action: #selector(MessageCollectionViewCell.download(_:)))

        let addContactMenuItem = UIMenuItem(title:NSLocalizedString("addContact", comment: "Alert title shown when you select to add a contact inserting his/her email"), action: #selector(MessageCollectionViewCell.addContact(_:)))

        let removeRichLinkMenuItem = UIMenuItem(title:NSLocalizedString("removePreview", comment: "Once a preview is generated for a message which contains URLs, the user can remove it. Same button is also shown during loading of the preview - and would cancel the loading (text of the button is the same in both cases)."), action: #selector(MessageCollectionViewCell.removeRichPreview(_:)))

        
        UIMenuController.shared.menuItems = [forwardMenuItem, importMenuItem, editMenuItem, downloadMenuItem, addContactMenuItem, removeRichLinkMenuItem]
    }
    
    private func configureTopBannerButton() {
          view.addSubview(topBannerButton)
          topBannerButtonTopConstraint = topBannerButton.autoPinEdge(toSuperviewMargin: .top, withInset: -44)
          topBannerButton.autoPinEdge(toSuperviewEdge: .leading)
          topBannerButton.autoPinEdge(toSuperviewEdge: .trailing)
          topBannerButton.autoSetDimension(.height, toSize: 44)
          topBannerButton.addTarget(self, action: #selector(joinActiveCall), for: .touchUpInside)
          topBannerButton.backgroundColor = UIColor.mnz_turquoise(for: self.traitCollection)
          topBannerButton.isHidden = true
      }
    
    private func configurePreviewerButton() {
        view.addSubview(previewerView)
        previewerView.autoPinEdge(toSuperviewMargin: .top, withInset: 12)
        previewerView.autoAlignAxis(toSuperviewAxis: .vertical)
        previewerView.autoSetDimensions(to: CGSize(width: 75, height: 34))
        previewerView.isHidden = true
    }
    
    private func relayoutChatInputBarIfNeeded() {
        if let inputbar = inputAccessoryView as? ChatInputBar {
            inputbar.relayout()
        }
    }
    
    func configureGuesture() {
        let longPressRecognizer = UILongPressGestureRecognizer(target: self, action: #selector(longPressed(_:)))
        
        messagesCollectionView.addGestureRecognizer(longPressRecognizer)
    }
    
    private func registerCustomCells() {
        messagesCollectionView.register(ChatViewCallCollectionCell.self,
                                         forCellWithReuseIdentifier: ChatViewCallCollectionCell.reuseIdentifier)
        messagesCollectionView.register(ChatViewAttachmentCell.self,
                                         forCellWithReuseIdentifier: ChatViewAttachmentCell.reuseIdentifier)
        messagesCollectionView.register(ChatMediaCollectionViewCell.self,
                                         forCellWithReuseIdentifier: ChatMediaCollectionViewCell.reuseIdentifier)
        messagesCollectionView.register(ChatRichPreviewMediaCollectionViewCell.self,
                                               forCellWithReuseIdentifier: ChatRichPreviewMediaCollectionViewCell.reuseIdentifier)
        messagesCollectionView.register(ChatVoiceClipCollectionViewCell.self,
                                                 forCellWithReuseIdentifier: ChatVoiceClipCollectionViewCell.reuseIdentifier)
        messagesCollectionView.register(ChatTextMessageViewCell.self,
                                                     forCellWithReuseIdentifier: ChatTextMessageViewCell.reuseIdentifier)
        messagesCollectionView.register(ChatLocationCollectionViewCell.self,
                                        forCellWithReuseIdentifier: ChatLocationCollectionViewCell.reuseIdentifier)
        messagesCollectionView.register(ChatGiphyCollectionViewCell.self,
                                              forCellWithReuseIdentifier: ChatGiphyCollectionViewCell.reuseIdentifier)
        messagesCollectionView.register(ChatManagmentTypeCollectionViewCell.self,
                                        forCellWithReuseIdentifier: ChatManagmentTypeCollectionViewCell.reuseIdentifier)
        messagesCollectionView.register(ChatUnreadMessagesLabelCollectionCell.nib,
                                        forCellWithReuseIdentifier: ChatUnreadMessagesLabelCollectionCell.reuseIdentifier)
        messagesCollectionView.register(ChatRichPreviewDialogCollectionViewCell.self,
                                        forCellWithReuseIdentifier: ChatRichPreviewDialogCollectionViewCell.reuseIdentifier)

    }

    @objc func update() {
        guard isViewLoaded, chatRoom != nil else {
            return
        }

        configureNavigationBar()
        chatRoomDelegate.openChatRoom()
        if !chatRoom.isGroup {
            MEGASdkManager.sharedMEGAChatSdk().requestLastGreen(chatRoom.peerHandle(at: 0))
        }
        if let layout = messagesCollectionView.collectionViewLayout as? MessagesCollectionViewFlowLayout {
            layout.setMessageOutgoingAvatarSize(.zero)
            layout.setMessageOutgoingMessageTopLabelAlignment(LabelAlignment(textAlignment: .right, textInsets:  UIEdgeInsets(top: 0, left: 0, bottom: 0, right: 12)))

        }
    }
    
    @objc func setLastMessageAsSeen() {
        if messages.count > 0 {
            let chatMessages = messages.filter { (message) -> Bool in
                guard let message = message as? ChatMessage, message.transfer == nil else {
                    return false
                }
                return true
            }
            
            guard let lastMessage = chatMessages.last as? ChatMessage else {
                return
            }
            
            let lastSeenMessage = MEGASdkManager.sharedMEGAChatSdk().lastChatMessageSeen(forChat: chatRoom.chatId)
            if lastMessage.message.userHandle != MEGASdkManager.sharedMEGAChatSdk().myUserHandle
                && (lastSeenMessage?.messageId != lastMessage.message.messageId) {
                MEGASdkManager.sharedMEGAChatSdk().setMessageSeenForChat(chatRoom.chatId, messageId: lastMessage.message.messageId)
            }
        }
    }
    
    @objc func loadMoreMessages() {
        
        chatRoomDelegate.loadMoreMessages()
    }

    private func addObservers() {
        NotificationCenter.default.addObserver(forName: NSNotification.Name.reachabilityChanged,
                                               object: nil,
                                               queue: OperationQueue.main) { [weak self] _ in
                                                self?.configureNavigationBar()
        }
        
        NotificationCenter.default.addObserver(self,
                                               selector: #selector(handleKeyboardShown(_:)),
                                               name: UIResponder.keyboardDidShowNotification,
                                               object: nil)
        NotificationCenter.default.addObserver(self,
                                               selector: #selector(handleKeyboardHidden(_:)),
                                               name: UIResponder.keyboardWillHideNotification,
                                               object: nil)
        
        NotificationCenter.default.addObserver(self,
                                               selector: #selector(willResignActive(_:)),
                                               name: UIApplication.willResignActiveNotification,
                                               object: nil)
        
        NotificationCenter.default.addObserver(self,
                                               selector: #selector(didBecomeActive(_:)),
                                               name: UIApplication.didBecomeActiveNotification,
                                               object: nil)
    }
    
    private func removeObservers() {
        NotificationCenter.default.removeObserver(self,
                                                  name: NSNotification.Name.reachabilityChanged,
                                                  object: nil)
        NotificationCenter.default.removeObserver(self,
                                                  name: UIResponder.keyboardDidShowNotification,
                                                  object: nil)
        NotificationCenter.default.removeObserver(self,
                                                  name: UIResponder.keyboardWillHideNotification,
                                                  object: nil)
        NotificationCenter.default.removeObserver(self,
                                               name: UIApplication.willResignActiveNotification,
                                               object: nil)
    }
        
    @objc private func handleKeyboardShown(_ notification: Notification) {
        
        showOrHideJumpToBottom()

        // When there are no messages and the introduction text is shown and the keyboard appears the content inset is not added automatically and we do need to add the inset to the collection
        guard chatRoomDelegate.chatMessages.count == 0,
            let inputView = inputAccessoryView as? ChatInputBar,
            inputView.isTextViewTheFirstResponder() else {
            return
        }
        
        guard let keyboardFrame = notification.userInfo?[UIResponder.keyboardFrameEndUserInfoKey] as? CGRect,
            let inputAccessoryView = inputAccessoryView  else {
            return
        }
        
        additionalBottomInset = keyboardFrame.height + inputAccessoryView.frame.height
        messagesCollectionView.scrollToBottom()
        keyboardVisible = true
    }
    
    @objc private func handleKeyboardHidden(_ notification: Notification) {
        guard keyboardVisible else {
            return
        }
        
        additionalBottomInset = 0
        keyboardVisible = false
    }
    
    @objc func didBecomeActive(_ notification: Notification) {
        if UIApplication.mnz_visibleViewController() == self {
            setLastMessageAsSeen()
        }
    }
    
    @objc private func willResignActive(_ notification: Notification) {
        saveDraft()
    }
    
    func checkTransferPauseStatus() {
        if UserDefaults.standard.bool(forKey: "TransfersPaused") {
            let alertController = UIAlertController(title: NSLocalizedString("Resume Transfers?", comment: ""), message: nil, preferredStyle: .alert)
            
            let cancel = UIAlertAction(title: NSLocalizedString("cancel", comment: ""), style: .cancel)
            
            let action2 = UIAlertAction(title: NSLocalizedString("resume", comment: ""), style: .default) { (action:UIAlertAction) in
                MEGASdkManager.sharedMEGASdk().pauseTransfers(false)
                UserDefaults.standard.set(false, forKey: "TransfersPaused")
            }
            
            alertController.addAction(cancel)
            alertController.addAction(action2)
            present(viewController: alertController)
        }
    }
    
    private func addChatBottomInfoScreenToView() {
        chatBottomInfoScreen.tapHandler = { [weak self] in
            guard let `self` = self else {
                return
            }
            self.unreadNewMessagesCount = 0
            self.messagesCollectionView.scrollToLastItem()
            self.hideJumpToBottomIfRequired()
        }
        view.addSubview(chatBottomInfoScreen)
        chatBottomInfoScreen.isHidden = true
        chatBottomInfoScreen.translatesAutoresizingMaskIntoConstraints = false
        
        chatBottomInfoScreen.autoSetDimensions(to: CGSize(width: chatBottomInfoScreen.bounds.width, height: chatBottomInfoScreen.bounds.height))
        chatBottomInfoScreenBottomConstraint = chatBottomInfoScreen.autoPinEdge(toSuperviewEdge: .bottom, withInset: -chatBottomInfoScreenBottomPadding)
        chatBottomInfoScreen.autoPinEdge(toSuperviewSafeArea: .right, withInset: 20)
    }
    
    func showOrHideJumpToBottom() {
        let verticalIncrementToShow = view.frame.size.height * 1.5
        let bottomContentOffsetValue = messagesCollectionView.contentSize.height - messagesCollectionView.contentOffset.y
        if bottomContentOffsetValue < verticalIncrementToShow {
            hideJumpToBottomIfRequired()
            unreadNewMessagesCount = 0
        } else {
            showJumpToBottom()
        }
    }
    
    private func hideJumpToBottomIfRequired() {
        guard !chatBottomInfoScreen.isHidden else {
            return
        }
        
        UIView.animate(withDuration: 0.2, animations: {
            self.chatBottomInfoScreen.alpha = 0.0
        }) { _ in
            self.chatBottomInfoScreen.isHidden = true
            self.chatBottomInfoScreen.alpha = 1.0
        }
    }

    // MARK: - Bar Button actions

    @objc func startAudioCall() {
        DevicePermissionsHelper.audioPermissionModal(true, forIncomingCall: false) { (granted) in
            if granted {
                self.openCallViewWithVideo(videoCall: false)
            } else {
                DevicePermissionsHelper.alertAudioPermission(forIncomingCall: false)
            }
        }
    }

    @objc func startVideoCall() {
        DevicePermissionsHelper.audioPermissionModal(true, forIncomingCall: false) { (granted) in
            if granted {
                DevicePermissionsHelper.videoPermission { (videoPermission) in
                    if videoPermission {
                        self.openCallViewWithVideo(videoCall: true)
                    } else {
                        DevicePermissionsHelper.alertVideoPermission(completionHandler: nil)
                    }
                }
                
            } else {
                DevicePermissionsHelper.alertAudioPermission(forIncomingCall: false)
            }
        }
    }

    @objc func dismissChatRoom() {
        dismiss(animated: true) {
            if MEGASdkManager.sharedMEGAChatSdk().initState() == .anonymous {
                MEGASdkManager.sharedMEGAChatSdk().logout()
                
                if MEGALinkManager.selectedOption == .joinChatLink, let onboardingVC = UIApplication.mnz_visibleViewController() as? OnboardingViewController {
                    onboardingVC.presentLoginViewController()
                }
            }
        }
    }
    
    @objc func addParticipant() {
        let navigationController = UIStoryboard.init(name: "Contacts", bundle: nil).instantiateViewController(withIdentifier: "ContactsNavigationControllerID") as! UINavigationController
        let contactsVC = navigationController.viewControllers.first as! ContactsViewController
        contactsVC.contactsMode = .chatAddParticipant
        var participantsMutableDictionary: [NSNumber:NSNumber] = [:]
        
        if chatRoom.peerCount > 1 {
            for idx in 0...chatRoom.peerCount - 1 {
                let peerHandle = chatRoom.peerHandle(at: idx)
                if chatRoom.peerPrivilege(byHandle: peerHandle) > MEGAChatRoomPrivilege.rm.rawValue {
                    participantsMutableDictionary[NSNumber(value: peerHandle)] = NSNumber(value: peerHandle)
                }
            }
        }
        
        contactsVC.participantsMutableDictionary = NSMutableDictionary(dictionary: participantsMutableDictionary)
        contactsVC.userSelected = { users in
            users?.forEach({ [weak self] (user) in
                guard let `self` = self else {
                    return
                }
                MEGASdkManager.sharedMEGAChatSdk().invite(toChat: self.chatRoom.chatId, user: (user as! MEGAUser).handle, privilege: MEGAChatRoomPrivilege.standard.rawValue)
            })
        }
        present(viewController: navigationController)
    }
    
    @objc func cancelSelecting() {
        setEditing(false, animated: true)
    }

    func openCallViewWithVideo(videoCall: Bool) {
        var callType = CallType.outgoing
        let call = MEGASdkManager.sharedMEGAChatSdk().chatCall(forChatId: chatRoom.chatId)
        
        if let call = call {
            callType = (call.status == .ringIn) ? .incoming : .active
        }
        
        if chatRoom.isGroup {
            guard chatRoom.peerCount + 1 <= 20 || call?.status == .inProgress else {
                if callType == .outgoing  {
                    SVProgressHUD.showError(withStatus: NSLocalizedString("Unable to start a call because the participants limit was exceeded.", comment: "Error shown when trying to start a call in a group with more peers than allowed"))
                } else {
                    SVProgressHUD.showError(withStatus: NSLocalizedString("Error. No more participants are allowed in this group call.", comment: "Message show when a call cannot be established because there are too many participants in the group call"))
                }
                return
            }
            
            let groupCallVC = UIStoryboard(name: "Chat", bundle: nil).instantiateViewController(withIdentifier: "GroupCallViewControllerID") as! GroupCallViewController
            groupCallVC.callType = callType
            if let call = call {
                groupCallVC.callId = call.callId
            }
            groupCallVC.videoCall = videoCall
            groupCallVC.chatRoom = chatRoom
            groupCallVC.modalTransitionStyle = .crossDissolve
            groupCallVC.modalPresentationStyle = .fullScreen
            groupCallVC.megaCallManager = (UIApplication.shared.delegate as! AppDelegate).megaCallManager
            present(viewController: groupCallVC)
        } else {
            let callVC = UIStoryboard(name: "Chat", bundle: nil).instantiateViewController(withIdentifier: "CallViewControllerID") as! CallViewController
            callVC.chatRoom = chatRoom
            callVC.videoCall = videoCall
            callVC.callType = callType
            if let call = call {
                callVC.callId = call.callId
            }
            callVC.modalTransitionStyle = .crossDissolve
            callVC.modalPresentationStyle = .fullScreen
            callVC.megaCallManager = (UIApplication.shared.delegate as! AppDelegate).megaCallManager
            present(viewController: callVC)

        }
        
    }
    
    deinit {
        removeObservers()
        closeChatRoom()
    }
}
