
import UIKit
import FlexLayout
import PinLayout

class ReactionContainerView: UIView {
    fileprivate let rootFlexContainer = UIView()
    var chatMessage: ChatMessage? {
        didSet {
            emojis.removeAll()
            rootFlexContainer.subviews.forEach { $0.removeFromSuperview() }
            let megaMessage = chatMessage?.message
            let list = MEGASdkManager.sharedMEGAChatSdk()?.getMessageReactions(forChat: chatMessage?.chatRoom.chatId ?? 0, messageId: megaMessage?.messageId ?? 0)
            for index in 0 ..< list!.size {
                emojis.append((list?.string(at: index))!)
            }
            rootFlexContainer.flex.direction(.rowReverse).wrap(.wrap).padding(12).justifyContent(.start).alignItems(.start).define { (flex) in
                emojis.forEach { (emoji) in
                    let emojiButton = UILabel()
                    let megaMessage = chatMessage?.message
                    
                    let count = MEGASdkManager.sharedMEGAChatSdk()?.getMessageReactionCount(forChat: chatMessage?.chatRoom.chatId ?? 0, messageId: megaMessage?.messageId ?? 0, reaction: emoji) ?? 0
                    
                    emojiButton.text = "\(emoji) \(count)"
                    emojiButton.layer.borderWidth = 1
                    emojiButton.layer.borderColor = UIColor.green.cgColor
                    emojiButton.sizeToFit()
                    emojiButton.flex.marginHorizontal(4)
                    flex.addItem(emojiButton)
                }
            }
            
            if UInt64(chatMessage?.sender.senderId ?? "") == MEGASdkManager.sharedMEGAChatSdk()?.myUserHandle {
                rootFlexContainer.flex.direction(.rowReverse)
            } else {
                rootFlexContainer.flex.direction(.row)
            }
            setNeedsLayout()
        }
    }
    private var emojis = [String]()

    init() {
        super.init(frame: .zero)
        backgroundColor = .white
        
     
        
        addSubview(rootFlexContainer)
    }
    
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
    }

    override func sizeThatFits(_ size: CGSize) -> CGSize {
        layout()
        return rootFlexContainer.frame.size
    }
    
    private func layout() {
        rootFlexContainer.pin.width(200)
        rootFlexContainer.pin.top().margin(pin.safeArea)
        rootFlexContainer.flex.layout(mode: .adjustHeight)
        rootFlexContainer.pin.right()
        if UInt64(chatMessage?.sender.senderId ?? "") == MEGASdkManager.sharedMEGAChatSdk()?.myUserHandle {
            rootFlexContainer.pin.right()
        } else {
            rootFlexContainer.pin.left()
        }
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        layout()
    }
}
