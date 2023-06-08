import MessageKit
import CoreGraphics

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
        let waveView = UIImageView(image: Asset.Images.Chat.Wave.waveform0000.image)
        waveView.animationDuration = 1
        waveView.frame = CGRect(origin: CGPoint(x: 0, y: 0), size: Dimensions.waveViewSize)
        return waveView
    }()
    
    open var loadingIndicator: UIActivityIndicatorView = {
        let loadingIndicator = UIActivityIndicatorView()
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
        playButton.autoPinEdge(toSuperviewEdge: .leading, withInset: Dimensions.itemSpacing)
        playButton.autoAlignAxis(toSuperviewAxis: .horizontal)
        playButton.autoSetDimensions(to: Dimensions.playButtonSize)
        durationLabel.autoPinEdge(.leading, to: .trailing, of: playButton, withOffset: Dimensions.itemSpacing)
        durationLabel.autoPinEdge(.trailing, to: .leading, of: waveView, withOffset: Dimensions.itemSpacing)
        durationLabel.autoAlignAxis(toSuperviewAxis: .horizontal)
        
        waveView.autoPinEdge(toSuperviewEdge: .trailing, withInset: Dimensions.itemSpacing)
        waveView.autoAlignAxis(toSuperviewAxis: .horizontal)
        waveView.autoSetDimensions(to: Dimensions.waveViewSize)

        loadingIndicator.autoPinEdge(.left, to: .left, of: playButton)
        loadingIndicator.autoPinEdge(.right, to: .right, of: playButton)
        loadingIndicator.autoPinEdge(.top, to: .top, of: playButton)
        loadingIndicator.autoPinEdge(.bottom, to: .bottom, of: playButton)
    }
    
    open override func setupSubviews() {
        messageContainerView.addSubview(waveView)
        messageContainerView.addSubview(loadingIndicator)
        super.setupSubviews()
        playButton.setImage(Asset.Images.Chat.Messages.playVoiceClip.image.withRenderingMode(.alwaysTemplate), for: .normal)
        playButton.setImage(Asset.Images.Chat.Messages.pauseVoiceClip.image.withRenderingMode(.alwaysTemplate), for: .selected)
        progressView.isHidden = true
        durationLabel.textAlignment = .left
        durationLabel.font = .preferredFont(forTextStyle: .subheadline)
        durationLabel.adjustsFontForContentSizeCategory = true
    }
    
    override func configure(with message: MessageType, at indexPath: IndexPath, and messagesCollectionView: MessagesCollectionView) {
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
        var imageData:[UIImage] = []
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
        incomingMessageBottomLabelAlignment = LabelAlignment(textAlignment: .left, textInsets:  UIEdgeInsets(top: 0, left: 34, bottom: 0, right: 0))
    }
    
    open override func messageContainerSize(for message: MessageType) -> CGSize {
        let fitSize = CGSize(width: messageContainerMaxWidth(for: message), height: .greatestFiniteMagnitude)
        return calculateDynamicSize(for: message, fitSize: fitSize)
    }
    
    private func calculateDynamicSize(for message: MessageType, fitSize: CGSize) -> CGSize {
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
