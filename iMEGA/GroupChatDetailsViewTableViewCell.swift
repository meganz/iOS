import MEGADesignToken

extension GroupChatDetailsViewTableViewCell {
    @objc func configNameLabelColor(isDestructive: Bool) {
        if UIColor.isDesignTokenEnabled() {
            nameLabel?.textColor = isDestructive ? TokenColors.Text.error : TokenColors.Text.primary
        } else {
            nameLabel?.textColor = isDestructive ? UIColor.mnz_red(for: traitCollection) : UIColor.label
        }
    }
    
    @objc func updateAppearance() {
        if UIColor.isDesignTokenEnabled() {
            backgroundColor = TokenColors.Background.page
            enableLabel?.textColor = TokenColors.Text.secondary
            rightLabel?.textColor = TokenColors.Text.secondary
            emailLabel?.textColor = TokenColors.Text.secondary
            nameLabel?.textColor = isDestructive ? TokenColors.Text.error : TokenColors.Text.primary
        } else {
            enableLabel?.textColor = UIColor.secondaryLabel
            rightLabel?.textColor = UIColor.secondaryLabel
            emailLabel?.textColor = UIColor.mnz_subtitles(for: traitCollection)
            nameLabel?.textColor = isDestructive ? UIColor.mnz_red(for: traitCollection) : UIColor.label
        }
    }
    
    @objc func configEmailLabelColorAsPrimary() {
        if UIColor.isDesignTokenEnabled() {
            emailLabel?.textColor = TokenColors.Text.primary
        } else {
            emailLabel?.textColor = UIColor.mnz_subtitles(for: traitCollection)
        }
    }
}
