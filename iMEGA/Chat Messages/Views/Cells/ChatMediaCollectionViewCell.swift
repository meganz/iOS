import MEGAAssets
import MEGADesignToken
import MEGADomain
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
        imageView.translatesAutoresizingMaskIntoConstraints = false
        imageView.backgroundColor = .clear
        imageView.contentMode = .scaleAspectFit
        return imageView
    }()
    
    open var downloadGifIcon: UIImageView = {
        let downloadGifIcon = UIImageView(image: MEGAAssets.UIImage.downloadGif)
        downloadGifIcon.translatesAutoresizingMaskIntoConstraints = false
        downloadGifIcon.isHidden = true
        return downloadGifIcon
    }()
    
    open var playIconView: UIImageView = {
        let playIconView = UIImageView(image: MEGAAssets.UIImage.playButton)
        playIconView.translatesAutoresizingMaskIntoConstraints = false
        playIconView.isHidden = true
        return playIconView
    }()

    open var loadingIndicator: UIActivityIndicatorView = {
        let loadingIndicator = UIActivityIndicatorView(style: .medium)
        loadingIndicator.translatesAutoresizingMaskIntoConstraints = false
        loadingIndicator.startAnimating()
        loadingIndicator.hidesWhenStopped = true
        loadingIndicator.color = TokenColors.Icon.primary
        return loadingIndicator
    }()
    
    open var progressView: UIProgressView = {
        let progressView = UIProgressView(progressViewStyle: .default)
        progressView.translatesAutoresizingMaskIntoConstraints = false
        progressView.tintColor = TokenColors.Support.success
        progressView.trackTintColor = .clear
        return progressView
    }()

    open var durationLabel: UILabel = {
        let label = UILabel()
        label.translatesAutoresizingMaskIntoConstraints = false
        label.textColor = MEGAAssets.UIColor.whiteFFFFFF
        label.font = UIFont.preferredFont(forTextStyle: .caption1)
        label.layer.shadowColor = TokenColors.Background.blur.cgColor
        label.layer.shadowOffset = CGSize(width: 0, height: 1)
        label.layer.shadowRadius = 2
        label.layer.shadowOpacity = 1
        label.isHidden = true
        return label
    }()

    override public init(frame: CGRect) {
        super.init(frame: frame)
        MEGASdk.sharedSdk.add(self)
    }
    
    public required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        MEGASdk.sharedSdk.add(self)
    }

    // MARK: - Methods

    /// Responsible for setting up the constraints of the cell's subviews.
    open func setupConstraints() {
        NSLayoutConstraint.activate([
            imageView.topAnchor.constraint(equalTo: messageContainerView.topAnchor),
            imageView.leadingAnchor.constraint(equalTo: messageContainerView.leadingAnchor),
            imageView.bottomAnchor.constraint(equalTo: messageContainerView.bottomAnchor),
            imageView.trailingAnchor.constraint(equalTo: messageContainerView.trailingAnchor),
            
            playIconView.centerXAnchor.constraint(equalTo: imageView.centerXAnchor),
            playIconView.centerYAnchor.constraint(equalTo: imageView.centerYAnchor),
            
            downloadGifIcon.centerXAnchor.constraint(equalTo: imageView.centerXAnchor),
            downloadGifIcon.centerYAnchor.constraint(equalTo: imageView.centerYAnchor),
            downloadGifIcon.widthAnchor.constraint(equalToConstant: 40),
            downloadGifIcon.heightAnchor.constraint(equalToConstant: 40),
            
            durationLabel.leadingAnchor.constraint(equalTo: imageView.leadingAnchor, constant: 10),
            durationLabel.trailingAnchor.constraint(equalTo: imageView.trailingAnchor, constant: -10),
            durationLabel.bottomAnchor.constraint(equalTo: imageView.bottomAnchor, constant: -10),
            durationLabel.heightAnchor.constraint(equalToConstant: 14),
            
            loadingIndicator.centerXAnchor.constraint(equalTo: messageContainerView.centerXAnchor),
            loadingIndicator.centerYAnchor.constraint(equalTo: messageContainerView.centerYAnchor),
            loadingIndicator.widthAnchor.constraint(equalToConstant: 20),
            loadingIndicator.heightAnchor.constraint(equalToConstant: 20),
            
            progressView.leadingAnchor.constraint(equalTo: messageContainerView.leadingAnchor),
            progressView.trailingAnchor.constraint(equalTo: messageContainerView.trailingAnchor),
            progressView.bottomAnchor.constraint(equalTo: messageContainerView.bottomAnchor),
            progressView.heightAnchor.constraint(equalToConstant: 4)
        ])
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

    override func configure(with message: any MessageType, at indexPath: IndexPath, and messagesCollectionView: MessagesCollectionView) {
        super.configure(with: message, at: indexPath, and: messagesCollectionView)

        guard let chatMessage = message as? ChatMessage else {
            return
        }
        messageContainerView.backgroundColor = TokenColors.Background.surface3
        let megaMessage = chatMessage.message
        currentTransfer = chatMessage.transfer
        progressView.progress = 0
        if let transfer = chatMessage.transfer, let transferPath = transfer.path {
            loadingIndicator.isHidden = false
            loadingIndicator.startAnimating()
            progressView.isHidden = false
            durationLabel.isHidden = true
            playIconView.isHidden = true
            downloadGifIcon.isHidden = true
            let path = NSHomeDirectory().append(pathComponent: transferPath)
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
            if #unavailable(iOS 18.0) {
                if let previewImage = UIImage(contentsOfFile: previewFilePath) ?? UIImage(contentsOfFile: originalImagePath),
                    (previewImage.size.width / previewImage.size.height).precised(2) != (messageContainerView.frame.width / messageContainerView.frame.height).precised(2),
                    messagesCollectionView.numberOfSections > indexPath.section {
                    imageView.image = nil
                    messagesCollectionView.reloadItems(at: [indexPath])
                }
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
            progressView.setProgress( Float(transfer.transferredBytes) / Float(transfer.totalBytes), animated: true)
        }
    }
    
    func onTransferFinish(_: MEGASdk, transfer: MEGATransfer, error _: MEGAError) {
        if currentNode?.handle == transfer.nodeHandle,
           let transferPath = transfer.path,
            FileManager.default.fileExists(atPath: transferPath),
           transfer.appData != TransferMetaDataEntity.saveInPhotos.rawValue {
            imageView.sd_setImage(with: URL(fileURLWithPath: transferPath))
            downloadGifIcon.isHidden = true
        }
    }
}

open class ChatMediaCollectionViewSizeCalculator: MessageSizeCalculator {
    let cell = ChatMediaCollectionViewCell()

    override public init(layout: MessagesCollectionViewFlowLayout? = nil) {
        super.init(layout: layout)
        configureAccessoryView()
    }

    open override func messageContainerMaxWidth(for message: any MessageType, at indexPath: IndexPath) -> CGFloat {
       min(UIDevice.current.mnz_maxSideForChatBubble(withMedia: true), super.messageContainerMaxWidth(for: message, at: indexPath))
    }

    open override func messageContainerSize(for message: any MessageType, at indexPath: IndexPath) -> CGSize {
        switch message.kind {
        case .custom:
            let maxWidth = min(UIDevice.current.mnz_maxSideForChatBubble(withMedia: true), messageContainerMaxWidth(for: message, at: indexPath))
            let maxHeight = UIDevice.current.mnz_maxSideForChatBubble(withMedia: true)
            guard let chatMessage = message as? ChatMessage else {
                return .zero
            }

            var width: CGFloat = 200
            var height: CGFloat = 200

            if let transfer = chatMessage.transfer, let transferPath = transfer.path {
                let path = NSHomeDirectory().append(pathComponent: transferPath)

                if FileManager.default.fileExists(atPath: path) {
                    guard let previewImage = UIImage(contentsOfFile: path) else {
                        return CGSize(width: max(width, 0), height: height)
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

            return CGSize(width: max(width, 0), height: height)
        default:
            fatalError("messageContainerSize received unhandled MessageDataType: \(message.kind)")
        }
    }
}
