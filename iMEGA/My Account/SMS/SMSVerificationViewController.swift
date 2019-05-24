
import UIKit

class SMSVerificationViewController: UIViewController {
    
    @IBOutlet private var scrollView: UIScrollView!
    @IBOutlet private var headerImageView: UIImageView!
    @IBOutlet private var nextButton: UIButton!
    @IBOutlet private var nextButtonBottomConstraint: NSLayoutConstraint!

    override func viewDidLoad() {
        super.viewDidLoad()
        
        title = "Verify Your Account"
        navigationController?.isNavigationBarHidden = true

        disableAutomaticAdjustmentContentInsetsBehavior()
        
        NotificationCenter.default.addObserver(self, selector: #selector(didReceiveKeyboardWillShowNotification(_:)), name: UIResponder.keyboardWillShowNotification, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(didReceiveKeyboardWillHideNotification(_:)), name: UIResponder.keyboardWillHideNotification, object: nil)
    }
    
    override var preferredStatusBarStyle: UIStatusBarStyle {
        if navigationController?.isNavigationBarHidden ?? false {
            return .lightContent
        } else {
            return .default
        }
    }
    
    @objc private func didReceiveKeyboardWillShowNotification(_ notification: Notification) {
        guard let duration = (notification.userInfo?[UIResponder.keyboardAnimationDurationUserInfoKey] as? NSNumber)?.doubleValue,
            let keyboardHeight = (notification.userInfo?[UIResponder.keyboardFrameBeginUserInfoKey] as? NSValue)?.cgRectValue.height else {
                return
        }
        
        animateViewAdjustments(withDuration: duration, keyboardHeight: keyboardHeight)
    }
    
    @IBAction private func didTapCountryView() {
        
    }
    
    private func animateViewAdjustments(withDuration duration: Double, keyboardHeight: CGFloat) {
        navigationController?.setNavigationBarHidden(false, animated: true)
        UIView.animate(withDuration: duration, animations: {
            self.headerImageView.isHidden = true
            self.setNeedsStatusBarAppearanceUpdate()
            self.enableAutomaticAdjustmentContentInsetsBehavior()
            self.nextButtonBottomConstraint.constant = keyboardHeight
        })
    }
    
    @objc private func didReceiveKeyboardWillHideNotification(_ notification: Notification) {
        
    }
    
    private func enableAutomaticAdjustmentContentInsetsBehavior() {
        if #available(iOS 11.0, *) {
            self.scrollView.contentInsetAdjustmentBehavior = .automatic
        } else {
            self.automaticallyAdjustsScrollViewInsets = true
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

extension SMSVerificationViewController: UITextFieldDelegate {
    
}
