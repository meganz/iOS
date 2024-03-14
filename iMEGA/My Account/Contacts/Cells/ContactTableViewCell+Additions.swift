import MEGADesignToken

extension ContactTableViewCell {
    @objc func updateAppearance() {
        if UIColor.isDesignTokenEnabled() {
            backgroundColor = TokenColors.Background.page
            nameLabel.textColor = TokenColors.Text.primary
            shareLabel?.textColor = TokenColors.Text.secondary
            permissionsLabel?.textColor = TokenColors.Text.primary
            
            contactDetailsButton?.tintColor = TokenColors.Icon.secondary
            nameLabel.textColor = TokenColors.Text.primary
            shareLabel?.textColor = TokenColors.Text.secondary
            permissionsLabel?.textColor = TokenColors.Text.primary
        } else {
            nameLabel.textColor = UIColor.label
            shareLabel?.textColor = UIColor.mnz_subtitles(for: traitCollection)
            permissionsLabel?.textColor = UIColor.mnz_tertiaryGray(for: traitCollection)
            
            nameLabel.textColor = UIColor.label
            shareLabel?.textColor = UIColor.mnz_subtitles(for: traitCollection)
            permissionsLabel?.textColor = UIColor.mnz_tertiaryGray(for: traitCollection)
        }
    }
    
    @objc func updateNewViewAppearance() {
        if UIColor.isDesignTokenEnabled() {
            contactNewLabel.textColor = TokenColors.Text.success
            contactNewLabelView.backgroundColor = TokenColors.Notifications.notificationSuccess
        } else {
            contactNewLabel.textColor = UIColor.mnz_whiteFFFFFF()
            contactNewLabelView.backgroundColor = UIColor.mnz_turquoise(for: traitCollection)
        }
    }
}
