

import UIKit
import MessageKit

class ChatViewController: MessagesViewController {
    @objc var chatRoom: MEGAChatRoom! {
        didSet {
            if isViewLoaded == false {
                return
            }
            
            updateUI()
        }
    }
    
    @objc var publicChatLink: URL?
    @objc var publicChatWithLinkCreated: Bool = false
    
    var messages: [MessageType] = []
    var chatRoomDelegate: ChatRoomDelegate?
    
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
        messagesCollectionView.messagesDataSource = self
        messagesCollectionView.messagesLayoutDelegate = self
        messagesCollectionView.messagesDisplayDelegate = self
        
        populateSampleData()
        
        updateUI()
    }
    
    @objc func updateUnreadLabel() {
        
    }
    
    @objc func showOptions(forPeerWithHandle handle: UInt64, senderView: UIView) {
        
    }
    
    private func updateUI() {
        configureNavigationBar()
        chatRoomDelegate = ChatRoomDelegate(chatRoom: chatRoom, collectionView: messagesCollectionView)
    }
    
    // MARK: - Bar Button actions
    
    @objc func startAudioCall() {
        
    }
    
    @objc func startVideoCall() {
        
    }
    
    @objc func addParticipant() {
        
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
    
    private func populateSampleData() {
        let sender = Sender(senderId: "sender", displayName: "sender")
        let receiver = Sender(senderId: "receiver", displayName: "receiver")
        messages.append(Message(sender: sender, messageId: "1", sentDate: Date(), kind: .text("Hello")))
        messages.append(Message(sender: receiver, messageId: "2", sentDate: Date(), kind: .text("Hi")))
        messages.append(Message(sender: sender, messageId: "3", sentDate: Date(), kind: .text("How are you?")))
        messages.append(Message(sender: receiver, messageId: "4", sentDate: Date(), kind: .text("I am doin good")))
    }
}

extension ChatViewController: MessagesDataSource {
       
    public func currentSender() -> SenderType {
        return Sender(senderId: "receiver", displayName: "receiver")
    }

    public func numberOfSections(in messagesCollectionView: MessagesCollectionView) -> Int {
        return chatRoomDelegate?.messages.count ?? 0
    }

    public func messageForItem(at indexPath: IndexPath, in messagesCollectionView: MessagesCollectionView) -> MessageType {
        return messages[indexPath.section % 4]
    }
}

extension ChatViewController: MessagesDisplayDelegate, MessagesLayoutDelegate {}
