
import UIKit

class SMSVerificationViewController: UIViewController {
    
    @IBOutlet private var scrollView: UIScrollView!
    @IBOutlet private var headerImageView: UIImageView!
    @IBOutlet private var nextButton: UIButton!
    @IBOutlet private var nextButtonBottomConstraint: NSLayoutConstraint!
    @IBOutlet private var scrollContentViewPreferredEqualHeightConstraint: NSLayoutConstraint!
    @IBOutlet private var phoneNumberTextField: UITextField!
    @IBOutlet private var countryNameLabel: UILabel!
    @IBOutlet private var countryCodeLabel: UILabel!
    
    private var countryCallingCodeDict: [String: MEGAStringList]?

    // MARK: View lifecycle
    override func viewDidLoad() {
        super.viewDidLoad()
        
        title = "Verify Your Account"
        navigationController?.isNavigationBarHidden = true

        disableAutomaticAdjustmentContentInsetsBehavior()
        
        NotificationCenter.default.addObserver(self, selector: #selector(didReceiveTextDidChangeNotification(_:)), name: UITextField.textDidChangeNotification, object: phoneNumberTextField)
        
        countryNameLabel.text = " "
        countryCodeLabel.text = nil
        loadCountryCallingCodes()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        NotificationCenter.default.addObserver(self, selector: #selector(didReceiveKeyboardWillShowNotification(_:)), name: UIResponder.keyboardWillShowNotification, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(didReceiveKeyboardWillHideNotification(_:)), name: UIResponder.keyboardWillHideNotification, object: nil)
        
        navigationItem.backBarButtonItem?.title = ""
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        
        NotificationCenter.default.removeObserver(self, name: UIResponder.keyboardWillShowNotification, object: nil)
        NotificationCenter.default.removeObserver(self, name: UIResponder.keyboardWillHideNotification, object: nil)
    }
    
    // MARK: Network calls
    private func loadCountryCallingCodes() {
        SVProgressHUD.show()
        MEGASdkManager.sharedMEGASdk()?.getCountryCallingCodes(with: MEGAGenericRequestDelegate() { [weak self] request, error in
            SVProgressHUD.dismiss()
            if error.type == .apiOk {
                self?.countryCallingCodeDict = request.megaStringListDictionary
                self?.configDefaultCountryCode()
            }
        })
    }
    
    private func configDefaultCountryCode() {
        guard let countryCallingCodeDict = self.countryCallingCodeDict else {
            return
        }
        
        guard let systemCurrentRegionCode = Locale.current.regionCode else {
            return
        }
        
        guard let (_, callingCodeList) = countryCallingCodeDict.first(where: { $0.key == systemCurrentRegionCode }) else {
            return
        }
        
        guard let callCode = callingCodeList.stringArray.first else {
            return
        }
        
        guard let appLanguageId = LocalizationSystem.sharedLocal()?.getLanguage() else {
            return
        }

        let appLocale = Locale(identifier: Locale.identifier(fromComponents: [NSLocale.Key.languageCode.rawValue : appLanguageId]))
        
        guard let countryDisplayName = appLocale.localizedString(forRegionCode: systemCurrentRegionCode) else {
            return
        }
        
        countryNameLabel.text = "\(countryDisplayName) (+\(callCode))"
        countryCodeLabel.text = "+\(callCode)"
    }

    // MARK: UI actions
    @IBAction private func didTapCountryView() {
        phoneNumberTextField.resignFirstResponder()
    }
    
    private func animateViewAdjustments(withDuration duration: Double, keyboardHeight: CGFloat) {
        navigationController?.setNavigationBarHidden(false, animated: true)
        UIView.animate(withDuration: duration, animations: {
            self.enableAutomaticAdjustmentContentInsetsBehavior()
            self.headerImageView.isHidden = true
            self.setNeedsStatusBarAppearanceUpdate()
            self.nextButtonBottomConstraint.constant = keyboardHeight
        }) { _ in
            self.adjustScrollViewContentPreferredHeight()
        }
    }
    
    // MARK: Notification handlers
    @objc private func didReceiveKeyboardWillShowNotification(_ notification: Notification) {
        guard let duration = (notification.userInfo?[UIResponder.keyboardAnimationDurationUserInfoKey] as? NSNumber)?.doubleValue,
            let keyboardHeight = (notification.userInfo?[UIResponder.keyboardFrameBeginUserInfoKey] as? NSValue)?.cgRectValue.height else {
                return
        }
        
        animateViewAdjustments(withDuration: duration, keyboardHeight: keyboardHeight)
    }
    
    @objc private func didReceiveKeyboardWillHideNotification(_ notification: Notification) {
        nextButtonBottomConstraint.constant = 0
        adjustScrollViewContentPreferredHeight()
    }
    
    @objc private func didReceiveTextDidChangeNotification(_ notification: Notification) {
        if notification.object as? UITextField === phoneNumberTextField {
            nextButton.isEnabled = !(phoneNumberTextField.text?.isEmpty ?? true)
        }
    }
    
    // MARK: UI configurations
    override var preferredStatusBarStyle: UIStatusBarStyle {
        if navigationController?.isNavigationBarHidden ?? false {
            return .lightContent
        } else {
            return .default
        }
    }
    
    private func adjustScrollViewContentPreferredHeight() {
        if #available(iOS 11.0, *) {
            scrollContentViewPreferredEqualHeightConstraint.constant = -scrollView.adjustedContentInset.top
        } else {
            scrollContentViewPreferredEqualHeightConstraint.constant = -scrollView.contentInset.top
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
