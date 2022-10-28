
import UIKit

class AccountExpiredViewController: UIViewController {
    
    var isFetchNodesDone = false
    
    @IBOutlet weak var imageView: UIImageView!
    @IBOutlet weak var titleLabel: UILabel!
    @IBOutlet weak var detailLabel: UILabel!
    @IBOutlet weak var dismissButton: UIButton!
    
    //MARK: - Lifecycle
    
    override func viewDidLoad() {
        super.viewDidLoad()

        MEGASdkManager.sharedMEGASdk().getAccountDetails()
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
    
    //MARK: - Set contents
    
    func configContent() {
        guard let accountDetails = MEGASdkManager.sharedMEGASdk().mnz_accountDetails else { return }
        switch accountDetails.type {
        case .proFlexi:
            configProFlexiAccount()
        case .business:
            configBusinessAccount()
        default:
            return
        }
    }
    
    func configProFlexiAccount() {
        titleLabel.text = Strings.Localizable.Account.Expired.ProFlexi.title
        imageView.image = Asset.Images.Business.accountExpiredAdmin.image
        detailLabel.text = Strings.Localizable.Account.Expired.ProFlexi.message
        dismissButton.setTitle(Strings.Localizable.ok, for: .normal)
    }
    
    func configBusinessAccount() {
        titleLabel.text = Strings.Localizable.yourBusinessAccountIsExpired
        dismissButton.setTitle(Strings.Localizable.dismiss, for: .normal)
        if MEGASdkManager.sharedMEGASdk().isMasterBusinessAccount {
            imageView.image = Asset.Images.Business.accountExpiredAdmin.image
            detailLabel.text = Strings.Localizable.ThereHasBeenAProblemProcessingYourPayment.megaIsLimitedToViewOnlyUntilThisIssueHasBeenFixedInADesktopWebBrowser
        } else {
            imageView.image = Asset.Images.Business.accountExpiredUser.image
            detailLabel.text = Strings.Localizable.YourAccountIsCurrentlyBSuspendedB.youCanOnlyBrowseYourData.replacingOccurrences(of: "[B]", with: "").replacingOccurrences(of: "[/B]", with: "") + "\n\n" + Strings.Localizable.contactYourBusinessAccountAdministratorToResolveTheIssueAndActivateYourAccount
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

extension AccountExpiredViewController: MEGARequestDelegate {
    func onRequestFinish(_ api: MEGASdk, request: MEGARequest, error: MEGAError) {
        guard error.type == .apiOk else { return }
        
        switch request.type {
        case .MEGARequestTypeFetchNodes:
            isFetchNodesDone = true
        case .MEGARequestTypeAccountDetails:
            configContent()
        default:
            return
        }
    }
}
