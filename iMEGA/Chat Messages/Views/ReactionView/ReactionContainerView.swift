import FlexLayout
import Haptica
import MEGADesignToken
import PinLayout
import UIKit

protocol ReactionEmojiViewDelegate: AnyObject {
    func emojiLongPressed(_ emoji: String, sender: UIView)
    func addMorePressed(sender: UIView)
}

enum ReactionErrorType: Int {
    case `default` = 0
    case message = -1
    case user = 1
}

class ReactionContainerView: UIView {
    fileprivate let rootFlexContainer = UIView()
    
    weak var delegate: (any ReactionEmojiViewDelegate)?
    open var addMoreView: UIButton = {
        let addMoreView = UIButton()
        addMoreView.setImage(UIImage(resource: .addReactionSmall), for: .normal)
        addMoreView.imageView?.contentMode = .scaleAspectFit
        addMoreView.layer.borderColor = TokenColors.Border.strong.cgColor
        addMoreView.layer.borderWidth = 1
        addMoreView.layer.cornerRadius = 12
        addMoreView.backgroundColor = UIColor.pageBackgroundColor()

        return addMoreView
    }()

    var chatMessage: ChatMessage? {
        didSet {
            emojis.removeAll()
            rootFlexContainer.subviews.forEach { $0.removeFromSuperview() }
            let megaMessage = chatMessage?.message
            guard let list = MEGAChatSdk.shared.messageReactions(forChat: chatMessage?.chatRoom.chatId ?? 0, messageId: megaMessage?.messageId ?? 0) else {
                return
            }
            for index in 0 ..< list.size {
                if let value = list.string(at: index) {
                    emojis.append(value)
                }
            }
            rootFlexContainer.flex.direction(.rowReverse).wrap(.wrap).paddingHorizontal(10).justifyContent(.start).alignItems(.start).define { (flex) in
                emojis.forEach { (emoji) in
                    let megaMessage = chatMessage?.message
                    guard let userhandles = MEGAChatSdk.shared.reactionUsers(forChat: chatMessage?.chatRoom.chatId ?? 0, messageId: megaMessage?.messageId ?? 0, reaction: emoji) else {
                        return
                    }
                    let isEmojiSelected = emojiSelected(userhandles)
                    let emojiButton = ReactionEmojiButton(count: Int(userhandles.size), emoji: emoji, emojiSelected: isEmojiSelected)
                    emojiButton.addHaptic(.selection, forControlEvents: .touchDown)
                    
                    if let delegate = delegate {
                        emojiButton.buttonPressed = { [weak self] emoji, _ in
                            if isEmojiSelected {
                                MEGAChatSdk.shared.deleteReaction(forChat: self?.chatMessage?.chatRoom.chatId ?? 0, messageId: megaMessage?.messageId ?? 0, reaction: emoji)
                            } else {
                                MEGAChatSdk.shared.addReaction(forChat: self?.chatMessage?.chatRoom.chatId ?? 0, messageId: megaMessage?.messageId ?? 0, reaction: emoji)
                            }
                        }
                        emojiButton.buttonLongPress = delegate.emojiLongPressed
                    }
                    
                    emojiButton.flex.margin(2).height(30).minWidth(52)
                    flex.addItem(emojiButton)
                }
                
                flex.addItem(addMoreView).width(44).margin(2).height(30)
            }
            
            if UInt64(chatMessage?.sender.senderId ?? "") == MEGAChatSdk.shared.myUserHandle {
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
        configureColors()
    }
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
    }
    
    private func configureColors() {
        addMoreView.backgroundColor = TokenColors.Button.secondary
        addMoreView.layer.borderColor = TokenColors.Border.strong.cgColor
    }
    
    func emojiSelected(_ userhandles: MEGAHandleList) -> Bool {
        for index in 0..<userhandles.size where userhandles.megaHandle(at: index) == MEGAChatSdk.shared.myUserHandle {
            return true
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
        rootFlexContainer.pin.top()
        if UInt64(chatMessage?.sender.senderId ?? "") == MEGAChatSdk.shared.myUserHandle {
            rootFlexContainer.pin.width(UIScreen.main.bounds.width - 40)
            rootFlexContainer.pin.right()
        } else {
            rootFlexContainer.pin.width(UIScreen.main.bounds.width - 70)
            rootFlexContainer.pin.left(30)
        }
        rootFlexContainer.flex.layout(mode: .adjustHeight)
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        layout()
    }
}
