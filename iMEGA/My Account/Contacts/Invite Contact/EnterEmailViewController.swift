import ContactsUI
import MEGADesignToken
import MEGADomain
import MEGAL10n
import UIKit
import WSTagsField

class EnterEmailViewController: UIViewController {
    @IBOutlet weak var descriptionLabel: UILabel!
    @IBOutlet weak var descriptionView: UIView!
    @IBOutlet weak var instructionsLabel: UILabel!
    @IBOutlet weak var inviteContactsButton: UIButton!
    @IBOutlet weak var tagsFieldView: UIView!
    @IBOutlet weak var tagsField: WSTagsField!
    @IBOutlet weak var tagsFieldHeightLayoutConstraint: NSLayoutConstraint!
    @IBOutlet weak var tagsFieldButton: UIButton!
    @IBOutlet weak var inviteContactsButtonBottomConstraint: NSLayoutConstraint!
    @IBOutlet weak var separatorView: UIView!
    
    private let contactPickerViewController: CNContactPickerViewController = {
        let controller = CNContactPickerViewController()
        controller.predicateForEnablingContact = NSPredicate(format: "emailAddresses.@count > 0")
        return controller
    }()
    
    // MARK: Lifecycle
    override func viewDidLoad() {
        super.viewDidLoad()
        
        navigationItem.title = Strings.Localizable.enterEmail
        
        descriptionLabel.text = Strings.Localizable.selectFromPhoneContactsOrEnterMultipleEmailAddresses
        instructionsLabel.text = Strings.Localizable.tapSpaceToEnterMultipleEmails
        customizeTagsField()
        
        disableInviteContactsButton()
        
        updateAppearance()
        
        navigationController?.presentationController?.delegate = self
        contactPickerViewController.delegate = self
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        
        NotificationCenter.default.addObserver(self, selector: #selector(keyboardWillShow(_:)), name: UIResponder.keyboardWillShowNotification, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(keyBoardWillHide(_:)), name: UIResponder.keyboardWillHideNotification, object: nil)
        
        tagsField.becomeFirstResponder()
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        
        NotificationCenter.default.removeObserver(self)
    }
    
    override func viewWillTransition(to size: CGSize, with coordinator: any UIViewControllerTransitionCoordinator) {
        super.viewWillTransition(to: size, with: coordinator)
        coordinator.animate(alongsideTransition: { (_) in
            self.tagsFieldHeightLayoutConstraint.constant = self.tagsField.frame.height
        }, completion: nil)
    }
    
    override func traitCollectionDidChange(_ previousTraitCollection: UITraitCollection?) {
        super.traitCollectionDidChange(previousTraitCollection)
        
        if traitCollection.hasDifferentColorAppearance(comparedTo: previousTraitCollection) {
            self.updateAppearance(shouldClearExistingText: false)
        }
    }
    
    // MARK: Notifications
    @objc func keyboardWillShow(_ notification: Notification) {
        guard let info = notification.userInfo else { return }
        guard let value: NSValue = info[UIResponder.keyboardFrameEndUserInfoKey] as? NSValue else { return }
        let keyboardSize = value.cgRectValue
        
        if let durationNumber = info[UIResponder.keyboardAnimationDurationUserInfoKey] as? NSNumber, let keyboardCurveNumber = info[UIResponder.keyboardAnimationCurveUserInfoKey] as? NSNumber {
            let duration = durationNumber.doubleValue
            let keyboardCurve = keyboardCurveNumber.uintValue
            UIView.animate(withDuration: duration, delay: 0, options: UIView.AnimationOptions(rawValue: keyboardCurve), animations: {
                self.updateBottomConstraint(keyboardSize.height)
            }, completion: nil)
        } else {
            updateBottomConstraint(250)
        }
    }
    
    @objc func keyBoardWillHide(_ notification: Notification) {
        guard let info = notification.userInfo else { return }
        
        if let durationNumber = info[UIResponder.keyboardAnimationDurationUserInfoKey] as? NSNumber, let keyboardCurveNumber = info[UIResponder.keyboardAnimationCurveUserInfoKey] as? NSNumber {
            let duration = durationNumber.doubleValue
            let keyboardCurve = keyboardCurveNumber.uintValue
            UIView.animate(withDuration: duration, delay: 0, options: UIView.AnimationOptions(rawValue: keyboardCurve), animations: {
                self.updateBottomConstraint(60)
            }, completion: nil)
        } else {
            updateBottomConstraint(60)
        }
    }
    
    // MARK: Private
    
    private func updateAppearance(shouldClearExistingText: Bool = true) {
        view.backgroundColor = TokenColors.Background.page
        descriptionLabel.textColor = TokenColors.Text.primary
        tagsFieldView.backgroundColor = TokenColors.Background.page
        tagsFieldButton.tintColor = TokenColors.Button.primary
        separatorView.backgroundColor = TokenColors.Border.strong
        
        customizeTagsField(shouldClearExistingText: shouldClearExistingText)
        
        if tagsField.tags.isNotEmpty || tagsField.text?.mnz_isValidEmail() == true {
            inviteContactsButton.mnz_setupPrimary(traitCollection)
        } else {
            inviteContactsButton.mnz_setupPrimary_disabled(traitCollection)
        }
        
        if instructionsLabel.text == Strings.Localizable.theEmailAddressFormatIsInvalid {
            tagsField.textField.textColor = TokenColors.Text.error
        } else {
            tagsField.textField.textColor = TokenColors.Text.primary
        }
    }
    
    private func updateBottomConstraint(_ newValue: CGFloat) {
        inviteContactsButtonBottomConstraint.constant = newValue
        view.layoutIfNeeded()
    }
    
    private func disableInviteContactsButton() {
        inviteContactsButton.setTitle(Strings.Localizable.invite, for: .normal)
        inviteContactsButton.mnz_setupPrimary_disabled(traitCollection)
    }
    
    private func enableInviteContactsButton() {
        inviteContactsButton.mnz_setupPrimary(traitCollection)
        let emailTag = tagsField.text?.mnz_isValidEmail() == true ? 1 : 0
        let tagsNumber = tagsField.tags.count + emailTag
        
        inviteContactsButton.setTitle(
            Strings.Localizable.Contacts.Invite.EmailAddress.inviteNumberOfContacts(tagsNumber),
            for: .normal
        )
    }
    
    private func customizeTagsField(shouldClearExistingText: Bool = true) {
        
        tagsField.layoutMargins = UIEdgeInsets(top: 4, left: 8, bottom: 4, right: 8)
        
        let tagsFieldColor = TokenColors.Background.surface1
        let tagsFieldTextColor = TokenColors.Text.primary
        tagsField.spaceBetweenLines = 12.0
        tagsField.spaceBetweenTags = 10.0
        tagsField.font = .preferredFont(forTextStyle: .body)
        tagsField.tintColor = tagsFieldColor
        tagsField.textColor = tagsFieldTextColor
        tagsField.selectedColor = tagsFieldColor
        tagsField.selectedTextColor = tagsFieldTextColor
        
        tagsField.textField.textColor = tagsFieldTextColor
        tagsField.textField.keyboardType = .emailAddress
        tagsField.textField.returnKeyType = .next
        tagsField.acceptTagOption = .space
        
        tagsField.cornerRadius = 16
        
        tagsField.placeholderColor = TokenColors.Text.placeholder
        tagsField.placeholder = Strings.Localizable.insertYourFriendsEmails
        
        configureTagFieldEvents()
    }
    
    private func updateUIOnEmailPickedFromContacts(_ email: String) {
        tagsField.addTag(email)
        
        instructionsLabel.text = Strings.Localizable.tapSpaceToEnterMultipleEmails
        instructionsLabel.textColor = TokenColors.Text.secondary
        
        if tagsField.tags.isEmpty {
            disableInviteContactsButton()
        } else {
            enableInviteContactsButton()
        }
    }
    
    // MARK: Actions
    @IBAction func inviteContactsTapped(_ sender: UIButton) {
        if let text = tagsField.text, text.mnz_isValidEmail() {
            tagsField.textField.textColor = TokenColors.Text.primary
            instructionsLabel.text = Strings.Localizable.tapSpaceToEnterMultipleEmails
            instructionsLabel.textColor = TokenColors.Text.secondary
            tagsField.addTag(text)
        }
        
        guard MEGAReachabilityManager.isReachableHUDIfNot(), tagsField.tags.isNotEmpty else {
            return
        }
        
        weak var weakSelf = self
        let inviteContactRequestDelegate = MEGAInviteContactRequestDelegate.init(numberOfRequests: UInt(tagsField.tags.count), presentSuccessOver: UIApplication.mnz_presentingViewController()) {
            weakSelf?.tagsField.removeTags()
            weakSelf?.disableInviteContactsButton()
            weakSelf?.navigationController?.popViewController(animated: true)
        }
        tagsField.tags.forEach { (tag) in
            MEGASdk.shared.inviteContact(withEmail: tag.text, message: "", action: MEGAInviteAction.add, delegate: inviteContactRequestDelegate)
        }
        
        tagsField.textField.resignFirstResponder()
    }
    
    @IBAction func addContactsTapped(_ sender: UIButton) {
        if presentedViewController != nil {
            presentedViewController?.dismiss(animated: true) {
                self.showContactsPicker()
            }
        } else {   
            showContactsPicker()
        }
    }
    
    private func showContactsPicker() {
        present(contactPickerViewController, animated: true, completion: nil)
    }
}

// MARK: - CNContactPickerDelegate

extension EnterEmailViewController: CNContactPickerDelegate {
    func contactPicker(_ picker: CNContactPickerViewController, didSelect contacts: [CNContact]) {
        let emails = contacts.extractEmails()
        emails.forEach(updateUIOnEmailPickedFromContacts(_:))
    }
}

// MARK: - UIAdaptivePresentationControllerDelegate

extension EnterEmailViewController: UIAdaptivePresentationControllerDelegate {
    func presentationControllerShouldDismiss(_ presentationController: UIPresentationController) -> Bool {
        false
    }
}

// MARK: - WSTagFieldEvents

extension EnterEmailViewController {
    
    private func configureTagFieldEvents() {
        tagsField.onDidAddTag = { _, _ in
            if self.tagsField.tags.isNotEmpty {
                self.enableInviteContactsButton()
            }
        }
        
        tagsField.onDidRemoveTag = { _, _ in
            self.instructionsLabel.text = Strings.Localizable.tapSpaceToEnterMultipleEmails
            
            if self.tagsField.tags.isNotEmpty {
                self.enableInviteContactsButton()
            } else {
                self.disableInviteContactsButton()
            }
        }
        
        tagsField.onDidChangeText = { _, text in
            if text!.mnz_isValidEmail() || self.tagsField.tags.isNotEmpty {
                self.tagsField.textField.textColor = TokenColors.Text.primary
                self.instructionsLabel.text = Strings.Localizable.tapSpaceToEnterMultipleEmails
                self.instructionsLabel.textColor = TokenColors.Text.secondary
                self.enableInviteContactsButton()
            } else {
                self.disableInviteContactsButton()
            }
        }
        
        tagsField.onDidChangeHeightTo = { [weak self] _, height in
            self?.tagsFieldHeightLayoutConstraint.constant = height
        }
        
        tagsField.onShouldAcceptTag = { field in
            guard let text = field.text else {
                return false
            }
            if text.mnz_isValidEmail() {
                self.tagsField.textField.textColor = TokenColors.Text.primary
                self.instructionsLabel.text = Strings.Localizable.tapSpaceToEnterMultipleEmails
                self.instructionsLabel.textColor = TokenColors.Text.secondary
                
                return true
            } else {
                self.tagsField.textField.textColor = TokenColors.Text.error
                self.instructionsLabel.text = Strings.Localizable.theEmailAddressFormatIsInvalid
                
                return false
            }
        }
    }
    
}
