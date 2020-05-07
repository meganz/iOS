
import Foundation

class SectionTableViewCell: UITableViewCell {
    @IBOutlet weak var leftImageView: UIImageView!
    @IBOutlet weak var mainTextLabel: UILabel!
    @IBOutlet weak var rightDetailTextLabel: UILabel!
    
    @objc func configureContactsSection(indexPath: IndexPath) {
        rightDetailTextLabel.textColor = UIColor.mnz_tertiaryGray(for: traitCollection)
        
        if indexPath.row == 0 {
            leftImageView.image = UIImage(named: "contactRequests")?.imageFlippedForRightToLeftLayoutDirection()
            mainTextLabel.text = AMLocalizedString("Requests", "Label for any ‘Requests’ button, link, text, title, etc. On iOS is used to go to the Contact request section from Contacts")
            
            let incomingContactsLists: MEGAContactRequestList = MEGASdkManager.sharedMEGASdk().incomingContactRequests()
            let text = (incomingContactsLists.size.intValue == 0) ? "" : incomingContactsLists.size.stringValue
            rightDetailTextLabel.text = text
        } else {
            leftImageView.image = UIImage(named: "groups")?.imageFlippedForRightToLeftLayoutDirection()
            mainTextLabel.text = AMLocalizedString("Groups", "Label for any ‘Groups’ button, link, text, title, etc. On iOS is used to go to the chats 'Groups' section from Contacts")
            rightDetailTextLabel.text = ""
        }
    }
}
