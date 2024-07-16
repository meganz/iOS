import Foundation
import MEGADesignToken
import MEGAL10n

class ContactsTableViewHeader: UIView {
    @objc var navigationController: UINavigationController!
    
    @IBOutlet weak var disclosureIndicatorRequestImageView: UIImageView!
    @IBOutlet weak var disclosureIndicatorGroupsImageView: UIImageView!
    @IBOutlet weak var requestsImageView: UIImageView!
    @IBOutlet weak var requestsLabel: UILabel!
    @IBOutlet weak var requestsDetailLabel: UILabel!
    @IBOutlet weak var requestsSeparatorView: UIView!
    
    @IBOutlet weak var groupsImageView: UIImageView!
    @IBOutlet weak var groupsLabel: UILabel!
    
    @IBOutlet weak var requestsTapGestureRecognizer: UITapGestureRecognizer!
    @IBOutlet weak var groupsTapGestureRecognizer: UITapGestureRecognizer!
    
    override func awakeFromNib() {
        super.awakeFromNib()
        requestsLabel.text = Strings.Localizable.requests
        groupsLabel.text = Strings.Localizable.groups
        
        configDetailsLabel()
        updateAppearance()
        
        if UIColor.isDesignTokenEnabled() {
            disclosureIndicatorRequestImageView.image?.withRenderingMode(.alwaysTemplate)
            disclosureIndicatorRequestImageView.tintColor = TokenColors.Icon.secondary
            disclosureIndicatorGroupsImageView.image?.withRenderingMode(.alwaysTemplate)
            disclosureIndicatorGroupsImageView.tintColor = TokenColors.Icon.secondary
        }
    }
    
    override func traitCollectionDidChange(_ previousTraitCollection: UITraitCollection?) {
        super.traitCollectionDidChange(previousTraitCollection)
        
        if traitCollection.hasDifferentColorAppearance(comparedTo: previousTraitCollection) {
            self.updateAppearance()
        }
    }
    
    // MARK: - Private
    
    private func updateAppearance() {
        backgroundColor = UIColor.isDesignTokenEnabled() ? TokenColors.Background.page : UIColor.mnz_backgroundElevated(traitCollection)
        
        requestsLabel.textColor = UIColor.isDesignTokenEnabled() ? TokenColors.Text.primary : UIColor.label
        groupsLabel.textColor = UIColor.isDesignTokenEnabled() ? TokenColors.Text.primary : UIColor.label
        requestsDetailLabel.textColor = UIColor.isDesignTokenEnabled() ? TokenColors.Text.secondary : UIColor.secondaryLabel
        
        requestsSeparatorView.backgroundColor = UIColor.mnz_separator(for: traitCollection)
        
        // contactRequestsIcon should be deleted on assets when design token is permanently applied. It is only used here.
        requestsImageView.image = (UIColor.isDesignTokenEnabled() ? UIImage.contactRequests : UIImage.contactRequestsIcon).imageFlippedForRightToLeftLayoutDirection()
        // contactGroupsIcon should be deleted on assets when design token is permanently applied. It is only used here.
        groupsImageView.image = (UIColor.isDesignTokenEnabled() ? UIImage.contactGroups : UIImage.contactGroupsIcon).imageFlippedForRightToLeftLayoutDirection()
    }
    
    private func configDetailsLabel() {
        let incomingContactsLists = MEGASdk.shared.incomingContactRequests()
        let contactsCount = incomingContactsLists.size
        requestsDetailLabel.text = contactsCount == 0 ? "" : String(contactsCount)
    }
    
    // MARK: - IBAction
    
    @IBAction func requestsTapped(_ sender: UITapGestureRecognizer) {
        let contactRequestsVC = UIStoryboard(name: "Contacts", bundle: nil).instantiateViewController(withIdentifier: "ContactsRequestsViewControllerID")
        
        navigationController.pushViewController(contactRequestsVC, animated: true)
    }
    
    @IBAction func groupsTapped(_ sender: UITapGestureRecognizer) {
        let contactsGroupsVC = UIStoryboard(name: "ContactsGroups", bundle: nil).instantiateViewController(withIdentifier: "ContactsGroupsViewControllerID")
        
        navigationController.pushViewController(contactsGroupsVC, animated: true)
    }
}
