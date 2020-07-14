import MessageKit

class ChatMediaCollectionViewCell: MessageContentCell, MEGATransferDelegate {
    var currentNode: MEGANode?
    var currentTransfer: MEGATransfer?

    open var imageView: YYAnimatedImageView = {
        let imageView = YYAnimatedImageView(frame: CGRect(x: 0, y: 0, width: 40, height: 40))
        imageView.backgroundColor = .clear
        imageView.contentMode = .scaleAspectFit
        return imageView
    }()

    open var playIconView: UIImageView = {
        let playIconView = UIImageView(image: UIImage(named: "playButton"))
        playIconView.isHidden = true
        return playIconView
    }()

    open var loadingIndicator: UIActivityIndicatorView = {
        let loadingIndicator = UIActivityIndicatorView(style: .gray)
        loadingIndicator.startAnimating()
        loadingIndicator.isHidden = true
        return loadingIndicator
    }()
    
    open var progressView: UIProgressView = {
        let progressView = UIProgressView(progressViewStyle: .default)
        progressView.tintColor = UIColor.mnz_turquoise(for: progressView.traitCollection)
        progressView.trackTintColor = .clear
        return progressView
    }()

    open var durationLabel: UILabel = {
        let label = UILabel()
        label.textColor = .white
        label.font = UIFont.systemFont(ofSize: 12)
        label.layer.shadowColor = UIColor(red: 0, green: 0, blue: 0, alpha: 0.2).cgColor
        label.layer.shadowOffset = CGSize(width: 0, height: 1)
        label.layer.shadowRadius = 2
        label.layer.shadowOpacity = 1
        label.isHidden = true
        return label
    }()

    override public init(frame: CGRect) {
        super.init(frame: frame)
        MEGASdkManager.sharedMEGASdk()?.add(self)
    }

    public required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        MEGASdkManager.sharedMEGASdk()?.add(self)
    }

    // MARK: - Methods

    /// Responsible for setting up the constraints of the cell's subviews.
    open func setupConstraints() {
        imageView.autoPinEdgesToSuperviewEdges()
        playIconView.autoCenterInSuperview()
        durationLabel.autoPinEdge(toSuperviewEdge: .leading, withInset: 10)
        durationLabel.autoPinEdge(toSuperviewEdge: .trailing, withInset: 10)
        durationLabel.autoPinEdge(toSuperviewEdge: .bottom, withInset: 10)
        durationLabel.autoSetDimension(.height, toSize: 14)

        loadingIndicator.autoCenterInSuperview()
        loadingIndicator.autoSetDimensions(to: CGSize(width: 20, height: 20))
        
        progressView.autoPinEdgesToSuperviewEdges(with: .zero, excludingEdge: .top)
        progressView.autoSetDimension(.height, toSize: 4)
    }

    override open func setupSubviews() {
        super.setupSubviews()
        messageContainerView.addSubview(loadingIndicator)
        messageContainerView.addSubview(imageView)
        messageContainerView.addSubview(progressView)
        imageView.addSubview(playIconView)
        imageView.addSubview(durationLabel)
        setupConstraints()
    }

    override func configure(with message: MessageType, at indexPath: IndexPath, and messagesCollectionView: MessagesCollectionView) {
        super.configure(with: message, at: indexPath, and: messagesCollectionView)

        guard let chatMessage = message as? ChatMessage else {
            return
        }

        let megaMessage = chatMessage.message
        currentTransfer = chatMessage.transfer

        if let transfer = chatMessage.transfer {
            loadingIndicator.isHidden = false
            loadingIndicator.startAnimating()
            progressView.isHidden = false
            durationLabel.isHidden = true
            playIconView.isHidden = true
            let path = NSHomeDirectory().append(pathComponent: transfer.path)
            imageView.yy_imageURL = URL(fileURLWithPath: path)
            return
        }

        progressView.isHidden = true

        let node = megaMessage.nodeList.node(at: 0)!
        currentNode = node
        let name = node.name! as NSString
                 let previewFilePath = Helper.path(for: node, inSharedSandboxCacheDirectory: "previewsV3")
        let originalImagePath = Helper.path(for: node, inSharedSandboxCacheDirectory: "originalV3")

        if FileManager.default.fileExists(atPath: previewFilePath) || FileManager.default.fileExists(atPath: originalImagePath) {
            loadingIndicator.isHidden = true
        } else {
            loadingIndicator.isHidden = false
            loadingIndicator.startAnimating()
        }
        imageView.mnz_setPreview(by: node) { _ in
            let visibleIndexPaths = messagesCollectionView.indexPathsForVisibleItems
            guard visibleIndexPaths.contains(indexPath) else {
                return
            }

            messagesCollectionView.reloadItems(at: [indexPath])
        }

        durationLabel.isHidden = true
        playIconView.isHidden = true
        if name.pathExtension == "gif" {
            let originalImagePath = Helper.path(for: node, inSharedSandboxCacheDirectory: "originalV3")
            if FileManager.default.fileExists(atPath: originalImagePath) {
                imageView.yy_imageURL = URL(fileURLWithPath: originalImagePath)
                return
            }
            MEGASdkManager.sharedMEGASdk()?.startDownloadTopPriority(with: node, localPath: originalImagePath, appData: nil)
        } else if name.mnz_isVideoPathExtension {
            durationLabel.text = NSString.mnz_string(fromTimeInterval: TimeInterval(node.duration))
            durationLabel.isHidden = false
            playIconView.isHidden = false
        }
    }

    func onTransferUpdate(_ api: MEGASdk, transfer: MEGATransfer) {
        if currentTransfer?.nodeHandle == transfer.nodeHandle {
            progressView.setProgress(transfer.transferredBytes.floatValue / transfer.totalBytes.floatValue, animated: true)
        }
    }
    
    func onTransferFinish(_: MEGASdk, transfer: MEGATransfer, error _: MEGAError) {
        if currentNode?.handle == transfer.nodeHandle {
            if transfer.path != nil, FileManager.default.fileExists(atPath: transfer.path) {
                imageView.yy_imageURL = URL(fileURLWithPath: transfer.path)
            }
        }
    }
}

open class ChatMediaCollectionViewSizeCalculator: MessageSizeCalculator {
    let cell = ChatMediaCollectionViewCell()

    override public init(layout: MessagesCollectionViewFlowLayout? = nil) {
        super.init(layout: layout)
        configureAccessoryView()
    }

    override open func messageContainerMaxWidth(for message: MessageType) -> CGFloat {
        return min(UIDevice.current.mnz_maxSideForChatBubble(withMedia: true), super.messageContainerMaxWidth(for: message))
    }

    override open func messageContainerSize(for message: MessageType) -> CGSize {
        switch message.kind {
        case .custom:
            let maxWidth = min(UIDevice.current.mnz_maxSideForChatBubble(withMedia: true), messageContainerMaxWidth(for: message))
            let maxHeight = UIDevice.current.mnz_maxSideForChatBubble(withMedia: true)
            guard let chatMessage = message as? ChatMessage else {
                return .zero
            }

            var width: CGFloat = 200
            var height: CGFloat = 200

            if chatMessage.transfer != nil {
                let path = NSHomeDirectory().append(pathComponent: chatMessage.transfer!.path)

                if FileManager.default.fileExists(atPath: path) {
                    guard let previewImage = UIImage(contentsOfFile: path) else {
                        return CGSize(width: width, height: height)
                    }
                    width = previewImage.size.width
                    height = previewImage.size.height

                    let ratio = width / height
                    if ratio > 1 {
                        width = min(maxWidth, width)
                        height = width / ratio
                    } else {
                        height = min(maxHeight, height)
                        width = height * ratio
                    }
                }
            } else {
                let megaMessage = chatMessage.message
                let node = megaMessage.nodeList.node(at: 0)!
                let previewFilePath = Helper.path(for: node, inSharedSandboxCacheDirectory: "previewsV3")
                let originalImagePath = Helper.path(for: node, inSharedSandboxCacheDirectory: "originalV3")

                if FileManager.default.fileExists(atPath: previewFilePath), let previewImage = UIImage(contentsOfFile: previewFilePath) {
                    width = previewImage.size.width
                    height = previewImage.size.height
                } else if FileManager.default.fileExists(atPath: originalImagePath), let previewImage = UIImage(contentsOfFile: originalImagePath) {
                    width = previewImage.size.width
                    height = previewImage.size.height
                }
                if node.hasPreview(),
                    node.height > 0,
                    node.width > 0 {
                    width = CGFloat(node.width)
                    height = CGFloat(node.height)
                }
            }
            let ratio = width / height
            if ratio > 1 {
                width = min(maxWidth, width)
                height = width / ratio
            } else {
                height = min(maxHeight, height)
                width = height * ratio
            }

            return CGSize(width: width, height: height)
        default:
            fatalError("messageContainerSize received unhandled MessageDataType: \(message.kind)")
        }
    }
}
