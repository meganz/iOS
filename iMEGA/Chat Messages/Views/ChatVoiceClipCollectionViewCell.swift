import CoreGraphics
import MEGADesignToken
import MessageKit

class ChatVoiceClipCollectionViewCell: AudioMessageCell {
    struct Dimensions {
        static var waveViewSize = CGSize(width: 42, height: 25)
        static var playButtonSize = CGSize(width: 15, height: 15)
        static var itemSpacing: CGFloat = 10
        static var containerDefaultHeight: CGFloat = 40
    }
    
    var currentNode: MEGANode?
    weak var messagesCollectionView: MessagesCollectionView?

    open var waveView: UIImageView = {
        let waveView = UIImageView(image: UIImage(resource: .waveform0000))
        waveView.translatesAutoresizingMaskIntoConstraints = false
        waveView.animationDuration = 1
        waveView.frame = CGRect(origin: CGPoint(x: 0, y: 0), size: Dimensions.waveViewSize)
        return waveView
    }()
    
    open var loadingIndicator: UIActivityIndicatorView = {
        let loadingIndicator = UIActivityIndicatorView()
        loadingIndicator.translatesAutoresizingMaskIntoConstraints = false
        loadingIndicator.startAnimating()
        loadingIndicator.isHidden = true
        return loadingIndicator
    }()
    
    // MARK: - Methods
    
    override public init(frame: CGRect) {
        super.init(frame: frame)
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func setupConstraints() {        
        playButton.translatesAutoresizingMaskIntoConstraints = false
        
        NSLayoutConstraint.activate([
            playButton.leadingAnchor.constraint(equalTo: messageContainerView.leadingAnchor, constant: Dimensions.itemSpacing),
            playButton.centerYAnchor.constraint(equalTo: messageContainerView.centerYAnchor),
            playButton.widthAnchor.constraint(equalToConstant: Dimensions.playButtonSize.width),
            playButton.heightAnchor.constraint(equalToConstant: Dimensions.playButtonSize.height)
        ])
        
        durationLabel.translatesAutoresizingMaskIntoConstraints = false

        NSLayoutConstraint.activate([
            durationLabel.leadingAnchor.constraint(equalTo: playButton.trailingAnchor, constant: Dimensions.itemSpacing),
            durationLabel.trailingAnchor.constraint(equalTo: waveView.leadingAnchor, constant: -Dimensions.itemSpacing),
            durationLabel.centerYAnchor.constraint(equalTo: messageContainerView.centerYAnchor)
        ])
        
        NSLayoutConstraint.activate([
            waveView.trailingAnchor.constraint(equalTo: messageContainerView.trailingAnchor, constant: -Dimensions.itemSpacing),
            waveView.centerYAnchor.constraint(equalTo: messageContainerView.centerYAnchor),
            waveView.widthAnchor.constraint(equalToConstant: Dimensions.waveViewSize.width),
            waveView.heightAnchor.constraint(equalToConstant: Dimensions.waveViewSize.height)
        ])
        
        NSLayoutConstraint.activate([
            loadingIndicator.leadingAnchor.constraint(equalTo: playButton.leadingAnchor),
            loadingIndicator.trailingAnchor.constraint(equalTo: playButton.trailingAnchor),
            loadingIndicator.topAnchor.constraint(equalTo: playButton.topAnchor),
            loadingIndicator.bottomAnchor.constraint(equalTo: playButton.bottomAnchor)
        ])
    }
    
    open override func setupSubviews() {
        messageContainerView.addSubview(waveView)
        messageContainerView.addSubview(loadingIndicator)
        super.setupSubviews()
        playButton.setImage(UIImage(resource: .playVoiceClip).withRenderingMode(.alwaysTemplate), for: .normal)
        playButton.setImage(UIImage(resource: .pauseVoiceClip).withRenderingMode(.alwaysTemplate), for: .selected)
        progressView.isHidden = true
        durationLabel.textAlignment = .left
        durationLabel.font = .preferredFont(forTextStyle: .subheadline)
        durationLabel.adjustsFontForContentSizeCategory = true
    }
    
    override func configure(with message: any MessageType, at indexPath: IndexPath, and messagesCollectionView: MessagesCollectionView) {
        super.configure(with: message, at: indexPath, and: messagesCollectionView)
        guard let chatMessage = message as? ChatMessage else {
            return
        }
        self.messagesCollectionView = messagesCollectionView
        let megaMessage = chatMessage.message
        
        guard let displayDelegate = messagesCollectionView.messagesDisplayDelegate else {
            return
            
        }
        
        let textColor = displayDelegate.textColor(for: message, at: indexPath, in: messagesCollectionView)
        messageContainerView.tintColor = textColor
        durationLabel.textColor = textColor
        progressView.trackTintColor = .lightGray
        var imageData: [UIImage] = []
        for i in 0...59 {
            let name = "waveform_000\(i)"
            guard let data = UIImage(named: name)?.withRenderingMode(.alwaysTemplate).withTintColor(textColor) else {
                return
            }
            imageData.append(data)
        }
        waveView.animationImages = imageData
        
        loadingIndicator.color = textColor
        
        if let transfer = chatMessage.transfer {
            if transfer.type == .download {
                guard let nodeList = megaMessage.nodeList, let currentNode = nodeList.node(at: 0) else { return }
                self.currentNode = currentNode
                let duration = max(currentNode.duration, 0)
                durationLabel.text = TimeInterval(duration).timeString
                if transfer.state.rawValue < MEGATransferState.complete.rawValue {
                    configureLoadingView()
                } else {
                    configureLoadedView()
                }
            } else if let path = transfer.path {
                guard FileManager.default.fileExists(atPath: path) else {
                    MEGALogInfo("Failed to create audio player for URL: \(path)")
                    return
                }
                let asset = AVAsset(url: URL(fileURLWithPath: path))
                durationLabel.text = CMTimeGetSeconds(asset.duration).timeString
            }
        } else {
            guard let nodeList = megaMessage.nodeList, let currentNode = nodeList.node(at: 0) else { return }
            self.currentNode = currentNode
            let duration = max(currentNode.duration, 0)
            durationLabel.text = TimeInterval(duration).timeString
            let nodePath = currentNode.mnz_voiceCachePath()
            if !FileManager.default.fileExists(atPath: nodePath) {
                let appData = NSString().mnz_appDataToDownloadAttach(toMessageID: megaMessage.messageId)
                MEGASdk.shared.startDownloadNode(
                    currentNode,
                    localPath: nodePath,
                    fileName: nil,
                    appData: appData,
                    startFirst: true,
                    cancelToken: nil,
                    collisionCheck: CollisionCheck.fingerprint,
                    collisionResolution: CollisionResolution.newWithN
                )
                configureLoadingView()
            } else {
                configureLoadedView()
            }
        }
        
        let buttonColor = isFromCurrentSender(message: message) ? TokenColors.Icon.inverse : TokenColors.Icon.primary
        let playButtonImage = UIImage(resource: .playVoiceClipButton).withTintColor(buttonColor, renderingMode: .alwaysTemplate)
        let pauseButtonImage = UIImage(resource: .pauseVoiceClip).withTintColor(buttonColor, renderingMode: .alwaysTemplate)
        playButton.setImage(playButtonImage, for: .normal)
        playButton.setImage(pauseButtonImage, for: .selected)
    }
    
    private func configureLoadingView() {
        loadingIndicator.startAnimating()
        loadingIndicator.isHidden = false
        playButton.isHidden = true
    }
     
    private func configureLoadedView() {
        loadingIndicator.stopAnimating()
        loadingIndicator.isHidden = true
        playButton.isHidden = false
    }
    
    private func isFromCurrentSender(message: any MessageType) -> Bool {
        return UInt64(message.sender.senderId) == MEGAChatSdk.shared.myUserHandle
    }
}

open class ChatVoiceClipCollectionViewSizeCalculator: MessageSizeCalculator {
    lazy var calculateDurationLabel: UILabel = {
        let titleLabel = UILabel()
        return titleLabel
    }()
    
    public override init(layout: MessagesCollectionViewFlowLayout? = nil) {
        super.init(layout: layout)
        configureAccessoryView()
        outgoingMessageBottomLabelAlignment = LabelAlignment(textAlignment: .right, textInsets: UIEdgeInsets(top: 0, left: 0, bottom: 0, right: 8))
        incomingMessageBottomLabelAlignment = LabelAlignment(textAlignment: .left, textInsets: UIEdgeInsets(top: 0, left: 34, bottom: 0, right: 0))
    }
    
    open override func messageContainerSize(for message: any MessageType) -> CGSize {
        let fitSize = CGSize(width: messageContainerMaxWidth(for: message), height: .greatestFiniteMagnitude)
        return calculateDynamicSize(for: message, fitSize: fitSize)
    }
    
    private func calculateDynamicSize(for message: some MessageType, fitSize: CGSize) -> CGSize {
        calculateDurationLabel.textAlignment = .left
        calculateDurationLabel.font = .preferredFont(forTextStyle: .subheadline)
        calculateDurationLabel.text = "00:00"
        
        let durationLabelSize = calculateDurationLabel.sizeThatFits(fitSize)
        
        return CGSize(width:
                        ChatVoiceClipCollectionViewCell.Dimensions.itemSpacing
                      + ChatVoiceClipCollectionViewCell.Dimensions.playButtonSize.width
                      + ChatVoiceClipCollectionViewCell.Dimensions.itemSpacing
                      + durationLabelSize.width
                      + ChatVoiceClipCollectionViewCell.Dimensions.itemSpacing
                      + ChatVoiceClipCollectionViewCell.Dimensions.waveViewSize.width
                      + ChatVoiceClipCollectionViewCell.Dimensions.itemSpacing,
                      height:
                        max(ChatVoiceClipCollectionViewCell.Dimensions.containerDefaultHeight,
                            durationLabelSize.height))
    }
}
