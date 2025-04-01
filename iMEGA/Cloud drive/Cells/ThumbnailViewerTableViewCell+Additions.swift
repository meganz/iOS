import MEGAAppPresentation
import MEGADesignToken
import MEGADomain
import MEGASDKRepo
import PhotosBrowser

extension ThumbnailViewerTableViewCell {
    @objc func setupColors() {
        backgroundColor = TokenColors.Background.page
        thumbnailViewerCollectionView?.backgroundColor = TokenColors.Background.page
        addedByLabel?.textColor = TokenColors.Text.primary
        timeLabel?.textColor = TokenColors.Text.secondary
        infoLabel?.textColor = TokenColors.Text.secondary
        indicatorImageView.tintColor = TokenColors.Icon.secondary
    }
    
    @objc func indicatorTintColor() -> UIColor {
        TokenColors.Icon.secondary
    }
    
    @objc func createViewModel(nodes: [MEGANode]) -> ThumbnailViewerTableViewCellViewModel {
        let accountUseCase = AccountUseCase(
            repository: AccountRepository.newRepo)
        return .init(nodes: nodes.toNodeEntities(),
              sensitiveNodeUseCase: SensitiveNodeUseCase(
                nodeRepository: NodeRepository.newRepo,
                accountUseCase: accountUseCase),
              nodeIconUseCase: NodeIconUseCase(nodeIconRepo: NodeAssetsManager.shared),
              thumbnailUseCase: ThumbnailUseCase(repository: ThumbnailRepository.newRepo))
    }
    
    @objc func configureItem(at indexPath: NSIndexPath, cell: ItemCollectionViewCell) {
        
        guard let itemViewModel = viewModel.item(for: indexPath.row) else {
            return
        }
        
        cell.bind(viewModel: itemViewModel)
    }
    
    @objc func photosBrowserViewController(with nodes: [MEGANode], at indexPath: IndexPath) -> UIViewController? {
        guard nodes.isNotEmpty else { return nil }
        
        if DIContainer.featureFlagProvider.isFeatureFlagEnabled(for: .photosBrowser) {
            let config = PhotosBrowserConfiguration(displayMode: .cloudDrive,
                                                    library: MediaLibrary(assets: nodes.toPhotosBrowserEntities(),
                                                                          currentIndex: indexPath.row))
            let photoBrowserViewModel = PhotosBrowserViewModel(config: config)
            let photosBrowserViewController = PhotosBrowserViewController(viewModel: photoBrowserViewModel)
            photosBrowserViewController.modalPresentationStyle = .overFullScreen
            
            return photosBrowserViewController
        } else {
            return MEGAPhotoBrowserViewController.photoBrowser(withMediaNodes: NSMutableArray(array: nodes),
                                                               api: MEGASdk.shared,
                                                               displayMode: DisplayMode.cloudDrive,
                                                               isFromSharedItem: false, presenting: nodes[indexPath.row])
        }
    }
}
