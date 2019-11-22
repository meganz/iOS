
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

        navigationItem.title = AMLocalizedString("inviteContact", "Text shown when the user tries to make a call and the receiver is not a contact")
        addFromContactsLabel.text = AMLocalizedString("addFromContacts", "Item menu option to add a contact through your device app Contacts")
        enterEmailLabel.text = AMLocalizedString("Enter Email", "Text used as a section title or similar")
        scanQrCodeLabel.text = AMLocalizedString("scanCode")
        moreLabel.text = AMLocalizedString("more")
        
        let contactLinkCreateDelegate = MEGAContactLinkCreateRequestDelegate { (request) in
            guard let base64Handle = MEGASdk.base64Handle(forHandle: request.nodeHandle) else { return }
            self.userLink = String(format: "https://mega.nz/C!%@", base64Handle)
        }
        MEGASdkManager.sharedMEGASdk().contactLinkCreateRenew(false, delegate: contactLinkCreateDelegate)
        
        if UserDefaults.standard.bool(forKey: "IsChatEnabled") {
            createContactsOnMegaChild()
        }
        
        if !MFMessageComposeViewController.canSendText() {
            addFromContactsLabel.textColor = UIColor.mnz_gray8F8F8F()
        }
    }
    
    override var supportedInterfaceOrientations: UIInterfaceOrientationMask {
        return .portrait
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
    func contactPicker(_ picker: CNContactPickerViewController, didSelect contactProperty: CNContactProperty) {
        print(contactProperty)
        picker.dismiss(animated: true) {
            let composeVC = MFMessageComposeViewController()
            composeVC.messageComposeDelegate = self
            guard let phone = (contactProperty.value as AnyObject).stringValue else { return }
            
            composeVC.recipients = [phone]
            composeVC.body = AMLocalizedString("Hi, Have encrypted conversations on Mega with me and get 50GB free storage.", "Text to send as SMS message to user contacts inviting them to MEGA") + " " + self.userLink
            self.present(composeVC, animated: true, completion: nil)
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
