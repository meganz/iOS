import ChatRepo
import Combine
import KeyboardLayoutGuide
import MEGADesignToken
import MEGADomain
import MEGAL10n
import MEGAPermissions
import MEGASDKRepo
import MEGAUIKit
import MessageKit
import UIKit

class ChatViewController: MessagesViewController {
    let spacePadding = "   "
    let sdk = MEGASdk.shared
    let chatContentViewModel: ChatContentViewModel
    
    @objc private(set) var chatRoom: MEGAChatRoom
    
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
    
    var startOrJoinButtonIsHiddenSubscription: AnyCancellable?
    
    lazy var exportBarButtonItem: UIBarButtonItem = {
        let exportBarButtonItem = UIBarButtonItem(image: UIImage(resource: .export).imageFlippedForRightToLeftLayoutDirection(), style: .done, target: self, action: #selector(ChatViewController.exportSelectedMessages))
        return exportBarButtonItem
    }()
    lazy var forwardBarButtonItem: UIBarButtonItem = {
        let forwardBarButtonItem = UIBarButtonItem(image: UIImage(resource: .forwardToolbar).imageFlippedForRightToLeftLayoutDirection(), style: .done, target: self, action: #selector(ChatViewController.forwardSelectedMessages))
        return forwardBarButtonItem
    }()
    lazy var copyBarButtonItem: UIBarButtonItem = {
        let copyBarButtonItem = UIBarButtonItem(image: UIImage(resource: .copy).imageFlippedForRightToLeftLayoutDirection(), style: .done, target: self, action: #selector(ChatViewController.copySelectedMessages))
        return copyBarButtonItem
    }()
    lazy var offlineBarButtonItem: UIBarButtonItem = {
        let offlineBarButtonItem = UIBarButtonItem(image: UIImage(resource: .offline).imageFlippedForRightToLeftLayoutDirection(), style: .done, target: self, action: #selector(ChatViewController.downloadSelectedMessages))
        return offlineBarButtonItem
    }()
    lazy var saveToPhotosButtonItem: UIBarButtonItem = {
        let saveToPhotosButtonItem = UIBarButtonItem(image: UIImage(resource: .saveToPhotos).imageFlippedForRightToLeftLayoutDirection(), style: .done, target: self, action: #selector(ChatViewController.saveToPhotoSelectedMessages))
        return saveToPhotosButtonItem
    }()
    lazy var importButtonItem: UIBarButtonItem = {
        let importButtonItem = UIBarButtonItem(image: UIImage(resource: .import).imageFlippedForRightToLeftLayoutDirection(), style: .done, target: self, action: #selector(ChatViewController.importSelectedMessages))
        return importButtonItem
    }()
    
    lazy var deleteBarButtonItem: UIBarButtonItem = {
        let deleteBarButtonItem = UIBarButtonItem(barButtonSystemItem: .trash, target: self, action: #selector(ChatViewController.deleteSelectedMessages))
        return deleteBarButtonItem
    }()
    
    var sendTypingTimer: Timer?
    var keyboardVisible = false
    var richLinkWarningCounterValue: Int = 0
    var isVoiceRecordingInProgress = false
    var shouldDisableAudioVideoCalling = false
    var unreadNewMessagesCount = 0 {
        didSet {
            chatBottomInfoScreen.unreadNewMessagesCount = unreadNewMessagesCount
        }
    }
    
    open lazy var audioController = BasicAudioController(messageCollectionView: messagesCollectionView)
    
    let permissionHandler: some DevicePermissionsHandling = DevicePermissionsHandler.makeHandler()
    
    lazy var startOrJoinCallButton: UIButton = {
        let button = UIButton()
        button.titleLabel?.font = UIFont.preferredFont(forTextStyle: .callout)
        button.layer.cornerRadius = 20
        button.backgroundColor = TokenColors.Background.inverse
        button.setTitleColor(TokenColors.Text.inverseAccent, for: .normal)
        
        return button
    }()
    
    lazy var tapToReturnToCallButton: UIButton = {
        let button = MEGAButtonLegacy(textStyle: "caption1", weight: "bold")
        button.setTitle(Strings.Localizable.tapToReturnToCall, for: .normal)
        button.setTitleColor(TokenColors.Text.inverseAccent, for: .normal)
        button.backgroundColor = TokenColors.Button.primary
        
        return button
    }()
    
    lazy var previewerView: PreviewersView = {
        let view = PreviewersView.instanceFromNib
        view.translatesAutoresizingMaskIntoConstraints = false
        return view
    }()
    
    var messages: [any MessageType] {
        return chatRoomDelegate.messages
    }
    
    var myUser = User(senderId: String(format: "%llu", MEGAChatSdk.shared.myUserHandle), displayName: "")
    
    lazy var chatRoomDelegate: ChatRoomDelegate = {
        return ChatRoomDelegate(chatRoom: chatRoom)
    }()
    
    lazy var audioCallBarButtonItem: UIBarButtonItem = {
        return UIBarButtonItem(image: UIImage(resource: .audioCall),
                               style: .done,
                               target: self,
                               action: #selector(startAudioCall))
    }()
    
    lazy var videoCallBarButtonItem = {
        return UIBarButtonItem(image: UIImage(resource: .videoCall),
                               style: .done,
                               target: self,
                               action: #selector(startVideoCall))
    }()
    
    lazy var addParticipantBarButtonItem = {
        return UIBarButtonItem(image: UIImage(resource: .addContact),
                               style: .done,
                               target: self,
                               action: #selector(addParticipant))
    }()
    
    lazy var cancelBarButtonItem = {
        return UIBarButtonItem(barButtonSystemItem: .cancel, target: self, action: #selector(cancelSelecting))
    }()
    
    private lazy var chatBottomInfoScreen: ChatBottomNewMessageIndicatorView = {
        let chatBottomNewMessageIndicatorView = ChatBottomNewMessageIndicatorView()
        chatBottomNewMessageIndicatorView.translatesAutoresizingMaskIntoConstraints = false
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
    
    init(chatRoom: MEGAChatRoom, chatContentViewModel: ChatContentViewModel) {
        self.chatRoom = chatRoom
        self.chatContentViewModel = chatContentViewModel
        super.init(nibName: nil, bundle: nil)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func viewDidLoad() {
        messagesCollectionView = MessagesCollectionView(frame: .zero,
                                                        collectionViewLayout: ChatViewMessagesFlowLayout())
        registerCustomCells()
        
        super.viewDidLoad()
        
        messagesCollectionView.backgroundColor = TokenColors.Background.page
        chatRoomDelegate.chatViewController = self
        configureMessageCollectionView()
        update()
        
        messagesCollectionView.allowsMultipleSelection = true
        configureStartOrJoinCallButton()
        configureTapToReturnToCallButton()
        configurePreviewerButton()
        addObservers()
        addChatBottomInfoScreenToView()
        configureGesture()
        
        chatContentViewModel.invokeCommand = { [weak self] command in
            guard let self else { return }
            executeCommand(command)
        }
        setMenuCapableBackButtonWith(
            menuTitle: Self.backButtonMenuTitle(
                chatTitle: chatRoom.title,
                isOneToOne: chatRoom.isOneToOne
            )
        )
        
        startOrJoinButtonIsHiddenSubscription = startOrJoinCallButton
            .publisher(for: \.isHidden)
            .receive(on: DispatchQueue.main)
            .sink(receiveValue: { [weak self] isHidden in
                guard let self else { return }
                messagesCollectionView.contentInset.top = isHidden ? 0 : startOrJoinCallButton.frame.height * 2
            })
        
        NotificationCenter.default.addObserver(self, selector: #selector(stopVoiceRecording), name: UIApplication.willResignActiveNotification, object: nil)
    }
    
    static func backButtonMenuTitle(chatTitle: String?, isOneToOne: Bool) -> String {
        let title = chatTitle ?? ""
        
        if isOneToOne && title.isNotEmpty {
            return Strings.Localizable.Chat.BackButton.OneToOne.menu(title)
        }
        
        return title
    }
    
    @objc func update(chatRoom: MEGAChatRoom) {
        self.chatRoom = chatRoom
        updateChatRoom(chatRoom.toChatRoomEntity())
        update()
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
        MEGAChatSdk.shared.add(self as (any MEGAChatDelegate))
        
        previewerView.isHidden = chatRoom.previewersCount == 0
        previewerView.previewersLabel.text = "\(chatRoom.previewersCount)"
        configureNavigationBar()
        chatContentViewModel.dispatch(.updateContent)
        
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
        
        reloadInputViews()
        
        if (presentingViewController != nil) && parent != nil && UIApplication.mnz_visibleViewController() == self {
            navigationItem.leftBarButtonItem = UIBarButtonItem(title: Strings.Localizable.close, style: .plain, target: self, action: #selector(dismissChatRoom))
        }
        
        guard let publicChatLinkString = self.publicChatLink?.absoluteString else {
            setLastMessageAsSeen()
            loadDraft()
            return
        }
        if publicChatWithLinkCreated {
            let customModalAlertVC = CustomModalAlertViewController()
            customModalAlertVC.modalPresentationStyle = .overCurrentContext
            customModalAlertVC.image = UIImage(resource: .chatLinkCreation)
            customModalAlertVC.viewTitle = chatRoom.title
            customModalAlertVC.detail = Strings.Localizable.peopleCanJoinYourGroupByUsingThisLink
            customModalAlertVC.firstButtonTitle = Strings.Localizable.General.share
            customModalAlertVC.link = publicChatLink?.absoluteString
            customModalAlertVC.secondButtonTitle = Strings.Localizable.delete
            customModalAlertVC.dismissButtonTitle = Strings.Localizable.dismiss
            customModalAlertVC.firstCompletion = { [weak customModalAlertVC] in
                customModalAlertVC?.dismiss(animated: true, completion: {
                    let activityVC = UIActivityViewController(activityItems: [publicChatLinkString], applicationActivities: nil)
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
                    MEGAChatSdk.shared.removeChatLink(self.chatRoom.chatId, delegate: ChatRequestDelegate { result in
                        if case .success = result {
                            SVProgressHUD.showSuccess(withStatus: Strings.Localizable.Chat.Link.linkRemoved)
                        }
                    })
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
        
        stopVoiceRecording()
        
        MEGAChatSdk.shared.removeMEGAChatDelegateAsync(self as (any MEGAChatDelegate))
        
        if previewMode || isMovingFromParent || presentingViewController != nil && navigationController?.viewControllers.count == 1 {
            closeChatRoom()
        }
        
        audioController.stopAnyOngoingPlaying()
    }
    
    @objc func stopVoiceRecording() {
        chatInputBar?.cancelRecordingIfNeeded()
    }
    
    override func traitCollectionDidChange(_ previousTraitCollection: UITraitCollection?) {
        super.traitCollectionDidChange(previousTraitCollection)
        
        guard traitCollection.hasDifferentColorAppearance(comparedTo: previousTraitCollection) ||
                traitCollection.preferredContentSizeCategory != previousTraitCollection?.preferredContentSizeCategory else {
            return
        }

        messagesCollectionView.reloadData()
        startOrJoinCallButton.backgroundColor = TokenColors.Background.inverse
        startOrJoinCallButton.setTitleColor(TokenColors.Text.inverseAccent, for: .normal)
        
        if let inputbar = inputAccessoryView as? ChatInputBar {
            inputbar.set(keyboardAppearance: traitCollection.userInterfaceStyle == .dark ? .dark : .light)
        }
    }
    
    override func viewWillTransition(to size: CGSize, with coordinator: any UIViewControllerTransitionCoordinator) {
        super.viewWillTransition(to: size, with: coordinator)
        
        coordinator.animate(alongsideTransition: { [weak self] _ in
            self?.relayoutChatInputBarIfNeeded()
        }, completion: { [weak self] _ in
            self?.relayoutChatInputBarIfNeeded()
        })
    }
    
    override func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        
        return super.collectionView(collectionView, cellForItemAt: indexPath)
    }
    
    override func collectionView(_ collectionView: UICollectionView, shouldShowMenuForItemAt indexPath: IndexPath) -> Bool {
        return false
    }
    
    override func scrollViewDidScroll(_ scrollView: UIScrollView) {
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
    
    func customCell(for message: any MessageType, at indexPath: IndexPath, in messagesCollectionView: MessagesCollectionView) -> UICollectionViewCell {
        
        guard let messagesDataSource = messagesCollectionView.messagesDataSource else {
            fatalError("Ouch. nil data source for messages")
        }
        
        if let notificationMessage = message as? ChatNotificationMessage {
            return customCell(for: notificationMessage, in: indexPath)
        }
        
        let chatMessage = messagesDataSource.messageForItem(at: indexPath, in: messagesCollectionView) as! ChatMessage
        
        let messageType = chatMessage.message.type
        let transferMessageType = chatMessage.transfer?.transferChatMessageType()
        
        if transferMessageType == .voiceClip {
            return customCellForTransferMessageTypeVoiceClip(chatMessage, in: indexPath)
        }
        
        if transferMessageType == .attachment {
            return customCellForTransferMessageTypeAttachment(chatMessage, in: indexPath)
        }
        
        if messageType == .attachment || messageType == .contact {
            return customCellForMessageTypeAttachmentOrContact(chatMessage, in: indexPath)
        }
        
        if messageType == .normal {
            return customCellForNormalMessage(chatMessage, in: indexPath)
        }
        
        if messageType == .voiceClip {
            return customCellForMessageTypeVoiceClip(chatMessage, in: indexPath)
        }
        
        if messageType == .containsMeta {
            return customCellForMessageTypeContainsMeta(chatMessage, in: indexPath)
        }
        
        if chatMessage.message.isManagementMessage {
            return customCellForManagementMessage(chatMessage, in: indexPath)
        }
        
        let cell = messagesCollectionView.dequeueReusableCell(withReuseIdentifier: ChatViewCallCollectionCell.reuseIdentifier, for: indexPath) as! ChatViewCallCollectionCell
        cell.configure(with: chatMessage, at: indexPath, and: messagesCollectionView)
        return cell
    }
    
    private func customCell(
        for notificationMessage: ChatNotificationMessage,
        in indexPath: IndexPath
    ) -> UICollectionViewCell {
        guard let cell = messagesCollectionView.dequeueReusableCell(
            withReuseIdentifier: ChatUnreadMessagesLabelCollectionCell.reuseIdentifier,
            for: indexPath
        ) as? ChatUnreadMessagesLabelCollectionCell, case .unreadMessage(let count) = notificationMessage.type else {
            fatalError("Could not dequeue `ChatUnreadMessagesLabelCollectionCell`")
        }
        cell.unreadMessageCount = count
        return cell
    }
    
    private func customCellForTransferMessageTypeVoiceClip(
        _ chatMessage: ChatMessage,
        in indexPath: IndexPath
    ) -> UICollectionViewCell {
        let cell = messagesCollectionView.dequeueReusableCell(withReuseIdentifier: ChatVoiceClipCollectionViewCell.reuseIdentifier, for: indexPath) as! ChatVoiceClipCollectionViewCell
        cell.configure(with: chatMessage, at: indexPath, and: messagesCollectionView)
        return cell
    }
    
    private func customCellForTransferMessageTypeAttachment(
        _ chatMessage: ChatMessage,
        in indexPath: IndexPath
    ) -> UICollectionViewCell {
        let cell = messagesCollectionView.dequeueReusableCell(withReuseIdentifier: ChatMediaCollectionViewCell.reuseIdentifier, for: indexPath) as! ChatMediaCollectionViewCell
        cell.configure(with: chatMessage, at: indexPath, and: messagesCollectionView)
        return cell
    }
    
    private func customCellForMessageTypeAttachmentOrContact(
        _ chatMessage: ChatMessage,
        in indexPath: IndexPath
    ) -> UICollectionViewCell {
        if chatMessage.message.nodeList?.size ?? 0 == 1 {
            if let node = chatMessage.message.nodeList?.node(at: 0),
               node.name?.fileExtensionGroup.isVisualMedia ?? false {
                let cell = messagesCollectionView.dequeueReusableCell(withReuseIdentifier: ChatMediaCollectionViewCell.reuseIdentifier, for: indexPath) as! ChatMediaCollectionViewCell
                cell.configure(with: chatMessage, at: indexPath, and: messagesCollectionView)
                return cell
            }
        }
        
        let cell = messagesCollectionView.dequeueReusableCell(withReuseIdentifier: ChatViewAttachmentCell.reuseIdentifier, for: indexPath) as! ChatViewAttachmentCell
        cell.configure(with: chatMessage, at: indexPath, and: messagesCollectionView)
        return cell
    }
    
    private func customCellForNormalMessage(
        _ chatMessage: ChatMessage,
        in indexPath: IndexPath
    ) -> UICollectionViewCell {
        if chatMessage.message.warningDialog.rawValue > MEGAChatMessageWarningDialog.none.rawValue {
            let cell = messagesCollectionView.dequeueReusableCell(withReuseIdentifier: ChatRichPreviewDialogCollectionViewCell.reuseIdentifier, for: indexPath) as! ChatRichPreviewDialogCollectionViewCell
            cell.configure(with: chatMessage, at: indexPath, and: messagesCollectionView)
            return cell
        } else if chatMessage.message.containsMEGALink() {
            if (chatMessage.message.megaLink as? NSURL)?.mnz_type() == .contactLink {
                let cell = messagesCollectionView.dequeueReusableCell(withReuseIdentifier: ContactLinkCollectionViewCell.reuseIdentifier, for: indexPath) as! ContactLinkCollectionViewCell
                cell.configure(with: chatMessage, at: indexPath, and: messagesCollectionView)
                return cell
            }
            let cell = messagesCollectionView.dequeueReusableCell(withReuseIdentifier: ChatRichPreviewMediaCollectionViewCell.reuseIdentifier, for: indexPath) as! ChatRichPreviewMediaCollectionViewCell
            cell.configure(with: chatMessage, at: indexPath, and: messagesCollectionView)
            return cell
        }
        
        let cell = messagesCollectionView.dequeueReusableCell(withReuseIdentifier: ChatTextMessageViewCell.reuseIdentifier, for: indexPath) as! ChatTextMessageViewCell
        cell.configure(with: chatMessage, at: indexPath, and: messagesCollectionView)
        return cell
        
    }
    
    private func customCellForMessageTypeVoiceClip(
        _ chatMessage: ChatMessage,
        in indexPath: IndexPath
    ) -> UICollectionViewCell {
        let cell = messagesCollectionView.dequeueReusableCell(withReuseIdentifier: ChatVoiceClipCollectionViewCell.reuseIdentifier, for: indexPath) as! ChatVoiceClipCollectionViewCell
        cell.configure(with: chatMessage, at: indexPath, and: messagesCollectionView)
        return cell
    }
    
    private func customCellForMessageTypeContainsMeta(
        _ chatMessage: ChatMessage,
        in indexPath: IndexPath
    ) -> UICollectionViewCell {
        if chatMessage.message.containsMeta?.type == .geolocation {
            let cell = messagesCollectionView.dequeueReusableCell(withReuseIdentifier: ChatLocationCollectionViewCell.reuseIdentifier, for: indexPath) as! ChatLocationCollectionViewCell
            cell.configure(with: chatMessage, at: indexPath, and: messagesCollectionView)
            return cell
        } else if chatMessage.message.containsMeta?.type == .richPreview {
            let cell = messagesCollectionView.dequeueReusableCell(withReuseIdentifier: ChatRichPreviewMediaCollectionViewCell.reuseIdentifier, for: indexPath) as! ChatRichPreviewMediaCollectionViewCell
            cell.configure(with: chatMessage, at: indexPath, and: messagesCollectionView)
            return cell
        } else if chatMessage.message.containsMeta?.type == .giphy {
            let cell = messagesCollectionView.dequeueReusableCell(withReuseIdentifier: ChatGiphyCollectionViewCell.reuseIdentifier, for: indexPath) as! ChatGiphyCollectionViewCell
            cell.configure(with: chatMessage, at: indexPath, and: messagesCollectionView)
            return cell
        } else {
            let cell = messagesCollectionView.dequeueReusableCell(withReuseIdentifier: ChatTextMessageViewCell.reuseIdentifier, for: indexPath) as! ChatTextMessageViewCell
            cell.configure(with: chatMessage, at: indexPath, and: messagesCollectionView)
            return cell
        }
    }
    
    private func customCellForManagementMessage(
        _ chatMessage: ChatMessage,
        in indexPath: IndexPath
    ) -> UICollectionViewCell {
        switch chatMessage.message.type {
        case .callEnded, .callStarted:
            let cell = messagesCollectionView.dequeueReusableCell(withReuseIdentifier: ChatViewCallCollectionCell.reuseIdentifier, for: indexPath) as! ChatViewCallCollectionCell
            cell.configure(with: chatMessage, at: indexPath, and: messagesCollectionView)
            return cell
        case .scheduledMeeting:
            let cell = messagesCollectionView.dequeueReusableCell(withReuseIdentifier: ChatManagmentTypeCollectionViewCell.reuseIdentifier, for: indexPath) as! ChatManagmentTypeCollectionViewCell
            cell.configure(with: chatMessage, at: indexPath, and: messagesCollectionView)
            return cell
        default:
            let cell = messagesCollectionView.dequeueReusableCell(withReuseIdentifier: ChatManagmentTypeCollectionViewCell.reuseIdentifier, for: indexPath) as! ChatManagmentTypeCollectionViewCell
            cell.configure(with: chatMessage, at: indexPath, and: messagesCollectionView)
            return cell
        }
    }
    
    // MARK: - Interface methods
    
    @objc func showOptions(forPeerWithHandle handle: UInt64, senderView: UIView?) {
        
    }
    
    @objc func closeChatRoom() {
        chatRoomDelegate.resetChatRoom()
        chatRoomDelegate.removeDelegatesAsync()
    }
    
    func showJumpToBottom() {
        chatBottomInfoScreen.unreadNewMessagesCount = unreadNewMessagesCount
        
        let contentInset = messagesCollectionView.adjustedContentInset.bottom
        
        let bottomConstant = contentInset + chatBottomInfoScreenBottomPadding
        chatBottomInfoScreenBottomConstraint?.constant = bottomConstant * -1
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
    
    func isFromCurrentSender(message: any MessageType) -> Bool {
        return UInt64(message.sender.senderId) == MEGAChatSdk.shared.myUserHandle
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
        
        guard let currentSenderId = messages[safe: indexPath.section]?.sender.senderId,
              let previousSenderId = messages[safe: previousMessageIndexPath.section]?.sender.senderId else {
            return false
        }
        
        return currentSenderId == previousSenderId
    }
    
    func avatarImage(for message: any MessageType) -> UIImage? {
        guard let userHandle = UInt64(message.sender.senderId) else { return nil }
        
        return UIImage.mnz_image(forUserHandle: userHandle, name: message.sender.displayName, size: CGSize(width: 24, height: 24), delegate: RequestDelegate(completion: { _ in
        }))
    }
    
    func initials(for message: any MessageType) -> String {
        guard let userHandle = UInt64(message.sender.senderId) else {
            return ""
        }
        
        if let displayName = MEGAStore.shareInstance().fetchUser(withUserHandle: userHandle)?.displayName {
            return (displayName as NSString).mnz_initialForAvatar()
        }
        
        if let peerFullname = chatRoom.participantName(forUserHandle: userHandle) {
            return (peerFullname as NSString).mnz_initialForAvatar()
        }
        
        return ""
    }
    
    // MARK: - Private methods
    
    private func executeCommand(_ command: ChatContentViewModel.Command) {
        switch command {
        case .configNavigationBar:
            configureNavigationBar()
        case .tapToReturnToCallCleanUp:
            tapToReturnToCallCleanup()
        case .hideStartOrJoinCallButton(let hide):
            hideStartOrJoinCallButton(hide)
        case .showStartOrJoinCallButton:
            showStartOrJoinCallButton()
        case .showTapToReturnToCall(let title):
            showTapToReturnToCall(withTitle: title)
        case .enableAudioVideoButtons(let enable):
            shouldEnableAudioVideoButtons(enable)
        }
    }
    
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
    
    private func configureTapToReturnToCallButton() {
        tapToReturnToCallButton.addTarget(self, action: #selector(didTapToReturnToCallBannerButton), for: .touchUpInside)
        view.addSubview(tapToReturnToCallButton)
        
        tapToReturnToCallButton.translatesAutoresizingMaskIntoConstraints = false
        [
            tapToReturnToCallButton.heightAnchor.constraint(equalToConstant: 44.0),
            tapToReturnToCallButton.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
            tapToReturnToCallButton.widthAnchor.constraint(equalTo: view.widthAnchor)
        ].activate()
        
        tapToReturnToCallCleanup()
    }
    
    private func configureStartOrJoinCallButton() {
        startOrJoinCallButton.addTarget(self, action: #selector(didTapStartOrJoinCallFloatingButton), for: .touchUpInside)
        view.addSubview(startOrJoinCallButton)
        startOrJoinCallButton.isHidden = true
        
        startOrJoinCallButton.translatesAutoresizingMaskIntoConstraints = false
        [
            startOrJoinCallButton.heightAnchor.constraint(equalToConstant: 40.0),
            startOrJoinCallButton.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 20),
            startOrJoinCallButton.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            startOrJoinCallButton.widthAnchor.constraint(greaterThanOrEqualToConstant: 150.0)
        ].activate()
        
        chatContentViewModel.dispatch(.startOrJoinCallCleanUp)
    }
    
    private func configurePreviewerButton() {
        view.addSubview(previewerView)
        
        NSLayoutConstraint.activate([
            previewerView.topAnchor.constraint(equalTo: view.topAnchor, constant: 12),
            previewerView.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            previewerView.widthAnchor.constraint(equalToConstant: 75),
            previewerView.heightAnchor.constraint(equalToConstant: 34)
        ])
        
        previewerView.isHidden = true
    }
    
    private func relayoutChatInputBarIfNeeded() {
        if let inputbar = inputAccessoryView as? ChatInputBar {
            inputbar.relayout()
        }
    }
    
    private func configureGesture() {
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
        messagesCollectionView.register(ContactLinkCollectionViewCell.self,
                                        forCellWithReuseIdentifier: ContactLinkCollectionViewCell.reuseIdentifier)
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
        guard isViewLoaded else {
            return
        }
        
        configureNavigationBar()
        chatRoomDelegate.openChatRoom()
        
        if !chatRoom.isGroup {
            MEGAChatSdk.shared.requestLastGreen(chatRoom.peerHandle(at: 0))
        }
        
        if let layout = messagesCollectionView.collectionViewLayout as? MessagesCollectionViewFlowLayout {
            layout.setMessageOutgoingAvatarSize(.zero)
            layout.setMessageOutgoingMessageTopLabelAlignment(LabelAlignment(textAlignment: .right, textInsets: UIEdgeInsets(top: 0, left: 0, bottom: 0, right: 12)))
        }
    }
    
    @objc func setLastMessageAsSeen() {
        if messages.isNotEmpty {
            let chatMessages = messages.filter { (message) -> Bool in
                guard let message = message as? ChatMessage, message.transfer == nil else {
                    return false
                }
                return true
            }
            
            guard let lastMessage = chatMessages.last as? ChatMessage else {
                return
            }
            
            let lastSeenMessage = MEGAChatSdk.shared.lastChatMessageSeen(forChat: chatRoom.chatId)
            if lastMessage.message.userHandle != MEGAChatSdk.shared.myUserHandle
                && (lastSeenMessage?.messageId != lastMessage.message.messageId) {
                MEGAChatSdk.shared.setMessageSeenForChat(chatRoom.chatId, messageId: lastMessage.message.messageId)
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
        guard chatRoomDelegate.chatMessages.isEmpty,
              let inputView = inputAccessoryView as? ChatInputBar,
              inputView.isTextViewTheFirstResponder() else {
            return
        }
        
        guard let keyboardFrame = notification.userInfo?[UIResponder.keyboardFrameEndUserInfoKey] as? CGRect,
              let inputAccessoryView = inputAccessoryView  else {
            return
        }
        
        additionalBottomInset = keyboardFrame.height + inputAccessoryView.frame.height
        messagesCollectionView.scrollToLastItem()
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
            let alertController = UIAlertController(title: Strings.Localizable.resumeTransfers, message: nil, preferredStyle: .alert)
            
            let cancel = UIAlertAction(title: Strings.Localizable.cancel, style: .cancel)
            
            let action2 = UIAlertAction(title: Strings.Localizable.resume, style: .default) { _ in
                MEGASdk.shared.pauseTransfers(false)
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
            self.scrollToBottom()
            self.hideJumpToBottomIfRequired()
        }
        view.addSubview(chatBottomInfoScreen)
        chatBottomInfoScreen.isHidden = true
        
        NSLayoutConstraint.activate([
            chatBottomInfoScreen.widthAnchor.constraint(equalToConstant: chatBottomInfoScreen.bounds.width),
            chatBottomInfoScreen.heightAnchor.constraint(equalToConstant: chatBottomInfoScreen.bounds.height)
        ])
        
        chatBottomInfoScreenBottomConstraint = chatBottomInfoScreen.bottomAnchor.constraint(equalTo: view.bottomAnchor, constant: -chatBottomInfoScreenBottomPadding)
        chatBottomInfoScreenBottomConstraint?.isActive = true
        
        chatBottomInfoScreen.trailingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.trailingAnchor, constant: -20).isActive = true
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
        }, completion: { _ in
            self.chatBottomInfoScreen.isHidden = true
            self.chatBottomInfoScreen.alpha = 1.0
        })
    }
    
    private func updateChatRoom(_ chatRoom: ChatRoomEntity) {
        chatContentViewModel.dispatch(.updateChatRoom(chatRoom))
    }
    
    var permissionRouter: PermissionAlertRouter {
        .makeRouter(deviceHandler: permissionHandler)
    }
    
    // MARK: - Bar Button actions
    
    @objc
    func startAudioCall() {
        chatContentViewModel.dispatch(
            .startCallBarButtonTapped(isVideoEnabled: false)
        )
    }
    
    @objc
    func startVideoCall() {
        chatContentViewModel.dispatch(
            .startCallBarButtonTapped(isVideoEnabled: true)
        )
    }
    
    @objc func dismissChatRoom() {
        dismiss(animated: true) {
            if MEGAChatSdk.shared.initState() == .anonymous {
                MEGAChatSdk.shared.logout()
                
                if MEGALinkManager.selectedOption == .joinChatLink, let onboardingVC = UIApplication.mnz_visibleViewController() as? OnboardingViewController {
                    
                    if let publicChatLink = self.publicChatLink {
                        MEGALinkManager.linkURL = publicChatLink
                        MEGALinkManager.urlType = .publicChatLink
                    }
                    onboardingVC.presentLoginViewController()
                }
            }
        }
    }
    
    @objc func cancelSelecting() {
        setEditing(false, animated: true)
    }
    
    func scrollToBottom(animated: Bool = true) {
        messagesCollectionView.performBatchUpdates(nil) { [weak self] _ in
            guard let self = self,
                  case let collectionViewContentHeight = self.messagesCollectionView.collectionViewLayout.collectionViewContentSize.height,
                  collectionViewContentHeight >= 1.0 else {
                return
            }
            
            self.messagesCollectionView.scrollRectToVisible(
                CGRect(x: 0.0, y: collectionViewContentHeight - 1.0, width: 1.0, height: 1.0),
                animated: animated
            )
        }
    }
    
    deinit {
        removeObservers()
        closeChatRoom()
    }
}
