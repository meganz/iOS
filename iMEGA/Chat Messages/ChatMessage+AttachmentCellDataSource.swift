
extension ChatMessage: AttachmentCellDataSource {
    var title: String {
        switch message.type {
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
}

/// Attachment Extension for - Attachment type object
extension ChatMessage {
    private func titleForAttachment() -> String {
        if message.nodeList.size.uintValue == 1 {
            let node = message.nodeList.node(at: 0)!
            return node.name
        } else {
            return String(format: NSLocalizedString("files", comment: ""), message.nodeList.size.uintValue)
        }
    }
    
    private func subtitleForAttachment() -> String {
        if message.nodeList.size.uintValue == 1 {
            let node = message.nodeList.node(at: 0)!
            return Helper.memoryStyleString(fromByteCount: node.size.int64Value)
        } else {
            let totalSize = (0..<message.nodeList.size.intValue)
                .map({ message.nodeList.node(at: $0)!.size.int64Value })
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
}

/// Attachment Extension for - contact type object
extension ChatMessage {
    
    private func titleForContact() -> String {
        if message.usersCount == 1 {
            return message.userName(at: 0)
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
