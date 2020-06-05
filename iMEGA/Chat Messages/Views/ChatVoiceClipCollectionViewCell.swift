import MessageKit

class ChatVoiceClipCollectionViewCell: AudioMessageCell {

    open var waveView: UIImageView = {

        var imageData:[UIImage] = []
        for i in 0...59 {
            let name = "waveform_000\(i)"
            guard let data = UIImage(named: name)?.withRenderingMode(.alwaysTemplate) else {
                return YYAnimatedImageView()
            }
            imageData.append(data)
        }
        let waveView = UIImageView(image: UIImage(named: "waveform_0000"))
        waveView.animationImages = imageData
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
        waveView.tintColor = textColor
        loadingIndicator.color = textColor
        
        guard chatMessage.transfer != nil else {
            guard let nodeList = megaMessage.nodeList, let node = nodeList.node(at: 0) else { return }
                let duration = max(node.duration, 0)
                durationLabel.text = NSString.mnz_string(fromTimeInterval: TimeInterval(duration))
                let nodePath = node.mnz_temporaryPath(forDownloadCreatingDirectories: true)
                if !FileManager.default.fileExists(atPath: nodePath) {
                    MEGASdkManager.sharedMEGASdk()?.startDownloadTopPriority(with: node, localPath: nodePath, appData: nil, delegate: MEGAStartDownloadTransferDelegate(progress: nil, completion: { (transfer) in
                        let visibleIndexPaths = messagesCollectionView.indexPathsForVisibleItems
                        guard visibleIndexPaths.contains(indexPath) else {
                            return
                        }
                        
                        messagesCollectionView.reloadItems(at: [indexPath])
                    }, onError: nil))
                }
            
            loadingIndicator.isHidden = true
            playButton.isHidden = false
            return
        }
        loadingIndicator.startAnimating()
        loadingIndicator.isHidden = false
        playButton.isHidden = true
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
