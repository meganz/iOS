import MEGAAssets
import MEGADesignToken

extension ContactRequestsTableViewCell {
    @objc func updateAppearance() {
        backgroundColor = TokenColors.Background.page
        nameLabel?.textColor = TokenColors.Text.primary
        timeAgoLabel?.textColor = TokenColors.Text.secondary
        
        let declineImage = MEGAAssets.UIImage.contactRequestDeny
            .withRenderingMode(.alwaysTemplate)
        declineButton?.setImage(declineImage, for: .normal)
        declineButton?.tintColor = TokenColors.Support.error
        
        let acceptImage = MEGAAssets.UIImage.contactRequestAccept
            .withRenderingMode(.alwaysTemplate)
        acceptButton?.setImage(acceptImage, for: .normal)
        acceptButton?.tintColor = TokenColors.Support.success
    }
}
