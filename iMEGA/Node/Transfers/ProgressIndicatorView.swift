import UIKit
import MEGAFoundation
import MEGADomain
import MEGAData

class ProgressIndicatorView: UIView, MEGATransferDelegate, MEGARequestDelegate {
    var backgroundLayer: CAShapeLayer?
    var progressBackgroundLayer: CAShapeLayer?
    var progressLayer: CAShapeLayer?
    var arrowImageView: UIImageView = UIImageView(image: Asset.Images.Transfers.transfersDownload.image)
    var stateBadge: UIImageView = UIImageView()
    var transferStatus: Int?
    var transfers = [TransferEntity]()
    var transfersPaused: Bool {
        UserDefaults.standard.bool(forKey: "TransfersPaused")
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
    
    private let throttler = Throttler(timeInterval: 1.0, dispatchQueue: .main)
    
    private let transferInventoryUseCase = TransferInventoryUseCase(transferInventoryRepository: TransferInventoryRepository(sdk: MEGASdkManager.sharedMEGASdk()), fileSystemRepository: FileSystemRepository.newRepo)
    private let sharedFolderTransferInventoryUseCase = TransferInventoryUseCase(transferInventoryRepository: TransferInventoryRepository(sdk: MEGASdkManager.sharedMEGASdkFolder()), fileSystemRepository: FileSystemRepository.newRepo)

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
        translatesAutoresizingMaskIntoConstraints = false
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
        super.traitCollectionDidChange(previousTraitCollection)
        if traitCollection.hasDifferentColorAppearance(comparedTo: previousTraitCollection) {
            updateAppearance()
        }
    }
    
    // MARK: - Private
    
    private func updateAppearance() {
        backgroundLayer?.fillColor = UIColor.mnz_secondaryBackgroundElevated(traitCollection).cgColor
        switch traitCollection.userInterfaceStyle {
        case .unspecified, .light:
            progressBackgroundLayer?.strokeColor = #colorLiteral(red: 0, green: 0, blue: 0, alpha: 0.05)
            
        case .dark:
            progressBackgroundLayer?.strokeColor = #colorLiteral(red: 0, green: 0, blue: 0, alpha: 0.33)
            
        @unknown default:
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
            stateBadge.image = Asset.Images.Transfers.Widget.Pause.combinedShape.image
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
        transfers = transferInventoryUseCase.transfers(filteringUserTransfers: true) + sharedFolderTransferInventoryUseCase.transfers(filteringUserTransfers: true)
        
        if let failedTransfer = transferInventoryUseCase.completedTransfers(filteringUserTransfers: true).first(where: { (transfer) -> Bool in
            return transfer.state != .complete && transfer.state != .cancelled
        }) {
            if let lastErrorExtended = failedTransfer.lastErrorExtended {
                if lastErrorExtended == .overquota {
                    stateBadge.image = Asset.Images.Transfers.Widget.overquota.image
                } else if lastErrorExtended != .generic {
                    stateBadge.image = Asset.Images.Transfers.Widget.Error.FileList.FileAcessory.errorBadge.image
                }
            } else {
                stateBadge.image = nil
            }
        } else {
            stateBadge.image = nil
        }
        
        if transfers.isNotEmpty {
            self.isHidden = false
            self.alpha = 1
            self.progressLayer?.strokeColor = #colorLiteral(red: 0, green: 0.6588235294, blue: 0.5254901961, alpha: 1)
            let hasDownloadTransfer = transfers.contains { (transfer) -> Bool in
                return transfer.type == .download
            }
            let hasUploadTransfer = transfers.contains { (transfer) -> Bool in
                return transfer.type == .upload
            }
            arrowImageView.image = hasDownloadTransfer ? Asset.Images.Transfers.transfersDownload.image : Asset.Images.Transfers.transfersUpload.image
            if overquota {
                stateBadge.image = Asset.Images.Transfers.Widget.overquota.image
                self.progressLayer?.strokeColor = hasUploadTransfer ? #colorLiteral(red: 0, green: 0.6588235294, blue: 0.5254901961, alpha: 1) : #colorLiteral(red: 1, green: 0.8, blue: 0, alpha: 1)
            } else if transfersPaused {
                stateBadge.image = Asset.Images.Transfers.Widget.Pause.combinedShape.image
            }
        } else {
            let completedTransfers = transferInventoryUseCase.completedTransfers(filteringUserTransfers: true)
            if (completedTransfers.count) > 0 {
                progress = 1
                self.isHidden = false
                
                if let failedTransfer = completedTransfers.first(where: { (transfer) -> Bool in
                    return transfer.state != .complete && transfer.state != .cancelled
                }) {
                    if let lastErrorExtended = failedTransfer.lastErrorExtended {
                        if lastErrorExtended == .overquota {
                            stateBadge.image = Asset.Images.Transfers.Widget.overquota.image
                            self.progressLayer?.strokeColor = #colorLiteral(red: 1, green: 0.8, blue: 0, alpha: 1)
                        } else if lastErrorExtended != .generic {
                            stateBadge.image = Asset.Images.Transfers.Widget.Error.FileList.FileAcessory.errorBadge.image
                            self.progressLayer?.strokeColor = #colorLiteral(red: 1, green: 0.231372549, blue: 0.1882352941, alpha: 1)
                        }
                    } else {
                        stateBadge.image = Asset.Images.Transfers.Widget.Complete.completedBadge.image
                        self.progressLayer?.strokeColor = #colorLiteral(red: 0, green: 0.6588235294, blue: 0.5254901961, alpha: 1)
                        dismissWidget()
                    }
                } else {
                    stateBadge.image = Asset.Images.Transfers.Widget.Complete.completedBadge.image
                    self.progressLayer?.strokeColor = #colorLiteral(red: 0, green: 0.6588235294, blue: 0.5254901961, alpha: 1)
                    dismissWidget()
                }
                
            } else {
                self.isHidden = true
            }
        }
    }
    
    private func filterUserManualDownloads(_ transfers: [MEGATransfer]) -> [MEGATransfer] {
        return transfers.filter { $0.path.hasPrefix(FileSystemRepository.newRepo.documentsDirectory().path) }
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
            guard self.transfers.isEmpty else {
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
    
    // MARK: - MEGATransferDelegate
    
    func onTransferStart(_ api: MEGASdk, transfer: MEGATransfer) {
        if transfer.type == .download {
            if overquota {
                overquota = false
            }
        }
        throttler.start { [weak self] in
            guard let self = self else { return }
            self.configureData()
        }
    }
    
    func onTransferUpdate(_ api: MEGASdk, transfer: MEGATransfer) {
        var isExportFile = false
        var isSaveToPhotos = false
        if let appData = transfer.appData {
            isExportFile = appData.contains(NSString().mnz_appDataToExportFile())
            isSaveToPhotos = appData.contains(NSString().mnz_appDataToSaveInPhotosApp())
        }
         
        guard transfer.path?.hasPrefix(transferInventoryUseCase.documentsDirectory().path) ?? false ||
                transfer.type == .upload ||
                isExportFile || isSaveToPhotos else {
                    return
                }
        
        self.updateProgress()
    }
    
    func onTransferFinish(_ api: MEGASdk, transfer: MEGATransfer, error: MEGAError) {
        if !transfer.isStreamingTransfer {
            MEGASdkManager.sharedMEGASdk().completedTransfers.add(transfer)
        }

        if MEGASdkManager.sharedMEGASdk().transfers.size.intValue == 0 {
            MEGASdkManager.sharedMEGASdk().resetTotalUploads()
            MEGASdkManager.sharedMEGASdk().resetTotalDownloads()
        }
        throttler.start { [weak self] in
            guard let self = self else { return }
            self.configureData()
        }
    }
    
    func onTransferTemporaryError(_ api: MEGASdk, transfer: MEGATransfer, error: MEGAError) {
        if error.type == .apiEOverQuota || error.type == .apiEgoingOverquota {
            overquota = true
        }
    }
    
    // MARK: - MEGARequestDelegate

    func onRequestFinish(_ api: MEGASdk, request: MEGARequest, error: MEGAError) {
        if error.type != .apiOk {
            switch error.type {
            case .apiEgoingOverquota, .apiEOverQuota:
                overquota = true
            default:
                break
            }
            
            return
        }
        if request.type == .MEGARequestTypePauseTransfers {
            if request.flag {
                stateBadge.image = Asset.Images.Transfers.Widget.Pause.combinedShape.image
            } else {
                configureData()
            }
            
        }
        
    }
}
