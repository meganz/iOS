import MEGADesignToken
import MEGAL10n
import MEGAPresentation
import UIKit

final class SMSVerificationViewController: UIViewController, ViewType {
    // MARK: - Private properties
    @IBOutlet private weak var scrollView: UIScrollView!
    @IBOutlet private weak var headerImageView: UIImageView!
    @IBOutlet private weak var descriptionTextView: UITextView!
    @IBOutlet private weak var nextButton: UIButton!
    @IBOutlet private weak var cancelButton: UIButton!
    @IBOutlet private weak var titleLabel: UILabel!
    
    @IBOutlet private weak var phoneNumberTopSeparatorView: UIView!
    @IBOutlet private weak var phoneNumberContainerView: UIView!
    @IBOutlet private weak var phoneNumberLabel: UILabel!
    @IBOutlet private weak var phoneNumberTextField: UITextField!
    @IBOutlet private weak var phoneNumberBottomSeparatorView: UIView!
    @IBOutlet weak var phoneFieldImageView: UIImageView!
    
    @IBOutlet private weak var countryTopSeparatorView: UIView!
    @IBOutlet private weak var countryContainerView: UIView!
    @IBOutlet private weak var countryNameLabel: UILabel!
    @IBOutlet private weak var countryCodeLabel: UILabel!
    @IBOutlet private weak var countryBottomSeparatorView: UIView!
    @IBOutlet private weak var disclosureIndicatorImageView: UIImageView!
    @IBOutlet weak var countryFieldImageView: UIImageView!
    
    @IBOutlet private weak var errorImageView: UIImageView!
    @IBOutlet private weak var errorMessageLabel: UILabel!
    @IBOutlet private weak var errorView: UIView!
    @IBOutlet private weak var countryLabel: UILabel!

    // MARK: - Internal properties
    var viewModel: SMSVerificationViewModel!

    // MARK: - View lifecycle
    override func viewDidLoad() {
        super.viewDidLoad()

        configViewContents()
        
        viewModel.invokeCommand = { [weak self] command in
            DispatchQueue.main.async { self?.executeCommand(command) }
        }
        
        viewModel.dispatch(.onViewReady)
        viewModel.dispatch(.loadRegionCodes)
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
    
    // MARK: - UI actions
    @IBAction private func didTapCancelButton() {
        viewModel.dispatch(.cancel)
    }
    
    @IBAction private func didTapLogoutButton() {
        setEditing(false, animated: true)
        viewModel.dispatch(.logout)
    }

    @IBAction private func didTapCountryView() {
        viewModel.dispatch(.showRegionList)
    }

    @IBAction private func didTapPhoneView() {
        phoneNumberTextField.becomeFirstResponder()
    }

    @IBAction private func didTapNextButton() {
        guard let localNumber = phoneNumberTextField.text, let selectedRegion = viewModel.selectedRegion else { return }
        let phoneNumber = "\(countryCodeLabel.text ?? "")\(localNumber)"
        viewModel.dispatch(.sendCodeToPhoneNumber(phoneNumber, regionCode: selectedRegion.regionCode))
    }

    @IBAction private func didEditingChangedInPhoneNumberField() {
        nextButton.isEnabled = !(phoneNumberTextField.text?.isEmpty ?? true)
        phoneNumberLabel.textColor = TokenColors.Text.secondary
        phoneNumberTextField.textColor = TokenColors.Text.primary
        errorView.isHidden = true
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
        disableAutomaticAdjustmentContentInsetsBehavior()
        navigationItem.backBarButtonItem = UIBarButtonItem(title: "", style: .plain, target: nil, action: nil)
        errorView.isHidden = true
        countryNameLabel.text = " "
        countryCodeLabel.text = nil
        descriptionTextView.text = nil

        countryLabel.text = Strings.Localizable.country
        phoneNumberLabel.text = Strings.Localizable.yourPhoneNumber
        nextButton.setTitle(Strings.Localizable.next, for: .normal)
        
        setupColors()
    }
    
    private func configViewForAddPhoneNumber() {
        let cancelTitle = Strings.Localizable.cancel
        navigationItem.rightBarButtonItem = UIBarButtonItem(title: cancelTitle, style: .plain, target: self, action: #selector(SMSVerificationViewController.didTapCancelButton))
        title = Strings.Localizable.addPhoneNumber
        titleLabel.text = title
        cancelButton.setTitle(cancelTitle, for: .normal)
        cancelButton.addTarget(self, action: #selector(SMSVerificationViewController.didTapCancelButton), for: .touchUpInside)
    }
    
    private func configViewForUnblockAccount() {
        let logoutTitle = Strings.Localizable.logoutLabel
        navigationItem.rightBarButtonItem = UIBarButtonItem(title: logoutTitle, style: .plain, target: self, action: #selector(SMSVerificationViewController.didTapLogoutButton))
        title = Strings.Localizable.verifyYourAccount
        titleLabel.text = title
        cancelButton.setTitle(logoutTitle, for: .normal)
        cancelButton.addTarget(self, action: #selector(SMSVerificationViewController.didTapLogoutButton), for: .touchUpInside)
        descriptionTextView.text = Strings.Localizable.YourAccountHasBeenSuspendedTemporarilyDueToPotentialAbuse.pleaseVerifyYourPhoneNumberToUnlockYourAccount
    }
    
    private func setupColors() {
        view.backgroundColor = TokenColors.Background.page
        
        let primaryTextColor = TokenColors.Text.primary
        let secondaryTextColor = TokenColors.Text.secondary
        let separatorColor = TokenColors.Border.strong
        let fieldBackgroundColor = TokenColors.Background.page
        
        titleLabel.textColor = primaryTextColor
        cancelButton.setTitleColor(primaryTextColor, for: .normal)
        descriptionTextView.textColor = primaryTextColor
        
        countryTopSeparatorView.backgroundColor = separatorColor
        countryContainerView.backgroundColor = fieldBackgroundColor
        countryLabel.textColor = secondaryTextColor
        countryBottomSeparatorView.backgroundColor = separatorColor
        countryNameLabel.textColor = primaryTextColor
        
        phoneNumberTopSeparatorView.backgroundColor = separatorColor
        phoneNumberContainerView.backgroundColor = fieldBackgroundColor
        phoneNumberLabel.textColor = secondaryTextColor
        phoneNumberBottomSeparatorView.backgroundColor = separatorColor
        
        errorImageView.tintColor = TokenColors.Support.error
        errorMessageLabel.textColor = TokenColors.Text.error
        
        disclosureIndicatorImageView.image = UIImage.standardDisclosureIndicatorDesignToken
        countryFieldImageView.image = UIImage.verificationCountry.withRenderingMode(.alwaysTemplate)
        phoneFieldImageView.image = UIImage.phoneNumber.withRenderingMode(.alwaysTemplate)
        
        let iconTintColor = TokenColors.Icon.secondary
        countryFieldImageView.tintColor = iconTintColor
        phoneFieldImageView.tintColor = iconTintColor
        
        nextButton.mnz_setupPrimary(traitCollection)
    }

    private func showSendCodeErrorMessage(_ message: String?) {
        let errorColor = TokenColors.Text.error
        phoneNumberLabel.textColor = errorColor
        phoneNumberTextField.textColor = errorColor
        errorMessageLabel.text = message
        errorView.isHidden = false
    }

    private func configRegion(name: String, callingCode: String) {
        countryNameLabel.text = name
        countryCodeLabel.text = callingCode
    }

    override var preferredStatusBarStyle: UIStatusBarStyle {
        if navigationController?.isNavigationBarHidden ?? false {
            return .lightContent
        } else {
            return .default
        }
    }

    private func enableAutomaticAdjustmentContentInsetsBehavior() {
        scrollView.contentInsetAdjustmentBehavior = .automatic
    }

    private func disableAutomaticAdjustmentContentInsetsBehavior() {
        scrollView.contentInsetAdjustmentBehavior = .never
    }

    private func animateViewAdjustments(withDuration duration: Double, keyboardHeight: CGFloat) {
        navigationController?.setNavigationBarHidden(false, animated: true)
        UIView.animate(withDuration: duration + 0.75, animations: {
            self.enableAutomaticAdjustmentContentInsetsBehavior()
            self.headerImageView.isHidden = true
            self.cancelButton.isHidden = true
            self.titleLabel.isHidden = true
            self.setNeedsStatusBarAppearanceUpdate()
        }, completion: { _ in
            var insets = self.scrollView.contentInset
            insets.bottom = keyboardHeight
            self.scrollView.contentInset = insets
            self.scrollView.scrollIndicatorInsets = insets
        })
    }
    
    // MARK: - Execute command
    func executeCommand(_ command: SMSVerificationViewModel.Command) {
        switch command {
        case .startLoading:
            SVProgressHUD.show()
        case .finishLoading:
            SVProgressHUD.dismiss()
        case .configView(let type):
            switch type {
            case .addPhoneNumber:
                configViewForAddPhoneNumber()
            case .unblockAccount:
                configViewForUnblockAccount()
            }
        case .showLoadAchievementResult(let resultCommand):
            executeCommand(resultCommand)
        case let .showRegion(name, callingCode):
            configRegion(name: name, callingCode: callingCode)
        case .sendCodeToPhoneNumberError(let message):
            showSendCodeErrorMessage(message)
        }
    }
    
    func executeCommand(_ command: SMSVerificationViewModel.Command.LoadAchievementResultCommand) {
        switch command {
        case .showStorage(let message):
            descriptionTextView.text = message
        case .showError(let message):
            descriptionTextView.text = message
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
            let factor = offset.y / (headerImageView.frame.height / 2)
            let scaleFactor = 1 - factor
            transform = CATransform3DScale(transform, scaleFactor, scaleFactor, 1)
            headerImageView.layer.transform = transform
        } else {
            headerImageView.layer.transform = CATransform3DIdentity
        }
    }
}

// MARK: - UITextFieldDelegate
extension SMSVerificationViewController: UITextFieldDelegate {
    func textField(_ textField: UITextField, shouldChangeCharactersIn range: NSRange, replacementString string: String) -> Bool {
        let currentText = textField.text ?? ""

        guard let stringRange = Range(range, in: currentText) else { return false }

        let updatedText = currentText.replacingCharacters(in: stringRange, with: string)

        return updatedText.count <= 20
    }
}
