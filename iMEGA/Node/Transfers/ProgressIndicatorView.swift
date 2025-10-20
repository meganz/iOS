import Combine
import MEGAAppSDKRepo
import MEGAAssets
import MEGADesignToken
import MEGADomain
import MEGARepo
import MEGASwift
import UIKit

final class ProgressIndicatorView: UIView {
    private let transferInventoryUseCaseHelper = TransferInventoryUseCaseHelper()
    
    private var backgroundLayer: CAShapeLayer?
    private var progressBackgroundLayer: CAShapeLayer?
    private var progressLayer: CAShapeLayer?
    
    private var arrowImageView: UIImageView = UIImageView(
        image: MEGAAssets.UIImage.transfersDownload
    )
    private var stateBadge: UIImageView = UIImageView()
    
    private var subscriptions = Set<AnyCancellable>()
    
    private var isDismissing = false
    
    private var progressIndicatorViewModel = ProgressIndicatorViewModel(
        transferCounterUseCase: TransferCounterUseCase(
            repo: NodeTransferRepository.newRepo,
            transferInventoryRepository: TransferInventoryRepository.newRepo,
            fileSystemRepository: FileSystemRepository.sharedRepo
        )
    )
    
    // MARK: - Init
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        translatesAutoresizingMaskIntoConstraints = false
        configureLayers()
        configureView()
        configureDelegate()
        setupBindings()
        progressIndicatorViewModel.configureData()
    }
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
        configureLayers()
        configureView()
        setupBindings()
    }
    
    override func traitCollectionDidChange(_ previousTraitCollection: UITraitCollection?) {
        super.traitCollectionDidChange(previousTraitCollection)
        if traitCollection.hasDifferentColorAppearance(comparedTo: previousTraitCollection) {
            updateAppearance()
        }
    }
    
    // MARK: - Private
    
    private func setupBindings() {
        progressIndicatorViewModel.$progress
            .receive(on: DispatchQueue.main)
            .sink { [weak self] progress in
                self?.progressLayer?.strokeEnd = progress
            }
            .store(in: &subscriptions)
        
        progressIndicatorViewModel.$isHidden
            .receive(on: DispatchQueue.main)
            .sink { [weak self] isHidden in
                self?.isHidden = isHidden
            }
            .store(in: &subscriptions)
        
        progressIndicatorViewModel.$shouldShowUploadImage
            .receive(on: DispatchQueue.main)
            .sink { [weak self] shouldShowUpload in
                self?.arrowImageView.image = shouldShowUpload ? self?.transfersUploadImage : self?.transfersDownloadImage
            }
            .store(in: &subscriptions)
        
        progressIndicatorViewModel.$badgeState
            .receive(on: DispatchQueue.main)
            .sink { [weak self] state in
                self?.updateStateBadge(for: state)
            }
            .store(in: &subscriptions)
        
        progressIndicatorViewModel.$progressStrokeColor
            .receive(on: DispatchQueue.main)
            .sink { [weak self] color in
                self?.progressLayer?.strokeColor = color
            }
            .store(in: &subscriptions)
        
        progressIndicatorViewModel.$shouldDismissWidget
            .receive(on: DispatchQueue.main)
            .sink { [weak self] shouldDismiss in
                if shouldDismiss {
                    self?.dismissWidget()
                }
            }
            .store(in: &subscriptions)
    }
    
    @objc func showWidgetIfNeeded() {
        progressIndicatorViewModel.showWidgetIfNeeded()
    }
    
    @objc func hideWidget(widgetFobidden: Bool = false) {
        progressIndicatorViewModel.hideWidget(widgetForbidden: widgetFobidden)
    }
    
    @objc func dismissWidget() {
        guard !isDismissing else { return }
        isDismissing = true
        UIView.animate(withDuration: 0.5, animations: { [weak self] in
            self?.alpha = 0
        }, completion: { [weak self] _ in
            self?.progressIndicatorViewModel.hideWidget()
            self?.alpha = 1.0
            self?.isDismissing = false
        })
    }
    
    @objc func configureData() {
        progressIndicatorViewModel.configureData()
    }
    
    private func updateStateBadge(for state: TransferBadgeState) {
        switch state {
        case .error:
            stateBadge.image = errorBadge
        case .overquota:
            stateBadge.image = overquotaImage
        case .paused:
            stateBadge.image = pauseImage
        case .completed:
            stateBadge.image = completedBadge
        case .none:
            stateBadge.image = nil
        }
    }
}

// MARK: - Design token colors and images

private extension ProgressIndicatorView {
    var completedBadge: UIImage {
        MEGAAssets.UIImage.completedBadgeDesignToken.withTintColor(TokenColors.Support.success)
    }
    
    var errorBadge: UIImage {
        MEGAAssets.UIImage.errorBadgeDesignToken.withTintColor(TokenColors.Support.error)
    }
    
    var overquotaImage: UIImage {
        MEGAAssets.UIImage.overquotaDesignToken.withTintColor(TokenColors.Support.warning)
    }
    
    var pauseImage: UIImage {
        MEGAAssets.UIImage.pauseDesignToken.withTintColor(TokenColors.Icon.secondary)
    }
    
    var transfersDownloadImage: UIImage {
        MEGAAssets.UIImage.transfersDownloadDesignToken
    }
    
    var transfersUploadImage: UIImage {
        MEGAAssets.UIImage.transfersUploadDesignToken
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
    }
    
    private func configureLayers() {
        addBackgroundLayer()
        addProgressBackgroundLayer()
        addProgressLayer()
    }
    
    private func configureDelegate() {
        MEGASdk.shared.add(self as (any MEGARequestDelegate))
    }
}

// MARK: - Setup Progress Layers

private extension ProgressIndicatorView {
    func addBackgroundLayer() {
        let shapeLayer = circlularLayer(
            withRect: bounds,
            insetSize: CGSize(width: 5, height: 5)
        )
        shapeLayer.fillColor = TokenColors.Background.surface2.cgColor
        shapeLayer.shadowRadius = 16
        shapeLayer.shadowOpacity = 0.2
        // No design token color available for the shadow
        shapeLayer.shadowColor = MEGAAssets.UIColor.gray04040F.cgColor
        shapeLayer.shadowOffset = CGSize(width: 0, height: 2)
        
        layer.addSublayer(shapeLayer)
        backgroundLayer = shapeLayer
    }
    
    func addProgressBackgroundLayer() {
        let shapeLayer = circlularLayer(
            withRect: bounds,
            insetSize: CGSize(width: 10, height: 10)
        )
        shapeLayer.fillColor = UIColor.clear.cgColor
        shapeLayer.strokeColor = TokenColors.Background.surface3.cgColor
        shapeLayer.lineWidth = 2
        
        layer.addSublayer(shapeLayer)
        progressBackgroundLayer = shapeLayer
    }
    
    func addProgressLayer() {
        let shapeLayer = circlularLayer(withRect: bounds,
                                        insetSize: CGSize(width: 10, height: 10))
        shapeLayer.fillColor = UIColor.clear.cgColor
        shapeLayer.strokeColor = TokenColors.Support.success.cgColor
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
        backgroundLayer?.fillColor = TokenColors.Background.surface2.cgColor
        progressBackgroundLayer?.strokeColor = TokenColors.Background.surface3.cgColor
        // Reset the progress layer's stroke color when the trait collection is changed.
        // This is necessary due to limitations with CAShapeLayer.
        progressIndicatorViewModel.configureData()
    }
}

// MARK: - MEGARequestDelegate

extension ProgressIndicatorView: MEGARequestDelegate {
    nonisolated func onRequestFinish(_ api: MEGASdk, request: MEGARequest, error: MEGAError) {
        if error.type != .apiOk {
            return
        }
        if request.type == .MEGARequestTypePauseTransfers {
            Task {
                await progressIndicatorViewModel.handleTransferPauseRequest(flag: request.flag)
            }
        }
    }
}
