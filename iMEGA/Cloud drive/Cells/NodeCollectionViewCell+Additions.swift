import MEGADesignToken
import MEGADomain
import MEGASdk
import MEGASDKRepo
import UIKit

extension NodeCollectionViewCell {
    
    open override func prepareForReuse() {
        super.prepareForReuse()
        
        cancellables = []
        
        [thumbnailIconView, thumbnailImageView]
            .forEach { $0?.image = nil }
        
        [thumbnailImageView, thumbnailIconView, topNodeIconsView, labelsContainerStackView]
            .forEach { $0?.alpha = 1 }
    }
    
    @objc func createViewModel(node: MEGANode?, isFromSharedItem: Bool, sdk: MEGASdk) -> NodeCollectionViewCellViewModel {
        NodeCollectionViewCellViewModel(
            node: node?.toNodeEntity(),
            isFromSharedItem: isFromSharedItem,
            nodeUseCase: NodeUseCase(
              nodeDataRepository: NodeDataRepository.newRepo,
              nodeValidationRepository: NodeValidationRepository.newRepo,
              nodeRepository: NodeRepository.newRepo),
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
        let asset = AVURLAsset(url: URL(fileURLWithPath: path, isDirectory: false))
        asset.loadValuesAsynchronously(forKeys: ["duration"]) {
            DispatchQueue.main.async {
                var error: NSError?
                switch asset.statusOfValue(forKey: "duration", error: &error) {
                case .loaded:
                    let time = asset.duration
                    let seconds = CMTimeGetSeconds(time)
                    if seconds > 0, !CMTIME_IS_POSITIVEINFINITY(time) {
                        self.durationLabel?.isHidden = false
                        self.durationLabel?.layer.cornerRadius = 4
                        self.durationLabel?.layer.masksToBounds = true
                        self.durationLabel?.text = seconds.timeString
                    } else {
                        self.durationLabel?.isHidden = true
                    }
                default:
                    self.durationLabel?.isHidden = true
                }
            }
        }
    }
    
    @objc func setThumbnail(url: URL) {
        let fileAttributeGenerator = FileAttributeGenerator(sourceURL: url)
        
        Task { @MainActor in
            guard let image = await fileAttributeGenerator.requestThumbnail() else { return }
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
        if UIColor.isDesignTokenEnabled() {
            topNodeIconsView?.backgroundColor = TokenColors.Background.surface2
            thumbnailImageView?.backgroundColor = TokenColors.Background.surface1
        } else {
            setupLegacyThumbnailBackgroundColor()
        }
    }
    
    private func setupLegacyThumbnailBackgroundColor() {
        switch traitCollection.userInterfaceStyle {
        case .light:
            self.topNodeIconsView?.backgroundColor = UIColor.init(white: 1, alpha: 0.3)
            self.thumbnailImageView?.backgroundColor = UIColor.mnz_whiteF7F7F7()
        case .dark:
            self.topNodeIconsView?.backgroundColor = UIColor.init(white: 0, alpha: 0.4)
            self.thumbnailImageView?.backgroundColor = UIColor.mnz_black1C1C1E()
        default:
            self.topNodeIconsView?.backgroundColor = UIColor.init(white: 1, alpha: 0.3)
            self.thumbnailImageView?.backgroundColor = UIColor.mnz_whiteF7F7F7()
        }
    }
    
    @objc func updateSelection() {
        if moreButton?.isHidden ?? false && self.isSelected {
            selectImageView?.image = UIColor.isDesignTokenEnabled() ? UIImage.checkBoxSelectedSemantic : UIImage(resource: .thumbnailSelected)
            self.contentView.layer.borderColor = UIColor.mnz_green00A886().cgColor
        } else {
            selectImageView?.image = UIImage(resource: .checkBoxUnselected)
            
            guard !UIColor.isDesignTokenEnabled() else {
                self.contentView.layer.borderColor = TokenColors.Border.strong.cgColor
                return
            }
            
            setupLegacyContentViewBorderColor()
        }
    }
    
    private func setupLegacyContentViewBorderColor() {
        switch traitCollection.userInterfaceStyle {
        case .light:
            self.contentView.layer.borderColor = UIColor.mnz_whiteF7F7F7().cgColor
        case .dark:
            self.contentView.layer.borderColor = UIColor.mnz_gray545458().cgColor
        default:
            self.contentView.layer.borderColor = UIColor.mnz_whiteF7F7F7().cgColor
        }
    }
}
