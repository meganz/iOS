
import UIKit

class VerificationCodeViewController: UIViewController {
    
    @IBOutlet private var resendButton: UIButton!
    @IBOutlet private var didnotReceiveCodeLabel: UILabel!
    @IBOutlet private var verificationCodeSentToLabel: UILabel!
    @IBOutlet private var phoneNumberLabel: UILabel!
    @IBOutlet private var codeFieldsContainerView: UIStackView!
    @IBOutlet private var errorImageView: UIImageView!
    @IBOutlet private var errorMessageLabel: UILabel!
    @IBOutlet private var errorView: UIStackView!
    
    var phoneNumber: PhoneNumber!
    
    class func instantiate(with phoneNumber: PhoneNumber) -> VerificationCodeViewController {
        let controller = VerificationCodeViewController.instantiate(withStoryboardName: "SMSVerification")
        controller.phoneNumber = phoneNumber
        return controller
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        title = "Verify Your Account"
        
        resendButton.tintColor = UIColor.mnz_green00BFA5()
        didnotReceiveCodeLabel.textColor = UIColor.gray
        errorImageView.tintColor = UIColor.mnz_redError()
        errorMessageLabel.textColor = UIColor.mnz_redError()
        
        phoneNumberLabel.text = PhoneNumberKit().format(phoneNumber, toType: .e164)
        
        configCodeFieldsAppearance()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        navigationController?.isNavigationBarHidden = false
    }
    
    // MARK: - config views
    
    private func configCodeFieldsAppearance(with error: MEGAError? = nil) {
        if let error = error {
            errorView.isHidden = false
            codeFieldsContainerView.subviews.compactMap { $0 as? UITextField }.forEach {
                $0.layer.cornerRadius = 8
                $0.layer.borderWidth = 2
                $0.layer.borderColor = UIColor(red:1, green:0.2, blue:0.23, alpha:0.4).cgColor
                $0.layer.shadowOffset = CGSize(width: 0, height: 1)
                $0.layer.shadowColor = UIColor.mnz_black000000_01()?.cgColor
                $0.layer.shadowOpacity = 1
                $0.layer.shadowRadius = 0
            }
            
            var errorMessage: String?
            switch error.type {
            case .apiEAccess: // you have reached the verification limits.
                errorMessage = "You have reached your limit in getting verification code for today"
            case .apiEFailed: // the verification code does not match.
                errorMessage = "The verification code does not match"
            case .apiEExpired: // the phone number was verified on a different account.
                errorMessage = "Your account is already verified by an phone number"
            default: break
            }
            errorMessageLabel.text = errorMessage
            errorMessageLabel.textColor = UIColor.mnz_redError()
        } else {
            errorView.isHidden = true
            codeFieldsContainerView.subviews.compactMap { $0 as? UITextField }.forEach {
                $0.layer.cornerRadius = 8
                $0.layer.borderWidth = 1
                $0.layer.borderColor = UIColor.mnz_black000000_01()?.cgColor
                $0.layer.shadowOffset = CGSize(width: 0, height: 1)
                $0.layer.shadowColor = UIColor.mnz_black000000_01()?.cgColor
                $0.layer.shadowOpacity = 1
                $0.layer.shadowRadius = 0
            }
        }
    }
    
    // MARK: - UI Actions
    
    @IBAction private func didTapResendButton() {
        navigationController?.popViewController(animated: true)
    }
    
    @IBAction private func didTapConfirmButton() {
        SVProgressHUD.show()
        MEGASdkManager.sharedMEGASdk()?.checkSMSVerificationCode("", delegate: MEGAGenericRequestDelegate() {
            [weak self] request, error in
            SVProgressHUD.dismiss()
            if error.type == .apiOk {
                self?.configCodeFieldsAppearance(with: nil)
                self?.dismiss(animated: true, completion: nil)
            } else {
                self?.configCodeFieldsAppearance(with: error)
            }
        })
    }
}

// MARK: - UITextFieldDelegate

extension VerificationCodeViewController: UITextFieldDelegate {
    
}
