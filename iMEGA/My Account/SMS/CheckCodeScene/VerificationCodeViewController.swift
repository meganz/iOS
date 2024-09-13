import MEGADesignToken
import MEGAL10n
import MEGAPresentation
import UIKit

final class VerificationCodeViewController: UIViewController, ViewType {
    // MARK: - Private properties
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
    
    private var verificationCode: String {
        return verificationCodeFields.compactMap { $0.text }.joined()
    }
    
    // MARK: - Internal properties
    var viewModel: VerificationCodeViewModel!
    
    // MARK: - View lifecycle
    override func viewDidLoad() {
        super.viewDidLoad()

        configViewContents()
        
        viewModel.invokeCommand = { [weak self] command in
            DispatchQueue.main.async { self?.executeCommand(command) }
        }
        
        viewModel.dispatch(.onViewReady)
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)

        navigationController?.isNavigationBarHidden = false
    }
    
    override func traitCollectionDidChange(_ previousTraitCollection: UITraitCollection?) {
        super.traitCollectionDidChange(previousTraitCollection)
        
        if traitCollection.hasDifferentColorAppearance(comparedTo: previousTraitCollection) {
            if let nav = navigationController {
                AppearanceManager.forceNavigationBarUpdate(nav.navigationBar, traitCollection: traitCollection)
            }
            
            updateAppearance()
        }
    }
    
    // MARK: - Config views
    private func configViewContents() {
        verificationCodeSentToLabel.text = Strings.Localizable.pleaseTypeTheVerificationCodeSentTo
        errorView.isHidden = true
        didnotReceiveCodeLabel.text = Strings.Localizable.youDidnTReceiveACode
        resendButton.setTitle(Strings.Localizable.resend, for: .normal)
        confirmButton.setTitle(Strings.Localizable.confirm, for: .normal)
        
        resendStackView.isHidden = true
        showResendView()

        verificationCodeFields = codeFieldsContainerView.subviews.compactMap { $0 as? UITextField }
        verificationCodeFields.first?.becomeFirstResponder()
        
        updateAppearance()
    }

    private func showResendView() {
        DispatchQueue.main.asyncAfter(deadline: .now() + resendCheckTimeInterval) {
            UIView.animate(withDuration: 0.75, animations: {
                self.resendStackView.isHidden = false
            })
        }
    }
    
    private func showCheckCodeErrorMessage(_ message: String) {
        errorMessageLabel.text = message
        errorMessageLabel.textColor = TokenColors.Text.error
        errorView.isHidden = false
    }
    
    private func updateAppearance() {
        view.backgroundColor = .mnz_backgroundElevated(traitCollection)
        
        updateCodeFieldsAppearance()
        
        verificationCodeSentToLabel.textColor = TokenColors.Text.primary
        phoneNumberLabel.textColor = TokenColors.Text.primary
        errorImageView.tintColor = TokenColors.Support.error
        errorMessageLabel.textColor = TokenColors.Text.error
        didnotReceiveCodeLabel.textColor = TokenColors.Text.primary
        resendButton.tintColor = TokenColors.Link.primary

        confirmButton.mnz_setupPrimary(traitCollection)
    }
    
    private func updateCodeFieldsAppearance() {
        let errorBorderColor = TokenColors.Support.error.cgColor
        
        verificationCodeFields.forEach {
            $0.textColor = TokenColors.Text.primary
            $0.backgroundColor = TokenColors.Background.surface1
            $0.layer.cornerRadius = 4
            $0.layer.borderWidth = 0.5
            $0.layer.borderColor = errorView.isHidden ? UIColor.mnz_separator(for: traitCollection).cgColor : errorBorderColor
        }
    }

    // MARK: - Execute command
    func executeCommand(_ command: VerificationCodeViewModel.Command) {
        switch command {
        case .startLoading:
            SVProgressHUD.show()
        case .finishLoading:
            SVProgressHUD.dismiss()
        case let .configView(phoneNumber, screenTitle):
            phoneNumberLabel.text = phoneNumber
            title = screenTitle
        case .checkCodeSucceeded:
            checkSMSVerificationCodeSucceeded()
        case .checkCodeError(let message):
            showCheckCodeErrorMessage(message)
            showResendView()
        }
    }
    
    // MARK: - UI Actions
    @IBAction private func didTapResendButton() {
        viewModel.dispatch(.resendCode)
    }

    @IBAction private func didTapConfirmButton() {
        let code = verificationCode
        guard code.count == verificationCodeCount else { return }
        viewModel.dispatch(.checkVerificationCode(code))
    }

    @IBAction private func didEditingChangeInTextField(_ textField: UITextField) {
        confirmButton.isEnabled = verificationCode.count == verificationCodeCount
    }

    private func checkSMSVerificationCodeSucceeded() {
        errorView.isHidden = true
        updateCodeFieldsAppearance()
        SVProgressHUD.showInfo(withStatus: Strings.Localizable.yourPhoneNumberHasBeenVerifiedSuccessfully)
        setEditing(false, animated: true)
        viewModel.dispatch(.didCheckCodeSucceeded)
    }
}

// MARK: - UITextFieldDelegate

extension VerificationCodeViewController: UITextFieldDelegate {
    func textField(_ textField: UITextField, shouldChangeCharactersIn range: NSRange, replacementString newText: String) -> Bool {
        guard newText.mnz_isDecimalNumber else {
            return false
        }

        if newText.count >= verificationCodeCount {
            distributeCodeString(newText)
            didEditingChangeInTextField(textField)
            return false
        }
        
        let shouldDeleteCurrentTextFieldText = textField.text?.isNotEmpty == true
        if newText.isEmpty && shouldDeleteCurrentTextFieldText {
            makeCurrentCodeFieldBecomeFirstResponder(for: textField)
            return true
        }

        if newText.isNotEmpty {
            if !shouldDeleteCurrentTextFieldText {
                textField.text = String(newText[newText.startIndex])
            } else {
                guard let currentIndex = verificationCodeFields.firstIndex(of: textField) else { return false }
                attemptFillNextTextField(at: currentIndex + 1, replacementString: newText)
            }
            makeNextCodeFieldBecomeFirstResponder(for: textField)
            didEditingChangeInTextField(textField)
            return false
        }

        return  true
    }
    
    private func attemptFillNextTextField(at nextIndex: Int, replacementString string: String) {
        if nextIndex <= verificationCodeCount {
            let nextTextField = verificationCodeFields[safe: nextIndex]
            nextTextField?.text = String(string[string.startIndex])
        }
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
    
    private func makeCurrentCodeFieldBecomeFirstResponder(for textField: UITextField) {
        guard let currentIndex = verificationCodeFields.firstIndex(of: textField), currentIndex > 0 else { return }
        verificationCodeFields[currentIndex].becomeFirstResponder()
    }
}

// MARK: - SingleCodeTextFieldDelegate

extension VerificationCodeViewController: SingleCodeTextFieldDelegate {
    func didDeleteBackwardInTextField(_ textField: SingleCodeTextField) {
        guard textField.text?.count ?? 0 == 0 else { return }
        makePreviousCodeFieldBecomeFirstResponder(for: textField)
    }
}
