import MEGADesignToken

class ActionSheetCell: UITableViewCell {

    func configureCell(action: BaseAction) {
        NSLayoutConstraint.activate([heightAnchor.constraint(greaterThanOrEqualToConstant: 60.0)])    
        textLabel?.text = action.title
        detailTextLabel?.text = action.detail
        accessoryView = action.accessoryView
        imageView?.image = action.image
        if UIColor.isDesignTokenEnabled() {
            textLabel?.textColor = TokenColors.Text.primary
            detailTextLabel?.textColor = TokenColors.Text.secondary
            backgroundColor = TokenColors.Background.surface1
        }
        switch action.style {
        case .cancel, .destructive:
            textLabel?.textColor = UIColor.isDesignTokenEnabled() ? TokenColors.Support.error : .mnz_red(for: traitCollection)
            imageView?.tintColor = UIColor.isDesignTokenEnabled() ? TokenColors.Support.error : .mnz_red(for: traitCollection)
        default: break
        }
    }
}
