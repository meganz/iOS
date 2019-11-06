
import ContactsUI
import UIKit

class EnterEmailViewController: UIViewController {

    @IBOutlet weak var descriptionLabel: UILabel!
    @IBOutlet weak var instructionsLabel: UILabel!
    @IBOutlet weak var inviteContactsButton: UIButton!
    @IBOutlet weak var tokenField: VENTokenField!
    @IBOutlet weak var tokenFieldHeightLayoutConstraint: NSLayoutConstraint!
    @IBOutlet weak var inviteContactsButtonBottomConstraint: NSLayoutConstraint!

    var tokens = [String]()
    
    // MARK: Lifecycle
    override func viewDidLoad() {
        super.viewDidLoad()
        
        navigationItem.title = AMLocalizedString("Enter Email", "Text used as a section title or similar")
        
        descriptionLabel.text = AMLocalizedString("inviteYourFriendsExplanation", "Text shown to explain how and where you can invite friends")
        instructionsLabel.text = AMLocalizedString("Tap space to enter multiple emails", "Text showing the user how to write more than one email in order to invite them to MEGA")
        customizeTokenField()
        
        disableInviteContactsButton()
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        
        NotificationCenter.default.addObserver(self, selector: #selector(keyboardWillShow(_:)), name: UIResponder.keyboardWillShowNotification, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(keyBoardWillHide(_:)), name: UIResponder.keyboardWillHideNotification, object: nil)
        
        tokenField.becomeFirstResponder()
    }
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        
        NotificationCenter.default.removeObserver(self)
    }
    
    override func viewWillTransition(to size: CGSize, with coordinator: UIViewControllerTransitionCoordinator) {
        super.viewWillTransition(to: size, with: coordinator)
        coordinator.animate(alongsideTransition: { (context) in
            self.tokenField.reloadData()
            self.tokenFieldHeightLayoutConstraint.constant = self.tokenField.frame.height
        }, completion: nil)
    }
    
    // MARK: Notifications
    @objc func keyboardWillShow(_ notification:Notification) {
        guard let info = notification.userInfo else { return }
        guard let value: NSValue = info[UIResponder.keyboardFrameEndUserInfoKey] as? NSValue else { return }
        let keyboardSize = value.cgRectValue
        
        if let durationNumber = info[UIResponder.keyboardAnimationDurationUserInfoKey] as? NSNumber, let keyboardCurveNumber = info[UIResponder.keyboardAnimationCurveUserInfoKey] as? NSNumber {
            let duration = durationNumber.doubleValue
            let keyboardCurve = keyboardCurveNumber.uintValue
            UIView.animate(withDuration: duration, delay: 0, options: UIView.AnimationOptions(rawValue: keyboardCurve), animations: {
                self.updateBottomConstraint(keyboardSize.height)
            }, completion:nil)
        } else {
            updateBottomConstraint(250)
        }
    }
    
    @objc func keyBoardWillHide(_ notification:Notification) {
        guard let info = notification.userInfo else { return }
        
        if let durationNumber = info[UIResponder.keyboardAnimationDurationUserInfoKey] as? NSNumber, let keyboardCurveNumber = info[UIResponder.keyboardAnimationCurveUserInfoKey] as? NSNumber {
            let duration = durationNumber.doubleValue
            let keyboardCurve = keyboardCurveNumber.uintValue
            UIView.animate(withDuration: duration, delay: 0, options: UIView.AnimationOptions(rawValue: keyboardCurve), animations: {
                self.updateBottomConstraint(60)
            }, completion:nil)
        } else {
            updateBottomConstraint(60)
        }
    }
    
    // MARK: Private
    func updateBottomConstraint(_ newValue:CGFloat) {
        inviteContactsButtonBottomConstraint.constant = newValue
        view.layoutIfNeeded()
    }

    func disableInviteContactsButton() {
        inviteContactsButton.setTitle(AMLocalizedString("invite", "A button on a dialog which invites a contact to join MEGA."), for: .normal)
        inviteContactsButton.backgroundColor = UIColor.mnz_grayCCCCCC()
    }
    
    func enableInviteContactsButton() {
        inviteContactsButton.backgroundColor = UIColor.mnz_green00BFA5()
        inviteContactsButton.setTitle(AMLocalizedString("Invite [X] contacts", "Text showing the user how many contacts would be invited").replacingOccurrences(of: "[X]", with: String(tokens.count)), for: .normal)
    }
    
    func customizeTokenField() {
        tokenField.dataSource = self
        tokenField.delegate = self
        
        tokenField.maxHeight = 500
        tokenField.verticalInset = 11
        tokenField.horizontalInset = 11
        tokenField.tokenPadding = 10
        tokenField.minInputWidth = tokenField.frame.width / 2
        
        tokenField.inputTextFieldKeyboardType = .emailAddress
        
        tokenField.toLabelText = "";
        tokenField.inputTextFieldTextColor = UIColor.mnz_black333333()
        tokenField.inputTextFieldFont = UIFont.mnz_SFUIRegular(withSize: 17)
        
        tokenField.tokenFont = UIFont.mnz_SFUIRegular(withSize: 17)
        tokenField.tokenHighlightedTextColor = UIColor.mnz_black333333()
        tokenField.tokenHighlightedBackgroundColor = UIColor.mnz_grayEEEEEE()
        
        tokenField.delimiters = [",", " "];
        tokenField.placeholderText = AMLocalizedString("insertYourFriendsEmails", "");
        tokenField.setColorScheme(UIColor.mnz_redMain())
    }
    
    // MARK: Actions
    @IBAction func inviteContactsTapped(_ sender: UIButton) {
        guard MEGAReachabilityManager.isReachableHUDIfNot(), tokens.count > 0 else {
            return
        }
        
        let inviteContactRequestDelegate = MEGAInviteContactRequestDelegate.init(numberOfRequests: UInt(tokens.count))
        tokens.forEach { (email) in
            MEGASdkManager.sharedMEGASdk().inviteContact(withEmail: email, message: "", action: MEGAInviteAction.add, delegate: inviteContactRequestDelegate)
        }
        
        tokenField.resignFirstResponder()
    }
    
    @IBAction func addContactsTapped(_ sender: UIButton) {
        if (presentedViewController != nil) {
            presentedViewController?.dismiss(animated: false, completion: nil)
        }
        
        let contactsPickerVC = CNContactPickerViewController()
        contactsPickerVC.predicateForEnablingContact = NSPredicate(format: "emailAddresses.@count > 0")
        contactsPickerVC.predicateForSelectionOfProperty = NSPredicate(format: "key == 'emailAddresses'")
        contactsPickerVC.delegate = self
        present(contactsPickerVC, animated: true, completion: nil)
    }
}

// MARK - VENTokenFieldDataSource
extension EnterEmailViewController: VENTokenFieldDataSource {
    func tokenField(_ tokenField: VENTokenField, titleForTokenAt index: UInt) -> String {
        return tokens[Int(index)]
    }
    
    func numberOfTokens(in tokenField: VENTokenField) -> UInt {
        return UInt(tokens.count)
    }
    
    func tokenField(_ tokenField: VENTokenField, colorSchemeForTokenAt index: UInt) -> UIColor {
        return UIColor.mnz_black333333()
    }
}

// MARK - VENTokenFieldDelegate
extension EnterEmailViewController: VENTokenFieldDelegate {
    func tokenField(_ tokenField: VENTokenField, didEnterText text: String) {
        guard text.count != 0 || !text.mnz_isEmpty() else {
            return
        }
        
        if text.mnz_isValidEmail() {
            tokenField.inputTextFieldTextColor = UIColor.mnz_black333333()
            instructionsLabel.text = AMLocalizedString("Tap space to enter multiple emails", "Text showing the user how to write more than one email in order to invite them to MEGA")
            instructionsLabel.textColor = UIColor.mnz_gray999999()
            tokens.append(text)
            tokenField.reloadData()
            if tokens.count > 0 {
                enableInviteContactsButton()
            }
        } else {
            tokenField.inputTextFieldTextColor = UIColor.mnz_redMain()
            instructionsLabel.text = AMLocalizedString("theEmailAddressFormatIsInvalid", "Add contacts and share dialog error message when user try to add wrong email address")
        }
    }
    
    func tokenField(_ tokenField: VENTokenField, didDeleteTokenAt index: UInt) {
        tokens.remove(at: Int(index))
        tokenField.reloadData()
        
        instructionsLabel.text = AMLocalizedString("Tap space to enter multiple emails", "Text showing the user how to write more than one email in order to invite them to MEGA")

        if tokens.count == 0 {
            disableInviteContactsButton()
        }
    }
    
    func tokenField(_ tokenField: VENTokenField, didChangeContentHeight height: CGFloat) {
        tokenFieldHeightLayoutConstraint.constant = height
    }
}

// MARK: - CNContactPickerDelegate
extension EnterEmailViewController: CNContactPickerDelegate {
    func contactPicker(_ picker: CNContactPickerViewController, didSelect contacts: [CNContact]) {
        var invalidEmails = [String]()
        contacts.forEach { (contact) in
            contact.emailAddresses.forEach({ (email) in
                if email.value.mnz_isValidEmail() {
                    tokens.append(String(email.value))
                } else {
                    invalidEmails.append(String(email.value))
                }
            })
        }
        
        if invalidEmails.count > 0 {
            var invalidEmailsString = ""
            invalidEmails.forEach { (email) in
                invalidEmailsString += AMLocalizedString("theEmailAddressFormatIsInvalid", "Add contacts and share dialog error message when user try to add wrong email address") + ": " + email + "\n"
            }
            instructionsLabel.text = invalidEmailsString
            instructionsLabel.textColor = UIColor.mnz_redMain()
        } else {
            instructionsLabel.text = AMLocalizedString("Tap space to enter multiple emails", "Text showing the user how to write more than one email in order to invite them to MEGA")
            instructionsLabel.textColor = UIColor.mnz_gray999999()
        }
        
        tokenField.reloadData()
        
        if tokens.count == 0 {
            disableInviteContactsButton()
        } else {
            enableInviteContactsButton()
        }
    }
}
