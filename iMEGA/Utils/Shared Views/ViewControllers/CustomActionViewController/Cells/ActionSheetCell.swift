import MEGADesignToken
import MEGAL10n

class ActionSheetCell: UITableViewCell {

    var accessoryTappedHandler: (() -> Void)?
    
    func configureCell(action: BaseAction) {
        NSLayoutConstraint.activate([heightAnchor.constraint(greaterThanOrEqualToConstant: 60.0)])
        textLabel?.text = action.title
        detailTextLabel?.text = action.detail
        if let badge = action.badgeModel {
            addNewFeatureBadgeView(badge)
        } else {
            accessoryView = action.accessoryView
            attachAccessoryAction()
        }
        if action.syncIconAndTextColor {
            imageView?.image = action.image?.withRenderingMode(.alwaysTemplate)
            // [MEET-3972] adjust and sync image tint to text color for iPad
            imageView?.tintColor = textLabel?.textColor
        } else {
            imageView?.image = action.image
        }
        // [MEET-3972] action item to toggle call layout is disabled
        // when user is sharing his/her screen
        contentView.alpha = action.enabled ? 1.0 : 0.5
        textLabel?.textColor = TokenColors.Text.primary
        detailTextLabel?.textColor = TokenColors.Text.secondary
        backgroundColor = TokenColors.Background.surface1
        
        switch action.style {
        case .cancel, .destructive:
            textLabel?.textColor = TokenColors.Support.error
            imageView?.tintColor = TokenColors.Support.error
        default: break
        }
    }
    
    func addNewFeatureBadgeView(_ badge: Badge) {
        let badgeView = UIView()
        badgeView.backgroundColor = badge.backgroundColor
        badgeView.layer.cornerRadius = 10
        badgeView.translatesAutoresizingMaskIntoConstraints = false

        let badgeLabel = UILabel()
        badgeLabel.textColor = badge.foregroundColor
        badgeLabel.font = UIFont.preferredFont(forTextStyle: .caption2)
        badgeLabel.text = badge.title
        badgeLabel.textAlignment = .center
        badgeLabel.translatesAutoresizingMaskIntoConstraints = false
        
        badgeView.addSubview(badgeLabel)
        NSLayoutConstraint.activate([
            badgeLabel.topAnchor.constraint(equalTo: badgeView.topAnchor, constant: 4),
            badgeLabel.bottomAnchor.constraint(equalTo: badgeView.bottomAnchor, constant: -4),
            badgeLabel.leadingAnchor.constraint(equalTo: badgeView.leadingAnchor, constant: 8),
            badgeLabel.trailingAnchor.constraint(equalTo: badgeView.trailingAnchor, constant: -8)
        ])
        
        addSubview(badgeView)
        NSLayoutConstraint.activate([
            badgeView.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -16),
            badgeView.centerYAnchor.constraint(equalTo: centerYAnchor)
        ])
    }
    
    private func attachAccessoryAction() {
        guard let accessoryControl = accessoryView as? UIControl else { return }
        
        accessoryControl.addTarget(self, action: #selector(accessoryTapped(sender:)), for: .touchUpInside)
    }
    
    @objc private func accessoryTapped(sender: UIControl) {
        accessoryTappedHandler?()
    }
}
