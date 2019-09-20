
import UIKit

class BusinessExpiredViewController: UIViewController {
    
    var isFetchNodesDone = false
    
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
            detailLabel.text = NSLocalizedString("Your account has been suspended, please contact your organization administrator for more information.\n\nMEGA is limited to view only.", comment: "Details shown when a Business account is expired. Details for users of the Business account")
        }
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        MEGASdkManager.sharedMEGASdk().add(self)
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        
        MEGASdkManager.sharedMEGASdk().remove(self)
    }

    @IBAction func dismissTouchUpInside(_ sender: UIButton) {
        self.dismiss(animated: true) {
            if self.isFetchNodesDone {
                let rootViewController = UIApplication.mnz_presentingViewController()
                if rootViewController.isMember(of: LaunchViewController.self) {
                    guard let launchViewController = rootViewController as? LaunchViewController else {return}
                    if launchViewController.delegate.responds(to: #selector(LaunchViewControllerDelegate.setupFinished)) {
                        launchViewController.delegate.setupFinished()
                    }
                } else if rootViewController.isMember(of: InitialLaunchViewController.self) {
                    guard let initialLaunchViewController = rootViewController as? InitialLaunchViewController else {return}
                    DispatchQueue.main.async {
                        initialLaunchViewController.performAnimation()
                    }
                }
            }
        }
    }
}

extension BusinessExpiredViewController: MEGARequestDelegate {
    func onRequestFinish(_ api: MEGASdk, request: MEGARequest, error: MEGAError) {
        if error.type == .apiOk && request.type == .MEGARequestTypeFetchNodes {
            isFetchNodesDone = true
        }
    }
}
