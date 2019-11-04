
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
        
        updateUI()
    }
    
    //MARK: Private

    func configureUI() {
        localizeLabels()
        addGradientBackground()
        boldenText()
        updateUI()
    }
    
    func updateUI() {
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
        
        let attributtedString = NSMutableAttributedString(string: textToBolden, attributes: [NSAttributedString.Key.font: UIFont.mnz_SFUISemiBold(withSize: 16)!])
        let regularlString = NSAttributedString(string: textRegular, attributes: [NSAttributedString.Key.font: UIFont.mnz_SFUIRegular(withSize: 16)!])
        attributtedString.append(regularlString)
        
        bottomDescriptionLabel.attributedText = attributtedString
    }
    
    func showWhyIAmBlocked() {
        let customModal = CustomModalAlertViewController.init()
        customModal.modalPresentationStyle = .overCurrentContext
        
        customModal.image = UIImage(named: "lockedAccounts")
        customModal.viewTitle = NSLocalizedString("Locked Accounts", comment: "")
        customModal.detail = NSLocalizedString("It is possible that you are using the same password for your MEGA account as for other services, and that at least one of these other services has suffered a data breach.", comment: "") + "\n\n" + NSLocalizedString("Your password leaked and is now being used by bad actors to log into your accounts, including, but not limited to, your MEGA account.", comment: "")
        customModal.dismissButtonTitle = NSLocalizedString("close", comment: "")
        
        present(customModal, animated: true, completion: nil)
    }
    
    func localizeLabels() {
        topDescriptionLabel.text = NSLocalizedString("Your account has been temporarily suspended for your safety.", comment: "")
        bottomDescriptionLabel.text = NSLocalizedString("[S]Please verify your email[/S] and follow its steps to unlock your account.", comment: "")
        resendButton.setTitle(NSLocalizedString("resend", comment: ""), for: .normal)
        hintButton.setTitle(NSLocalizedString("Why am I seeing this?", comment: ""), for: .normal)
        hintLabel.text = NSLocalizedString("Email sent", comment: "")
    }
    
    @objc func checkIfBlocked() {
        let whyAmIBlockedRequestDelegate = MEGAGenericRequestDelegate.init { (request, error) in
            if error.type == .apiOk && request.number == 0 {
                
                let rootNode = MEGASdkManager.sharedMEGASdk()?.rootNode
                
                if (rootNode == nil) {
                    guard let session = SAMKeychain.password(forService: "MEGA", account: "sessionV3") else { return }
                    let loginRequestDelegate = MEGALoginRequestDelegate.init()
                    MEGASdkManager.sharedMEGASdk()?.fastLogin(withSession: session, delegate: loginRequestDelegate)
                }
                
                self.presentedViewController?.dismiss(animated: true, completion: nil)
                self.dismiss(animated: true, completion: nil)
            }
        }
        MEGASdkManager.sharedMEGASdk()?.whyAmIBlocked(with: whyAmIBlockedRequestDelegate)
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
                if error.type == MEGAErrorType.apiOk || error.type == MEGAErrorType.apiEArgs {
                    self.hintLabel.isHidden = false
                } else {
                    SVProgressHUD.showError(withStatus: NSLocalizedString("error", comment: ""))
                }
            }
            MEGASdkManager.sharedMEGASdk()?.resendVerificationEmail(with: resendVerificationEmailDelegate)
        }
    }
}
