import UIKit

class ChatMessageActionMenuViewController: ActionSheetViewController {
    weak var chatViewController: ChatViewController?
    private let separatorLineView = UIView.newAutoLayout()
    
    var chatMessage: ChatMessage? {
        didSet {
            configureActions()
        }
    }
    
    var sender: Any?
    lazy var forwardAction = ActionSheetAction(title: AMLocalizedString("forward"), detail: nil, image: UIImage(named: "forwardToolbar"), style: .default) {
        guard let chatMessage = self.chatMessage else {
            return
        }
        self.chatViewController?.forwardMessage(chatMessage)
     }
    
     lazy var editAction = ActionSheetAction(title: AMLocalizedString("edit"), detail: nil, image: UIImage(named: "rename"), style: .default) {
        guard let chatMessage = self.chatMessage else {
            return
        }
        self.chatViewController?.editMessage(chatMessage)
    }
    
     lazy var copyAction = ActionSheetAction(title: AMLocalizedString("copy"), detail: nil, image: UIImage(named: "copy"), style: .default) {
        guard let chatMessage = self.chatMessage else {
            return
        }
        self.chatViewController?.copyMessage(chatMessage)
    }
    
//     lazy var  selectAction = ActionSheetAction(title: AMLocalizedString("select"), detail: nil, image: UIImage(named: "select"), style: .default) {
//        guard let chatMessage = self.chatMessage else {
//                return
//            }
    //            self.chatViewController?.copyMessage(chatMessage)
    //    }
    
    lazy var deleteAction = ActionSheetAction(title: AMLocalizedString("delete"), detail: nil, image: UIImage(named: "delete"), style: .destructive) {
        guard let chatMessage = self.chatMessage else {
            return
        }
        self.chatViewController?.deleteMessage(chatMessage)
    }
    
    lazy var saveForOfflineAction = ActionSheetAction(title: AMLocalizedString("saveForOffline"), detail: nil, image: UIImage(named: "offline"), style: .default) {
        guard let chatMessage = self.chatMessage else {
            return
        }
        self.chatViewController?.downloadMessage(chatMessage)
    }
    
    lazy var importAction = ActionSheetAction(title: AMLocalizedString("Import to Cloud Drive"), detail: nil, image: UIImage(named: "import"), style: .default) {
        guard let chatMessage = self.chatMessage else {
            return
        }
        self.chatViewController?.importMessage(chatMessage)
    }
    
    lazy var addContactAction = ActionSheetAction(title: AMLocalizedString("addContact"), detail: nil, image: UIImage(named: "addContact"), style: .default) {
        guard let chatMessage = self.chatMessage else {
            return
        }
        self.chatViewController?.addContactMessage(chatMessage)
    }
    
    lazy var removeRichLinkAction = ActionSheetAction(title: AMLocalizedString("removePreview"), detail: nil, image: UIImage(named: "removeLink"), style: .default) {
        guard let chatMessage = self.chatMessage else {
            return
        }
        self.chatViewController?.removeRichPreview(chatMessage)
    }
    
    
    // MARK: - ChatMessageActionMenuViewController initializers
    
    convenience init(chatMessage: ChatMessage?, sender: Any?, chatViewController: ChatViewController) {
        self.init(nibName: nil, bundle: nil)
        
        self.chatMessage = chatMessage
        self.sender = sender
        self.chatViewController = chatViewController
        configureActions()

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
        configureHeaderView()
    }
    
    override func traitCollectionDidChange(_ previousTraitCollection: UITraitCollection?) {
        super.traitCollectionDidChange(previousTraitCollection)
        
        if #available(iOS 13.0, *) {
            if traitCollection.hasDifferentColorAppearance(comparedTo: previousTraitCollection) {
                updateAppearance()
            }
        }
    }
    
    override func updateAppearance() {
        super.updateAppearance()
        
        separatorLineView.backgroundColor = UIColor.mnz_separator(for: traitCollection)
    }
    
    func configureActions() {
        guard let chatMessage = chatMessage else {
            return
        }
        
        switch chatMessage.message.type  {
        case .invalid, .revokeAttachment:
            actions = []
        case .normal:
            //All messages
            actions = [forwardAction, copyAction]
            //Your messages
            if isFromCurrentSender(message: chatMessage) {
                if chatMessage.message.isEditable {
                    actions.append(contentsOf: [editAction])
                }
                if chatMessage.message.isDeletable, chatViewController?.editMessage?.message.messageId != chatMessage.message.messageId {
                    actions.append(contentsOf: [deleteAction])
                }
                
                
            }
            
        case .containsMeta:
            //All messages
            actions = [forwardAction]
            if chatMessage.message.containsMeta.type != .geolocation {
                actions.append(contentsOf: [copyAction])
            }
            
            //Your messages
            if isFromCurrentSender(message: chatMessage) {
               
                if chatMessage.message.isEditable {
                    actions.append(contentsOf: [editAction])
                    if chatMessage.message.containsMeta.type != .geolocation {
                        actions.append(contentsOf: [removeRichLinkAction])
                    }
                }
                if chatMessage.message.isDeletable, chatViewController?.editMessage?.message.messageId != chatMessage.message.messageId {
                    actions.append(contentsOf: [deleteAction])
                }
                
            }
            
        case .alterParticipants, .truncate, .privilegeChange, .chatTitle:
            //All messages
            actions = [copyAction]
            
        case .attachment:
            actions = [saveForOfflineAction, forwardAction]
            //Your messages
            if isFromCurrentSender(message: chatMessage) {
                if chatMessage.message.isDeletable {
                    actions.append(contentsOf: [deleteAction])
                }
            } else {
                actions.append(contentsOf: [importAction])
            }
        case .voiceClip:
            actions = [saveForOfflineAction]
            if (chatMessage.message.richNumber) != nil {
                actions.append(forwardAction)
            }
            //Your messages
            if isFromCurrentSender(message: chatMessage) {
                if chatMessage.message.isDeletable {
                    actions.append(contentsOf: [deleteAction])
                }
            } else {
                actions.append(contentsOf: [importAction])
            }
        case .contact:
            actions = [forwardAction]
         
            if chatMessage.message.usersCount == 1 {
                if let email = chatMessage.message.userEmail(at: 0), let user = MEGASdkManager.sharedMEGASdk()?.contact(forEmail: email), user.visibility != .visible {
                    actions.append(contentsOf: [addContactAction])
                } else {
                    for index in 0..<chatMessage.message.usersCount {
                        if let email = chatMessage.message.userEmail(at: index), let user = MEGASdkManager.sharedMEGASdk()?.contact(forEmail: email), user.visibility != .visible {
                            return
                        }
                    }
                    actions.append(contentsOf: [addContactAction])
                }
            }
            
            //Your messages
            if isFromCurrentSender(message: chatMessage) {
                if chatMessage.message.isDeletable {
                    actions.append(contentsOf: [deleteAction])
                }
            }
        default:
            break
        }
        
    }
    
    func configureHeaderView() {
        let emojiHeader = UIStackView()
        emojiHeader.axis = .horizontal
        emojiHeader.distribution = .equalSpacing
        emojiHeader.alignment = .fill

        let emojis = ["😀", "☹️", "🤣", "👍", "👎"]
        emojis.forEach { (emoji) in
            let emojiView = UIButton()
            let attributedEmoji = NSAttributedString(string: emoji, attributes: [NSAttributedString.Key.font: UIFont.systemFont(ofSize: 30)])
            emojiView.setAttributedTitle(attributedEmoji, for: .normal)
            emojiView.layer.cornerRadius = 22
            emojiView.backgroundColor = UIColor.mnz_whiteF2F2F2()
            emojiView.autoSetDimensions(to: CGSize(width: 44, height: 44))
            emojiView.addTarget(self, action: #selector(emojiPress(_:)), for: .touchUpInside)

            emojiHeader.addArrangedSubview(emojiView)
        }
        
        let addMoreView = UIButton()
        addMoreView.setImage(UIImage(named: "addReactionSmall"), for: .normal)
        addMoreView.layer.cornerRadius = 22
        addMoreView.backgroundColor = UIColor.mnz_whiteF2F2F2()
        addMoreView.imageView?.contentMode = .scaleAspectFit
        addMoreView.imageEdgeInsets = UIEdgeInsets(top: 6, left: 6, bottom: 6, right: 6)
        addMoreView.autoSetDimensions(to: CGSize(width: 44, height: 44))
        addMoreView.addTarget(self, action: #selector(addMorePress(_:)), for: .touchUpInside)

        emojiHeader.addArrangedSubview(addMoreView)

        headerView?.frame = CGRect(x: 0, y: 0, width: 320, height: 60)
        headerView?.addSubview(emojiHeader)
        emojiHeader.autoPinEdgesToSuperviewMargins()
        
        headerView?.addSubview(separatorLineView)
        separatorLineView.autoPinEdge(toSuperviewEdge: .leading)
        separatorLineView.autoPinEdge(toSuperviewEdge: .trailing)
        separatorLineView.autoPinEdge(toSuperviewEdge: .bottom)
        separatorLineView.autoSetDimension(.height, toSize: 1/UIScreen.main.scale)
        
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
        
        if let sourceView = self.sender as? UIView, let presentingViewController = presentingViewController {
            dismiss(animated: true, completion: nil)
            presentingViewController.presentPanModal(vc, sourceView:sourceView , sourceRect: sourceView.bounds)
        }
        
    }
    
    
    // MARK: - Internal methods used by the extension of this class

    func isFromCurrentSender(message: ChatMessage) -> Bool {
        return UInt64(message.sender.senderId) == MEGASdkManager.sharedMEGAChatSdk()?.myUserHandle
    }

}
