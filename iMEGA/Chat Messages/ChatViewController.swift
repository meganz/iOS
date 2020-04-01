

import UIKit
import MessageKit

class ChatViewController: MessagesViewController {
    @objc var chatRoom: MEGAChatRoom! {
        didSet {
            update()
        }
    }
    
    @objc var publicChatLink: URL?
    @objc var publicChatWithLinkCreated: Bool = false
    
    var messages: [ChatMessage] {
        return chatRoomDelegate.messages
    }
    
    var myUser: MEGAUser {
        return MEGASdkManager.sharedMEGASdk()!.myUser!
    }
    
    lazy var chatRoomDelegate: ChatRoomDelegate = {
        return ChatRoomDelegate(chatRoom: chatRoom, collectionView: messagesCollectionView)
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
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        print(ChatMessageHeaderView.reuseIdentifier)
        messagesCollectionView.register(ChatMessageHeaderView.nib,
                                        forSupplementaryViewOfKind: UICollectionView.elementKindSectionHeader,
                                        withReuseIdentifier: ChatMessageHeaderView.reuseIdentifier)
        
        messagesCollectionView.messagesDataSource = self
        messagesCollectionView.messagesLayoutDelegate = self
        messagesCollectionView.messagesDisplayDelegate = self
        
        update()
    }
    
    @objc func updateUnreadLabel() {
        
    }
    
    @objc func showOptions(forPeerWithHandle handle: UInt64, senderView: UIView) {
        
    }
    
    func isFromCurrentSender(message: MessageType) -> Bool {
        guard let chatMessage = message as? ChatMessage else {
            return false
        }
        
        return chatMessage.senderHandle == myUser.handle
    }
    
    func isTimeLabelVisible(at indexPath: IndexPath) -> Bool {
        guard let previousIndexPath = indexPath.previousSectionIndexPath else { return true }
        
        if isPreviousMessageSameSender(at: indexPath)
            && isTimeLabelVisible(at: previousIndexPath)
            && isPreviousMessageHasSameTime(at: indexPath) {
            return false
        }
        
        return true
    }
    
    /// This method ignores the milliseconds.
    func isPreviousMessageHasSameTime(at indexPath: IndexPath) -> Bool {
        guard let previousIndexPath = indexPath.previousSectionIndexPath else { return false }
        
        return Calendar.current.compare(messages[indexPath.section].sentDate,
                                        to: messages[previousIndexPath.section].sentDate,
                                        toGranularity: .minute) == .orderedSame
    }
    
    func isPreviousMessageSameSender(at indexPath: IndexPath) -> Bool {
        guard let previousIndexPath = indexPath.previousSectionIndexPath else { return false }
        return messages[indexPath.section].senderHandle == messages[previousIndexPath.section].senderHandle
    }
    
    func avatarImage(for message: MessageType) -> UIImage? {
        guard let chatMessage = message as? ChatMessage else { return nil }
        return chatMessage.avatarImage
    }
    
    func initials(for message: MessageType) -> String {
        guard let chatMessage = message as? ChatMessage else { return "" }
        
        if let user = MEGAStore.shareInstance()?.fetchUser(withUserHandle: chatMessage.senderHandle) {
            return (user.displayName as NSString).mnz_initialForAvatar()
        }
        
        if let peerFullname = chatRoom.peerFullname(byHandle: chatMessage.senderHandle) {
            return (peerFullname as NSString).mnz_initialForAvatar()
        }
        
        return ""
    }
    
    // MARK: - Private methods
    
    private func update() {
        guard isViewLoaded, chatRoom != nil else {
            return
        }
        
        configureNavigationBar()
        configureInputBar()
        chatRoomDelegate.openChatRoom()
        
        if let layout = messagesCollectionView.collectionViewLayout as? MessagesCollectionViewFlowLayout {
            layout.textMessageSizeCalculator.outgoingAvatarSize = .zero
        }
    }
    
    // MARK: - Bar Button actions
    
    @objc func startAudioCall() {
        
    }
    
    @objc func startVideoCall() {
        
    }
    
    @objc func addParticipant() {
        
    }
    
    deinit {
        chatRoomDelegate.closeChatRoom()
    }
}

// TODO: Remove the temporary extension
extension ChatViewController {
    private struct Sender: SenderType {
        public let senderId: String
        public let displayName: String
    }
    
    private struct Message: MessageType {
        var sender: SenderType
        var messageId: String
        var sentDate: Date
        var kind: MessageKind
    }
}

extension ChatViewController: MessagesDataSource {
    
    public func currentSender() -> SenderType {
        return myUser
    }
    
    public func numberOfSections(in messagesCollectionView: MessagesCollectionView) -> Int {
        return messages.count
    }
    
    public func messageForItem(at indexPath: IndexPath,
                               in messagesCollectionView: MessagesCollectionView) -> MessageType {
        return messages[indexPath.section]
    }
    
    func messageTopLabelAttributedText(for message: MessageType, at indexPath: IndexPath) -> NSAttributedString? {
        if isTimeLabelVisible(at: indexPath) {
            return NSAttributedString(
                string: message.sentDate.string(withDateFormat: "hh:mm") ,
                attributes: [NSAttributedString.Key.font: UIFont.systemFont(ofSize: 13.0, weight: .medium),
                             NSAttributedString.Key.foregroundColor: UIColor(fromHexString: "#848484") ?? .black])
        }
        return nil
    }
    
    func messageHeaderView(for indexPath: IndexPath, in messagesCollectionView: MessagesCollectionView) -> MessageReusableView {
        let chatMessageHeaderView = messagesCollectionView.dequeueReusableSupplementaryView(ofKind: UICollectionView.elementKindSectionHeader, withReuseIdentifier: ChatMessageHeaderView.reuseIdentifier, for: indexPath) as! ChatMessageHeaderView
        chatMessageHeaderView.chatRoom = chatRoom
        return chatMessageHeaderView
    }
}

extension ChatViewController: MessagesDisplayDelegate {
    func backgroundColor(for message: MessageType,
                         at indexPath: IndexPath,
                         in messagesCollectionView: MessagesCollectionView) -> UIColor {
        return isFromCurrentSender(message: message) ? UIColor(fromHexString: "#009476") : UIColor(fromHexString: "#EEEEEE")
    }
    
    func textColor(for message: MessageType, at indexPath: IndexPath, in messagesCollectionView: MessagesCollectionView) -> UIColor {
        return isFromCurrentSender(message: message) ? .white : .black
    }
    
    func messageStyle(for message: MessageType, at indexPath: IndexPath, in messagesCollectionView: MessagesCollectionView) -> MessageStyle {
        return .custom { containerView in
            containerView.layer.cornerRadius = 13.0
        }
    }
    
    func configureAvatarView(_ avatarView: AvatarView,
                             for message: MessageType,
                             at indexPath: IndexPath,
                             in messagesCollectionView: MessagesCollectionView) {
        avatarView.isHidden = isFromCurrentSender(message: message)
        
        let chatInitials = initials(for: message)
        let avatar = Avatar(image: avatarImage(for: message), initials: chatInitials)
        avatarView.set(avatar: avatar)
    }
}

extension ChatViewController: MessagesLayoutDelegate {
    func messageTopLabelHeight(for message: MessageType, at indexPath: IndexPath, in messagesCollectionView: MessagesCollectionView) -> CGFloat {
        return isTimeLabelVisible(at: indexPath) ? 28.0 : 0.0
    }
    
    func headerViewSize(for section: Int, in messagesCollectionView: MessagesCollectionView) -> CGSize {
        if chatRoomDelegate.isFullChatHistoryLoaded && section == 0 {
            let chatMessageHeaderView = ChatMessageHeaderView.instanceFromNib
            chatMessageHeaderView.chatRoom = chatRoom
            return chatMessageHeaderView.sizeThatFits(
                CGSize(width: messagesCollectionView.bounds.width,
                       height: CGFloat.greatestFiniteMagnitude)
            )
        }
        
        return .zero
    }
}
