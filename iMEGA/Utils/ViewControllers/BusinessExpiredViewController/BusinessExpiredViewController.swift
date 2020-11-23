
import UIKit

class BusinessExpiredViewController: UIViewController {
    
    var isFetchNodesDone = false
    
    @IBOutlet weak var imageView: UIImageView!
    @IBOutlet weak var titleLabel: UILabel!
    @IBOutlet weak var detailLabel: UILabel!
    @IBOutlet weak var dismissButton: UIButton!
    
    //MARK: - Lifecycle
    
    override func viewDidLoad() {
        super.viewDidLoad()

        titleLabel.text = AMLocalizedString("Your business account is expired", "A dialog title shown to users when their business account is expired.")
        dismissButton.titleLabel?.text = AMLocalizedString("dismiss", "")
        if MEGASdkManager.sharedMEGASdk().isMasterBusinessAccount {
            imageView.image = UIImage(named: "accountExpiredAdmin")
            detailLabel.text = AMLocalizedString("There has been a problem processing your payment. MEGA is limited to view only until this issue has been fixed in a desktop web browser.", "Details shown when a Business account is expired. Details for the administrator of the Business account")
        } else {
            imageView.image = UIImage(named: "accountExpiredUser")
            detailLabel.text = AMLocalizedString("Your account is currently [B]suspended[/B]. You can only browse your data.", "A dialog message which is shown to sub-users of expired business accounts.").replacingOccurrences(of: "[B]", with: "").replacingOccurrences(of: "[/B]", with: "") + "\n\n" + AMLocalizedString("Contact your business account administrator to resolve the issue and activate your account.", "A dialog message which is shown to sub-users of expired business accounts.");
        }
        
        updateAppearance()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        MEGASdkManager.sharedMEGASdk().add(self)
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        
        MEGASdkManager.sharedMEGASdk().remove(self)
    }
    
    override func traitCollectionDidChange(_ previousTraitCollection: UITraitCollection?) {
        super.traitCollectionDidChange(previousTraitCollection)
        
        if #available(iOS 13, *) {
            if traitCollection.hasDifferentColorAppearance(comparedTo: previousTraitCollection) {
                updateAppearance()
            }
        }
    }
    
    //MARK: - Private
    
    private func updateAppearance() {
        view.backgroundColor = UIColor.mnz_backgroundElevated(traitCollection)
        
        detailLabel.textColor = .mnz_subtitles(for: traitCollection)
        
        dismissButton.mnz_setupCancel(traitCollection)
    }
    
    //MARK: - IBActions
    
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
