import Contacts
import ContactsUI
import MessageUI
import UIKit

class InviteContactViewController: UIViewController {

    var userLink = String()

    @IBOutlet var mainView: UIView!
    
    @IBOutlet weak var contactsOnMegaContainerView: UIView!
    @IBOutlet weak var addFromContactsView: UIStackView!
    @IBOutlet weak var addFromContactsLabel: UILabel!
    @IBOutlet weak var addFromContactsSeparatorView: UIView!
    @IBOutlet weak var enterEmailLabel: UILabel!
    @IBOutlet weak var enterEmailSeparatorView: UIView!
    @IBOutlet weak var scanQrCodeLabel: UILabel!
    @IBOutlet weak var scanQrCodeSeparatorView: UIView!
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
        
        if CNContactStore.authorizationStatus(for: .contacts) == .authorized && ContactsOnMegaManager.shared.contactsOnMegaCount() != 0 {
            createContactsOnMegaChild()
        }
        
        if !MFMessageComposeViewController.canSendText() {
            addFromContactsLabel.textColor = UIColor.mnz_secondaryGray(for: self.traitCollection)
        }
        
        updateAppearance()
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        navigationController?.presentationController?.delegate = self
    }
    
    override var supportedInterfaceOrientations: UIInterfaceOrientationMask {
        return .portrait
    }
    
    override func traitCollectionDidChange(_ previousTraitCollection: UITraitCollection?) {
        super.traitCollectionDidChange(previousTraitCollection)
        
        if #available(iOS 13, *) {
            if traitCollection.hasDifferentColorAppearance(comparedTo: previousTraitCollection) {
                self.updateAppearance()
            }
        }
    }
    
    // MARK: - Private
    
    func updateAppearance() {
        mainView.backgroundColor = (presentingViewController == nil) ? .mnz_backgroundGrouped(for: traitCollection) : .mnz_backgroundGroupedElevated(traitCollection)
        
        let separatorColor = UIColor.mnz_separator(for: self.traitCollection)
        addFromContactsSeparatorView.backgroundColor = separatorColor
        enterEmailSeparatorView.backgroundColor = separatorColor
        scanQrCodeSeparatorView.backgroundColor = separatorColor
    }
    
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
        
        let contactsPickerNavigation = MEGANavigationController.init(rootViewController: ContactsPickerViewController.instantiate(withContactKeys: [CNContactPhoneNumbersKey], delegate: self))
        present(contactsPickerNavigation, animated: true, completion:nil)
    }

    @IBAction func enterEmailButtonTapped(_ sender: Any) {
        guard let enterEmailVC = UIStoryboard(name: "InviteContact", bundle: nil).instantiateViewController(withIdentifier: "EnterEmailViewControllerID") as? EnterEmailViewController else { return }
        navigationItem.backBarButtonItem = UIBarButtonItem(title: "", style: .plain, target: nil, action: nil)
        navigationController?.pushViewController(enterEmailVC, animated: true)
    }

    @IBAction func scanQrCodeButtonTapped(_ sender: Any) {
        guard let contactLinkVC = UIStoryboard(name: "ContactLinkQR", bundle: nil).instantiateViewController(withIdentifier: "ContactLinkQRViewControllerID") as? ContactLinkQRViewController  else { return }
        contactLinkVC.scanCode = true
        present(contactLinkVC, animated: true, completion: nil)
    }

    @IBAction func moreButtonTapped(_ sender: Any) {
        let items = [AMLocalizedString("Hi, Have encrypted conversations on Mega with me and get 50GB free storage.", "Text to send as SMS message to user contacts inviting them to MEGA"), userLink]
        let activity = UIActivityViewController(activityItems: items, applicationActivities: [])
        activity.popoverPresentationController?.sourceView = moreLabel
        activity.popoverPresentationController?.sourceRect = moreLabel.frame
        present(activity, animated: true)
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

// MARK: - ContactsPickerViewControllerDelegate

extension InviteContactViewController: ContactsPickerViewControllerDelegate {
    func contactsPicker(_ contactsPicker: ContactsPickerViewController, didSelectContacts values: [String]) {
        let composeVC = MFMessageComposeViewController()
        composeVC.messageComposeDelegate = self
        composeVC.recipients = values
        composeVC.body = AMLocalizedString("Hi, Have encrypted conversations on Mega with me and get 50GB free storage.", "Text to send as SMS message to user contacts inviting them to MEGA") + " " + self.userLink
        self.present(composeVC, animated: true, completion: nil)
    }
}

// MARK: - UIAdaptivePresentationControllerDelegate

extension InviteContactViewController: UIAdaptivePresentationControllerDelegate {
    func presentationControllerShouldDismiss(_ presentationController: UIPresentationController) -> Bool {
        return false
    }
    
    func presentationControllerDidAttemptToDismiss(_ presentationController: UIPresentationController) {
        let discardChangesActionSheet = UIAlertController().discardChanges(fromSourceView: navigationController?.view, sourceRect: CGRect(x: 20, y: 20, width: 1, height: 1), withConfirmAction: {
            self.dismiss(animated: true, completion: nil)
        })
        present(discardChangesActionSheet, animated: true, completion: nil)
    }
}
