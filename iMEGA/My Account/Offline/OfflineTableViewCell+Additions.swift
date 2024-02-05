import MEGADesignToken

extension OfflineTableViewCell {
    @objc func setThumbnail(url: URL) {
        let fileAttributeGenerator = FileAttributeGenerator(sourceURL: url)
        Task { @MainActor in
            guard let image = await fileAttributeGenerator.requestThumbnail() else { return }
            self.thumbnailImageView?.image = image
        }
    }
    
    @objc func setCellBackgroundColor(with traitCollection: UITraitCollection) {
        if UIColor.isDesignTokenEnabled() {
            backgroundColor = TokenColors.Background.page
        } else {
            backgroundColor = traitCollection.userInterfaceStyle == .dark ? UIColor.black1C1C1E : UIColor.whiteFFFFFF
        }
    }
    
    @objc func configureMoreButtonUI() {
        moreButton.tintColor = UIColor.isDesignTokenEnabled() ? TokenColors.Icon.secondary : UIColor.grayBBBBBB
    }
}
