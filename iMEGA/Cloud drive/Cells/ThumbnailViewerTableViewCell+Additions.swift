import MEGADesignToken
import MEGADomain
import MEGASDKRepo

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
        .init(nodes: nodes.toNodeEntities(),
              sensitiveNodeUseCase: SensitiveNodeUseCase(
                nodeRepository: NodeRepository.newRepo,
                accountUseCase: AccountUseCase(
                    repository: AccountRepository.newRepo)),
              nodeIconUseCase: NodeIconUseCase(nodeIconRepo: NodeAssetsManager.shared),
              thumbnailUseCase: ThumbnailUseCase(repository: ThumbnailRepository.newRepo))
    }
    
    @objc func configureItem(at indexPath: NSIndexPath, cell: ItemCollectionViewCell) {
        
        guard let itemViewModel = viewModel.item(for: indexPath.row) else {
            return
        }
        
        cell.bind(viewModel: itemViewModel)
    }
}
