

class ChatViewAttachmentCellViewModel {
    //MARK: - Private properties.
    private let chatMessage: ChatMessage
    
    private var message: MEGAChatMessage {
        return chatMessage.message
    }
    
    //MARK: - Inteface properties.
    
    var title: String {
        switch chatMessage.message.type {
        case .attachment:
            return titleForAttachment()
        case .contact:
            return titleForContact()
        default:
            return ""
        }
    }
    
    var subtitle: String {
        switch message.type {
        case .attachment:
            return subtitleForAttachment()
        case .contact:
            return subtitleForContact()
            
        default:
            return ""
        }
    }
    
    //MARK: - Intializers.
    
    init(chatMessage: ChatMessage) {
        self.chatMessage = chatMessage
    }
    
    //MARK: - Interface methods.
    
    func set(imageView: UIImageView) {
        switch message.type {
        case .attachment:
            return setImageForAttachment(imageView: imageView)
        case .contact:
            return setImageForContact(imageView: imageView)
        default:
            break
        }
    }
    
    //MARK: - Private methods.
    
    private func titleForAttachment() -> String {
        if message.nodeList.size.uintValue == 1 {
            return message.nodeList.node(at: 0)?.name ?? ""
        } else {
            return String(format: NSLocalizedString("files", comment: ""), message.nodeList.size.uintValue)
        }
    }
    
    private func subtitleForAttachment() -> String {
        if message.nodeList.size.uintValue == 1 {
            let size = message.nodeList.node(at: 0)?.size ?? 0
            return Helper.memoryStyleString(fromByteCount: size.int64Value)
        } else {
            let totalSize = (0..<message.nodeList.size.intValue)
                .compactMap({ message.nodeList.node(at: $0)?.size?.int64Value })
                .reduce(0, +)
            return Helper.memoryStyleString(fromByteCount: totalSize)
        }
    }
    
    private func setImageForAttachment(imageView: UIImageView) {
        if message.nodeList.size.uintValue == 1 {
            let node = message.nodeList.node(at: 0)!
            imageView.mnz_setThumbnail(by: node)
        }
    }
    
    private func titleForContact() -> String {
        if message.usersCount == 1 {
            return message.contactName(at: 0) ?? message.userName(at: 0)
        } else {
            return NSLocalizedString("XContactsSelected", comment: "").replacingOccurrences(of: "[X]", with: "\(message.usersCount)", options: .literal, range: nil)
        }
    }
    
    private func subtitleForContact() -> String {
        if message.usersCount == 1 {
            return message.userEmail(at: 0)
        } else {
            let emails = (0..<message.usersCount)
                .map({ (message.usersCount - 1 == $0) ? message.userEmail(at: $0)! : "\(message.userEmail(at: $0)!) " })
                .reduce("", +)
            return emails
        }
    }
    
    private func setImageForContact(imageView: UIImageView) {
        imageView.mnz_setImage(forUserHandle: message.userHandle(at: 0),
                               name: message.userName(at: 0))
    }
}
