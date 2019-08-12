
import UIKit

class BusinessExpiredViewController: UIViewController {
    
    @IBOutlet weak var imageView: UIImageView!
    @IBOutlet weak var titleLabel: UILabel!
    @IBOutlet weak var detailLabel: UILabel!
    @IBOutlet weak var dismissButton: UIButton!
    
    override func viewDidLoad() {
        super.viewDidLoad()

        titleLabel.text = NSLocalizedString("Your Account is Expired", comment: "")
        dismissButton.titleLabel?.text = NSLocalizedString("dismiss", comment: "")
        if MEGASdkManager.sharedMEGASdk().isMasterBusinessAccount {
            imageView.image = UIImage(named: "accountExpiredAdmin")
            detailLabel.text = NSLocalizedString("There has been a problem processing your payment. MEGA is limited to view only until this issue has been fixed in a desktop web browser.", comment: "")
        } else {
            imageView.image = UIImage(named: "accountExpiredUser")
            detailLabel.text = NSLocalizedString("Your account has been suspended, please contact your organization administrator for more information.\n\nMEGA is limited to view only.", comment: "")
        }
    }
    
    @IBAction func dismissTouchUpInside(_ sender: UIButton) {
        self.dismiss(animated: true, completion: nil)
    }
}
