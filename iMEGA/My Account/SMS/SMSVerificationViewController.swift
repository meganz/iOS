
import UIKit

@objc enum SMSVerificationType: Int {
    case UnblockAccount
    case AddPhoneNumber
}

class SMSVerificationViewController: UIViewController {
    
    @IBOutlet private weak var scrollView: UIScrollView!
    @IBOutlet private weak var headerImageView: UIImageView!
    @IBOutlet private weak var descriptionTextView: UITextView!
    @IBOutlet private weak var nextButton: UIButton!
    @IBOutlet private weak var cancelButton: UIButton!
    @IBOutlet private weak var titleLabel: UILabel!
    @IBOutlet private weak var phoneNumberLabel: UILabel!
    @IBOutlet private weak var phoneNumberTextField: UITextField!
    @IBOutlet private weak var countryNameLabel: UILabel!
    @IBOutlet private weak var countryCodeLabel: UILabel!
    @IBOutlet private weak var errorImageView: UIImageView!
    @IBOutlet private weak var errorMessageLabel: UILabel!
    @IBOutlet private weak var errorView: UIView!
    @IBOutlet private weak var countryLabel: UILabel!
    
    private var currentCountry: SMSCountry?
    private var countryCallingCodeDict: [String: MEGAStringList]?
    
    private var verificationType: SMSVerificationType = .UnblockAccount
    
    // MARK: - View lifecycle
    
    @objc class func instantiate(with verificationType: SMSVerificationType) -> SMSVerificationViewController {
        let controller = UIStoryboard(name: "SMSVerification", bundle: nil).instantiateViewController(withIdentifier: "SMSVerificationViewControllerID") as! SMSVerificationViewController
        controller.verificationType = verificationType
        return controller
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        navigationItem.backBarButtonItem = UIBarButtonItem(title: "", style: .plain, target: nil, action: nil)
        
        disableAutomaticAdjustmentContentInsetsBehavior()
        
        errorImageView.tintColor = UIColor.mnz_redError()
        errorMessageLabel.textColor = UIColor.mnz_redError()
        errorView.isHidden = true
        
        countryNameLabel.text = " "
        countryCodeLabel.text = nil
        loadCountryCallingCodes()
        
        configViewContents()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        NotificationCenter.default.addObserver(self, selector: #selector(didReceiveKeyboardWillShowNotification(_:)), name: UIResponder.keyboardWillShowNotification, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(didReceiveKeyboardWillHideNotification(_:)), name: UIResponder.keyboardWillHideNotification, object: nil)
        
        if !headerImageView.isHidden {
            navigationController?.isNavigationBarHidden = true
        }
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        
        NotificationCenter.default.removeObserver(self, name: UIResponder.keyboardWillShowNotification, object: nil)
        NotificationCenter.default.removeObserver(self, name: UIResponder.keyboardWillHideNotification, object: nil)
    }
    
    override var supportedInterfaceOrientations: UIInterfaceOrientationMask {
        if UIDevice.current.userInterfaceIdiom == .phone {
            return [.portrait, .portraitUpsideDown]
        } else {
            return .all
        }
    }
    
    // MARK: - Network calls
    
    private func loadCountryCallingCodes() {
        SVProgressHUD.show()
        MEGASdkManager.sharedMEGASdk()?.getCountryCallingCodes(with: MEGAGenericRequestDelegate() {
            [weak self] request, error in
            SVProgressHUD.dismiss()
            if error.type == .apiOk {
                self?.countryCallingCodeDict = request.megaStringListDictionary
                self?.configDefaultCountryCode()
            }
        })
    }
    
    private func configDefaultCountryCode() {
        guard let countryCallingCodeDict = countryCallingCodeDict else { return }
        guard let systemCurrentRegionCode = Locale.current.regionCode else { return }
        guard let callingCode = countryCallingCodeDict.first(where: { $0.key == systemCurrentRegionCode })?.value.string(at: 0) else { return }
        guard let appLanguageId = LocalizationSystem.sharedLocal()?.getLanguage() else { return }
        let appLocale = Locale(identifier: Locale.identifier(fromComponents: [NSLocale.Key.languageCode.rawValue : appLanguageId]))
        guard let country = SMSCountry(countryCode: systemCurrentRegionCode, countryLocalizedName: appLocale.localizedString(forRegionCode: systemCurrentRegionCode), callingCode: callingCode) else { return }
        
        configView(by: country)
    }
    
    // MARK: - UI actions
    
    @IBAction private func didTapCancelButton() {
        switch verificationType {
        case .UnblockAccount:
            MEGASdkManager.sharedMEGASdk()?.logout()
            phoneNumberTextField.resignFirstResponder()
            
        case .AddPhoneNumber:
            dismiss(animated: true, completion: nil)
            
        default:
            dismiss(animated: true, completion: nil)
            
        }
    }
    
    @IBAction private func didTapCountryView() {
        guard let countryCallingCodeDict = countryCallingCodeDict else { return }
        
        navigationController?.pushViewController(SMSCountriesTableViewController(countryCallingCodeDict: countryCallingCodeDict, delegate: self), animated: true)
    }
    
    @IBAction private func didTapPhoneView() {
        phoneNumberTextField.becomeFirstResponder()
    }
    
    @IBAction private func didTapNextButton() {
        guard let country = currentCountry, let localNumber = phoneNumberTextField.text else { return }
        
        let numberKit = PhoneNumberKit()
        do {
            let phoneNumber = try numberKit.parse("\(country.displayCallingCode)\(localNumber)")
            SVProgressHUD.show()
            MEGASdkManager.sharedMEGASdk()?.sendSMSVerificationCode(toPhoneNumber: numberKit.format(phoneNumber, toType: .e164), delegate: MEGAGenericRequestDelegate() {
                [weak self] request, error in
                SVProgressHUD.dismiss()
                if error.type == .apiOk {
                    self?.sendVerificationCodeSucceeded(with: phoneNumber)
                } else {
                    self?.sendVerificationCodeFailed(with: error)
                }
            })
        } catch {
            configErrorStyle(withErrorMessage: AMLocalizedString("Please enter a valid phone number"))
        }
    }
    
    @IBAction private func didEditingChangedInPhoneNumberField() {
        nextButton.isEnabled = !(phoneNumberTextField.text?.isEmpty ?? true)
        phoneNumberLabel.textColor = UIColor.mnz_secondaryGray(for: self.traitCollection)
        phoneNumberTextField.textColor = UIColor.black
        errorView.isHidden = true
    }
    
    private func sendVerificationCodeSucceeded(with number: PhoneNumber) {
        navigationController?.pushViewController(VerificationCodeViewController.instantiate(with: number, verificationType: verificationType), animated: true)
    }
    
    private func sendVerificationCodeFailed(with error: MEGAError) {
        var errorMessage: String?
        switch error.type {
        case .apiETempUnavail: // a limit is reached.
            errorMessage = AMLocalizedString("You have reached the daily limit")
        case .apiEAccess: // your account is already verified with an SMS number
            errorMessage = AMLocalizedString("Your account is already verified")
        case .apiEExist: // MEGAErrorTypeApiEExist if the number is already verified for some other account
            errorMessage = AMLocalizedString("This number is already associated with a Mega account")
        case .apiEArgs: // the phone number is badly formatted or invalid
            errorMessage = AMLocalizedString("Wrong code. Please try again or resend.")
        default: // other errors
            errorMessage = AMLocalizedString("Unknown error")
        }
        
        configErrorStyle(withErrorMessage: errorMessage)
    }
    
    private func animateViewAdjustments(withDuration duration: Double, keyboardHeight: CGFloat) {
        navigationController?.setNavigationBarHidden(false, animated: true)
        UIView.animate(withDuration: duration + 0.75, animations: {
            self.enableAutomaticAdjustmentContentInsetsBehavior()
            self.headerImageView.isHidden = true
            self.cancelButton.isHidden = true
            self.titleLabel.isHidden = true
            self.setNeedsStatusBarAppearanceUpdate()
        }) { _ in
            var insets = self.scrollView.contentInset
            insets.bottom = keyboardHeight
            self.scrollView.contentInset = insets
            self.scrollView.scrollIndicatorInsets = insets
        }
    }
    
    // MARK: - Notification handlers
    
    @objc private func didReceiveKeyboardWillShowNotification(_ notification: Notification) {
        guard let duration = (notification.userInfo?[UIResponder.keyboardAnimationDurationUserInfoKey] as? NSNumber)?.doubleValue,
            let keyboardHeight = (notification.userInfo?[UIResponder.keyboardFrameBeginUserInfoKey] as? NSValue)?.cgRectValue.height
            else { return }
        
        animateViewAdjustments(withDuration: duration, keyboardHeight: keyboardHeight)
    }
    
    @objc private func didReceiveKeyboardWillHideNotification(_ notification: Notification) {
        var insets = scrollView.contentInset
        insets.bottom = 0
        scrollView.contentInset = insets
        scrollView.scrollIndicatorInsets = insets
    }
    
    // MARK: - UI configurations
    
    private func configViewContents() {
        descriptionTextView.text = nil
        
        countryLabel.text = AMLocalizedString("Country")
        phoneNumberLabel.text = AMLocalizedString("Your phone number")
        nextButton.setTitle(AMLocalizedString("next"), for: .normal)
        
        switch verificationType {
        case .AddPhoneNumber:
            let cancelTitle = AMLocalizedString("cancel")
            navigationItem.rightBarButtonItem = UIBarButtonItem(title: cancelTitle, style: .plain, target: self, action: #selector(SMSVerificationViewController.didTapCancelButton))
            title = AMLocalizedString("Add Phone Number")
            titleLabel.text = title
            cancelButton.setTitle(cancelTitle, for: .normal)
            if !MEGASdkManager.sharedMEGASdk().isAchievementsEnabled {
                descriptionTextView.text = AMLocalizedString("Add your phone number to MEGA. This makes it easier for your contacts to find you on MEGA.")
            } else {
                MEGASdkManager.sharedMEGASdk()?.getAccountAchievements(with: MEGAGenericRequestDelegate() { [weak self] request, error in
                    guard error.type == .apiOk else { return }
                    guard let byteCount = request.megaAchievementsDetails?.classStorage(forClassId: Int(MEGAAchievement.addPhone.rawValue)) else { return }
                    UIView.animate(withDuration: 0.5) {
                        self?.descriptionTextView.text = String(format: AMLocalizedString("Get free %@ when you add your phone number. This makes it easier for your contacts to find you on MEGA."), Helper.memoryStyleString(fromByteCount: byteCount))
                    }
                })
            }
            
        case .UnblockAccount:
            let logoutTitle = AMLocalizedString("logoutLabel")
            navigationItem.rightBarButtonItem = UIBarButtonItem(title: logoutTitle, style: .plain, target: self, action: #selector(SMSVerificationViewController.didTapCancelButton))
            title = AMLocalizedString("Verify Your Account")
            titleLabel.text = title
            cancelButton.setTitle(logoutTitle, for: .normal)
            descriptionTextView.text = AMLocalizedString("Your account has been suspended temporarily due to potential abuse. Please verify your phone number to unlock your account.")
        }
    }
    
    private func configErrorStyle(withErrorMessage errorMessage: String?) {
        phoneNumberLabel.textColor = UIColor.mnz_redError()
        phoneNumberTextField.textColor = UIColor.mnz_redError()
        errorMessageLabel.text = errorMessage
        errorView.isHidden = false
    }
    
    private func configView(by country: SMSCountry) {
        currentCountry = country
        countryNameLabel.text = country.displayName
        countryCodeLabel.text = country.displayCallingCode
    }
    
    override var preferredStatusBarStyle: UIStatusBarStyle {
        if navigationController?.isNavigationBarHidden ?? false {
            return .lightContent
        } else {
            return .default
        }
    }
    
    private func enableAutomaticAdjustmentContentInsetsBehavior() {
        if #available(iOS 11.0, *) {
            scrollView.contentInsetAdjustmentBehavior = .automatic
        } else {
            automaticallyAdjustsScrollViewInsets = true
        }
    }
    
    private func disableAutomaticAdjustmentContentInsetsBehavior() {
        if #available(iOS 11.0, *) {
            scrollView.contentInsetAdjustmentBehavior = .never
        } else {
            automaticallyAdjustsScrollViewInsets = false
        }
    }
}

// MARK: - UIScrollViewDelegate

extension SMSVerificationViewController: UIScrollViewDelegate {
    func scrollViewDidScroll(_ scrollView: UIScrollView) {
        guard !headerImageView.isHidden else { return }
        
        let offset = scrollView.contentOffset
        if offset.y < 0 {
            var transform = CATransform3DTranslate(CATransform3DIdentity, 0, offset.y, 0)
            let scaleFactor = 1 + (-1 * offset.y / (headerImageView.frame.height / 2))
            transform = CATransform3DScale(transform, scaleFactor, scaleFactor, 1)
            headerImageView.layer.transform = transform
        } else {
            headerImageView.layer.transform = CATransform3DIdentity
        }
    }
}

// MARK: - SMSCountriesTableViewControllerDelegate

extension SMSVerificationViewController: SMSCountriesTableViewControllerDelegate {
    func countriesTableViewController(_ controller: SMSCountriesTableViewController?, didSelectCountry country: SMSCountry) {
        navigationController?.popToViewController(self, animated: true)
        configView(by: country)
    }
}

//MARK: - UITextFieldDelegate

extension SMSVerificationViewController: UITextFieldDelegate {
    func textField(_ textField: UITextField, shouldChangeCharactersIn range: NSRange, replacementString string: String) -> Bool {
        let currentText = textField.text ?? ""
        
        guard let stringRange = Range(range, in: currentText) else { return false }
        
        let updatedText = currentText.replacingCharacters(in: stringRange, with: string)
        
        return updatedText.count <= 20
    }
}
