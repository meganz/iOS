import MEGADesignToken

@objc extension OfflineTableViewCell {
   func setThumbnail(url: URL) {
        let fileAttributeGenerator = FileAttributeGenerator(sourceURL: url)
        Task { @MainActor in
            guard let image = await fileAttributeGenerator.requestThumbnail() else { return }
            self.thumbnailImageView?.image = image
        }
    }
    
    func configureTokenColors() {
        infoLabel.textColor = TokenColors.Text.secondary
        nameLabel.textColor = TokenColors.Text.primary
        moreButton.tintColor = TokenColors.Icon.secondary
        backgroundColor = TokenColors.Background.page
    }
}
