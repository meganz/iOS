import MEGADesignToken
import MEGASwiftUI
import SwiftUI

class ActionSheetCell: UITableViewCell {

    var accessoryTappedHandler: (() -> Void)?
    
    func configureCell(action: BaseAction) {
        NSLayoutConstraint.activate([contentView.heightAnchor.constraint(greaterThanOrEqualToConstant: 60.0)])
        textLabel?.text = action.title
        detailTextLabel?.text = action.detail
        if action.showNewFeatureBadge {
            addNewFeatureBadgeView()
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
    
    func addNewFeatureBadgeView() {
        let badgeView = NewFeatureBadgeView()
        
        let badgeHostingController = UIHostingController(rootView: badgeView)
        badgeHostingController.view.backgroundColor = .clear
        badgeHostingController.view.translatesAutoresizingMaskIntoConstraints = false
        contentView.addSubview(badgeHostingController.view)
        
        NSLayoutConstraint.activate([
            badgeHostingController.view.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -16),
            badgeHostingController.view.centerYAnchor.constraint(equalTo: contentView.centerYAnchor),
            badgeHostingController.view.heightAnchor.constraint(greaterThanOrEqualToConstant: 60)
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
