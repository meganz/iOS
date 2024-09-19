import MEGAL10n
import UIKit

class AccountExpiredViewController: UIViewController {
    
    var isFetchNodesDone = false
    
    @IBOutlet weak var imageView: UIImageView!
    @IBOutlet weak var titleLabel: UILabel!
    @IBOutlet weak var detailLabel: UILabel!
    @IBOutlet weak var dismissButton: UIButton!
    @IBOutlet weak var activityIndicator: UIActivityIndicatorView!
    
    // MARK: - Lifecycle
    
    override func viewDidLoad() {
        super.viewDidLoad()
        getAccountDetails()
        updateAppearance()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        MEGASdk.shared.add(self)
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        
        MEGASdk.shared.remove(self)
    }
    
    override func traitCollectionDidChange(_ previousTraitCollection: UITraitCollection?) {
        super.traitCollectionDidChange(previousTraitCollection)
        
        if traitCollection.hasDifferentColorAppearance(comparedTo: previousTraitCollection) {
            updateAppearance()
        }
    }
    
    // MARK: - Set contents
    func getAccountDetails() {
        activityIndicator.startAnimating()
        MEGASdk.shared.getAccountDetails()
    }
    
    func configContent() {
        guard let accountDetails = MEGASdk.shared.mnz_accountDetails else { return }
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
        imageView.image = UIImage.accountExpiredAdmin
        detailLabel.text = Strings.Localizable.Account.Expired.ProFlexi.message
        dismissButton.setTitle(Strings.Localizable.ok, for: .normal)
    }
    
    func configBusinessAccount() {
        titleLabel.text = Strings.Localizable.yourBusinessAccountIsExpired
        dismissButton.setTitle(Strings.Localizable.dismiss, for: .normal)
        titleLabel.text = Strings.Localizable.yourBusinessAccountIsExpired
        dismissButton.setTitle(Strings.Localizable.dismiss, for: .normal)
        if MEGASdk.shared.isMasterBusinessAccount {
            imageView.image = UIImage.accountExpiredAdmin
            detailLabel.text = Strings.Localizable.ThereHasBeenAProblemProcessingYourPayment.megaIsLimitedToViewOnlyUntilThisIssueHasBeenFixedInADesktopWebBrowser
        } else {
            imageView.image = UIImage.accountExpiredUser
            detailLabel.text = Strings.Localizable.YourAccountIsCurrentlyBSuspendedB.youCanOnlyBrowseYourData.replacingOccurrences(of: "[B]", with: "").replacingOccurrences(of: "[/B]", with: "") + "\n\n" + Strings.Localizable.contactYourBusinessAccountAdministratorToResolveTheIssueAndActivateYourAccount
        }
    }
    
    // MARK: - Private
    
    private func updateAppearance() {
        view.backgroundColor = UIColor.mnz_backgroundElevated()
        
        detailLabel.textColor = .mnz_subtitles()
        dismissButton.mnz_setupCancel(traitCollection)
    }
    
    // MARK: - IBActions
    
    @IBAction func dismissTouchUpInside(_ sender: UIButton) {
        self.dismiss(animated: true) {
            if self.isFetchNodesDone {
                let rootViewController = UIApplication.mnz_presentingViewController()
                if rootViewController.isMember(of: LaunchViewController.self) {
                    guard let launchViewController = rootViewController as? LaunchViewController else {return}
                    if launchViewController.delegate.responds(to: #selector((any LaunchViewControllerDelegate).setupFinished)) {
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
        switch request.type {
        case .MEGARequestTypeFetchNodes:
            guard error.type == .apiOk else { return }
            isFetchNodesDone = true
        case .MEGARequestTypeAccountDetails:
            activityIndicator.stopAnimating()
            guard error.type == .apiOk else {
                MEGALogError("[Account Expired] Error fetching account details with error \(error.localizedDescription).")
                self.dismiss(animated: true)
                return
            }
            configContent()
        default:
            return
        }
    }
}
