import MessageKit

class ChatVoiceClipCollectionViewCell: MessageContentCell {
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
    
    open var durationLabel: MessageLabel = {
        let label = MessageLabel()
        return label
    }()
    
    // MARK: - Methods
    
    /// Responsible for setting up the constraints of the cell's subviews.
    open func setupConstraints() {
        playIconView.autoPinEdge(toSuperviewEdge: .leading, withInset: 10)
        playIconView.autoAlignAxis(toSuperviewAxis: .horizontal)
        playIconView.autoSetDimensions(to: CGSize(width: 20, height: 20))

        durationLabel.autoPinEdge(.leading, to: .trailing, of: playIconView, withOffset: 10)
        durationLabel.autoPinEdge(.trailing, to: .leading, of: waveView, withOffset: 10)
        durationLabel.autoAlignAxis(toSuperviewAxis: .horizontal)
        
        waveView.autoPinEdge(toSuperviewEdge: .trailing, withInset: 10)
        waveView.autoAlignAxis(toSuperviewAxis: .horizontal)
        waveView.autoSetDimensions(to: CGSize(width: 55, height: 33))


    }
    
    open override func setupSubviews() {
        super.setupSubviews()
        messageContainerView.addSubview(durationLabel)
        messageContainerView.addSubview(playIconView)
        messageContainerView.addSubview(waveView)
        setupConstraints()
    }
    
    override func configure(with message: MessageType, at indexPath: IndexPath, and messagesCollectionView: MessagesCollectionView) {
        durationLabel.configure {
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
            
            let node = megaMessage.nodeList.node(at: 0)!
            let duration = max(node.duration, 0)
            durationLabel.text = NSString.mnz_string(fromTimeInterval: TimeInterval(duration))
            
            let nodePath = node.mnz_temporaryPath(forDownloadCreatingDirectories: true)
            if !FileManager.default.fileExists(atPath: nodePath!) {
                MEGASdkManager.sharedMEGASdk()?.startDownloadTopPriority(with: node, localPath: nodePath!, appData: nil, delegate: MEGAStartDownloadTransferDelegate(progress: nil, completion: { (transfer) in
                    messagesCollectionView.reloadItems(at: [indexPath])

                }, onError: nil))
            }
        }
    }
}

open class ChatVoiceClipCollectionViewSizeCalculator: MessageSizeCalculator {
    open override func messageContainerSize(for message: MessageType) -> CGSize {
        return CGSize(width: 170, height: 50)
    }
}
