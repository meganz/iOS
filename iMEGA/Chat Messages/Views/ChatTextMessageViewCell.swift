import MessageKit

class ChatTextMessageViewCell: TextMessageCell {
    
}

class ChatTextMessageSizeCalculator: TextMessageSizeCalculator {
    override func messageContainerSize(for message: MessageType) -> CGSize {
        let size = super.messageContainerSize(for: message)
        return CGSize(width: size.width, height: max(size.height, 40))
    }
}
