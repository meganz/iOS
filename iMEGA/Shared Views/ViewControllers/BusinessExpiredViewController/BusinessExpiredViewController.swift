
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

        titleLabel.text = Strings.Localizable.yourBusinessAccountIsExpired
        dismissButton.titleLabel?.text = Strings.Localizable.dismiss
        if MEGASdkManager.sharedMEGASdk().isMasterBusinessAccount {
            imageView.image = Asset.Images.Business.accountExpiredAdmin.image
            detailLabel.text = Strings.Localizable.ThereHasBeenAProblemProcessingYourPayment.megaIsLimitedToViewOnlyUntilThisIssueHasBeenFixedInADesktopWebBrowser
        } else {
            imageView.image = Asset.Images.Business.accountExpiredUser.image
            detailLabel.text = Strings.Localizable.YourAccountIsCurrentlyBSuspendedB.youCanOnlyBrowseYourData.replacingOccurrences(of: "[B]", with: "").replacingOccurrences(of: "[/B]", with: "") + "\n\n" + Strings.Localizable.contactYourBusinessAccountAdministratorToResolveTheIssueAndActivateYourAccount
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
        
        if traitCollection.hasDifferentColorAppearance(comparedTo: previousTraitCollection) {
            updateAppearance()
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
