import UIKit
import FlexLayout
import PinLayout

protocol ReactionEmojiViewDelegate: class {
    func emojiLongPressed(_ emoji: String, sender: UIView)
    func addMorePressed(sender: UIView)
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
                    guard let userhandles = MEGASdkManager.sharedMEGAChatSdk()?.getReactionUsers(forChat: chatMessage?.chatRoom.chatId ?? 0, messageId: megaMessage?.messageId ?? 0, reaction: emoji) else {
                        return
                    }
                    let isEmojiSelected = emojiSelected(userhandles)
                    let emojiButton = ReactionEmojiButton(count: Int(userhandles.size), emoji: emoji, emojiSelected: isEmojiSelected)
                    if let delegate = delegate {
                        emojiButton.buttonPressed = { [weak self] emoji, emojiButton in
                          if isEmojiSelected {
                            MEGASdkManager.sharedMEGAChatSdk()?.deleteReaction(forChat: self?.chatMessage?.chatRoom.chatId ?? 0, messageId: megaMessage?.messageId ?? 0, reaction: emoji)
                              } else {
                            MEGASdkManager.sharedMEGAChatSdk()?.addReaction(forChat: self?.chatMessage?.chatRoom.chatId ?? 0, messageId: megaMessage?.messageId ?? 0, reaction: emoji)
                              }
                        }
                        emojiButton.buttonLongPress = delegate.emojiLongPressed
                    }
                    
                    emojiButton.flex.margin(2).height(30).minWidth(52)
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

    func emojiSelected(_ userhandles: MEGAHandleList) -> Bool {
        for index in 0..<userhandles.size {
            if userhandles.megaHandle(at: index) == MEGASdkManager.sharedMEGAChatSdk()?.myUserHandle {
                return true
            }
        }
        
        return false
    }
    
    override func sizeThatFits(_ size: CGSize) -> CGSize {
        layout()
        return rootFlexContainer.frame.size
    }
    
    @objc func addMorePress(_ sender: UIButton) {
        delegate?.addMorePressed(sender: sender)

    }
    
    private func layout() {
        rootFlexContainer.pin.width(280)
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
