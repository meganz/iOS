
import Foundation

class ContactsTableViewHeader: UIView {
    
    @objc var navigationController: UINavigationController!
    
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
        
        requestsImageView.image = Asset.Images.Contacts.contactRequests.image.imageFlippedForRightToLeftLayoutDirection()
        requestsLabel.text = Strings.Localizable.requests
        
        configDetailsLabel()
        
        groupsImageView.image = Asset.Images.Contacts.groups.image.imageFlippedForRightToLeftLayoutDirection()
        groupsLabel.text = Strings.Localizable.groups
        
        updateAppearance()
    }
    
    override func traitCollectionDidChange(_ previousTraitCollection: UITraitCollection?) {
        super.traitCollectionDidChange(previousTraitCollection)
        
        if traitCollection.hasDifferentColorAppearance(comparedTo: previousTraitCollection) {
            self.updateAppearance()
        }
    }
    
    //MARK: - Private
    
    private func updateAppearance() {
        backgroundColor = .mnz_secondaryBackgroundGrouped(traitCollection)
        
        requestsDetailLabel.textColor = .mnz_secondaryLabel()
        requestsSeparatorView.backgroundColor = UIColor.mnz_separator(for: traitCollection)
    }
    
    private func configDetailsLabel() {
        let incomingContactsLists = MEGASdkManager.sharedMEGASdk().incomingContactRequests()
        let contactsCount = incomingContactsLists.size?.intValue ?? 0
        requestsDetailLabel.text = contactsCount == 0 ? "" : incomingContactsLists.size.stringValue
    }
    
    //MARK: - IBAction
    
    @IBAction func requestsTapped(_ sender: UITapGestureRecognizer) {
        let contactRequestsVC = UIStoryboard(name: "Contacts", bundle: nil).instantiateViewController(withIdentifier: "ContactsRequestsViewControllerID")
        
        navigationController.pushViewController(contactRequestsVC, animated: true)
    }
    
    @IBAction func groupsTapped(_ sender: UITapGestureRecognizer) {
        let contactsGroupsVC = UIStoryboard(name: "ContactsGroups", bundle: nil).instantiateViewController(withIdentifier: "ContactsGroupsViewControllerID")
        
        navigationController.pushViewController(contactsGroupsVC, animated: true)
    }
}
