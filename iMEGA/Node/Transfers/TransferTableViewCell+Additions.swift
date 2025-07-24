import MEGAAppPresentation
import MEGAAppSDKRepo
import MEGADesignToken
import MEGADomain

extension TransferTableViewCell {
    open override func prepareForReuse() {
        super.prepareForReuse()
        cancelImageRequest()
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
    
    @objc func setImageFor(transfer: MEGATransfer) {
        guard let appData = transfer.appData,
              let localIdentifier = extractLocalIdentifier(from: appData) else {
            iconImageView.image = NodeAssetsManager.shared.image(for: transfer.path?.pathExtension ?? "jpg")
            return
        }
        
        let fetchResult = PHAsset.fetchAssets(withLocalIdentifiers: [localIdentifier], options: nil)
        
        guard let asset = fetchResult.firstObject else {
            return
        }
        
        let options = PHImageRequestOptions()
        options.version = .current
        options.isNetworkAccessAllowed = true
        
        imageRequestID = PHImageManager.default().requestImage(for: asset, targetSize: iconImageView.frame.size, contentMode: .aspectFit, options: options) { [weak self] image, _ in
            guard let self else {
                return
            }
            guard let image else {
                iconImageView.image = NodeAssetsManager.shared.image(for: transfer.path?.pathExtension ?? "jpg")
                return
            }
            
            iconImageView.image = image
        }
    }
    
    func cancelImageRequest() {
        PHImageManager.default().cancelImageRequest(imageRequestID)
    }
    
    private func extractLocalIdentifier(from input: String) -> String? {
        let pattern = />localIdentifier=([^>]+)/
        if let match = input.firstMatch(of: pattern) {
            let localIdentifier = match.output.1
            return String(localIdentifier)
        }
        return nil
    }
    
    static var areTransfersPaused: Bool {
        UserDefaults.standard.bool(forKey: "TransfersPaused")
    }
    
    @objc func updatePauseButtonTintColor() {
        let color = Self.areTransfersPaused ? TokenColors.Icon.disabled : TokenColors.Icon.primary
        pauseButton.tintColor = color
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
}
