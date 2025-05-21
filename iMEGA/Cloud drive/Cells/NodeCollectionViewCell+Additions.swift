import MEGAAppSDKRepo
import MEGAAssets
import MEGADesignToken
import MEGADomain
import MEGASdk
import UIKit

private var AssociatedLoadThumbnailTaskHandle: UInt8 = 0

extension NodeCollectionViewCell {
    
    private var loadThumbnailTask: Task<Void, any Error>? {
        get {
            objc_getAssociatedObject(self, &AssociatedLoadThumbnailTaskHandle) as? Task<Void, any Error>
        }
        set {
            objc_setAssociatedObject(self, &AssociatedLoadThumbnailTaskHandle, newValue, objc_AssociationPolicy.OBJC_ASSOCIATION_RETAIN_NONATOMIC)
        }
    }
    
    /// Remove `awakeFromNib` from this extension and call `configureDurationLabel` in `awakeFromNib` in .m file instead
    /// Reason: Having `awakeFromNib` in both .m file and swift extension resulting in only code in swift is executed,
    @objc func configureDurationLabel() {
        durationLabel?.layer.cornerRadius = 4
        durationLabel?.layer.masksToBounds = true
    }
    
    open override func prepareForReuse() {
        super.prepareForReuse()
        
        loadThumbnailTask?.cancel()
        cancellables = []
        
        [thumbnailIconView, thumbnailImageView]
            .forEach { $0?.image = nil }
        
        [thumbnailImageView, thumbnailIconView, topNodeIconsView, labelsContainerStackView]
            .forEach { $0?.alpha = 1 }
    }
    
    @objc func createViewModel(node: MEGANode?, isFromSharedItem: Bool, sdk: MEGASdk) -> NodeCollectionViewCellViewModel {
        .init(
            node: node?.toNodeEntity(),
            isFromSharedItem: isFromSharedItem,
            sensitiveNodeUseCase: SensitiveNodeUseCase(
                nodeRepository: NodeRepository.newRepo,
                accountUseCase: AccountUseCase(repository: AccountRepository.newRepo)),
            thumbnailUseCase: ThumbnailUseCase(repository: ThumbnailRepository(
                sdk: sdk,
                fileManager: .default,
                nodeProvider: DefaultMEGANodeProvider(sdk: sdk))),
            nodeIconUseCase: NodeIconUseCase(nodeIconRepo: NodeAssetsManager(sdk: sdk)))
    }
    
    @objc  func bind(viewModel: NodeCollectionViewCellViewModel) {
        self.viewModel = viewModel
        
        viewModel.configureCell()
        
        cancellables = [
            viewModel
                .$isSensitive
                .removeDuplicates()
                .sink { [weak self] in self?.configureBlur(isSensitive: $0) },
            viewModel
                .$thumbnail
                .removeDuplicates()
                .sink { [weak self] in
                    guard let self else { return }
                    thumbnailImageView?.image = viewModel.hasThumbnail ? $0 : nil
                    thumbnailIconView?.image = viewModel.hasThumbnail ? nil : $0
                },
            
            viewModel
                .$videoDuration
                .removeDuplicates()
                .sink { [weak self] duration in
                    guard let self else { return }
                    if let duration {
                        durationLabel?.isHidden = false
                        durationLabel?.text = duration
                    } else {
                        durationLabel?.isHidden = true
                    }
                }
        ]
    }
    
    private func configureBlur(isSensitive: Bool) {
        let alpha: CGFloat = isSensitive ? 0.5 : 1
        [
            viewModel.hasThumbnail ? nil : thumbnailImageView,
            thumbnailIconView,
            topNodeIconsView,
            labelsContainerStackView
        ].forEach { $0?.alpha = alpha }
        
        if viewModel.hasThumbnail, isSensitive {
            thumbnailImageView?.addBlurToView(style: .systemUltraThinMaterial)
        } else {
            thumbnailImageView?.removeBlurFromView()
        }
    }
    
    @objc func setDurationForVideo(path: String) {
        viewModel.setDurationForVideo(path: path)
    }
    
    @objc func setThumbnail(url: URL) {
        guard url.relativeString.fileExtensionGroup.isVisualMedia else { return }
        let fileAttributeGenerator = FileAttributeGenerator(sourceURL: url)
        loadThumbnailTask = Task { @MainActor [weak self] in
            guard let self, let image = await fileAttributeGenerator.requestThumbnail() else { return }
            try Task.checkCancellation()
            self.thumbnailIconView?.isHidden = true
            self.thumbnailImageView?.image = image
        }
    }
    
    @objc func setupTokenColors() {
        nameLabel?.textColor = TokenColors.Text.primary
        infoLabel?.textColor = TokenColors.Text.secondary
        durationLabel?.textColor = TokenColors.Button.primary
        
        contentView.backgroundColor = TokenColors.Background.page
        durationLabel?.backgroundColor = TokenColors.Background.surface1
        
        moreButton?.tintColor = TokenColors.Icon.secondary
        
        favouriteImageView?.image = favouriteImageView?.image?.withRenderingMode(.alwaysTemplate)
        favouriteImageView?.tintColor = TokenColors.Icon.secondary
        
        linkImageView?.image = linkImageView?.image?.withRenderingMode(.alwaysTemplate)
        linkImageView?.tintColor = TokenColors.Icon.secondary
        
        versionedImageView?.image = versionedImageView?.image?.withRenderingMode(.alwaysTemplate)
        versionedImageView?.tintColor = TokenColors.Icon.secondary
        
        downloadedImageView?.image = downloadedImageView?.image?.withRenderingMode(.alwaysTemplate)
        downloadedImageView?.tintColor = TokenColors.Icon.secondary
        
        videoIconView?.image = videoIconView?.image?.withRenderingMode(.alwaysTemplate)
        videoIconView?.tintColor = TokenColors.Icon.secondary
    }
    
    @objc func setupThumbnailBackground() {
        topNodeIconsView?.backgroundColor = TokenColors.Background.surface2
        thumbnailImageView?.backgroundColor = TokenColors.Background.surface1
    }
    
    @objc func updateSelection() {
        if moreButton?.isHidden ?? false && self.isSelected {
            selectImageView?.image = MEGAAssets.UIImage.checkBoxSelectedSemantic
            self.contentView.layer.borderColor = TokenColors.Support.success.cgColor
        } else {
            selectImageView?.image = MEGAAssets.UIImage.checkBoxUnselected
            self.contentView.layer.borderColor = TokenColors.Border.strong.cgColor
        }
    }
}
