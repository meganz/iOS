
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
        
        requestsImageView.image = UIImage(named: "contactRequests")?.imageFlippedForRightToLeftLayoutDirection()
        requestsLabel.text = NSLocalizedString("Requests", comment: "Label for any ‘Requests’ button, link, text, title, etc. On iOS is used to go to the Contact request section from Contacts")
        let incomingContactsLists: MEGAContactRequestList = MEGASdkManager.sharedMEGASdk().incomingContactRequests()
        let text = (incomingContactsLists.size.intValue == 0) ? "" : incomingContactsLists.size.stringValue
        requestsDetailLabel.text = text
        
        groupsImageView.image = UIImage(named: "groups")?.imageFlippedForRightToLeftLayoutDirection()
        groupsLabel.text = NSLocalizedString("Groups", comment: "Label for any ‘Groups’ button, link, text, title, etc. On iOS is used to go to the chats 'Groups' section from Contacts")
        
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
