import Foundation

extension CustomModalAlertViewController {
    func configureUpgradeAccountThreeButtons(_ titleText: String, _ detailText: String, _ monospaceText: String?, _ imageName: String, hasBonusButton: Bool = true) {
        image = UIImage(named: imageName)
        viewTitle = titleText
        
        if monospaceText != nil {
            monospaceDetail = monospaceText
            detail = detailText + " (ID: " + monospaceDetail + ")"
        } else {
            detail = detailText
        }
        
        firstButtonTitle = NSLocalizedString("seePlans", comment: "Button title to see the available pro plans in MEGA")
        if MEGASdkManager.sharedMEGASdk().isAchievementsEnabled && hasBonusButton {
            secondButtonTitle = NSLocalizedString("general.button.getBonus", comment: "")
        }
        dismissButtonTitle = NSLocalizedString("dismiss", comment: "Label for any 'Dismiss' button, link, text, title, etc. - (String as short as possible).")
        
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
    }
}
