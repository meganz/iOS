import UIKit
import FlexLayout
import PinLayout

protocol ReactionEmojiViewDelegate: class {
    func emojiTapped(_ emoji: String, sender: UIView)
    func emojiLongPressed(_ emoji: String, sender: UIView)
}

class ReactionContainerView: UIView {
    fileprivate let rootFlexContainer = UIView()
    
    weak var delegate: ReactionEmojiViewDelegate?
    open var addMoreView: UIButton = {
        let addMoreView = UIButton()
        addMoreView.setImage(UIImage(named: "addReactionSmall"), for: .normal)
        addMoreView.imageView?.contentMode = .scaleAspectFit
        addMoreView.layer.borderColor = UIColor(red: 3/255, green: 3/255, blue: 3/255, alpha: 0.1).cgColor
        addMoreView.layer.borderWidth = 1
        addMoreView.layer.cornerRadius = 12
        addMoreView.backgroundColor = UIColor(hexString: "f9f9f9")

        return addMoreView
    }()
    
    var chatMessage: ChatMessage? {
        didSet {
            emojis.removeAll()
            rootFlexContainer.subviews.forEach { $0.removeFromSuperview() }
            let megaMessage = chatMessage?.message
            let list = MEGASdkManager.sharedMEGAChatSdk()?.getMessageReactions(forChat: chatMessage?.chatRoom.chatId ?? 0, messageId: megaMessage?.messageId ?? 0)
            for index in 0 ..< list!.size {
                emojis.append((list?.string(at: index))!)
            }
            rootFlexContainer.flex.direction(.rowReverse).wrap(.wrap).paddingHorizontal(10).justifyContent(.start).alignItems(.start).define { (flex) in
                emojis.forEach { (emoji) in
                    let megaMessage = chatMessage?.message
                    
                    let count = MEGASdkManager.sharedMEGAChatSdk()?.getMessageReactionCount(forChat: chatMessage?.chatRoom.chatId ?? 0, messageId: megaMessage?.messageId ?? 0, reaction: emoji) ?? 0
                    let emojiButton = ReactionEmojiButton(count: count, emoji: emoji)
                    if let delegate = delegate {
                        emojiButton.buttonPressed = delegate.emojiTapped
                        emojiButton.buttonLongPress = delegate.emojiLongPressed
                    }
                    
                    emojiButton.flex.margin(2).height(30)
                    flex.addItem(emojiButton)
                }
                
                flex.addItem(addMoreView).width(44).margin(2).height(30)
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
        addMoreView.addTarget(self, action: #selector(addMorePress(_:)), for: .touchUpInside)
        addSubview(rootFlexContainer)
    }
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
    }

    override func sizeThatFits(_ size: CGSize) -> CGSize {
        layout()
        return rootFlexContainer.frame.size
    }
    
    @objc func addMorePress(_ sender: UIButton) {
        print("123")
    }
    
    private func layout() {
        rootFlexContainer.pin.width(300)
        rootFlexContainer.pin.top()
        rootFlexContainer.flex.layout(mode: .adjustHeight)
        if UInt64(chatMessage?.sender.senderId ?? "") == MEGASdkManager.sharedMEGAChatSdk()?.myUserHandle {
            rootFlexContainer.pin.right()
        } else {
            rootFlexContainer.pin.left(30)
        }
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        layout()
    }
}
