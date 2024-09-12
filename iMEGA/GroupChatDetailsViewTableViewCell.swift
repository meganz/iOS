import MEGADesignToken

extension GroupChatDetailsViewTableViewCell {
    @objc func configNameLabelColor(isDestructive: Bool) {
        nameLabel?.textColor = isDestructive ? TokenColors.Text.error : TokenColors.Text.primary
    }
    
    @objc func updateAppearance() {
        backgroundColor = TokenColors.Background.page
        enableLabel?.textColor = TokenColors.Text.secondary
        rightLabel?.textColor = TokenColors.Text.secondary
        emailLabel?.textColor = TokenColors.Text.secondary
        nameLabel?.textColor = isDestructive ? TokenColors.Text.error : TokenColors.Text.primary
    }
    
    @objc func configEmailLabelColorAsPrimary() {
        emailLabel?.textColor = TokenColors.Text.primary
    }
}
