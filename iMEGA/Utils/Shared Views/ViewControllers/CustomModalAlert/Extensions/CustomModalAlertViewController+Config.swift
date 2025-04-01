import Foundation
import MEGAAnalyticsiOS
import MEGAAppPresentation
import MEGAL10n

extension CustomModalAlertViewController {
    func configureUpgradeAccountThreeButtons(_ titleText: String, _ detailText: String, _ monospaceText: String?, _ image: UIImage?, hasBonusButton: Bool = true, firstButtonTitle: String = Strings.Localizable.seePlans, dismissTitle: String = Strings.Localizable.dismiss, analyticsEvents: CustomModalAlertViewModel.CustomModalAlertViewAnalyticEvents? = nil) {
        if let image {
            self.image = image
        }
        viewTitle = titleText
        
        if monospaceText != nil {
            monospaceDetail = monospaceText
            detail = detailText + " (ID: " + monospaceDetail + ")"
        } else {
            detail = detailText
        }
        
        self.firstButtonTitle = firstButtonTitle
        if MEGASdk.shared.isAchievementsEnabled && hasBonusButton {
            secondButtonTitle = Strings.Localizable.General.Button.getBonus
        }
        dismissButtonTitle = dismissTitle
        
        firstCompletion = { [weak self] in
            self?.dismiss(animated: true, completion: {
                UpgradeAccountRouter().presentUpgradeTVC()
            })
        }
        
        secondCompletion = { [weak self] in
            self?.dismiss(animated: true, completion: {
                guard let achievementsVC = UIStoryboard(name: "Achievements", bundle: nil).instantiateViewController(withIdentifier: "AchievementsViewControllerID") as? AchievementsViewController else {
                    fatalError("Could not instantiate AchievementsViewController")
                }
                achievementsVC.enableCloseBarButton = true
                
                let navigationVC = UINavigationController(rootViewController: achievementsVC)
                UIApplication.mnz_presentingViewController().present(navigationVC, animated: true, completion: nil)
            })
        }
        
        dismissCompletion = { [weak self] in
            self?.dismiss(animated: true, completion: nil)
        }
        
        viewModel = .init(tracker: DIContainer.tracker,
                          analyticsEvents: analyticsEvents)
    }
    
    func configureUpgradeAccountDetailText(_ detailText: String) {
        setDetailLabelText(detailText)
    }
}
