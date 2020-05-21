import MessageKit

class ChatVoiceClipCollectionViewCell: AudioMessageCell {
    open var playIconView: UIImageView = {
        let playIconView = UIImageView(image: UIImage(named: "playButton"))
        playIconView.frame = CGRect(x: 0, y: 0, width: 20, height: 20)
        return playIconView
    }()
    
    open var waveView: UIImageView = {
        let waveView = UIImageView(image: UIImage(named: "voiceWave"))
        waveView.frame = CGRect(x: 0, y: 0, width: 55, height: 33)
        return waveView
    }()
    
    // MARK: - Methods
    
    
    open override func setupSubviews() {
        super.setupSubviews()
    
        playButton.setImage(UIImage(named: "playButton"), for: .normal)
        setupConstraints()
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
        durationLabel.textColor = textColor
        progressView.trackTintColor = .lightGray
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
        return CGSize(width: 170, height: 50)
    }
}
