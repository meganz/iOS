import MEGADesignToken
import MEGADomain
import MEGASDKRepo

extension ThumbnailViewerTableViewCell {
    @objc func updateAppearance(with traitCollection: UITraitCollection) {
        backgroundColor = TokenColors.Background.page
        thumbnailViewerCollectionView?.backgroundColor = TokenColors.Background.page
        addedByLabel?.textColor = UIColor.primaryTextColor()
        timeLabel?.textColor = UIColor.mnz_subtitles()
        infoLabel?.textColor = UIColor.mnz_subtitles()
        indicatorImageView.tintColor = indicatorTintColor()
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
