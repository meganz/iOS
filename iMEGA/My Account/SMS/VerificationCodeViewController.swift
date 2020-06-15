import UIKit

class VerificationCodeViewController: UIViewController {

    private let verificationCodeCount = 6
    private let resendCheckTimeInterval = 30.0
    private var verificationCodeFields = [UITextField]()

    @IBOutlet private weak var resendButton: UIButton!
    @IBOutlet private weak var confirmButton: UIButton!
    @IBOutlet private weak var didnotReceiveCodeLabel: UILabel!
    @IBOutlet private weak var verificationCodeSentToLabel: UILabel!
    @IBOutlet private weak var phoneNumberLabel: UILabel!
    @IBOutlet private weak var codeFieldsContainerView: UIStackView!
    @IBOutlet private weak var errorImageView: UIImageView!
    @IBOutlet private weak var errorMessageLabel: UILabel!
    @IBOutlet private weak var errorView: UIStackView!
    @IBOutlet private weak var resendStackView: UIStackView!

    private var phoneNumber: PhoneNumber!
    private var verificationType: SMSVerificationType = .UnblockAccount

    private var verificationCode: String {
        return verificationCodeFields.compactMap { $0.text }.joined()
    }

    class func instantiate(with phoneNumber: PhoneNumber, verificationType: SMSVerificationType) -> VerificationCodeViewController {
        let controller = UIStoryboard(name: "SMSVerification", bundle: nil).instantiateViewController(withIdentifier: "VerificationCodeViewControllerID") as! VerificationCodeViewController
        controller.phoneNumber = phoneNumber
        controller.verificationType = verificationType
        return controller
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        configViewContents()
        configResendView()
        updateAppearance()

        verificationCodeFields = codeFieldsContainerView.subviews.compactMap { $0 as? UITextField }
        verificationCodeFields.first?.becomeFirstResponder()

        phoneNumberLabel.text = PhoneNumberKit().format(phoneNumber, toType: .international)
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)

        navigationController?.isNavigationBarHidden = false
    }

    override var supportedInterfaceOrientations: UIInterfaceOrientationMask {
        if UIDevice.current.userInterfaceIdiom == .phone {
            return [.portrait, .portraitUpsideDown]
        } else {
            return .all
        }
    }
    
    override func traitCollectionDidChange(_ previousTraitCollection: UITraitCollection?) {
        super.traitCollectionDidChange(previousTraitCollection)
        
        if #available(iOS 13, *) {
            if traitCollection.hasDifferentColorAppearance(comparedTo: previousTraitCollection) {
                AppearanceManager.forceNavigationBarUpdate(navigationController!.navigationBar, traitCollection: traitCollection)
                
                updateAppearance()
            }
        }
    }
    
    // MARK: - Private
    
    private func updateAppearance() {
        view.backgroundColor = .mnz_backgroundElevated(traitCollection)
        
        updateCodeFieldsAppearance()
        
        errorImageView.tintColor = UIColor.mnz_redError()
        errorMessageLabel.textColor = UIColor.mnz_redError()
        
        didnotReceiveCodeLabel.textColor = UIColor.mnz_primaryGray(for: traitCollection)
        resendButton.tintColor = UIColor.mnz_turquoise(for: self.traitCollection)
        
        confirmButton.mnz_setupPrimary(traitCollection)
    }
    
    private func updateCodeFieldsAppearance() {
        verificationCodeFields.forEach {
            $0.backgroundColor = .mnz_secondaryBackgroundElevated(traitCollection)
            $0.layer.cornerRadius = 4
            $0.layer.borderWidth = 0.5
            $0.layer.borderColor = errorView.isHidden ? UIColor.mnz_separator(for: traitCollection).cgColor : UIColor.mnz_redError().cgColor
        }
    }
    
    // MARK: - Config views

    private func configViewContents() {
        verificationCodeSentToLabel.text = AMLocalizedString("Please type the verification code sent to")
        errorView.isHidden = true
        didnotReceiveCodeLabel.text = AMLocalizedString("You didn't receive a code?")
        resendButton.setTitle(AMLocalizedString("resend"), for: .normal)
        confirmButton.setTitle(AMLocalizedString("confirm"), for: .normal)
        switch verificationType {
        case .AddPhoneNumber:
            title = AMLocalizedString("Add Phone Number")
        case .UnblockAccount:
            title = AMLocalizedString("Verify Your Account")
        }
    }

    private func configResendView() {
        resendStackView.isHidden = true
        DispatchQueue.main.asyncAfter(deadline: .now() + resendCheckTimeInterval) {
            guard self.verificationCode.count == 0 else { return }

            UIView.animate(withDuration: 0.75, animations: {
                self.resendStackView.isHidden = false
            })
        }
    }

    private func configCodeFieldsAppearance(with error: MEGAError? = nil) {
        if let error = error {
            DispatchQueue.main.asyncAfter(deadline: .now() + resendCheckTimeInterval) {
                UIView.animate(withDuration: 0.75, animations: {
                    self.resendStackView.isHidden = false
                })
            }
            errorView.isHidden = false
            
            var errorMessage: String?
            switch error.type {
            case .apiEAccess: // you have reached the verification limits.
                errorMessage = AMLocalizedString("You have reached the daily limit")
            case .apiEFailed: // the verification code does not match.
                errorMessage = AMLocalizedString("The verification code doesn't match.")
            case .apiEExpired: // the phone number was verified on a different account.
                errorMessage = AMLocalizedString("Your account is already verified")
            default: break
            }
            errorMessageLabel.text = errorMessage
            errorMessageLabel.textColor = UIColor.mnz_redError()
        } else {
            errorView.isHidden = true
        }
        
        updateCodeFieldsAppearance()
    }

    // MARK: - UI Actions

    @IBAction private func didTapResendButton() {
        navigationController?.popViewController(animated: true)
    }

    @IBAction private func didTapConfirmButton() {
        let code = verificationCode
        guard code.count == verificationCodeCount else { return }

        SVProgressHUD.show()
        MEGASdkManager.sharedMEGASdk()?.checkSMSVerificationCode(code, delegate: MEGAGenericRequestDelegate {
            [weak self] _, error in
            SVProgressHUD.dismiss()
            if error.type == .apiOk {
                self?.checkSMSVerificationCodeSucceeded()
            } else {
                self?.configCodeFieldsAppearance(with: error)
            }
        })
    }

    @IBAction private func didEditingChangeInTextField(_ textField: UITextField) {
        confirmButton.isEnabled = verificationCode.count == verificationCodeCount
    }

    private func checkSMSVerificationCodeSucceeded() {
        SVProgressHUD.showInfo(withStatus: AMLocalizedString("Your phone number has been verified successfully"))
        setEditing(false, animated: true)
        configCodeFieldsAppearance(with: nil)
        dismiss(animated: true, completion: nil)

        if verificationType == .UnblockAccount {
            if let session = SAMKeychain.password(forService: MEGAPasswordService, account: MEGAPasswordName) {
                MEGASdkManager.sharedMEGASdk()?.fastLogin(withSession: session, delegate: MEGALoginRequestDelegate())
            } else {
                (UIApplication.shared.delegate as? AppDelegate)?.showOnboarding()
            }
        }
    }
}

// MARK: - UITextFieldDelegate

extension VerificationCodeViewController: UITextFieldDelegate {
    func textField(_ textField: UITextField, shouldChangeCharactersIn range: NSRange, replacementString string: String) -> Bool {
        guard string.mnz_isDecimalNumber else {
            return false
        }

        if string.count >= verificationCodeCount {
            distributeCodeString(string)
            didEditingChangeInTextField(textField)
            return false
        }

        if string.count > 0 {
            textField.text = String(string[string.startIndex])
            makeNextCodeFieldBecomeFirstResponder(for: textField)
            didEditingChangeInTextField(textField)
            return false
        }

        return  true
    }

    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        didTapResendButton()
        return false
    }

    private func distributeCodeString(_ string: String) {
        for (code, field) in zip(string, verificationCodeFields) {
            field.text = String(code)
        }
    }

    private func makeNextCodeFieldBecomeFirstResponder(for textField: UITextField) {
        guard let currentIndex = verificationCodeFields.firstIndex(of: textField), currentIndex < verificationCodeFields.count - 1 else { return }
        verificationCodeFields[currentIndex + 1].becomeFirstResponder()
    }

    private func makePreviousCodeFieldBecomeFirstResponder(for textField: UITextField) {
        guard let currentIndex = verificationCodeFields.firstIndex(of: textField), currentIndex > 0 else { return }
        verificationCodeFields[currentIndex - 1].becomeFirstResponder()
    }
}

// MARK: - SingleCodeTextFieldDelegate

extension VerificationCodeViewController: SingleCodeTextFieldDelegate {
    func didDeleteBackwardInTextField(_ textField: SingleCodeTextField) {
        guard textField.text?.count ?? 0 == 0 else { return }
        makePreviousCodeFieldBecomeFirstResponder(for: textField)
    }
}
