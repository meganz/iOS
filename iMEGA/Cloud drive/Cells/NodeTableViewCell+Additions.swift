import MEGADesignToken
import MEGADomain
import MEGAL10n
import MEGAPresentation
import MEGASDKRepo
import MEGASwift
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

    @objc func configureDescriptionLabel() {
        descriptionLabel?.font = .preferredFont(forTextStyle: .caption1)
    }

    @objc func configureCell(for node: MEGANode, searchText: String?, shouldApplySensitiveBehaviour: Bool, api: MEGASdk) {
        self.node = node
        bind(viewModel: createViewModel(node: node, shouldApplySensitiveBehaviour: shouldApplySensitiveBehaviour))
        setupColors()
        configureDownloadViews(for: node)

        moreButton?.isHidden = isNodeInRubbishBin
        favouriteView?.isHidden = !node.isFavourite
        linkView?.isHidden = !node.isExported() || node.mnz_isInRubbishBin()

        configureNodeLabel(for: node)

        if !FileExtensionGroupOCWrapper.verify(isVideo: node.name) {
            thumbnailPlayImageView?.isHidden = true
        }

        configureNameAndSubtitle(for: node, searchText: searchText)

        configureInfoLabelAndVersionImageView(for: node, api: api)

        thumbnailImageView?.accessibilityIgnoresInvertColors = true
        thumbnailPlayImageView?.accessibilityIgnoresInvertColors = true

        separatorView?.backgroundColor = .borderStrong()

        showDescriptionIfRequired(for: node, searchText: searchText)
    }

    @objc(configureCellForNode:shouldApplySensitiveBehaviour:api:)
    func configureCell(for node: MEGANode, shouldApplySensitiveBehaviour: Bool, api: MEGASdk) {
        configureCell(for: node, searchText: nil, shouldApplySensitiveBehaviour: shouldApplySensitiveBehaviour, api: api)
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

    private func showDescriptionIfRequired(for node: MEGANode, searchText: String?) {
        guard DIContainer.featureFlagProvider.isFeatureFlagEnabled(for: .searchUsingNodeDescription),
              let searchText,
              searchText.isNotEmpty,
              let description = node.description,
              description.containsIgnoringCaseAndDiacritics(searchText: searchText) else {
            descriptionLabel?.isHidden = true
            return
        }

        descriptionLabel?.attributedText = node.attributedDescription(searchText: searchText)
        // Note: For some reason app will crash without setting the `descriptionLabel?.textColor` so we need to put it here
        descriptionLabel?.textColor = TokenColors.Text.secondary
        descriptionLabel?.isHidden = false
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

    private func configureDownloadViews(for node: MEGANode) {
        downloadingArrowImageView?.isHidden = true
        downloadProgressView?.isHidden = true
        if downloadingArrowView != nil {
            downloadingArrowView?.isHidden = downloadingArrowImageView.isHidden
        }

        let isDownloaded = node.isFile() && MEGAStore.shareInstance().offlineNode(with: node) != nil
        downloadedImageView?.isHidden = !isDownloaded

        if downloadedView != nil {
            downloadedView?.isHidden = downloadedImageView.isHidden
        }
    }

    private func configureNodeLabel(for node: MEGANode) {
        labelView?.isHidden = node.label == .unknown

        if node.label != .unknown, let labelString = MEGANode.string(for: node.label)?.appending("Small") {
            labelImageView?.image = UIImage(named: labelString)
        }
        setAccessibilityLabelsForIcons(in: node)
    }

    private func configureNameAndSubtitle(for node: MEGANode, searchText: String?) {
        if node.isTakenDown() {
            nameLabel?.attributedText = node.attributedTakenDownName(searchText: searchText)
            // Note: For some reason app will crash without setting the `nameLabel?.textColor` so we need to put it here
            nameLabel?.textColor = .mnz_takenDownNodeTextColor()
        } else {
            nameLabel?.attributedText = node.attributedName(searchText: searchText)
            // Note: For some reason app will crash without setting the `nameLabel?.textColor` so we need to put it here
            nameLabel?.textColor = .primaryTextColor()
            subtitleLabel?.textColor = .mnz_secondaryTextColor()
        }
    }

    private func configureInfoLabelAndVersionImageView(for node: MEGANode, api: MEGASdk) {
        infoLabel?.textColor = .mnz_secondaryTextColor()
        if node.isFile() {
            let megaSDK = (recentActionBucket != nil) ? MEGASdk.shared : api
            switch cellFlavor {
            case .flavorVersions, .flavorRecentAction, .flavorCloudDrive:
                infoLabel?.text = recentActionBucket != nil ? Helper.sizeAndCreationDate(for: node, api: megaSDK) : Helper.sizeAndModificationDate(for: node, api: megaSDK)
                megaSDK.hasVersions(node: node) { hasVersions in
                    DispatchQueue.main.async { [weak self] in
                        self?.uploadOrVersionImageView?.isHidden = !hasVersions
                    }
                }

            case .flavorSharedLink:
                infoLabel?.text = Helper.sizeAndShareLinkCreateDate(forSharedLinkNode: node, api: megaSDK)
                megaSDK.hasVersions(node: node) { hasVersions in
                    DispatchQueue.main.async { [weak self] in
                        self?.versionedImageView?.isHidden = !hasVersions
                    }
                }

            case .explorerView:
                updateInfo()
            @unknown default:
                break
            }
        } else if node.isFolder() {
            infoLabel?.text = Helper.filesAndFolders(inFolderNode: node, api: api)
            versionedImageView?.isHidden = true
        }
    }

    @objc func setCellBackgroundColor() {
        backgroundColor = TokenColors.Background.page
    }
}
