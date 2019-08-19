
import UIKit

class SMSVerificationViewController: UIViewController {
    
    @IBOutlet private var scrollView: UIScrollView!
    @IBOutlet private var headerImageView: UIImageView!
    @IBOutlet private var nextButton: UIButton!
    @IBOutlet private var phoneNumberLabel: UILabel!
    @IBOutlet private var phoneNumberTextField: UITextField!
    @IBOutlet private var countryNameLabel: UILabel!
    @IBOutlet private var countryCodeLabel: UILabel!
    @IBOutlet private var errorImageView: UIImageView!
    @IBOutlet private var errorMessageLabel: UILabel!
    @IBOutlet private var errorView: UIView!
    
    private var currentCountry: SMSCountry?
    
    private var countryCallingCodeDict: [String: MEGAStringList]?
    
    // MARK: - View lifecycle
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        title = "Verify Your Account"
        navigationItem.backBarButtonItem = UIBarButtonItem(title: "", style: .plain, target: nil, action: nil)
        
        disableAutomaticAdjustmentContentInsetsBehavior()
        
        NotificationCenter.default.addObserver(self, selector: #selector(didReceiveTextDidChangeNotification(_:)), name: UITextField.textDidChangeNotification, object: phoneNumberTextField)
        
        errorImageView.tintColor = UIColor.mnz_redError()
        errorMessageLabel.textColor = UIColor.mnz_redError()
        errorView.isHidden = true
        
        countryNameLabel.text = " "
        countryCodeLabel.text = nil
        loadCountryCallingCodes()
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
        guard let countryCallingCodeDict = countryCallingCodeDict else {
            return
        }
        
        guard let systemCurrentRegionCode = Locale.current.regionCode else {
            return
        }
        
        guard let callingCode = countryCallingCodeDict.first(where: { $0.key == systemCurrentRegionCode })?.value.first else {
            return
        }
        
        guard let appLanguageId = LocalizationSystem.sharedLocal()?.getLanguage() else {
            return
        }
        
        let appLocale = Locale(identifier: Locale.identifier(fromComponents: [NSLocale.Key.languageCode.rawValue : appLanguageId]))
        guard let country = SMSCountry(countryCode: systemCurrentRegionCode, countryLocalizedName: appLocale.localizedString(forRegionCode: systemCurrentRegionCode), callingCode: callingCode) else {
            return
        }
        
        configView(by: country)
    }
    
    // MARK: - UI actions
    
    @IBAction private func didTapCountryView() {
        guard let countryCallingCodeDict = countryCallingCodeDict else {
            return
        }
        
        navigationController?.pushViewController(SMSCountriesTableViewController(countryCallingCodeDict: countryCallingCodeDict, delegate: self), animated: true)
    }
    
    @IBAction private func didTapNextButton() {
        guard let country = currentCountry, let localNumber = phoneNumberTextField.text else {
            return
        }
        
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
            configErrorStyle(withErrorMessage: "The phone number is invalid")
        }
    }
    
    private func sendVerificationCodeSucceeded(with number: PhoneNumber) {
        phoneNumberLabel.textColor = UIColor.mnz_gray999999()
        phoneNumberTextField.textColor = UIColor.black
        errorView.isHidden = true
        navigationController?.pushViewController(VerificationCodeViewController.instantiate(with: number), animated: true)
    }
    
    private func sendVerificationCodeFailed(with error: MEGAError) {
        errorView.isHidden = false
        var errorMessage: String?
        switch error.type {
        case .apiETempUnavail: // a limit is reached.
            errorMessage = "You have reached your limit in getting verification code for today"
        case .apiEAccess: // your account is already verified with an SMS number
            errorMessage = "Your account is already verified by an phone number"
        case .apiEExist: // MEGAErrorTypeApiEExist if the number is already verified for some other account
            errorMessage = "This number is already associated with a mega account"
        case .apiEArgs: // the phone number is badly formatted or invalid
            errorMessage = "The phone number is invalid"
        default: // other errors
            errorMessage = "Error happended in sending message to your phone number"
        }
        
        configErrorStyle(withErrorMessage: errorMessage)
    }
    
    private func animateViewAdjustments(withDuration duration: Double, keyboardHeight: CGFloat) {
        navigationController?.setNavigationBarHidden(false, animated: true)
        UIView.animate(withDuration: duration + 0.75, animations: {
            self.enableAutomaticAdjustmentContentInsetsBehavior()
            self.headerImageView.isHidden = true
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
            let keyboardHeight = (notification.userInfo?[UIResponder.keyboardFrameBeginUserInfoKey] as? NSValue)?.cgRectValue.height else {
                return
        }
        
        animateViewAdjustments(withDuration: duration, keyboardHeight: keyboardHeight)
    }
    
    @objc private func didReceiveKeyboardWillHideNotification(_ notification: Notification) {
        var insets = scrollView.contentInset
        insets.bottom = 0
        scrollView.contentInset = insets
        scrollView.scrollIndicatorInsets = insets
    }
    
    @objc private func didReceiveTextDidChangeNotification(_ notification: Notification) {
        if notification.object as? UITextField === phoneNumberTextField {
            nextButton.isEnabled = !(phoneNumberTextField.text?.isEmpty ?? true)
        }
    }
    
    // MARK: - UI configurations
    
    private func configErrorStyle(withErrorMessage errorMessage: String?) {
        phoneNumberLabel.textColor = UIColor.mnz_redError()
        phoneNumberTextField.textColor = UIColor.mnz_redError()
        errorMessageLabel.text = errorMessage
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
        guard !headerImageView.isHidden else {
            return
        }
        
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
    func countriesTableViewController(_ controller: SMSCountriesTableViewController, didSelectCountry country: SMSCountry) {
        navigationController?.popToViewController(self, animated: true)
        configView(by: country)
    }
}
