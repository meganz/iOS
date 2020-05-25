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
    
    
    // MARK: - Methods
    override func setupConstraints() {
//        super.setupConstraints()
        playButton.autoPinEdge(toSuperviewEdge: .leading, withInset: 10)
        playButton.autoAlignAxis(toSuperviewAxis: .horizontal)
        playButton.autoSetDimensions(to: CGSize(width: 20, height: 20))
        
        durationLabel.autoPinEdge(.leading, to: .trailing, of: playButton, withOffset: 10)
        durationLabel.autoPinEdge(.trailing, to: .leading, of: waveView, withOffset: 10)
        durationLabel.autoAlignAxis(toSuperviewAxis: .horizontal)
        
        waveView.autoPinEdge(toSuperviewEdge: .trailing, withInset: 10)
        waveView.autoAlignAxis(toSuperviewAxis: .horizontal)
        waveView.autoSetDimensions(to: CGSize(width: 42, height: 25))

//        waveView.autoPinEdge(.leading, to: .trailing, of: playButton, withOffset: 5)
//        waveView.autoPinEdge(.trailing, to: .leading, of: durationLabel, withOffset: 5)
//        waveView.autoAlignAxis(toSuperviewAxis: .horizontal)
    }
    
    open override func setupSubviews() {
        messageContainerView.addSubview(waveView)
        super.setupSubviews()
        playButton.setImage(UIImage(named: "playButton")?.withRenderingMode(.alwaysTemplate), for: .normal)
//        playButton.setImage(UIImage(named: "PauseButton")?.withRenderingMode(.alwaysTemplate), for: .selected)
        progressView.isHidden = true
        durationLabel.textAlignment = .left
    }
    
    override func configure(with message: MessageType, at indexPath: IndexPath, and messagesCollectionView: MessagesCollectionView) {
        //        durationLabel.configure {
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
        let node = megaMessage.nodeList.node(at: 0)!
        let duration = max(node.duration, 0)
        durationLabel.text = NSString.mnz_string(fromTimeInterval: TimeInterval(duration))
        let nodePath = node.mnz_temporaryPath(forDownloadCreatingDirectories: true)
        if !FileManager.default.fileExists(atPath: nodePath) {
            MEGASdkManager.sharedMEGASdk()?.startDownloadTopPriority(with: node, localPath: nodePath, appData: nil, delegate: MEGAStartDownloadTransferDelegate(progress: nil, completion: { (transfer) in
                messagesCollectionView.reloadItems(at: [indexPath])
            }, onError: nil))
        }
    }
}

open class ChatVoiceClipCollectionViewSizeCalculator: MessageSizeCalculator {
    public override init(layout: MessagesCollectionViewFlowLayout? = nil) {
        super.init(layout: layout)
        configureAccessoryView()
    }
    
    open override func messageContainerSize(for message: MessageType) -> CGSize {
        return CGSize(width: 140, height: 50)
    }
}
