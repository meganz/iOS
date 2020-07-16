import UIKit

class ChatMessageActionMenuViewController: ActionSheetViewController {

    var chatMessage: ChatMessage? {
        didSet {
            configureActions()
        }
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
        }
        
        let addMoreView = UIButton(frame: CGRect(x: 0, y: 0, width: 44, height: 44))
        addMoreView.setImage(UIImage(named: "addReactionSmall"), for: .normal)
        
        addMoreView.layer.cornerRadius = 22
        addMoreView.backgroundColor = UIColor.mnz_whiteF2F2F2()
        
        emojiHeader.addArrangedSubview(addMoreView)
        addMoreView.autoSetDimensions(to: CGSize(width: 44, height: 44))
        addMoreView.imageView?.contentMode = .scaleAspectFit
        addMoreView.imageEdgeInsets = UIEdgeInsets(top: 8, left: 8, bottom: 8, right: 8)

        headerView?.frame = CGRect(x: 0, y: 0, width: 320, height: 60)
        headerView?.addSubview(emojiHeader)
        emojiHeader.autoPinEdgesToSuperviewMargins()
        
    }
}
