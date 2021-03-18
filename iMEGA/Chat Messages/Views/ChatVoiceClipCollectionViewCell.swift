import MessageKit

class ChatVoiceClipCollectionViewCell: AudioMessageCell {
    
    var currentNode: MEGANode?
    lazy var transferDelegate: MEGAStartDownloadTransferDelegate = {
        return MEGAStartDownloadTransferDelegate(progress: nil, completion: { [weak self] (transfer) in
            if self?.currentNode?.handle == transfer?.nodeHandle {
                if let transfer = transfer, transfer.path != nil, FileManager.default.fileExists(atPath: transfer.path) {
                    self?.configureLoadedView()
                }
            }
        }, onError: nil)
    }()
    
    open var waveView: UIImageView = {
        let waveView = UIImageView(image: UIImage(named: "waveform_0000"))
        waveView.animationDuration = 1
        waveView.frame = CGRect(x: 0, y: 0, width: 42, height: 25)
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
        MEGASdkManager.sharedMEGASdk().add(transferDelegate)
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func setupConstraints() {
        playButton.autoPinEdge(toSuperviewEdge: .leading, withInset: 10)
        playButton.autoAlignAxis(toSuperviewAxis: .horizontal)
        playButton.autoSetDimensions(to: CGSize(width: 15, height: 15))
        durationLabel.autoPinEdge(.leading, to: .trailing, of: playButton, withOffset: 10)
        durationLabel.autoPinEdge(.trailing, to: .leading, of: waveView, withOffset: 10)
        durationLabel.autoAlignAxis(toSuperviewAxis: .horizontal)
        
        waveView.autoPinEdge(toSuperviewEdge: .trailing, withInset: 10)
        waveView.autoAlignAxis(toSuperviewAxis: .horizontal)
        waveView.autoSetDimensions(to: CGSize(width: 42, height: 25))

        loadingIndicator.autoPinEdge(.left, to: .left, of: playButton)
        loadingIndicator.autoPinEdge(.right, to: .right, of: playButton)
        loadingIndicator.autoPinEdge(.top, to: .top, of: playButton)
        loadingIndicator.autoPinEdge(.bottom, to: .bottom, of: playButton)
    }
    
    open override func setupSubviews() {
        messageContainerView.addSubview(waveView)
        messageContainerView.addSubview(loadingIndicator)
        super.setupSubviews()
        playButton.setImage(UIImage(named: "playVoiceClip")?.withRenderingMode(.alwaysTemplate), for: .normal)
        playButton.setImage(UIImage(named: "pauseVoiceClip")?.withRenderingMode(.alwaysTemplate), for: .selected)
        progressView.isHidden = true
        durationLabel.textAlignment = .left
        durationLabel.font = UIFont.systemFont(ofSize: 15)
    }
    
    override func configure(with message: MessageType, at indexPath: IndexPath, and messagesCollectionView: MessagesCollectionView) {
        super.configure(with: message, at: indexPath, and: messagesCollectionView)
        guard let chatMessage = message as? ChatMessage else {
            return
        }
        
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
            guard let data = UIImage(named: name)?.withRenderingMode(.alwaysTemplate).byTintColor(textColor) else {
                return
            }
            imageData.append(data)
        }
        waveView.animationImages = imageData
        
        loadingIndicator.color = textColor
        
        if let transfer = chatMessage.transfer {
            if transfer.type == .download {
                configureLoadingView()
            } else if let path = transfer.path {
                guard FileManager.default.fileExists(atPath: path) else {
                    MEGALogInfo("Failed to create audio player for URL: \(path)")
                    return
                }
                let asset = AVAsset(url: URL(fileURLWithPath: path))
                durationLabel.text = NSString.mnz_string(fromTimeInterval: CMTimeGetSeconds(asset.duration))
            }
        } else {
            guard let nodeList = megaMessage.nodeList, let currentNode = nodeList.node(at: 0) else { return }
            let duration = max(currentNode.duration, 0)
            durationLabel.text = NSString.mnz_string(fromTimeInterval: TimeInterval(duration))
            let nodePath = currentNode.mnz_voiceCachePath()
            if !FileManager.default.fileExists(atPath: nodePath) {
                MEGASdkManager.sharedMEGASdk().startDownloadTopPriority(with: currentNode, localPath: nodePath, appData: nil, delegate: MEGAStartDownloadTransferDelegate(progress: nil, completion: { (transfer) in
                    let visibleIndexPaths = messagesCollectionView.indexPathsForVisibleItems
                    guard visibleIndexPaths.contains(indexPath) else {
                        return
                    }
                    
                    messagesCollectionView.reloadItems(at: [indexPath])
                }, onError: nil))
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
    
    deinit {
        MEGASdkManager.sharedMEGASdk().remove(transferDelegate)
    }
}

open class ChatVoiceClipCollectionViewSizeCalculator: MessageSizeCalculator {
    public override init(layout: MessagesCollectionViewFlowLayout? = nil) {
        super.init(layout: layout)
        configureAccessoryView()
    }
    
    open override func messageContainerSize(for message: MessageType) -> CGSize {
        return CGSize(width: 140, height: 40)
    }
}
