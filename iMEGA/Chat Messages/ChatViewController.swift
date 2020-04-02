

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
        
        messagesCollectionView.register(ChatMessageIntroductionHeaderView.nib,
                                        forSupplementaryViewOfKind: UICollectionView.elementKindSectionHeader,
                                        withReuseIdentifier: ChatMessageIntroductionHeaderView.reuseIdentifier)
        
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
