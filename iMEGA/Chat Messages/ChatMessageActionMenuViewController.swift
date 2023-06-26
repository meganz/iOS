import Haptica
import UIKit

class ChatMessageActionMenuViewController: ActionSheetViewController {
    weak var chatViewController: ChatViewController?
    private let separatorLineView = UIView.newAutoLayout()
    var emojiViews = [UIView]()
    var chatMessage: ChatMessage? {
        didSet {
            configureActions()
        }
    }
    
    var sender: UIView?
    lazy var forwardAction = ActionSheetAction(title: Strings.Localizable.forward, detail: nil, image: Asset.Images.Chat.forwardToolbar.image, style: .default) {
        guard let chatMessage = self.chatMessage else {
            return
        }
        self.chatViewController?.forwardMessage(chatMessage)
     }
    
     lazy var editAction = ActionSheetAction(title: Strings.Localizable.edit, detail: nil, image: Asset.Images.Generic.rename.image, style: .default) {
        guard let chatMessage = self.chatMessage else {
            return
        }
        self.chatViewController?.editMessage(chatMessage)
    }
    
    lazy var copyAction = ActionSheetAction(title: Strings.Localizable.copy, detail: nil, image: Asset.Images.NodeActions.copy.image, style: .default) {
        guard let chatMessage = self.chatMessage else {
            return
        }
        self.chatViewController?.copyMessage(chatMessage)
    }

    lazy var deleteAction = ActionSheetAction(title: Strings.Localizable.delete, detail: nil, image: Asset.Images.NodeActions.delete.image, style: .destructive) {
        guard let chatMessage = self.chatMessage else {
            return
        }
        self.chatViewController?.deleteMessage(chatMessage)
    }
    
    lazy var saveForOfflineAction = ActionSheetAction(title: Strings.Localizable.General.downloadToOffline, detail: nil, image: Asset.Images.NodeActions.offline.image, style: .default) {
        guard let chatMessage = self.chatMessage else {
            return
        }
        self.chatViewController?.downloadMessage([chatMessage])
    }
    
    lazy var importAction = ActionSheetAction(title: Strings.Localizable.importToCloudDrive, detail: nil, image: Asset.Images.InfoActions.import.image, style: .default) {
        guard let chatMessage = self.chatMessage else {
            return
        }
        self.chatViewController?.importMessage([chatMessage])
    }
    
    lazy var addContactAction = ActionSheetAction(title: Strings.Localizable.addContact, detail: nil, image: Asset.Images.Contacts.addContact.image, style: .default) {
        guard let chatMessage = self.chatMessage else {
            return
        }
        self.chatViewController?.addContactMessage(chatMessage)
    }
    
    lazy var removeRichLinkAction = ActionSheetAction(title: Strings.Localizable.removePreview, detail: nil, image: Asset.Images.NodeActions.removeLink.image, style: .default) {
        guard let chatMessage = self.chatMessage else {
            return
        }
        self.chatViewController?.removeRichPreview(chatMessage)
    }
    
    lazy var saveToPhotosAction = ActionSheetAction(title: Strings.Localizable.saveToPhotos, detail: nil, image: Asset.Images.NodeActions.saveToPhotos.image, style: .default) {
        guard let chatMessage = self.chatMessage else {
            return
        }
        self.chatViewController?.saveToPhotos([chatMessage])
    }
    
    lazy var exportMessagesAction = ActionSheetAction(title: Strings.Localizable.General.export, detail: nil, image: Asset.Images.NodeActions.export.image, style: .default) {
        guard let chatMessage = self.chatMessage, let presenter = self.chatViewController else {
            return
        }
        
        ExportFileRouter.init(presenter: presenter, sender: self.sender).export(messages: [chatMessage.message.toChatMessageEntity()], chatId: chatMessage.chatRoom.chatId)
    }
    
    lazy var selectAction = ActionSheetAction(title: Strings.Localizable.select, detail: nil, image: UIImage(named: "select"), style: .default) {
        guard let chatMessage = self.chatMessage else {
            return
        }
        self.chatViewController?.select(chatMessage)
    }
    
    /**
     Haptic feedback generator (during presentation)
     */
    private let feedbackGenerator = UISelectionFeedbackGenerator()

    override func presentView(_ presentedView: UIView, presentingView: UIView, animationDuration: Double, completion: ((Bool) -> Void)?) {
        super.presentView(presentedView, presentingView: presentingView, animationDuration: animationDuration, completion: completion)
        
        feedbackGenerator.selectionChanged()
    }
    
    // MARK: - ChatMessageActionMenuViewController initializers
    
    convenience init(chatMessage: ChatMessage?, sender: UIView?, chatViewController: ChatViewController) {
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
        
        if traitCollection.hasDifferentColorAppearance(comparedTo: previousTraitCollection) {
            updateAppearance()
        }
    }
    
    override func updateAppearance() {
        super.updateAppearance()
        
        separatorLineView.backgroundColor = UIColor.mnz_separator(for: traitCollection)
        emojiViews.forEach { (view) in
            view.backgroundColor = UIColor.mnz_emoji(self.traitCollection)
        }
    }
    
    private func configureActions() {
        guard let chatMessage = chatMessage else {
            return
        }
        
        switch chatMessage.message.type {
        case .invalid, .revokeAttachment:
            actions = []
        case .normal:
            // All messages
            actions = [forwardAction, copyAction, selectAction]
            // Your messages
            if isFromCurrentSender(message: chatMessage) {
                if chatMessage.message.isEditable {
                    actions.append(contentsOf: [editAction])
                }
                if chatMessage.message.isDeletable, chatViewController?.editMessage?.message.messageId != chatMessage.message.messageId {
                    actions.append(contentsOf: [deleteAction])
                }
            }
            
        case .containsMeta:
            // All messages
            actions = [forwardAction, selectAction]
            if chatMessage.message.containsMeta?.type != .geolocation && chatMessage.message.containsMeta?.type != .giphy {
                actions.append(contentsOf: [copyAction])
            }
            
            if chatMessage.message.containsMeta?.type != .giphy {
                actions.append(contentsOf: [exportMessagesAction])
            }
            
            // Your messages
            if isFromCurrentSender(message: chatMessage) {
               
                if chatMessage.message.isEditable {
                    if chatMessage.message.containsMeta?.type != .giphy {
                        actions.append(contentsOf: [editAction])
                    }
                    
                    if chatMessage.message.containsMeta?.type != .geolocation, chatMessage.message.containsMeta?.type != .giphy {
                        actions.append(contentsOf: [removeRichLinkAction])
                    }
                }
                if chatMessage.message.isDeletable, chatViewController?.editMessage?.message.messageId != chatMessage.message.messageId {
                    actions.append(contentsOf: [deleteAction])
                }
                
            }
            
        case .alterParticipants, .truncate, .privilegeChange, .chatTitle:
            // All messages
            actions = [copyAction]
            
        case .attachment:
            actions = [saveForOfflineAction, forwardAction, exportMessagesAction, selectAction]
            
            if chatMessage.message.nodeList?.size.uintValue == 1,
               let name = chatMessage.message.nodeList?.node(at: 0)?.name, name.mnz_isVisualMediaPathExtension {
                actions.append(saveToPhotosAction)
                if name.fileExtensionGroup.isImage {
                    actions.append(copyAction)
                }
            }
            
            // Your messages
            if isFromCurrentSender(message: chatMessage) {
                if chatMessage.message.isDeletable {
                    actions.append(contentsOf: [deleteAction])
                }
            } else {
                actions.append(contentsOf: [importAction])
            }
        case .voiceClip:
            actions = [saveForOfflineAction, exportMessagesAction, selectAction]
            if (chatMessage.message.richNumber) != nil {
                actions.append(forwardAction)
            }
            // Your messages
            if isFromCurrentSender(message: chatMessage) {
                if chatMessage.message.isDeletable {
                    actions.append(contentsOf: [deleteAction])
                }
            } else {
                actions.append(contentsOf: [importAction])
            }
        case .contact:
            actions = [forwardAction, exportMessagesAction, selectAction]
         
            if chatMessage.message.usersCount == 1 {
                if let email = chatMessage.message.userEmail(at: 0), let user = MEGASdkManager.sharedMEGASdk().contact(forEmail: email), user.visibility != .visible {
                    actions.append(contentsOf: [addContactAction])
                } else {
                    for index in 0..<chatMessage.message.usersCount {
                        if let email = chatMessage.message.userEmail(at: index), let user = MEGASdkManager.sharedMEGASdk().contact(forEmail: email), user.visibility != .visible {
                            return
                        }
                    }
                    actions.append(contentsOf: [addContactAction])
                }
            }
            
            // Your messages
            if isFromCurrentSender(message: chatMessage) {
                if chatMessage.message.isDeletable {
                    actions.append(contentsOf: [deleteAction])
                }
            }
        default:
            break
        }
        
    }
    
    private func configureHeaderView() {
        guard let chatMessage = chatMessage, chatMessage.chatRoom.canAddReactions else {
            return
        }
        
        let stackView = UIStackView()
        stackView.axis = .horizontal
        stackView.distribution = .fillEqually
        stackView.alignment = .center
        stackView.spacing = 10
        
        let emojis = ["😀", "☹", "🤣", "👍", "👎", ""]
        emojis.forEach { (emoji) in
            let emojiView = UIButton()
            emojiView.addHaptic(.selection, forControlEvents: .touchDown)
            emojiView.layer.cornerRadius = 22
            if emoji != "" {
                let attributedEmoji = NSAttributedString(string: emoji, attributes: [NSAttributedString.Key.font: UIFont(name: "Apple color emoji", size: 30) as Any])
                emojiView.setAttributedTitle(attributedEmoji, for: .normal)
                emojiView.backgroundColor = UIColor.mnz_whiteF2F2F2()
                emojiView.addTarget(self, action: #selector(emojiPress(_:)), for: .touchUpInside)
            } else {
                emojiView.setImage(Asset.Images.Chat.addReactionSmall.image, for: .normal)
                emojiView.backgroundColor = UIColor.mnz_emoji(self.traitCollection)
                emojiView.imageView?.contentMode = .scaleAspectFit
                emojiView.imageEdgeInsets = UIEdgeInsets(top: 10, left: 10, bottom: 10, right: 10)
                emojiView.addTarget(self, action: #selector(addMorePress(_:)), for: .touchUpInside)
            }
            emojiView.heightAnchor.constraint(equalToConstant: 44).isActive = true
            
            emojiViews.append(emojiView)
            stackView.addArrangedSubview(emojiView)
        }
        
        let headerContainer = UIView()
        
        headerContainer.addSubview(stackView)
        headerView?.addSubview(headerContainer)
        headerView?.addSubview(separatorLineView)
        
        guard let superview = headerContainer.superview else { return }
        
        headerContainer.translatesAutoresizingMaskIntoConstraints = false
        [headerContainer.topAnchor.constraint(equalTo: superview.topAnchor),
         headerContainer.bottomAnchor.constraint(equalTo: superview.bottomAnchor),
         headerContainer.leadingAnchor.constraint(equalTo: superview.leadingAnchor),
         headerContainer.trailingAnchor.constraint(greaterThanOrEqualTo: superview.trailingAnchor)].activate()
        
        stackView.translatesAutoresizingMaskIntoConstraints = false
        [stackView.topAnchor.constraint(equalTo: headerContainer.topAnchor),
         stackView.bottomAnchor.constraint(equalTo: headerContainer.bottomAnchor),
         stackView.leadingAnchor.constraint(equalTo: headerContainer.leadingAnchor, constant: 10),
         stackView.trailingAnchor.constraint(greaterThanOrEqualTo: headerContainer.trailingAnchor, constant: -10).using(priority: 999)].activate()
        
        guard let superview = separatorLineView.superview else { return }
        
        separatorLineView.translatesAutoresizingMaskIntoConstraints = false
        [separatorLineView.heightAnchor.constraint(equalToConstant: 1/UIScreen.main.scale),
         separatorLineView.bottomAnchor.constraint(equalTo: superview.bottomAnchor),
         separatorLineView.leadingAnchor.constraint(equalTo: superview.leadingAnchor),
         separatorLineView.trailingAnchor.constraint(greaterThanOrEqualTo: superview.trailingAnchor)
        ].activate()
        
        headerView?.frame = CGRect(x: 0, y: 0, width: tableView.frame.width, height: 60)
    }
    
    @objc func emojiPress(_ sender: UIButton) {
        guard let emoji = sender.attributedTitle(for: .normal)?.string,
              let messageId = chatMessage?.message.messageId else {
                  dismiss(animated: true, completion: nil)
                  return
              }
        
        MEGASdkManager.sharedMEGAChatSdk().addReaction(forChat: chatMessage?.chatRoom.chatId ?? 0, messageId: messageId, reaction: emoji)
        dismiss(animated: true, completion: nil)
    }
    
    @objc func addMorePress(_ sender: UIButton) {
        let vc = ReactionPickerViewController()
        vc.message = chatMessage
        
        if let sourceView = self.sender, let presentingViewController = presentingViewController {
            dismiss(animated: true, completion: nil)
            presentingViewController.presentPanModal(vc, sourceView: sourceView, sourceRect: sourceView.bounds)
        }
        
    }
    
    // MARK: - Internal methods used by the extension of this class

    func isFromCurrentSender(message: ChatMessage) -> Bool {
        return UInt64(message.sender.senderId) == MEGASdkManager.sharedMEGAChatSdk().myUserHandle
    }

}
