
import UIKit

class VerifyEmailViewController: UIViewController {

    @IBOutlet weak var warningGradientView: UIView!
    
    @IBOutlet weak var titleLabel: UILabel!
    @IBOutlet weak var topDescriptionLabel: UILabel!
    @IBOutlet weak var bottomDescriptionLabel: UILabel!
    @IBOutlet weak var hintLabel: UILabel!
    
    @IBOutlet weak var topSeparatorView: UIView!
    @IBOutlet weak var bottomSeparatorView: UIView!
    
    @IBOutlet weak var hintButton: UIButton!
    @IBOutlet weak var resendButton: UIButton!
    @IBOutlet weak var logoutButton: UIButton!

    //MARK: Lifecyle

    override func viewDidLoad() {
        super.viewDidLoad()

        NotificationCenter.default.addObserver(self, selector: #selector(checkIfBlocked), name:
            UIApplication.willEnterForegroundNotification, object: nil)
        configureUI()
    }
    
    override var supportedInterfaceOrientations: UIInterfaceOrientationMask {
        return .portrait
    }
    
    override func traitCollectionDidChange(_ previousTraitCollection: UITraitCollection?) {
        super.traitCollectionDidChange(previousTraitCollection)
        
        updateAppearance()
    }
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        addGradientBackground()
    }
    
    //MARK: Private

    func configureUI() {
        localizeLabels()
        boldenText()
        updateAppearance()
    }
    
    func updateAppearance() {
        hintButton.backgroundColor = UIColor.white
        resendButton.backgroundColor = UIColor.white

        topSeparatorView.backgroundColor = UIColor.lightGray
        bottomSeparatorView.backgroundColor = UIColor.lightGray
        
        hintLabel.textColor = UIColor.gray
        topDescriptionLabel.textColor = UIColor.black
        bottomDescriptionLabel.textColor = UIColor.black
    }
    
    func addGradientBackground () {
        let gradient = CAGradientLayer()
        gradient.frame = warningGradientView.bounds
        gradient.colors = [
            UIColor(red:1, green:0.39, blue:0.39, alpha:1).cgColor,
            UIColor(red:0.81, green:0.29, blue:0.29, alpha:1).cgColor
        ]
        gradient.locations = [0, 1]
        gradient.startPoint = CGPoint(x: 0.5, y: 0)
        gradient.endPoint = CGPoint(x: 0.5, y: 1)

        warningGradientView.layer.addSublayer(gradient)
    }
    
    func boldenText() {
        guard let bottomString = bottomDescriptionLabel.text?.replacingOccurrences(of: "[S]", with: "") else { return }
        
        let bottomStringComponents = bottomString.components(separatedBy: "[/S]")
        guard let textToBolden = bottomStringComponents.first, let textRegular = bottomStringComponents.last else { return }
        
        let attributtedString = NSMutableAttributedString(string: textToBolden, attributes: [NSAttributedString.Key.font: UIFont.systemFont(ofSize: 16, weight: .semibold)])
        let regularlString = NSAttributedString(string: textRegular, attributes: [NSAttributedString.Key.font: UIFont.systemFont(ofSize: 16, weight: .regular)])
        attributtedString.append(regularlString)
        
        bottomDescriptionLabel.attributedText = attributtedString
    }
    
    func showWhyIAmBlocked() {
        let customModal = CustomModalAlertViewController.init()
        customModal.modalPresentationStyle = .overCurrentContext
        
        customModal.image = UIImage(named: "lockedAccounts")
        customModal.viewTitle = AMLocalizedString("Locked Accounts", "Title of a helping view about locked accounts")
        customModal.detail = AMLocalizedString("It is possible that you are using the same password for your MEGA account as for other services, and that at least one of these other services has suffered a data breach.", "Locked accounts description text by an external data breach. This text is 1 of 2 paragraph of a description.") + "\n\n" + AMLocalizedString("Your password leaked and is now being used by bad actors to log into your accounts, including, but not limited to, your MEGA account.", "Locked accounts description text by bad use of user password. This text is 2 of 2 paragraph of a description.")
        customModal.dismissButtonTitle = AMLocalizedString("close", "A button label. The button allows the user to close the conversation.")
        
        present(customModal, animated: true, completion: nil)
    }
    
    func localizeLabels() {
        topDescriptionLabel.text = AMLocalizedString("Your account has been temporarily suspended for your safety.", "Text describing account suspended state to the user")
        bottomDescriptionLabel.text = AMLocalizedString("[S]Please verify your email[/S] and follow its steps to unlock your account.", "Text indicating the user next step to unlock suspended account. Please leave [S], [/S] as it is which is used to bolden the text.")
        resendButton.setTitle(AMLocalizedString("resend", "A button to resend the email confirmation."), for: .normal)
        logoutButton.setTitle(AMLocalizedString("logoutLabel", "Title of the button which logs out from your account."), for: .normal)
        hintButton.setTitle(AMLocalizedString("Why am I seeing this?", "Text for button to open an helping view"), for: .normal)
        hintLabel.text = AMLocalizedString("Email sent", "Text to notify user an email has been sent")
    }
    
    @objc func checkIfBlocked() {
        let whyAmIBlockedRequestDelegate = MEGAGenericRequestDelegate.init { (request, error) in
            if error.type == .apiOk && request.number == 0 {
                                
                if (MEGASdkManager.sharedMEGASdk().rootNode == nil) {
                    guard let session = SAMKeychain.password(forService: "MEGA", account: "sessionV3") else { return }
                    let loginRequestDelegate = MEGALoginRequestDelegate.init()
                    MEGASdkManager.sharedMEGASdk().fastLogin(withSession: session, delegate: loginRequestDelegate)
                }
                
                self.presentedViewController?.dismiss(animated: true, completion: nil)
                self.dismiss(animated: true, completion: nil)
            }
        }
        MEGASdkManager.sharedMEGASdk().whyAmIBlocked(with: whyAmIBlockedRequestDelegate)
    }
    
    //MARK: Actions
    
    @IBAction func tapHintButton(_ sender: Any) {
        showWhyIAmBlocked()
    }
    
    @IBAction func tapResendButton(_ sender: Any) {
        if MEGAReachabilityManager.isReachableHUDIfNot() {
            SVProgressHUD.show()
            let resendVerificationEmailDelegate = MEGAGenericRequestDelegate.init { (request, error) in
                SVProgressHUD.dismiss()
                if error.type == .apiOk || error.type == .apiEArgs {
                    self.hintLabel.isHidden = false
                } else {
                    SVProgressHUD.showError(withStatus: AMLocalizedString(error.name, ""))
                }
            }
            MEGASdkManager.sharedMEGASdk().resendVerificationEmail(with: resendVerificationEmailDelegate)
        }
    }
    
    
    @IBAction func tapLogoutButton(_ sender: Any) {
        MEGASdkManager.sharedMEGASdk().logout()
    }
}
