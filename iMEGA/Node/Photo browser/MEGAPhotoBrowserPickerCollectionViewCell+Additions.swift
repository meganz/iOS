import MEGAAppSDKRepo
import MEGADomain

extension MEGAPhotoBrowserPickerCollectionViewCell {
    open override func prepareForReuse() {
        super.prepareForReuse()
        
        viewModel = nil
        cancellables = []
        
        imageView?.image = nil
        imageView?.removeBlurFromView()
        imageView?.alpha = 1
    }
    
    @objc func configureCell(for node: MEGANode, isFromSharedItem: Bool, sdk: MEGASdk) {
        let viewModel = makeViewModel(node: node, isFromSharedItem: isFromSharedItem, sdk: sdk)
        self.viewModel = viewModel
        
        videoDurationLabel.text = viewModel.videoDuration
        videoOverlay.isHidden = !viewModel.isVideo
        playView.isHidden = !viewModel.isVideo
        
        cancellables = [
            viewModel
                .$isSensitive
                .removeDuplicates()
                .sink { [weak self] in self?.configureBlur(isSensitive: $0) },
            viewModel
                .$thumbnail
                .removeDuplicates()
                .sink { [weak imageView] in imageView?.image = $0 }
        ]
        
        viewModel.configureCell()
    }
    
    private func makeViewModel(
        node: MEGANode,
        isFromSharedItem: Bool,
        sdk: MEGASdk
    ) -> PhotoBrowserPickerCollectionViewCellViewModel {
        .init(
            node: node.toNodeEntity(),
            isFromSharedItem: isFromSharedItem,
            sensitiveNodeUseCase: SensitiveNodeUseCase(
                nodeRepository: NodeRepository.newRepo,
                accountUseCase: AccountUseCase(repository: AccountRepository.newRepo)),
            thumbnailUseCase: ThumbnailUseCase(repository: ThumbnailRepository(
                sdk: sdk,
                fileManager: .default,
                nodeProvider: DefaultMEGANodeProvider(sdk: sdk))),
            nodeIconUseCase: NodeIconUseCase(nodeIconRepo: NodeAssetsManager.shared))
    }
    
    private func configureBlur(isSensitive: Bool) {
        if viewModel?.hasThumbnail == false {
            imageView.alpha = isSensitive ? 0.5 : 1
        }
        
        if viewModel?.hasThumbnail == true, isSensitive {
            imageView?.addBlurToView(style: .systemUltraThinMaterial)
        } else {
            imageView?.removeBlurFromView()
        }
    }
}
