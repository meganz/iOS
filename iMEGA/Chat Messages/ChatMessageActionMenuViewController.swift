import UIKit

class ChatMessageActionMenuViewController: ActionSheetViewController {

    var chatMessage: ChatMessage? {
        didSet {
            configureActions()
        }
    }
    
    var sender: Any?
    
    // MARK: - ChatMessageActionMenuViewController initializers
    
    convenience init(chatMessage: ChatMessage?, sender: Any?) {
        self.init(nibName: nil, bundle: nil)
        
        self.chatMessage = chatMessage
        self.sender = sender
        
        configurePresentationStyle(from: sender as Any)
    }
    
    override init(nibName nibNameOrNil: String?, bundle nibBundleOrNil: Bundle?) {
        super.init(nibName: nibNameOrNil, bundle: nibBundleOrNil)
    }
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        configureActions()
        configureHeaderView()
    }
 
    override func loadView() {
        super.loadView()
    }
    
    func configureActions() {
        
    }
    
    func configureHeaderView() {
        let emojiHeader = UIStackView()
        emojiHeader.axis = .horizontal
        emojiHeader.distribution = .equalSpacing
        emojiHeader.alignment = .fill

        let emojis = ["😀", "☹️", "🤣", "👍", "👎"]
        emojis.forEach { (emoji) in
            let emojiView = UIButton(frame: CGRect(x: 0, y: 0, width: 44, height: 44))
            let attributedEmoji = NSAttributedString(string: emoji, attributes: [NSAttributedString.Key.font: UIFont.systemFont(ofSize: 30)])
            emojiView.setAttributedTitle(attributedEmoji, for: .normal)
            emojiView.layer.cornerRadius = 22
            emojiView.backgroundColor = UIColor.mnz_whiteF2F2F2()
            emojiHeader.addArrangedSubview(emojiView)
            emojiView.autoSetDimensions(to: CGSize(width: 44, height: 44))
            emojiView.addTarget(self, action: #selector(emojiPress(_:)), for: .touchUpInside)

        }
        
        let addMoreView = UIButton(frame: CGRect(x: 0, y: 0, width: 44, height: 44))
        addMoreView.setImage(UIImage(named: "addReactionSmall"), for: .normal)
        
        addMoreView.layer.cornerRadius = 22
        addMoreView.backgroundColor = UIColor.mnz_whiteF2F2F2()
        
        emojiHeader.addArrangedSubview(addMoreView)
        addMoreView.autoSetDimensions(to: CGSize(width: 44, height: 44))
        addMoreView.imageView?.contentMode = .scaleAspectFit
        addMoreView.imageEdgeInsets = UIEdgeInsets(top: 6, left: 6, bottom: 6, right: 6)
        addMoreView.addTarget(self, action: #selector(addMorePress(_:)), for: .touchUpInside)

        headerView?.frame = CGRect(x: 0, y: 0, width: 320, height: 60)
        headerView?.addSubview(emojiHeader)
        emojiHeader.autoPinEdgesToSuperviewMargins()
        
    }
    
    @objc func emojiPress(_ sender: UIButton) {
        let emoji = sender.attributedTitle(for: .normal)?.string
        let megaMessage = chatMessage?.message

        MEGASdkManager.sharedMEGAChatSdk()?.addReaction(forChat: chatMessage?.chatRoom.chatId ?? 0, messageId: megaMessage?.messageId ?? 0, reaction: emoji)
        dismiss(animated: true, completion: nil)
    }
    
    @objc func addMorePress(_ sender: UIButton) {
        let vc = ReactionPickerViewController()
        vc.message = chatMessage
        
        if let sourceView = self.sender as? UIView {
            
          presentPanModal(vc, sourceView:sourceView , sourceRect: sourceView.bounds)
        }
        
        
    }
}
