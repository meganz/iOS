import MEGAL10n

extension CustomModalAlertViewController {
    
    func configureForChangeLaunchTab() {
        image = UIImage.changeLaunchTab
        viewTitle = Strings.Localizable.changeLaunchTab
        detail = Strings.Localizable.YouCanNowSelectWhichSectionTheAppOpensAtLaunch.chooseTheOneThatBetterSuitsYourNeedsWhetherItSChatCloudDriveOrHome
        
        firstButtonTitle = Strings.Localizable.changeSetting
        firstButtonStyle = MEGACustomButtonStyle.primary.rawValue
        dismissButtonTitle = Strings.Localizable.dismiss
        dismissButtonStyle = MEGACustomButtonStyle.cancel.rawValue

        firstCompletion = { [weak self] in
            self?.dismiss(animated: true, completion: {
                guard let defaultTabTableViewController = UIStoryboard(name: "Appearance", bundle: nil).instantiateViewController(withIdentifier: "DefaultTabTableViewControllerID") as? DefaultTabTableViewController else {
                    return
                }
                let navigation = UINavigationController(rootViewController: defaultTabTableViewController)
                defaultTabTableViewController.addRightDismissBarButtonItem(with: Strings.Localizable.close)
                UIApplication.mnz_presentingViewController().present(navigation, animated: true, completion: nil)
            })
        }
    }
}
