import MEGAAppPresentation
import MEGAAppSDKRepo
import MEGADesignToken
import MEGADomain

extension TransferTableViewCell {
    open override func prepareForReuse() {
        super.prepareForReuse()
        viewModel.cancelThumbnailLoading()
    }
    
    @objc func transferStateOverQuotaTextColor() -> UIColor {
        TokenColors.Text.warning
    }
    
    @objc func transferStateOverQuotaIconColor() -> UIColor {
        TokenColors.Support.warning
    }

    @objc func transferStateErrorTextColor() -> UIColor {
        TokenColors.Text.error
    }
    
    @objc func transferStateErrorIconColor() -> UIColor {
        TokenColors.Support.error
    }
    
    @objc func transferTypeColor(for type: MEGATransferType) -> UIColor {
        guard let transferType = TransferTypeEntity(transferType: type) else { return TokenColors.Icon.onColor }

        switch transferType {
        case .download: return TokenColors.Indicator.green
        case .upload: return TokenColors.Indicator.blue
        default: return TokenColors.Icon.onColor
        }
    }
    
    @objc func transferInfoColor(for type: MEGATransferType) -> UIColor {
        TokenColors.Text.secondary
    }
    
    @objc func setTransferStateIcon(_ image: UIImage, color: UIColor) {
        arrowImageView.image = image.withRenderingMode(.alwaysTemplate)
        arrowImageView.tintColor = color
    }
    
    static var areTransfersPaused: Bool {
        UserDefaults.standard.bool(forKey: "TransfersPaused")
    }
    
    @objc var isNetworkOffline: Bool {
        !MEGAReachabilityManager.isReachable() && DIContainer.featureFlagProvider.isNewOfflineModeEnabled
    }

    @objc func updatePauseButtonTintColor() {
        let isInert = isNetworkOffline
        pauseButton.tintColor = Self.areTransfersPaused || isInert
            ? TokenColors.Icon.disabled
            : TokenColors.Icon.primary
        pauseButton.isEnabled = !isInert
    }
}

extension TransferTableViewCell: ViewType {
    public func executeCommand(_ command: TransferTableViewCellViewModel.Command) {
        switch command {
        case .updateThumbnail(let image):
            iconImageView.image = image
        }
    }
    
    @objc func createViewModel() -> TransferTableViewCellViewModel {
        let viewModel = TransferTableViewCellViewModel(thumbnailUseCase: ThumbnailUseCase(repository: ThumbnailRepository.newRepo))
        viewModel.invokeCommand = { [weak self] in
            self?.executeCommand($0)
        }
        return viewModel
    }
    
    @objc func configureDownloadTransfer(_ transfer: MEGATransfer) {
        viewModel.dispatch(.configureDownloadTransfer(transfer.toTransferEntity()))
    }

    @objc func configureUploadTransfer(_ transfer: MEGATransfer) {
        viewModel.dispatch(.configureUploadTransfer(transfer.toTransferEntity()))
    }
}
