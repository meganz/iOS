import MEGADesignToken
import MEGADomain
import MEGAFoundation
import MEGARepo
import MEGASDKRepo
import UIKit

final class ProgressIndicatorView: UIView {
    private let throttler = Throttler(timeInterval: 1.0, dispatchQueue: .main)
    private let transferInventoryUseCase = TransferInventoryUseCase(
        transferInventoryRepository: TransferInventoryRepository(sdk: MEGASdk.shared),
        fileSystemRepository: FileSystemRepository.newRepo
    )
    private let sharedFolderTransferInventoryUseCase = TransferInventoryUseCase(
        transferInventoryRepository: TransferInventoryRepository(sdk: MEGASdk.sharedFolderLink),
        fileSystemRepository: FileSystemRepository.newRepo
    )

    private var backgroundLayer: CAShapeLayer?
    private var progressBackgroundLayer: CAShapeLayer?
    private var progressLayer: CAShapeLayer?

    private var arrowImageView: UIImageView = UIImageView(
        image: UIImage.transfersDownload
    )
    private var stateBadge: UIImageView = UIImageView()

    private var transferStatus: Int?
    private var transfers = [TransferEntity]()
    private var transfersPaused: Bool {
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
            guard let progressLayer else {
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

    // MARK: - Init

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

    @objc func animate(progress: CGFloat, duration: TimeInterval) {
        guard let progressLayer else {
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

    // MARK: - Private

    private func updateProgress() {
        let transferedBytes = MEGASdk.shared.totalsDownloadedBytes.floatValue + MEGASdk.shared.totalsUploadedBytes.floatValue
        let totalBytes = MEGASdk.shared.totalsDownloadBytes.floatValue + MEGASdk.shared.totalsUploadBytes.floatValue
        progress = CGFloat(transferedBytes / totalBytes)
    }

    private func filterUserManualDownloads(_ transfers: [MEGATransfer]) -> [MEGATransfer] {
        transfers.filter {
            $0.path?.hasPrefix(FileSystemRepository.newRepo.documentsDirectory().path) ?? false
        }
    }

    @objc func showWidgetIfNeeded() {
        isWidgetForbidden = false
        configureData()
    }

    @objc func hideWidget() {
        isWidgetForbidden = true
        isHidden = true
    }

    @objc func dismissWidget() {
        DispatchQueue.main.asyncAfter(deadline: .now() + 6) {
            guard self.transfers.isEmpty else {
                return
            }

            UIView.animate(withDuration: 0.5, animations: {
                self.alpha = 0
            }, completion: { _ in
                self.progress = 0
                self.hideWidget()
            })
        }
    }
}

// MARK: - Design token colors and images

private extension ProgressIndicatorView {
    var redProgressColor: CGColor {
        UIColor.isDesignTokenEnabled() ? TokenColors.Support.error.cgColor : MEGAAppColor.Red._FF3B30.uiColor.cgColor
    }

    var greenProgressColor: CGColor {
        UIColor.isDesignTokenEnabled() ? TokenColors.Support.success.cgColor : MEGAAppColor.Green._00A886.uiColor.cgColor
    }

    var yellowProgressColor: CGColor {
        UIColor.isDesignTokenEnabled() ? TokenColors.Support.warning.cgColor : MEGAAppColor.Yellow._FFCC00.uiColor.cgColor
    }

    var completedBadge: UIImage {
        UIColor.isDesignTokenEnabled() ?
        UIImage.completedBadgeDesignToken.withTintColor(TokenColors.Support.success) : UIImage.completedBadge
    }

    var errorBadge: UIImage {
        UIColor.isDesignTokenEnabled() ?
        UIImage.errorBadgeDesignToken.withTintColor(TokenColors.Support.error) : UIImage.errorBadge
    }

    var overquotaImage: UIImage {
        UIColor.isDesignTokenEnabled() ?
        UIImage.overquotaDesignToken.withTintColor(TokenColors.Support.warning) : UIImage.overquota
    }

    var pauseImage: UIImage {
        UIColor.isDesignTokenEnabled() ?
        UIImage.pauseDesignToken.withTintColor(TokenColors.Icon.secondary) : UIImage.combinedShape
    }

    var transfersDownloadImage: UIImage {
        UIColor.isDesignTokenEnabled() ? UIImage.transfersDownloadDesignToken : UIImage.transfersDownload
    }

    var transfersUploadImage: UIImage {
        UIColor.isDesignTokenEnabled() ? UIImage.transfersUploadDesignToken : UIImage.transfersUpload
    }
}

// MARK: - Configuration

extension ProgressIndicatorView {
    private func configureView() {
        addSubview(arrowImageView)
        arrowImageView.translatesAutoresizingMaskIntoConstraints = false

        NSLayoutConstraint.activate([
            arrowImageView.widthAnchor.constraint(equalToConstant: 28),
            arrowImageView.heightAnchor.constraint(equalToConstant: 28),
            arrowImageView.centerXAnchor.constraint(equalTo: centerXAnchor),
            arrowImageView.centerYAnchor.constraint(equalTo: centerYAnchor)
        ])
        arrowImageView.contentMode = .scaleToFill

        addSubview(stateBadge)
        stateBadge.translatesAutoresizingMaskIntoConstraints = false

        NSLayoutConstraint.activate([
            stateBadge.widthAnchor.constraint(equalToConstant: 12),
            stateBadge.heightAnchor.constraint(equalToConstant: 12),
            stateBadge.trailingAnchor.constraint(equalTo: arrowImageView.trailingAnchor),
            stateBadge.topAnchor.constraint(equalTo: arrowImageView.topAnchor)
        ])

        if transfersPaused {
            stateBadge.image = pauseImage
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
        MEGASdk.shared.add(self as (any MEGARequestDelegate))
        MEGASdk.shared.add(self as (any MEGATransferDelegate))
    }

    @objc func configureData() {
        guard !isWidgetForbidden else {
            isHidden = true
            return
        }

        transfers.removeAll()
        transfers = transferInventoryUseCase.transfers(filteringUserTransfers: true) +
        sharedFolderTransferInventoryUseCase.transfers(filteringUserTransfers: true)

        if let failedTransfer = transferInventoryUseCase.completedTransfers(filteringUserTransfers: true)
            .first(where: { $0.state != .complete && $0.state != .cancelled }) {
            updateStateBadge(for: failedTransfer)
        } else {
            stateBadge.image = nil
        }

        if transfers.isNotEmpty {
            updateForActiveTransfers()
        } else {
            updateForCompletedTransfers()
        }
    }

    private func updateStateBadge(for transfer: TransferEntity) {
        guard let lastErrorExtended = transfer.lastErrorExtended else {
            stateBadge.image = nil
            return
        }

        switch lastErrorExtended {
        case .overquota:
            stateBadge.image = overquotaImage
        case .generic:
            stateBadge.image = nil
        default:
            stateBadge.image = errorBadge
        }
    }

    private func updateForActiveTransfers() {
        isHidden = false
        alpha = 1
        progressLayer?.strokeColor = greenProgressColor

        let hasDownloadTransfer = transfers.contains { $0.type == .download }
        let hasUploadTransfer = transfers.contains { $0.type == .upload }
        arrowImageView.image = hasDownloadTransfer ? transfersDownloadImage : transfersUploadImage

        if overquota {
            stateBadge.image = overquotaImage
            progressLayer?.strokeColor = hasUploadTransfer ? greenProgressColor : yellowProgressColor
        } else if transfersPaused {
            stateBadge.image = pauseImage
        }
    }

    private func updateForCompletedTransfers() {
        let completedTransfers = transferInventoryUseCase.completedTransfers(filteringUserTransfers: true)
        guard completedTransfers.isNotEmpty else {
            isHidden = true
            return
        }

        progress = 1
        isHidden = false

        if let failedTransfer = completedTransfers.first(where: { $0.state != .complete && $0.state != .cancelled }) {
            handleFailedTransfer(failedTransfer)
        } else {
            stateBadge.image = completedBadge
            progressLayer?.strokeColor = greenProgressColor
            dismissWidget()
        }
    }

    private func handleFailedTransfer(_ transfer: TransferEntity) {
        guard let lastErrorExtended = transfer.lastErrorExtended else {
            stateBadge.image = completedBadge
            progressLayer?.strokeColor = greenProgressColor
            dismissWidget()
            return
        }

        if lastErrorExtended == .overquota {
            stateBadge.image = overquotaImage
            progressLayer?.strokeColor = yellowProgressColor
        } else if lastErrorExtended != .generic {
            stateBadge.image = errorBadge
            progressLayer?.strokeColor = redProgressColor
        }
    }
}

// MARK: - Setup Progress Layers

private extension ProgressIndicatorView {
    func addBackgroundLayer() {
        let shapeLayer = circlularLayer(
            withRect: bounds,
            insetSize: CGSize(width: 5, height: 5)
        )
        shapeLayer.fillColor = UIColor.isDesignTokenEnabled() ? TokenColors.Background.surface2.cgColor : UIColor.mnz_secondaryBackgroundElevated(traitCollection).cgColor
        shapeLayer.shadowRadius = 16
        shapeLayer.shadowOpacity = 0.2
        // No design token color available for the shadow
        shapeLayer.shadowColor = UIColor.gray04040F.cgColor
        shapeLayer.shadowOffset = CGSize(width: 0, height: 2)

        layer.addSublayer(shapeLayer)
        backgroundLayer = shapeLayer
    }

    func addProgressBackgroundLayer() {
        let shapeLayer = circlularLayer(
            withRect: bounds,
            insetSize: CGSize(width: 10, height: 10)
        )
        shapeLayer.fillColor = UIColor.isDesignTokenEnabled() ? UIColor.clear.cgColor : MEGAAppColor.Black._000000.uiColor.withAlphaComponent(0).cgColor
        shapeLayer.strokeColor = UIColor.isDesignTokenEnabled() ? TokenColors.Background.surface3.cgColor : MEGAAppColor.Black._000000.uiColor.withAlphaComponent(0.05).cgColor
        shapeLayer.lineWidth = 2

        layer.addSublayer(shapeLayer)
        progressBackgroundLayer = shapeLayer
    }

    func addProgressLayer() {
        let shapeLayer = circlularLayer(withRect: bounds,
                                        insetSize: CGSize(width: 10, height: 10))
        shapeLayer.fillColor = UIColor.isDesignTokenEnabled() ? UIColor.clear.cgColor : MEGAAppColor.Black._000000.uiColor.withAlphaComponent(0).cgColor
        shapeLayer.strokeColor = greenProgressColor
        shapeLayer.lineWidth = 2
        shapeLayer.strokeEnd = 0.0

        layer.addSublayer(shapeLayer)
        progressLayer = shapeLayer
    }

    func circlularLayer(withRect rect: CGRect,
                        insetSize size: CGSize) -> CAShapeLayer {

        let shapeLayer = CAShapeLayer()

        shapeLayer.path = UIBezierPath(
            roundedRect: rect.insetBy(dx: size.width, dy: size.height),
            cornerRadius: rect.width
        ).cgPath

        return shapeLayer
    }

    func updateAppearance() {
        guard !UIColor.isDesignTokenEnabled() else {
            backgroundLayer?.fillColor = TokenColors.Background.surface2.cgColor
            progressBackgroundLayer?.strokeColor = TokenColors.Background.surface3.cgColor
            // Reset the progress layer's stroke color when the trait collection is changed.
            // This is necessary due to limitations with CAShapeLayer.
            configureData()
            return
        }

        backgroundLayer?.fillColor = UIColor.mnz_secondaryBackgroundElevated(traitCollection).cgColor

        switch traitCollection.userInterfaceStyle {
        case .unspecified, .light:
            progressBackgroundLayer?.strokeColor = MEGAAppColor.Black._000000.uiColor.withAlphaComponent(0.05).cgColor
        case .dark:
            progressBackgroundLayer?.strokeColor = MEGAAppColor.Black._000000.uiColor.withAlphaComponent(0.33).cgColor
        @unknown default:
            progressBackgroundLayer?.strokeColor = MEGAAppColor.Black._000000.uiColor.withAlphaComponent(0.05).cgColor
        }
    }
}

// MARK: - MEGATransferDelegate

extension ProgressIndicatorView: MEGATransferDelegate {
    func onTransferStart(_ api: MEGASdk, transfer: MEGATransfer) {
        if transfer.type == .download {
            if overquota {
                overquota = false
            }
        }
        throttler.start { [weak self] in
            guard let self else { return }
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

        updateProgress()
    }

    func onTransferFinish(_ api: MEGASdk, transfer: MEGATransfer, error: MEGAError) {
        if !transfer.isStreamingTransfer {
            MEGASdk.shared.completedTransfers.add(transfer)
        }

        if MEGASdk.shared.transfers.size == 0 {
            MEGASdk.shared.resetTotalUploads()
            MEGASdk.shared.resetTotalDownloads()
        }
        throttler.start { [weak self] in
            guard let self else { return }
            self.configureData()
        }
    }

    func onTransferTemporaryError(_ api: MEGASdk, transfer: MEGATransfer, error: MEGAError) {
        if error.type == .apiEOverQuota || error.type == .apiEgoingOverquota {
            overquota = true
        }
    }
}

// MARK: - MEGARequestDelegate

extension ProgressIndicatorView: MEGARequestDelegate {
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
                stateBadge.image = pauseImage
            } else {
                configureData()
            }
        }
    }
}
