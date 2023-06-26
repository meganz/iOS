import MessageKit

extension CGFloat {
    func precised(_ value: Int = 1) -> CGFloat {
        let offset = pow(10, CGFloat(value))
        return (self * offset).rounded() / offset
    }

    static func equal(_ lhs: CGFloat, _ rhs: CGFloat, precise value: Int? = nil) -> Bool {
        guard let value = value else {
            return lhs == rhs
        }

        return lhs.precised(value) == rhs.precised(value)
    }
}

class ChatMediaCollectionViewCell: MessageContentCell, MEGATransferDelegate {
    var currentNode: MEGANode?
    var currentTransfer: MEGATransfer?

    let autoDownloadThresholdSize = 5.0 * 1024 * 1024

    open var imageView: UIImageView = {
        let imageView = UIImageView(frame: CGRect(x: 0, y: 0, width: 40, height: 40))
        imageView.backgroundColor = .clear
        imageView.contentMode = .scaleAspectFit
        return imageView
    }()
    
    open var downloadGifIcon: UIImageView = {
        let downloadGifIcon = UIImageView(image: Asset.Images.Chat.downloadGif.image)
        downloadGifIcon.isHidden = true
        return downloadGifIcon
    }()
    
    open var playIconView: UIImageView = {
        let playIconView = UIImageView(image: Asset.Images.Chat.Messages.playButton.image)
        playIconView.isHidden = true
        return playIconView
    }()

    open var loadingIndicator: UIActivityIndicatorView = {
        let loadingIndicator = UIActivityIndicatorView(style: .medium)
        loadingIndicator.startAnimating()
        loadingIndicator.hidesWhenStopped = true
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
        label.font = UIFont.preferredFont(forTextStyle: .caption1)
        label.layer.shadowColor = Colors.General.Shadow.blackAlpha20.color.cgColor
        label.layer.shadowOffset = CGSize(width: 0, height: 1)
        label.layer.shadowRadius = 2
        label.layer.shadowOpacity = 1
        label.isHidden = true
        return label
    }()

    override public init(frame: CGRect) {
        super.init(frame: frame)
        MEGASdkManager.sharedMEGASdk().add(self)
    }
    
    public required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        MEGASdkManager.sharedMEGASdk().add(self)
    }

    // MARK: - Methods

    /// Responsible for setting up the constraints of the cell's subviews.
    open func setupConstraints() {
        imageView.autoPinEdgesToSuperviewEdges()
        playIconView.autoCenterInSuperview()
        downloadGifIcon.autoCenterInSuperview()
        downloadGifIcon.autoSetDimensions(to: CGSize(width: 40, height: 40))

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
        messageContainerView.addSubview(imageView)
        messageContainerView.addSubview(loadingIndicator)
        messageContainerView.addSubview(progressView)
        imageView.addSubview(downloadGifIcon)
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
        progressView.progress = 0
        if let transfer = chatMessage.transfer {
            loadingIndicator.isHidden = false
            loadingIndicator.startAnimating()
            progressView.isHidden = false
            durationLabel.isHidden = true
            playIconView.isHidden = true
            downloadGifIcon.isHidden = true
            let path = NSHomeDirectory().append(pathComponent: transfer.path)
            imageView.sd_setImage(with: URL(fileURLWithPath: path))
            return
        }

        progressView.isHidden = true
        loadingIndicator.stopAnimating()

        guard let node = megaMessage.nodeList?.node(at: 0) else { return }
        currentNode = node
        let name = node.toNodeEntity().name
        let previewFilePath = Helper.path(for: node, inSharedSandboxCacheDirectory: "previewsV3")
        let originalImagePath = Helper.pathWithOriginalName(for: node, inSharedSandboxCacheDirectory: "originalV3")
        
        if FileManager.default.fileExists(atPath: previewFilePath) || FileManager.default.fileExists(atPath: originalImagePath) {
            loadingIndicator.stopAnimating()
            if let previewImage = UIImage(contentsOfFile: previewFilePath) ?? UIImage(contentsOfFile: originalImagePath),
                (previewImage.size.width / previewImage.size.height).precised(2) != (messageContainerView.frame.width / messageContainerView.frame.height).precised(2),
                messagesCollectionView.numberOfSections > indexPath.section {
                imageView.image = nil
                messagesCollectionView.reloadItems(at: [indexPath])
            }
        } else {
            downloadGifIcon.isHidden = true
            loadingIndicator.startAnimating()
        }
        imageView.mnz_setPreview(by: node) { [weak self] _ in
            guard messagesCollectionView.cellForItem(at: indexPath) != nil, let strongSelf = self else {
                return
            }
            
            if strongSelf.isLastSectionVisible(collectionView: messagesCollectionView) {
                messagesCollectionView.reloadDataAndKeepOffset()
            } else {
                messagesCollectionView.reloadItems(at: [indexPath])
            }
        }

        durationLabel.isHidden = true
        playIconView.isHidden = true
        downloadGifIcon.isHidden = true

        if name.pathExtension == "gif" || name.pathExtension == "webp" {
            let originalImagePath = Helper.pathWithOriginalName(for: node, inSharedSandboxCacheDirectory: "originalV3")
            if FileManager.default.fileExists(atPath: originalImagePath) {
                imageView.sd_setImage(with: URL(fileURLWithPath: originalImagePath))
                
                downloadGifIcon.isHidden = true
            } else if node.size?.doubleValue ?? 0 < autoDownloadThresholdSize {
                MEGASdk.shared.startDownloadNode(
                    node,
                    localPath: originalImagePath,
                    fileName: nil,
                    appData: nil,
                    startFirst: true, cancelToken: nil,
                    collisionCheck: CollisionCheck.fingerprint,
                    collisionResolution: CollisionResolution.newWithN
                )
                downloadGifIcon.isHidden = true
            } else {
                downloadGifIcon.isHidden = !loadingIndicator.isHidden
            }
        } else if node.toNodeEntity().fileExtensionGroup.isVideo {
            durationLabel.text = TimeInterval(node.duration).timeString
            durationLabel.isHidden = false
            playIconView.isHidden = !loadingIndicator.isHidden
            downloadGifIcon.isHidden = true
        }
    }

    func onTransferUpdate(_ api: MEGASdk, transfer: MEGATransfer) {
        if currentTransfer?.tag == transfer.tag {
            progressView.setProgress(transfer.transferredBytes.floatValue / transfer.totalBytes.floatValue, animated: true)
        }
    }
    
    func onTransferFinish(_: MEGASdk, transfer: MEGATransfer, error _: MEGAError) {
        if currentNode?.handle == transfer.nodeHandle {
            if transfer.path != nil, FileManager.default.fileExists(atPath: transfer.path) {
                imageView.sd_setImage(with: URL(fileURLWithPath: transfer.path))
                downloadGifIcon.isHidden = true

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
                guard let node = chatMessage.message.nodeList?.node(at: 0) else { return .zero }
                let previewFilePath = Helper.path(for: node, inSharedSandboxCacheDirectory: "previewsV3")
                let originalImagePath = Helper.pathWithOriginalName(for: node, inSharedSandboxCacheDirectory: "originalV3")

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
