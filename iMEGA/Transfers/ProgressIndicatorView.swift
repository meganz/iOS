import UIKit

class ProgressIndicatorView: UIView, MEGATransferDelegate, MEGAGlobalDelegate, MEGARequestDelegate {
    var backgroundLayer: CAShapeLayer?
    var progressBackgroundLayer: CAShapeLayer?
    var progressLayer: CAShapeLayer?
    var arrowImageView: UIImageView = UIImageView(image: #imageLiteral(resourceName: "transfersDownload"))
    var stateBadge: UIImageView = UIImageView()
    var transferStatus: Int?
    var transfers = [MEGATransfer]()
    var transfersDic = [Int: MEGATransfer]()
    var transfersPaused: Bool {
        get {
            UserDefaults.standard.bool(forKey: "TransfersPaused")
        }
    }
    
    private var isWidgetForbidden = false
    @objc var overquota = false {
        didSet {
            configureData()
        }
    }
    
    @objc var progress: CGFloat = 0 {
        didSet {
            guard let progressLayer = progressLayer else {
                return
            }
            
            if progress > 1.0 {
                progressLayer.strokeEnd = 1.0
            } else if progress < 0.0 {
                progressLayer.strokeEnd = 0.0
            } else {
                progressLayer.strokeEnd = progress
            }
        }
    }
    
    @objc func animate(progress: CGFloat, duration: TimeInterval) {
        guard let progressLayer = progressLayer else {
            return
        }
        progressLayer.removeAnimation(forKey: "strokeEnd")
        
        CATransaction.begin()
        let animation = CABasicAnimation(keyPath: "strokeEnd")
        animation.duration = duration
        animation.fromValue = self.progress
        animation.fillMode = .both // keep to value after finishing
        animation.isRemovedOnCompletion = false // don't remove after finishing
        animation.toValue = progress
        CATransaction.setCompletionBlock {
            self.progress = progress
            progressLayer.removeAnimation(forKey: "strokeEnd")
            
        }
        progressLayer.add(animation, forKey: "strokeEnd")
        CATransaction.commit()
    }
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        configureData()
        configureLayers()
        configureView()
        configureDelegate()
    }
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
        configureLayers()
        configureView()
    }
    
    override func traitCollectionDidChange(_ previousTraitCollection: UITraitCollection?) {
        if #available(iOS 13.0, *) {
            if traitCollection.hasDifferentColorAppearance(comparedTo: previousTraitCollection) {
                updateAppearance()
            }
        }
    }
    
    // MARK: - Private
    
    private func updateAppearance() {
        backgroundLayer?.fillColor = UIColor.mnz_secondaryBackgroundElevated(traitCollection).cgColor
        if #available(iOS 13.0, *) {
            switch traitCollection.userInterfaceStyle {
            case .unspecified, .light:
                progressBackgroundLayer?.strokeColor = #colorLiteral(red: 0, green: 0, blue: 0, alpha: 0.05)
                
            case .dark:
                progressBackgroundLayer?.strokeColor = #colorLiteral(red: 0, green: 0, blue: 0, alpha: 0.33)
                
            @unknown default:
                progressBackgroundLayer?.strokeColor = #colorLiteral(red: 0, green: 0, blue: 0, alpha: 0.05)
                
            }
        } else {
            progressBackgroundLayer?.strokeColor = #colorLiteral(red: 0, green: 0, blue: 0, alpha: 0.05)
            
        }
    }
    
    private func configureView() {
        addSubview(arrowImageView)
        arrowImageView.autoSetDimensions(to: CGSize(width: 28, height: 28))
        arrowImageView.autoCenterInSuperview()
        arrowImageView.contentMode = .scaleToFill
        
        addSubview(stateBadge)
        stateBadge.autoSetDimensions(to: CGSize(width: 12, height: 12))
        
        stateBadge.autoPinEdge(.right, to: .right, of: arrowImageView)
        stateBadge.autoPinEdge(.top, to: .top, of: arrowImageView)
        
        if transfersPaused {
            stateBadge.image = #imageLiteral(resourceName: "Combined Shape")
        } else {
             stateBadge.image = nil
        }
         
        updateProgress()

    }
    
    private func configureLayers() {
        addBackgroundLayer()
        addProgressBackgroundLayer()
        addProgressLayer()
    }
    
    private func configureDelegate() {
        MEGASdkManager.sharedMEGASdk().add(self as MEGARequestDelegate)
        MEGASdkManager.sharedMEGASdk().add(self as MEGATransferDelegate)
    }
    
    private func updateProgress() {
        let transferedBytes = MEGASdkManager.sharedMEGASdk().totalsDownloadedBytes.floatValue + MEGASdkManager.sharedMEGASdk().totalsUploadedBytes.floatValue
        
        let totalBytes = MEGASdkManager.sharedMEGASdk().totalsDownloadBytes.floatValue + MEGASdkManager.sharedMEGASdk().totalsUploadBytes.floatValue
        
        progress = CGFloat(transferedBytes / totalBytes)
        
    }
    
    @objc func showWidgetIfNeeded() {
        isWidgetForbidden = false
        configureData()
    }
    
    @objc func hideWidget() {
        isWidgetForbidden = true
        self.isHidden = true
    }
    
    @objc func configureData() {
        if isWidgetForbidden {
            self.isHidden = true
            return
        }
        
        transfers.removeAll()
        var transferList = MEGASdkManager.sharedMEGASdk().transfers
        if ((transferList.size.intValue) != 0) {
            transfers.append(contentsOf: transferList.mnz_transfersArrayFromTranferList())
        }
        transferList =  MEGASdkManager.sharedMEGASdkFolder().transfers
        if ((transferList.size.intValue) != 0) {
            transfers.append(contentsOf: transferList.mnz_transfersArrayFromTranferList())
        }
        
        let failedTransfer = MEGASdkManager.sharedMEGASdk().completedTransfers.first(where: { (transfer) -> Bool in
            guard let transfer = transfer as? MEGATransfer else {
                return false
            }
            return transfer.state != .complete && transfer.state != .cancelled
        })
        
        if let failedTransfer = failedTransfer as? MEGATransfer {
            if failedTransfer.lastErrorExtended.type == .apiEOverQuota {
                stateBadge.image = #imageLiteral(resourceName: "overquota")
            } else if failedTransfer.lastErrorExtended.type != .apiOk {
                stateBadge.image = #imageLiteral(resourceName: "errorBadge")
            }
        } else {
            stateBadge.image = nil
        }
        
        if transfers.count > 0 {
            self.isHidden = false
            self.alpha = 1
            self.progressLayer?.strokeColor = #colorLiteral(red: 0, green: 0.6588235294, blue: 0.5254901961, alpha: 1)
            let hasDownloadTransfer = transfers.contains { (transfer) -> Bool in
                return transfer.type == .download
            }
            arrowImageView.image = hasDownloadTransfer ? #imageLiteral(resourceName: "transfersDownload") : #imageLiteral(resourceName: "transfersUpload")
            if overquota {
                stateBadge.image = #imageLiteral(resourceName: "overquota")
                self.progressLayer?.strokeColor = #colorLiteral(red: 1, green: 0.8, blue: 0, alpha: 1)
            } else if transfersPaused {
                stateBadge.image = #imageLiteral(resourceName: "Combined Shape")
            }
        } else {
            if (MEGASdkManager.sharedMEGASdk().completedTransfers.count) > 0 {
                progress = 1
                self.isHidden = false
                
                if let failedTransfer = failedTransfer as? MEGATransfer {
                    if failedTransfer.lastErrorExtended.type == .apiEOverQuota {
                        stateBadge.image = #imageLiteral(resourceName: "overquota")
                        self.progressLayer?.strokeColor = #colorLiteral(red: 1, green: 0.8, blue: 0, alpha: 1)
                    } else if failedTransfer.lastErrorExtended.type != .apiOk {
                        stateBadge.image = #imageLiteral(resourceName: "errorBadge")
                        self.progressLayer?.strokeColor = #colorLiteral(red: 1, green: 0.231372549, blue: 0.1882352941, alpha: 1)
                    }
                } else {
                    stateBadge.image = #imageLiteral(resourceName: "completedBadge")
                    self.progressLayer?.strokeColor = #colorLiteral(red: 0, green: 0.6588235294, blue: 0.5254901961, alpha: 1)
                    dismissWidget()
                }
                
            } else {
                self.isHidden = true
            }
        }
    }
    
    private func addBackgroundLayer() {
        let shapeLayer = circlularLayer(withRect: bounds,
                                        insetSize: CGSize(width: 5, height: 5))
        shapeLayer.fillColor = UIColor.mnz_secondaryBackgroundElevated(traitCollection).cgColor
        shapeLayer.shadowRadius = 16
        shapeLayer.shadowOpacity = 0.2
        shapeLayer.shadowColor = #colorLiteral(red: 0.01568627451, green: 0.01568627451, blue: 0.05882352941, alpha: 1)
        shapeLayer.shadowOffset = CGSize(width: 0, height: 2)
        
        layer.addSublayer(shapeLayer)
        self.backgroundLayer = shapeLayer
    }
    
    private func addProgressBackgroundLayer() {
        let shapeLayer = circlularLayer(withRect: bounds,
                                        insetSize: CGSize(width: 10, height: 10))
        shapeLayer.strokeColor = #colorLiteral(red: 0, green: 0, blue: 0, alpha: 0.05)
        shapeLayer.fillColor = #colorLiteral(red: 0, green: 0, blue: 0, alpha: 0)
        shapeLayer.lineWidth = 2
        
        layer.addSublayer(shapeLayer)
        self.progressBackgroundLayer = shapeLayer
    }
    
    private func addProgressLayer() {
        let shapeLayer = circlularLayer(withRect: bounds,
                                        insetSize: CGSize(width: 10, height: 10))
        shapeLayer.strokeColor = #colorLiteral(red: 0, green: 0.6588235294, blue: 0.5254901961, alpha: 1)
        shapeLayer.fillColor = #colorLiteral(red: 0, green: 0, blue: 0, alpha: 0)
        shapeLayer.lineWidth = 2
        shapeLayer.strokeEnd = 0.0
        layer.addSublayer(shapeLayer)
        self.progressLayer = shapeLayer
    }
    
    private func circlularLayer(withRect rect: CGRect,
                                insetSize size: CGSize) -> CAShapeLayer {
        
        let shapeLayer = CAShapeLayer()
        
        shapeLayer.path = UIBezierPath(roundedRect: rect.insetBy(dx: size.width, dy: size.height), cornerRadius: rect.width).cgPath
        
        return shapeLayer
    }
    
    @objc func dismissWidget() {
        DispatchQueue.main.asyncAfter(deadline: .now() + 6) {
            guard self.transfers.count == 0 else {
                self.showWidgetIfNeeded()
                return
            }
            
            UIView.animate(withDuration: 0.5, animations: {
                self.alpha = 0
            }, completion: { _ in
                self.progress = 0
            })
        }
    }
    
    func onTransferStart(_ api: MEGASdk, transfer: MEGATransfer) {
        if transfer.type == .download {
            overquota = false
        }
        configureData()
    }
    
    func onTransferUpdate(_ api: MEGASdk, transfer: MEGATransfer) {
        updateProgress()
    }
    
    func onTransferFinish(_ api: MEGASdk, transfer: MEGATransfer, error: MEGAError) {
        MEGASdkManager.sharedMEGASdk().completedTransfers.add(transfer)

        if MEGASdkManager.sharedMEGASdk().transfers.size.intValue == 0 {
            MEGASdkManager.sharedMEGASdk().resetTotalUploads()
            MEGASdkManager.sharedMEGASdk().resetTotalDownloads()
            configureData()
        }
    }
    
    func onTransferTemporaryError(_ api: MEGASdk, transfer: MEGATransfer, error: MEGAError) {
        if error.type == .apiEOverQuota || error.type == .apiEgoingOverquota {
            overquota = true
        }
    }

    func onRequestFinish(_ api: MEGASdk, request: MEGARequest, error: MEGAError) {
        if error.type != .apiOk {
            switch error.type {
            case .apiEgoingOverquota, .apiEOverQuota:
                overquota = true
                break
            default:
                break
            }
            
            return
        }
        if request.type == .MEGARequestTypePauseTransfers {
            if request.flag {
                stateBadge.image = #imageLiteral(resourceName: "Combined Shape")
            } else {
                configureData()
            }
            
        }
        
    }
}
