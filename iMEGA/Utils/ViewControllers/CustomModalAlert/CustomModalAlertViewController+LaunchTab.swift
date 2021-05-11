extension CustomModalAlertViewController {
    
    func configureForChangeLaunchTab() {
        image = UIImage(named: "changeLaunchTab")
        viewTitle = NSLocalizedString("Change Launch Tab", comment: "Dialog title for the change launch tab screen")
        detail = NSLocalizedString("You can now select which section the app opens at launch. Choose the one that better suits your needs, whether it’s Chat, Cloud Drive, or Home.", comment: "Dialog description for the change launch tab screen")
        
        firstButtonTitle = NSLocalizedString("Change Setting", comment: "Dialog button text for the change launch tab screen")
        firstButtonStyle = MEGACustomButtonStyle.basic.rawValue
        dismissButtonTitle = NSLocalizedString("dismiss", comment: "")
        dismissButtonStyle = MEGACustomButtonStyle.cancel.rawValue

        firstCompletion = { [weak self] in
            self?.dismiss(animated: true, completion: {
                guard let defaultTabTableViewController = UIStoryboard(name: "Appearance", bundle: nil).instantiateViewController(withIdentifier: "DefaultTabTableViewControllerID") as? DefaultTabTableViewController else {
                    return
                }
                let navigation = UINavigationController(rootViewController: defaultTabTableViewController)
                defaultTabTableViewController.addRightCancelBarButtonItem()
                UIApplication.mnz_presentingViewController().present(navigation, animated: true, completion: nil)
            })
        }
    }
}
