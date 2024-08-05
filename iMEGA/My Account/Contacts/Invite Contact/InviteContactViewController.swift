import ContactsUI
import MEGADesignToken
import MEGADomain
import MEGAL10n
import MEGAPermissions
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
    
    @IBOutlet var disclosureIndicatorImageViews: [UIImageView]!
    @IBOutlet var separatorViews: [UIView]!
    
    @IBOutlet weak var addToContactImageView: UIImageView!
    @IBOutlet weak var enterEmailImageView: UIImageView!
    @IBOutlet weak var scanQRImageView: UIImageView!
    @IBOutlet weak var moreImageView: UIImageView!
    
    private let contactPickerViewController: CNContactPickerViewController = {
        let controller = CNContactPickerViewController()
        controller.predicateForEnablingContact = NSPredicate(format: "phoneNumbers.@count > 0")
        return controller
    }()

    // MARK: Lifecycle
    override func viewDidLoad() {
        super.viewDidLoad()

        navigationItem.title = Strings.Localizable.inviteContact
        addFromContactsLabel.text = Strings.Localizable.addFromContacts
        enterEmailLabel.text = Strings.Localizable.enterEmail
        scanQrCodeLabel.text = Strings.Localizable.scanCode
        moreLabel.text = Strings.Localizable.more

        let contactLinkCreateDelegate = MEGAContactLinkCreateRequestDelegate { (request) in
            guard let base64Handle = MEGASdk.base64Handle(forHandle: request.nodeHandle) else { return }
            self.userLink = String(format: "https://mega.nz/C!%@", base64Handle)
        }

        MEGASdk.shared.contactLinkCreateRenew(false, delegate: contactLinkCreateDelegate)
        
        updateAppearance()

        contactPickerViewController.delegate = self
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        navigationController?.presentationController?.delegate = self
        setMenuCapableBackButtonWith(menuTitle: Strings.Localizable.inviteContact)
        guard let navigationBar = navigationController?.navigationBar else { return }
        AppearanceManager.forceNavigationBarUpdate(navigationBar, traitCollection: traitCollection)
    }
    
    override func traitCollectionDidChange(_ previousTraitCollection: UITraitCollection?) {
        super.traitCollectionDidChange(previousTraitCollection)
        
        if traitCollection.hasDifferentColorAppearance(comparedTo: previousTraitCollection) {
            self.updateAppearance()
        }
    }
    
    // MARK: - Private
    
    private func updateAppearance() {
        if UIColor.isDesignTokenEnabled() {
            mainView.backgroundColor = TokenColors.Background.page
            
            disclosureIndicatorImageViews.forEach {
                $0.image = UIImage.standardDisclosureIndicatorDesignToken
            }
            
            separatorViews.forEach {
                $0.backgroundColor = TokenColors.Border.strong
            }
            
            let primaryTextColor = TokenColors.Text.primary
            enterEmailLabel.textColor = primaryTextColor
            scanQrCodeLabel.textColor = primaryTextColor
            moreLabel.textColor = primaryTextColor
            addFromContactsLabel.textColor = MFMessageComposeViewController.canSendText() ? primaryTextColor : TokenColors.Text.secondary
            
            addToContactImageView.image = UIImage.addFromContacts
            enterEmailImageView.image = UIImage.enterUserEmail
            scanQRImageView.image = UIImage.scanUserQRCode
            moreImageView.image = UIImage.inviteContactMore

        } else {
            mainView.backgroundColor = (presentingViewController == nil) ? .mnz_backgroundGrouped(for: traitCollection) : .mnz_secondaryBackground(for: traitCollection)
            
            let separatorColor = UIColor.mnz_separator(for: traitCollection)
            addFromContactsSeparatorView.backgroundColor = separatorColor
            enterEmailSeparatorView.backgroundColor = separatorColor
            scanQrCodeSeparatorView.backgroundColor = separatorColor
            
            addFromContactsLabel.textColor = MFMessageComposeViewController.canSendText() ? .label : .mnz_secondaryGray(for: traitCollection)
        }
    }

    private func presentComposeControllerForPhoneNumbers(_ phoneNumbers: [String]) {
        let composeVC = MFMessageComposeViewController()
        composeVC.messageComposeDelegate = self
        composeVC.recipients = phoneNumbers
        composeVC.body = Strings.Localizable.Contact.Invite.message + " " + self.userLink
        present(composeVC, animated: true, completion: nil)
    }

    // MARK: Actions
    @IBAction func addFromContactsButtonTapped(_ sender: Any) {
        guard MFMessageComposeViewController.canSendText() else {
            return
        }

        present(contactPickerViewController, animated: true, completion: nil)
    }

    @IBAction func enterEmailButtonTapped(_ sender: Any) {
        guard let enterEmailVC = UIStoryboard(name: "InviteContact", bundle: nil).instantiateViewController(withIdentifier: "EnterEmailViewControllerID") as? EnterEmailViewController else { return }
        navigationController?.pushViewController(enterEmailVC, animated: true)
    }

    @IBAction func scanQrCodeButtonTapped(_ sender: Any) {
        guard let contactLinkVC = UIStoryboard(name: "ContactLinkQR", bundle: nil).instantiateViewController(withIdentifier: "ContactLinkQRViewControllerID") as? ContactLinkQRViewController  else { return }
        contactLinkVC.scanCode = true
        contactLinkVC.modalPresentationStyle = .fullScreen
        present(contactLinkVC, animated: true, completion: nil)
    }

    @IBAction func moreButtonTapped(_ sender: Any) {
        guard let url = URL(string: userLink) else { return }
        let metadataItemSource = ContactLinkPresentationItemSource(title: Strings.Localizable.Invite.ContactLink.Share.title, description: Strings.Localizable.Contact.Invite.message, icon: .megaShareContactLink, url: url)
        let activity = UIActivityViewController(activityItems: [metadataItemSource], applicationActivities: [])
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
            controller.present(UIAlertController(title: Strings.Localizable.somethingWentWrong, message: "Try it later", preferredStyle: .alert), animated: true, completion: nil)

        case .cancelled, .sent:
            controller.dismiss(animated: true, completion: nil)

        @unknown default:
            controller.dismiss(animated: true, completion: nil)
        }
    }
}

extension InviteContactViewController: CNContactPickerDelegate {
    func contactPicker(_ picker: CNContactPickerViewController, didSelect contacts: [CNContact]) {
        let phoneNumbers = contacts.extractPhoneNumbers()
        presentComposeControllerForPhoneNumbers(phoneNumbers)
    }
}

// MARK: - UIAdaptivePresentationControllerDelegate

extension InviteContactViewController: UIAdaptivePresentationControllerDelegate {
    func presentationControllerShouldDismiss(_ presentationController: UIPresentationController) -> Bool {
        return false
    }
    
    func presentationControllerDidAttemptToDismiss(_ presentationController: UIPresentationController) {
        guard let sourceView = navigationController?.view else { return }
        let discardChangesActionSheet = UIAlertController().discardChanges(fromSourceView: sourceView, sourceRect: CGRect(x: 20, y: 20, width: 1, height: 1), withConfirmAction: {
            self.dismiss(animated: true, completion: nil)
        })
        present(discardChangesActionSheet, animated: true, completion: nil)
    }
}
