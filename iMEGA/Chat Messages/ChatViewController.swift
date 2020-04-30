import UIKit
import MessageKit

class ChatViewController: MessagesViewController {

    // MARK: - Properties

    @objc var chatRoom: MEGAChatRoom! {
        didSet {
            update()
        }
    }

    @objc var publicChatLink: URL?
    @objc var publicChatWithLinkCreated: Bool = false
    var chatInputBar: ChatInputBar!
    var editMessage: ChatMessage?
    var addToChatViewController: AddToChatViewController!
    
    private(set) lazy var refreshControl: UIRefreshControl = {
         let control = UIRefreshControl()
         control.addTarget(self, action: #selector(loadMoreMessages), for: .valueChanged)
         return control
     }()
    
    var messages: [ChatMessage] {
        return chatRoomDelegate.messages
    }

    var myUser: MEGAUser {
        return MEGASdkManager.sharedMEGASdk()!.myUser!
    }

    lazy var chatRoomDelegate: ChatRoomDelegate = {
        return ChatRoomDelegate(chatRoom: chatRoom,
                                chatViewController: self)
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
    

    // MARK: - Overriden methods

    override func viewDidLoad() {
        messagesCollectionView = MessagesCollectionView(frame: .zero,
                                                        collectionViewLayout: ChatViewMessagesFlowLayout())
        registerCustomCells()

        super.viewDidLoad()
        
        configureMessageCollectionView()
        update()
        
        messagesCollectionView.allowsMultipleSelection = true
        configureMenus()
        
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        if (presentingViewController != nil) && parent != nil {
            navigationItem.leftBarButtonItem = UIBarButtonItem(title: AMLocalizedString("close"), style: .plain, target: self, action: #selector(dismissChatRoom))
        }
        
        if publicChatWithLinkCreated {
            let customModalAlertVC = CustomModalAlertViewController()
            customModalAlertVC.modalPresentationStyle = .overCurrentContext
            customModalAlertVC.image = UIImage(named: "chatLinkCreation")
            customModalAlertVC.viewTitle = chatRoom.title
            customModalAlertVC.detail = AMLocalizedString("People can join your group by using this link.", "Text explaining users how the chat links work.")
            customModalAlertVC.firstButtonTitle = AMLocalizedString("share", "Button title which, if tapped, will trigger the action of sharing with the contact or contacts selected")
            customModalAlertVC.link = publicChatLink?.absoluteString;
            customModalAlertVC.secondButtonTitle = AMLocalizedString("delete", nil)
            customModalAlertVC.dismissButtonTitle = AMLocalizedString("dismiss", "Label for any 'Dismiss' button, link, text, title, etc. - (String as short as possible).")
            customModalAlertVC.firstCompletion = { [weak customModalAlertVC] in
                customModalAlertVC?.dismiss(animated: true, completion: {
                    let activityVC = UIActivityViewController(activityItems: [self.publicChatLink?.absoluteString], applicationActivities: nil)
                    self.publicChatWithLinkCreated = false
                    if UIDevice.current.iPadDevice {
                        activityVC.popoverPresentationController?.sourceView = self.view
                        activityVC.popoverPresentationController?.sourceRect = self.view.frame
                    }
                    self.present(activityVC, animated: true, completion: nil)
                    
                })
                
            }
            customModalAlertVC.secondCompletion = { [weak customModalAlertVC] in
                customModalAlertVC?.dismiss(animated: true, completion: {
                    MEGASdkManager.sharedMEGAChatSdk()?.removeChatLink(self.chatRoom.chatId, delegate: MEGAChatGenericRequestDelegate(completion: { (request, error) in
                        if error.type == .MEGAChatErrorTypeOk {
                            SVProgressHUD.showSuccess(withStatus: AMLocalizedString("linkRemoved", "Message shown when the link to a file or folder has been removed"))
                        }
                    }))
                    
                })
            }
            
            customModalAlertVC.dismissCompletion = { [weak customModalAlertVC] in
                self.publicChatWithLinkCreated = false
                customModalAlertVC?.dismiss(animated: true, completion: nil)
            }
            
            present(customModalAlertVC, animated: true, completion: nil)
        }
        
        setLastMessageAsSeen()
    }
    
    override func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        
        // Very important to check this when overriding `cellForItemAt`
               // Super method will handle returning the typing indicator cell
               guard !isSectionReservedForTypingIndicator(indexPath.section) else {
                   return super.collectionView(collectionView, cellForItemAt: indexPath)
               }

        return super.collectionView(collectionView, cellForItemAt: indexPath)
    }
    
    override func collectionView(_ collectionView: UICollectionView, canPerformAction action: Selector, forItemAt indexPath: IndexPath, withSender sender: Any?) -> Bool {

        guard let messagesDataSource = messagesCollectionView.messagesDataSource else {
            fatalError("Ouch. nil data source for messages")
        }
        
        let chatMessage = messagesDataSource.messageForItem(at: indexPath, in: messagesCollectionView) as! ChatMessage
        let message = chatMessage.message
        if MEGASdkManager.sharedMEGAChatSdk()?.initState() == .anonymous
        && action != NSSelectorFromString("copy:") {
            return false
        }
        
        switch chatMessage.message.type {
        case .invalid, .revokeAttachment:
            return false
        case .normal:
            //All messages
            if action == NSSelectorFromString("copy:")
            || action == NSSelectorFromString("forward:") {
                return true
            }
            
            //Your messages
            if isFromCurrentSender(message: chatMessage) {
                if action == NSSelectorFromString("delete:") {
                    if message.isDeletable {
                        if editMessage?.message.messageId != message.messageId {
                            return true
                        }
                    }
                }
                
                if action == NSSelectorFromString("edit:") {
                    return message.isEditable
                }
            }
        default:
            return false

        }
        return false
    }
    
    override func collectionView(_ collectionView: UICollectionView, performAction action: Selector, forItemAt indexPath: IndexPath, withSender sender: Any?) {
        
        guard let messagesDataSource = messagesCollectionView.messagesDataSource else {
            fatalError("Ouch. nil data source for messages")
        }
        
        let chatMessage = messagesDataSource.messageForItem(at: indexPath, in: messagesCollectionView) as! ChatMessage
        
        if action == NSSelectorFromString("copy:") {
            
            return
        }
        
        if action == NSSelectorFromString("edit:") {
            editMessage(chatMessage)
            return
        }
        
        if action == NSSelectorFromString("forward:") {
            forwardMessage(chatMessage)
            return
        }
        
        if action == NSSelectorFromString("import:") {

            return
        }
        
        if action == NSSelectorFromString("download:") {

            return
        }
        
        if action == NSSelectorFromString("addContact:") {

            return
        }
        
        if action == NSSelectorFromString("removeRichPreview:") {

            return
        }
        
        if action == NSSelectorFromString("delete:") {
            deleteMessage(chatMessage)
            return
        } else {
            super.collectionView(collectionView, performAction: action, forItemAt: indexPath, withSender: sender)
        }
    }
    
    override func collectionView(_ collectionView: UICollectionView, shouldShowMenuForItemAt indexPath: IndexPath) -> Bool {
        guard let messagesDataSource = messagesCollectionView.messagesDataSource else { return false }
        
        if isSectionReservedForTypingIndicator(indexPath.section) {
            return false
        }
        
        let message = messagesDataSource.messageForItem(at: indexPath, in: messagesCollectionView)

        switch message.kind {
        case .custom:
            let megaMessage = (message as! ChatMessage).message
            if megaMessage.isManagementMessage {
                return false
            }
            selectedIndexPathForMenu = indexPath
            return true
        default:
            selectedIndexPathForMenu = indexPath
            return true
        }
    }

    func customCell(for message: MessageType, at indexPath: IndexPath, in messagesCollectionView: MessagesCollectionView) -> UICollectionViewCell {

        guard let messagesDataSource = messagesCollectionView.messagesDataSource else {
              fatalError("Ouch. nil data source for messages")
          }

        let chatMessage = messagesDataSource.messageForItem(at: indexPath, in: messagesCollectionView) as! ChatMessage

        if chatMessage.message.type == .attachment
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
        } else if chatMessage.message.type == .normal && chatMessage.message.containsMEGALink() {
            let cell = messagesCollectionView.dequeueReusableCell(withReuseIdentifier: ChatRichPreviewMediaCollectionViewCell.reuseIdentifier, for: indexPath) as! ChatRichPreviewMediaCollectionViewCell
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
            } else {
                let cell = messagesCollectionView.dequeueReusableCell(withReuseIdentifier: ChatRichPreviewMediaCollectionViewCell.reuseIdentifier, for: indexPath) as! ChatRichPreviewMediaCollectionViewCell
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

    }

    @objc func showOptions(forPeerWithHandle handle: UInt64, senderView: UIView) {

    }

    // MARK: - Internal methods used by the extension of this class

    func isFromCurrentSender(message: MessageType) -> Bool {
        return UInt64(message.sender.senderId) == myUser.handle
    }

    func isDateLabelVisible(for indexPath: IndexPath) -> Bool {
        if isPreviousMessageSentSameDay(at: indexPath) {
            return false
        }

        return true
    }

    func isTimeLabelVisible(at indexPath: IndexPath) -> Bool {
        guard let previousIndexPath = indexPath.previousSectionIndexPath else { return true }

        if isPreviousMessageSameSender(at: indexPath)
            && isTimeLabelVisible(at: previousIndexPath)
            && isPreviousMessageSentSameTime(at: indexPath) {
            return false
        }

        return true
    }

    func isPreviousMessageSentSameDay(at indexPath: IndexPath) -> Bool {
        guard let previousIndexPath = indexPath.previousSectionIndexPath else { return true }

        let previousMessageDate = messages[previousIndexPath.section].sentDate
        return messages[indexPath.section].sentDate.isSameDay(date: previousMessageDate)
    }

    /// This method ignores the milliseconds.
    func isPreviousMessageSentSameTime(at indexPath: IndexPath) -> Bool {
        guard let previousIndexPath = indexPath.previousSectionIndexPath else { return true }

        let previousMessageDate = messages[previousIndexPath.section].sentDate
        return messages[indexPath.section].sentDate.isSameMinute(date: previousMessageDate)
    }

    func isPreviousMessageSameSender(at indexPath: IndexPath) -> Bool {
        guard let previousIndexPath = indexPath.previousSectionIndexPath else { return false }
        return messages[indexPath.section].sender.senderId == messages[previousIndexPath.section].sender.senderId
    }
    
    func avatarImage(for message: MessageType) -> UIImage? {
        guard let peerEmail = chatRoom.peerEmail(byHandle: UInt64(message.sender.senderId)!),
            let user = MEGASdkManager.sharedMEGASdk()?.contact(forEmail: peerEmail) else {
                return nil
        }
        return user.avatarImage(withDelegate: nil)
    }

    func initials(for message: MessageType) -> String {

        if let user = MEGAStore.shareInstance()?.fetchUser(withUserHandle: UInt64(message.sender.senderId)!) {
            return (user.displayName as NSString).mnz_initialForAvatar()
        }

        if let peerFullname = chatRoom.peerFullname(byHandle:UInt64(message.sender.senderId)!) {
            return (peerFullname as NSString).mnz_initialForAvatar()
        }

        return ""
    }

    // MARK: - Private methods
    
    private func configureMessageCollectionView() {
        messagesCollectionView.register(ChatViewIntroductionHeaderView.nib,
                                        forSupplementaryViewOfKind: UICollectionView.elementKindSectionHeader,
                                        withReuseIdentifier: ChatViewIntroductionHeaderView.reuseIdentifier)

        messagesCollectionView.messagesDataSource = self
        messagesCollectionView.messagesLayoutDelegate = self
        messagesCollectionView.messagesDisplayDelegate = self
        
        messagesCollectionView.refreshControl = refreshControl
    }
    
    private func configureMenus() {
        let forwardMenuItem = UIMenuItem(title:AMLocalizedString("forward","Item of a menu to forward a message chat to another chatroom"), action: #selector(MessageCollectionViewCell.forward(_:)))
        
        let importMenuItem = UIMenuItem(title:AMLocalizedString("import","Caption of a button to edit the files that are selected"), action: #selector(MessageCollectionViewCell.importMessage(_:)))
        
        let editMenuItem = UIMenuItem(title:AMLocalizedString("edit","Caption of a button to edit the files that are selected"), action: #selector(MessageCollectionViewCell.edit(_:)))

        UIMenuController.shared.menuItems = [forwardMenuItem, importMenuItem, editMenuItem]
    }

    private func registerCustomCells() {
        messagesCollectionView.register(ChatViewCallCollectionCell.nib,
                                         forCellWithReuseIdentifier: ChatViewCallCollectionCell.reuseIdentifier)
        messagesCollectionView.register(ChatViewAttachmentCell.self,
                                         forCellWithReuseIdentifier: ChatViewAttachmentCell.reuseIdentifier)
        messagesCollectionView.register(ChatMediaCollectionViewCell.self,
                                         forCellWithReuseIdentifier: ChatMediaCollectionViewCell.reuseIdentifier)
        messagesCollectionView.register(ChatRichPreviewMediaCollectionViewCell.self,
                                               forCellWithReuseIdentifier: ChatRichPreviewMediaCollectionViewCell.reuseIdentifier)
        messagesCollectionView.register(ChatVoiceClipCollectionViewCell.self,
                                                 forCellWithReuseIdentifier: ChatVoiceClipCollectionViewCell.reuseIdentifier)
        messagesCollectionView.register(ChatLocationCollectionViewCell.self,
                                        forCellWithReuseIdentifier: ChatLocationCollectionViewCell.reuseIdentifier)
        messagesCollectionView.register(ChatManagmentTypeCollectionViewCell.self,
                                        forCellWithReuseIdentifier: ChatManagmentTypeCollectionViewCell.reuseIdentifier)
    }

    private func update() {
        guard isViewLoaded, chatRoom != nil else {
            return
        }

        configureNavigationBar()
        chatRoomDelegate.openChatRoom()

        if let layout = messagesCollectionView.collectionViewLayout as? MessagesCollectionViewFlowLayout {
            layout.setMessageOutgoingAvatarSize(.zero)
            layout.setMessageOutgoingMessageTopLabelAlignment(LabelAlignment(textAlignment: .right, textInsets:  UIEdgeInsets(top: 0, left: 0, bottom: 0, right: 12)))

        }
    }
    
    private func setLastMessageAsSeen() {
        if messages.count > 0 {
            let lastMessage = messages.last
            if lastMessage?.message.userHandle != MEGASdkManager.sharedMEGAChatSdk()?.myUserHandle
                && ((MEGASdkManager.sharedMEGAChatSdk()?.lastChatMessageSeen(forChat: chatRoom.chatId))?.messageId != lastMessage!.message.messageId) {
                MEGASdkManager.sharedMEGAChatSdk()?.setMessageSeenForChat(chatRoom.chatId, messageId: lastMessage!.message.messageId)
            }
        }
    }
    
    @objc func loadMoreMessages() {
        
        chatRoomDelegate.loadMoreMessages()
    }

    // MARK: - Bar Button actions

    @objc func startAudioCall() {
        DevicePermissionsHelper.audioPermissionModal(true, forIncomingCall: false) { (granted) in
            if granted {
                self.openCallViewWithVideo(videoCall: false, active: (MEGASdkManager.sharedMEGAChatSdk()?.hasCall(inChatRoom:self.chatRoom.chatId))!)
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
                        self.openCallViewWithVideo(videoCall: true, active: (MEGASdkManager.sharedMEGAChatSdk()?.hasCall(inChatRoom:self.chatRoom.chatId))!)
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
            if MEGASdkManager.sharedMEGAChatSdk()?.initState() == .anonymous {
                MEGASdkManager.sharedMEGAChatSdk()?.logout(with: MEGAChatGenericRequestDelegate(completion: { (request, error) in
                    MEGASdkManager.destroySharedMEGAChatSdk()
                }))
                
                if MEGALinkManager.selectedOption == .joinChatLink {
                    let onboardingVC = UIApplication.mnz_visibleViewController() as! OnboardingViewController
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
            users?.forEach({ (user) in
                MEGASdkManager.sharedMEGAChatSdk()?.invite(toChat: self.chatRoom.chatId, user: (user as! MEGAUser).handle, privilege: MEGAChatRoomPrivilege.standard.rawValue)
            })
        }
        present(navigationController, animated: true, completion: nil)
    }

    func openCallViewWithVideo(videoCall: Bool, active: Bool) {
        if UIDevice.current.orientation != .portrait {
            UIDevice.current.setValue(NSNumber(integerLiteral: UIInterfaceOrientation.portrait.rawValue), forKey: "orientation")
        }
        
        if chatRoom.isGroup {
            let groupCallVC = UIStoryboard(name: "Chat", bundle: nil).instantiateViewController(withIdentifier: "GroupCallViewControllerID") as! GroupCallViewController
            groupCallVC.callType = active ? .active : (MEGASdkManager.sharedMEGAChatSdk()?.chatCall(forCallId: chatRoom.chatId) != nil ? .active : .outgoing)
            groupCallVC.videoCall = videoCall
            groupCallVC.chatRoom = chatRoom
            groupCallVC.modalTransitionStyle = .crossDissolve
            groupCallVC.megaCallManager = (UIApplication.shared.delegate as! AppDelegate).megaCallManager
            self.present(groupCallVC, animated: true, completion: nil)
        } else {
            let callVC = UIStoryboard(name: "Chat", bundle: nil).instantiateViewController(withIdentifier: "CallViewControllerID") as! CallViewController
            callVC.chatRoom = chatRoom
            callVC.videoCall = videoCall
            callVC.callType = active ? .active : .outgoing
            callVC.modalTransitionStyle = .crossDissolve
            callVC.megaCallManager = (UIApplication.shared.delegate as! AppDelegate).megaCallManager
            self.present(callVC, animated: true, completion: nil)

        }
        
    }
    
    deinit {
        chatRoomDelegate.closeChatRoom()
    }
}
