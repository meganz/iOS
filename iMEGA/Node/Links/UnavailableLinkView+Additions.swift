import MEGAAppPresentation
import MEGAAssets
import MEGAL10n

extension UnavailableLinkView {
    @objc var domainName: String {
        DIContainer.domainName
    }
    
    @objc func configureInvalidFileLinkForExpired() {
        imageView.image = MEGAAssets.UIImage.invalidLink
        titleLabel.text = Strings.Localizable.CloudDrive.FileLink.noLongerAvailable
        firstTextLabel.text = Strings.Localizable.CloudDrive.FileLink.hasExpired
        configureDescriptionLabelForExpired()
    }

    @objc func configureInvalidFolderLinkForExpired() {
        imageView.image = MEGAAssets.UIImage.invalidLink
        titleLabel.text = Strings.Localizable.CloudDrive.FolderLink.noLongerAvailable
        firstTextLabel.text = Strings.Localizable.CloudDrive.FolderLink.hasExpired
        configureDescriptionLabelForExpired()
    }
    
    private func configureDescriptionLabelForExpired() {
        descriptionLabel.text = nil
        secondTextLabel.text = nil
        thirdTextLabel.text = nil
        fourthTextLabel.text = nil
        stackView.setCustomSpacing(0, after: titleLabel)
    }
    
    @objc func configureGenericInvalidFileLink() {
        imageView.image = MEGAAssets.UIImage.invalidLink
        titleLabel.text = Strings.Localizable.CloudDrive.FileLink.notAvailable
        descriptionLabel.text = Strings.Localizable.fileLinkUnavailableText1
        firstTextLabel.text = "• \(Strings.Localizable.CloudDrive.FileLink.unavailableReason1)"
        secondTextLabel.text = "• \(Strings.Localizable.CloudDrive.FileLink.unavailableReason2)"
        thirdTextLabel.text = "• \(Strings.Localizable.CloudDrive.FileLink.unavailableReason3)"
        fourthTextLabel.text = "• \(Strings.Localizable.CloudDrive.FileLink.unavailableReason4)"
    }

    @objc func configureGenericInvalidFolderLink() {
        imageView.image = MEGAAssets.UIImage.invalidLink
        titleLabel.text = Strings.Localizable.CloudDrive.FolderLink.notAvailable
        descriptionLabel.text = Strings.Localizable.folderLinkUnavailableText1
        firstTextLabel.text = "• \(Strings.Localizable.CloudDrive.FolderLink.unavailableReason1)"
        secondTextLabel.text = "• \(Strings.Localizable.CloudDrive.FolderLink.unavailableReason2)"
        thirdTextLabel.text = "• \(Strings.Localizable.CloudDrive.FolderLink.unavailableReason3)"
        fourthTextLabel.text = "• \(Strings.Localizable.CloudDrive.FolderLink.unavailableReason4)"
    }
}
