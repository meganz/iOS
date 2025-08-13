import ContactsUI
import MEGAAppPresentation
import MEGAAssets
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
    
    let tracker = InviteContactTracking.inviteContactTracker

    // MARK: Lifecycle
    override func viewDidLoad() {
        super.viewDidLoad()

        navigationItem.title = Strings.Localizable.InviteContact.title
        addFromContactsLabel.text = Strings.Localizable.addFromContacts
        enterEmailLabel.text = Strings.Localizable.enterEmail
        scanQrCodeLabel.text = Strings.Localizable.scanCode
        moreLabel.text = Strings.Localizable.Invite.ContactLink.Share.title

        let contactLinkCreateDelegate = MEGAContactLinkCreateRequestDelegate { (request) in
            guard let base64Handle = MEGASdk.base64Handle(forHandle: request.nodeHandle) else { return }
            self.userLink = "https://\(DIContainer.appDomainUseCase.domainName)/C!\(base64Handle)"
        }

        MEGASdk.shared.contactLinkCreateRenew(false, delegate: contactLinkCreateDelegate)
        
        setupColors()

        contactPickerViewController.delegate = self
        tracker.trackInviteScreen()
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        forceResetNavigationBar()
        navigationController?.presentationController?.delegate = self
        setMenuCapableBackButtonWith(menuTitle: Strings.Localizable.inviteContact)
    }
    
    // MARK: - Private
    
    private func forceResetNavigationBar() {
        AppearanceManager.forceResetNavigationBar()
    }
    
    private func setupColors() {
        mainView.backgroundColor = TokenColors.Background.page
        
        disclosureIndicatorImageViews.forEach {
            $0.image = MEGAAssets.UIImage.standardDisclosureIndicatorDesignToken
        }
        
        separatorViews.forEach {
            $0.backgroundColor = TokenColors.Border.strong
        }
        
        let primaryTextColor = TokenColors.Text.primary
        enterEmailLabel.textColor = primaryTextColor
        scanQrCodeLabel.textColor = primaryTextColor
        moreLabel.textColor = primaryTextColor
        addFromContactsLabel.textColor = MFMessageComposeViewController.canSendText() ? primaryTextColor : TokenColors.Text.secondary
        
        addToContactImageView.image = MEGAAssets.UIImage.addFromContacts
        enterEmailImageView.image = MEGAAssets.UIImage.enterUserEmail
        scanQRImageView.image = MEGAAssets.UIImage.scanUserQRCode
        moreImageView.image = MEGAAssets.UIImage.inviteContactMore
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

        tracker.trackAddFromContactsTapped()
        AppearanceManager.setTranslucentNavigationBar()
        present(contactPickerViewController, animated: true, completion: nil)
    }

    @IBAction func enterEmailButtonTapped(_ sender: Any) {
        guard let enterEmailVC = UIStoryboard(name: "InviteContact", bundle: nil).instantiateViewController(withIdentifier: "EnterEmailViewControllerID") as? EnterEmailViewController else { return }
        tracker.trackEnterEmailAddressTapped()
        navigationController?.pushViewController(enterEmailVC, animated: true)
    }

    @IBAction func scanQrCodeButtonTapped(_ sender: Any) {
        guard let contactLinkVC = UIStoryboard(name: "ContactLinkQR", bundle: nil).instantiateViewController(withIdentifier: "ContactLinkQRViewControllerID") as? ContactLinkQRViewController  else { return }
        contactLinkVC.scanCode = true
        contactLinkVC.modalPresentationStyle = .fullScreen
        tracker.trackScanCodeTapped()
        present(contactLinkVC, animated: true, completion: nil)
    }

    @IBAction func moreButtonTapped(_ sender: Any) {
        guard let url = URL(string: userLink) else { return }
        let metadataItemSource = ContactLinkPresentationItemSource(title: Strings.Localizable.Invite.ContactLink.Share.title, description: Strings.Localizable.Contact.Invite.message, icon: MEGAAssets.UIImage.megaShareContactLink, url: url)
        let activity = UIActivityViewController(activityItems: [metadataItemSource], applicationActivities: [])
        activity.popoverPresentationController?.sourceView = moreLabel
        activity.popoverPresentationController?.sourceRect = moreLabel.frame
        tracker.trackShareInviteTapped()
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
        forceResetNavigationBar()
        let phoneNumbers = contacts.extractPhoneNumbers()
        UIApplication.mnz_visibleViewController().dismiss(animated: true) { [weak self] in
            self?.presentComposeControllerForPhoneNumbers(phoneNumbers)
        }
    }
    
    func contactPickerDidCancel(_ picker: CNContactPickerViewController) {
        forceResetNavigationBar()
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
