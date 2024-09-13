import MEGADesignToken

extension ContactRequestsTableViewCell {
    @objc func updateAppearance() {
        backgroundColor = TokenColors.Background.page
        nameLabel?.textColor = TokenColors.Text.primary
        timeAgoLabel?.textColor = TokenColors.Text.secondary
        
        let declineImage = UIImage(resource: .contactRequestDeny)
            .withRenderingMode(.alwaysTemplate)
        declineButton?.setImage(declineImage, for: .normal)
        declineButton?.tintColor = TokenColors.Support.error
        
        let acceptImage = UIImage(resource: .contactRequestAccept)
            .withRenderingMode(.alwaysTemplate)
        acceptButton?.setImage(acceptImage, for: .normal)
        acceptButton?.tintColor = TokenColors.Support.success
    }
}
