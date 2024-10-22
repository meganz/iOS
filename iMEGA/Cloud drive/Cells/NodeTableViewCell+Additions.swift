import MEGADesignToken
import MEGADomain
import MEGAL10n
import MEGAPresentation
import MEGASDKRepo
import MEGAUIKit

extension NodeTableViewCell {
    
    open override func prepareForReuse() {
        super.prepareForReuse()
        
        viewModel = nil
        cancellables = []
        thumbnailImageView?.image = nil
        thumbnailImageView?.removeBlurFromView()
        [thumbnailContainer, topContainerStackView, bottomContainerStackView]
            .forEach { $0?.alpha = 1 }        
    }
    
    @objc func setTitleAndFolderName(for recentActionBucket: MEGARecentActionBucket,
                                     withNodes nodes: [MEGANode]) {
        
        guard let firstNode = nodes.first else {
            infoLabel.text = ""
            nameLabel.text = ""
            return
        }
        
        let isNodeUndecrypted = firstNode.isUndecrypted(ownerEmail: recentActionBucket.userEmail ?? "",
                                                        in: .shared)
        guard !isNodeUndecrypted else {
            infoLabel.text = Strings.Localizable.SharedItems.Tab.Incoming.undecryptedFolderName
            nameLabel.text = Strings.Localizable.SharedItems.Tab.Recents.undecryptedFileName(nodes.count)
            return
        }
        
        let firstNodeName = firstNode.name ?? ""
        let nodesCount = nodes.count
        nameLabel.text = nodesCount == 1 ? firstNodeName : Strings.Localizable.Recents.Section.MultipleFile.title(nodesCount - 1).replacingOccurrences(of: "[A]", with: firstNodeName)
        
        let parentNode = MEGASdk.shared.node(forHandle: recentActionBucket.parentHandle)
        let parentNodeName = parentNode?.name ?? ""
        infoLabel.text = "\(parentNodeName) ・"
    }
    
    @objc func configureMoreButtonUI() {
        moreButton.tintColor = TokenColors.Icon.secondary
    }
    
    @objc func setAccessibilityLabelsForIcons(in node: MEGANode) {
        labelImageView?.accessibilityLabel = MEGANode.string(for: node.label)
        favouriteImageView?.accessibilityLabel = Strings.Localizable.favourite
        linkImageView?.accessibilityLabel = Strings.Localizable.shared
    }
    
    @objc func configureIconsImageColor() {
        configureIconImageColor(for: favouriteImageView)
        configureIconImageColor(for: linkImageView)
        configureIconImageColor(for: versionedImageView)
        configureIconImageColor(for: downloadedImageView)
    }
    
    @objc func createViewModel(node: MEGANode?, shouldApplySensitiveBehaviour: Bool) -> NodeTableViewCellViewModel {
        createViewModel(
            nodes: [node].compactMap { $0 },
            shouldApplySensitiveBehaviour: shouldApplySensitiveBehaviour)
    }
    
    @objc func createViewModel(nodes: [MEGANode], shouldApplySensitiveBehaviour: Bool) -> NodeTableViewCellViewModel {
        .init(
            nodes: nodes.toNodeEntities(),
            shouldApplySensitiveBehaviour: shouldApplySensitiveBehaviour,
            sensitiveNodeUseCase: SensitiveNodeUseCase(
                nodeRepository: NodeRepository.newRepo,
                accountUseCase: AccountUseCase(repository: AccountRepository.newRepo)),
            thumbnailUseCase: ThumbnailUseCase(repository: ThumbnailRepository.newRepo),
            nodeIconUseCase: NodeIconUseCase(nodeIconRepo: NodeAssetsManager.shared))
    }
    
    @objc func bind(viewModel: NodeTableViewCellViewModel) {
        
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
                .sink { [weak thumbnailImageView] in thumbnailImageView?.image = $0 }
        ]
    }
    
    private func configureBlur(isSensitive: Bool) {
        let alpha: CGFloat = isSensitive ? 0.5 : 1
        [
            viewModel.hasThumbnail ? nil : thumbnailContainer,
            topContainerStackView,
            bottomContainerStackView
        ].forEach { $0?.alpha = alpha }
        
        if viewModel.hasThumbnail, isSensitive {
            thumbnailImageView?.addBlurToView(style: .systemUltraThinMaterial)
        } else {
            thumbnailImageView?.removeBlurFromView()
        }
    }
    
    private func configureIconImageColor(for imageView: UIImageView?) {
        guard let imageView else { return }
        imageView.image = imageView.image?.withRenderingMode(.alwaysTemplate)
        imageView.tintColor = TokenColors.Icon.secondary
    }
    
    @objc func setCellBackgroundColor() {
        backgroundColor = TokenColors.Background.page
    }
}
