
import Contacts
import ContactsUI
import MessageUI
import UIKit

class InviteContactViewController: UIViewController {

    var userLink = String()

    @IBOutlet weak var contactsOnMegaContainerView: UIView!
    @IBOutlet weak var addFromContactsView: UIStackView!
    @IBOutlet weak var addFromContactsLabel: UILabel!
    @IBOutlet weak var enterEmailLabel: UILabel!
    @IBOutlet weak var scanQrCodeLabel: UILabel!
    @IBOutlet weak var moreLabel: UILabel!

    // MARK: Lifecycle
    override func viewDidLoad() {
        super.viewDidLoad()

        navigationItem.title = NSLocalizedString("inviteContact", comment: "Text shown when the user tries to make a call and the receiver is not a contact")
        
        let contactLinkCreateDelegate = MEGAContactLinkCreateRequestDelegate { (request) in
            self.userLink = String(format: "https://mega.nz/C!%@", MEGASdk.base64Handle(forHandle: request.nodeHandle))
        }
        MEGASdkManager.sharedMEGASdk().contactLinkCreateRenew(false, delegate: contactLinkCreateDelegate)
        
        createContactsOnMegaChild()
        
        if !MFMessageComposeViewController.canSendText() {
            addFromContactsLabel.textColor = UIColor.mnz_gray8F8F8F()
        }
}
    
    //MARK: Private
    func createContactsOnMegaChild() {
        guard let contactsOnMegaVC = storyboard?.instantiateViewController(withIdentifier: "ContactsOnMegaViewControllerID") as? ContactsOnMegaViewController else {
            return
        }
        addChild(contactsOnMegaVC)
        contactsOnMegaVC.view.frame = contactsOnMegaContainerView.bounds
        contactsOnMegaContainerView.addSubview(contactsOnMegaVC.view)
        contactsOnMegaVC.didMove(toParent: self)
        contactsOnMegaVC.searchFixedView.isHidden = true
        contactsOnMegaVC.inviteContactView.isHidden = true
        contactsOnMegaVC.hideSearchAndInviteViews()
    }
    
    // MARK: Actions
    @IBAction func addFromContactsButtonTapped(_ sender: Any) {
        guard MFMessageComposeViewController.canSendText() else {
            return
        }
        
        let contactsPickerVC = CNContactPickerViewController()
        contactsPickerVC.predicateForEnablingContact = NSPredicate(format: "phoneNumbers.@count > 0")
        contactsPickerVC.predicateForSelectionOfProperty = NSPredicate(format: "key == 'phoneNumbers'")
        contactsPickerVC.displayedPropertyKeys = [CNContactPhoneNumbersKey]
        contactsPickerVC.delegate = self
        
        present(contactsPickerVC, animated: true, completion: nil)
    }
    
    @IBAction func enterEmailButtonTapped(_ sender: Any) {
        guard let enterEmailVC = UIStoryboard(name: "Contacts", bundle: nil).instantiateViewController(withIdentifier: "EnterEmailViewControllerID") as? EnterEmailViewController else { return }
        navigationItem.backBarButtonItem = UIBarButtonItem(title: "", style: .plain, target: nil, action: nil)
        navigationController?.pushViewController(enterEmailVC, animated: true)
    }
    
    @IBAction func scanQrCodeButtonTapped(_ sender: Any) {
        guard let contactLinkVC = UIStoryboard(name: "Contacts", bundle: nil).instantiateViewController(withIdentifier: "ContactLinkQRViewControllerID") as? ContactLinkQRViewController  else { return }
        contactLinkVC.scanCode = true
        present(contactLinkVC, animated: true, completion: nil)
    }
    
    @IBAction func moreButtonTapped(_ sender: Any) {
        let activity = UIActivityViewController(activityItems: [userLink], applicationActivities: [])
        activity.popoverPresentationController?.sourceView = moreLabel
        activity.popoverPresentationController?.sourceRect = moreLabel.frame
        present(activity, animated: true)
    }
}

// MARK: - CNContactPickerDelegate
extension InviteContactViewController: CNContactPickerDelegate {
    func contactPicker(_ picker: CNContactPickerViewController, didSelect contacts: [CNContact]) {
        var phones = [String]()
        contacts.forEach { (contact) in
            phones.append(contentsOf: contact.phoneNumbers.map( { $0.value.stringValue.replacingOccurrences(of: " ", with: "") } ) )
        }
        
        picker.dismiss(animated: true) {
            if phones.count > 0 {
                let composeVC = MFMessageComposeViewController()
                composeVC.messageComposeDelegate = self
                composeVC.recipients = phones
                composeVC.body = NSLocalizedString("Hi, Have encrypted conversations on Mega with me and get 50GB free storage.", comment: "Text to send as SMS message to user contacts inviting them to MEGA") + " " + self.userLink
                self.present(composeVC, animated: true, completion: nil)
            }
        }
    }
}

// MARK: - MFMessageComposeViewControllerDelegate
extension InviteContactViewController: MFMessageComposeViewControllerDelegate {
    func messageComposeViewController(_ controller: MFMessageComposeViewController, didFinishWith result: MessageComposeResult) {
        switch result {
        case .failed:
            controller.present(UIAlertController(title: "Something went wrong", message: "Try it later", preferredStyle: .alert), animated: true, completion: nil)
            
        case .cancelled, .sent:
            controller.dismiss(animated: true, completion: nil)

        @unknown default:
            controller.dismiss(animated: true, completion: nil)
        }
    }
}
